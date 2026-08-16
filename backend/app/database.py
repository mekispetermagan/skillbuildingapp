from __future__ import annotations

import hashlib
import json
import sqlite3
from contextlib import contextmanager
from datetime import UTC, datetime
from pathlib import Path
from typing import Iterator

from .models import (
    InstallationRegistration,
    PlayRecord,
    RecordAcknowledgement,
    RecordBatchAcknowledgement,
)


SCHEMA = """
CREATE TABLE IF NOT EXISTS installations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS play_records (
    installation_id INTEGER NOT NULL,
    record_number INTEGER NOT NULL,
    area_id TEXT NOT NULL,
    feature_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    score INTEGER,
    rating INTEGER NOT NULL,
    metrics_json TEXT NOT NULL,
    started_at TEXT NOT NULL,
    completed_at TEXT NOT NULL,
    elapsed_milliseconds INTEGER NOT NULL,
    app_version TEXT NOT NULL,
    content_version TEXT NOT NULL,
    schema_version INTEGER NOT NULL,
    payload_json TEXT NOT NULL,
    payload_hash TEXT NOT NULL,
    received_at TEXT NOT NULL,
    PRIMARY KEY (installation_id, record_number),
    FOREIGN KEY (installation_id) REFERENCES installations(id)
);

CREATE TABLE IF NOT EXISTS record_conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    installation_id INTEGER NOT NULL,
    record_number INTEGER NOT NULL,
    accepted_payload_hash TEXT NOT NULL,
    conflicting_payload_hash TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    received_at TEXT NOT NULL,
    FOREIGN KEY (installation_id, record_number)
        REFERENCES play_records(installation_id, record_number),
    UNIQUE (installation_id, record_number, conflicting_payload_hash)
);

CREATE INDEX IF NOT EXISTS play_records_feature_index
    ON play_records(area_id, feature_id);
"""


class Database:
    def __init__(self, path: Path):
        self.path = path

    def initialize(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as connection:
            connection.execute("PRAGMA journal_mode = WAL")
            connection.executescript(SCHEMA)

    @contextmanager
    def connect(self) -> Iterator[sqlite3.Connection]:
        connection = sqlite3.connect(self.path, timeout=10)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("PRAGMA busy_timeout = 10000")
        try:
            yield connection
        finally:
            connection.close()

    def register_installation(self) -> InstallationRegistration:
        with self.connect() as connection:
            cursor = connection.execute(
                "INSERT INTO installations(created_at) VALUES (?)",
                (_now(),),
            )
            connection.commit()
            installation_id = cursor.lastrowid
            if installation_id is None:
                raise RuntimeError("SQLite did not allocate an installation ID")
            return InstallationRegistration(
                installation_id=installation_id,
                next_record_number=1,
            )

    def store_batch(
        self,
        installation_id: int,
        records: list[PlayRecord],
    ) -> RecordBatchAcknowledgement | None:
        acknowledgements: list[RecordAcknowledgement] = []
        with self.connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            installation = connection.execute(
                "SELECT id FROM installations WHERE id = ?",
                (installation_id,),
            ).fetchone()
            if installation is None:
                connection.rollback()
                return None

            for record in records:
                payload_json = _canonical_payload(record)
                payload_hash = hashlib.sha256(payload_json.encode()).hexdigest()
                existing = connection.execute(
                    """
                    SELECT payload_hash
                    FROM play_records
                    WHERE installation_id = ? AND record_number = ?
                    """,
                    (installation_id, record.record_number),
                ).fetchone()
                if existing is None:
                    self._insert_record(
                        connection,
                        record,
                        payload_json=payload_json,
                        payload_hash=payload_hash,
                    )
                    acknowledgements.append(
                        RecordAcknowledgement(
                            record_number=record.record_number,
                            status="accepted",
                        )
                    )
                elif existing["payload_hash"] == payload_hash:
                    acknowledgements.append(
                        RecordAcknowledgement(
                            record_number=record.record_number,
                            status="already_accepted",
                        )
                    )
                else:
                    conflict_id = self._store_conflict(
                        connection,
                        record,
                        accepted_payload_hash=existing["payload_hash"],
                        conflicting_payload_hash=payload_hash,
                        payload_json=payload_json,
                    )
                    acknowledgements.append(
                        RecordAcknowledgement(
                            record_number=record.record_number,
                            status="stored_as_conflict",
                            conflict_reference=(
                                f"{installation_id}-{record.record_number}-e{conflict_id}"
                            ),
                        )
                    )

            maximum = connection.execute(
                """
                SELECT COALESCE(MAX(record_number), 0) AS maximum
                FROM play_records
                WHERE installation_id = ?
                """,
                (installation_id,),
            ).fetchone()["maximum"]
            connection.commit()
        return RecordBatchAcknowledgement(
            installation_id=installation_id,
            next_record_number=maximum + 1,
            acknowledgements=acknowledgements,
        )

    def _insert_record(
        self,
        connection: sqlite3.Connection,
        record: PlayRecord,
        *,
        payload_json: str,
        payload_hash: str,
    ) -> None:
        connection.execute(
            """
            INSERT INTO play_records(
                installation_id, record_number, area_id, feature_id, outcome,
                score, rating, metrics_json, started_at, completed_at,
                elapsed_milliseconds, app_version, content_version,
                schema_version, payload_json, payload_hash, received_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                record.installation_id,
                record.record_number,
                record.area_id,
                record.feature_id,
                record.outcome,
                record.score,
                record.rating,
                json.dumps(record.metrics.model_dump(mode="json"), sort_keys=True),
                record.started_at.isoformat(),
                record.completed_at.isoformat(),
                record.elapsed_milliseconds,
                record.app_version,
                record.content_version,
                record.schema_version,
                payload_json,
                payload_hash,
                _now(),
            ),
        )

    def _store_conflict(
        self,
        connection: sqlite3.Connection,
        record: PlayRecord,
        *,
        accepted_payload_hash: str,
        conflicting_payload_hash: str,
        payload_json: str,
    ) -> int:
        connection.execute(
            """
            INSERT OR IGNORE INTO record_conflicts(
                installation_id, record_number, accepted_payload_hash,
                conflicting_payload_hash, payload_json, received_at
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                record.installation_id,
                record.record_number,
                accepted_payload_hash,
                conflicting_payload_hash,
                payload_json,
                _now(),
            ),
        )
        conflict = connection.execute(
            """
            SELECT id
            FROM record_conflicts
            WHERE installation_id = ?
              AND record_number = ?
              AND conflicting_payload_hash = ?
            """,
            (
                record.installation_id,
                record.record_number,
                conflicting_payload_hash,
            ),
        ).fetchone()
        if conflict is None:
            raise RuntimeError("SQLite did not store the conflicting record")
        return conflict["id"]


def _canonical_payload(record: PlayRecord) -> str:
    return json.dumps(
        record.model_dump(mode="json"),
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    )


def _now() -> str:
    return datetime.now(UTC).isoformat()


from __future__ import annotations

import hashlib
import json
import secrets
import sqlite3
from contextlib import contextmanager
from datetime import UTC, datetime
from pathlib import Path
from typing import Iterator

from .models import (
    AccountRegistration,
    AuthenticatedIdentity,
    AuthenticatedAccount,
    InstallationRegistration,
    PlayRecord,
    StudentProfile,
    RecordAcknowledgement,
    RecordBatchAcknowledgement,
)


SCHEMA = """
CREATE TABLE IF NOT EXISTS installations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE COLLATE NOCASE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('learner', 'teacher')),
    preferred_language TEXT NOT NULL CHECK (preferred_language IN ('en', 'de', 'hu')),
    location TEXT NOT NULL,
    age INTEGER CHECK (age BETWEEN 1 AND 120),
    gender TEXT CHECK (gender IN ('male', 'female', 'other_or_prefer_not_to_say')),
    pin_salt TEXT NOT NULL,
    pin_hash TEXT NOT NULL,
    access_token_hash TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    teacher_account_id INTEGER NOT NULL,
    client_id TEXT NOT NULL,
    name TEXT NOT NULL,
    location TEXT NOT NULL,
    age INTEGER NOT NULL CHECK (age BETWEEN 1 AND 120),
    gender TEXT NOT NULL CHECK (
        gender IN ('male', 'female', 'other_or_prefer_not_to_say')
    ),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (teacher_account_id) REFERENCES accounts(id),
    UNIQUE (teacher_account_id, client_id)
);

CREATE TABLE IF NOT EXISTS play_records (
    installation_id INTEGER NOT NULL,
    record_number INTEGER NOT NULL,
    area_id TEXT NOT NULL,
    feature_id TEXT NOT NULL,
    outcome TEXT NOT NULL,
    score INTEGER,
    rating INTEGER,
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
            self._migrate_nullable_rating(connection)
            self._migrate_player_columns(connection)

    def _migrate_player_columns(self, connection: sqlite3.Connection) -> None:
        columns = {
            column["name"]
            for column in connection.execute("PRAGMA table_info(play_records)")
        }
        additions = {
            "account_id": "INTEGER REFERENCES accounts(id)",
            "student_id": "INTEGER REFERENCES students(id)",
            "player_type": "TEXT CHECK (player_type IN ('learner', 'student'))",
            "student_client_id": "TEXT",
        }
        for name, definition in additions.items():
            if name not in columns:
                connection.execute(
                    f"ALTER TABLE play_records ADD COLUMN {name} {definition}"
                )

    def _migrate_nullable_rating(self, connection: sqlite3.Connection) -> None:
        columns = connection.execute("PRAGMA table_info(play_records)").fetchall()
        rating = next((column for column in columns if column["name"] == "rating"), None)
        if rating is None or rating["notnull"] == 0:
            return

        connection.execute("PRAGMA foreign_keys = OFF")
        try:
            connection.executescript(
                """
                BEGIN IMMEDIATE;
                ALTER TABLE record_conflicts RENAME TO record_conflicts_legacy;
                ALTER TABLE play_records RENAME TO play_records_legacy;

                CREATE TABLE play_records (
                    installation_id INTEGER NOT NULL,
                    record_number INTEGER NOT NULL,
                    area_id TEXT NOT NULL,
                    feature_id TEXT NOT NULL,
                    outcome TEXT NOT NULL,
                    score INTEGER,
                    rating INTEGER,
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

                INSERT INTO play_records SELECT * FROM play_records_legacy;

                CREATE TABLE record_conflicts (
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

                INSERT INTO record_conflicts SELECT * FROM record_conflicts_legacy;
                DROP TABLE record_conflicts_legacy;
                DROP TABLE play_records_legacy;
                DROP INDEX IF EXISTS play_records_feature_index;
                CREATE INDEX play_records_feature_index
                    ON play_records(area_id, feature_id);
                COMMIT;
                """
            )
        except BaseException:
            if connection.in_transaction:
                connection.rollback()
            raise
        finally:
            connection.execute("PRAGMA foreign_keys = ON")

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

    def register_account(
        self, registration: AccountRegistration
    ) -> AuthenticatedAccount | None:
        salt = secrets.token_bytes(16)
        token = secrets.token_urlsafe(32)
        with self.connect() as connection:
            try:
                cursor = connection.execute(
                    """
                    INSERT INTO accounts(
                        username, name, role, preferred_language, location, age, gender,
                        pin_salt, pin_hash,
                        access_token_hash, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        registration.username,
                        registration.name,
                        registration.role,
                        registration.preferred_language,
                        registration.location,
                        registration.age,
                        registration.gender,
                        salt.hex(),
                        _pin_hash(registration.pin, salt),
                        _token_hash(token),
                        _now(),
                    ),
                )
                connection.commit()
            except sqlite3.IntegrityError:
                return None
        account_id = cursor.lastrowid
        if account_id is None:
            raise RuntimeError("SQLite did not allocate an account ID")
        return AuthenticatedAccount(
            account_id=account_id,
            username=registration.username,
            name=registration.name,
            role=registration.role,
            preferred_language=registration.preferred_language,
            location=registration.location,
            age=registration.age,
            gender=registration.gender,
            access_token=token,
        )

    def authenticate_account(
        self, username: str, pin: str
    ) -> AuthenticatedAccount | None:
        with self.connect() as connection:
            account = connection.execute(
                """
                SELECT id, username, name, role, preferred_language, location,
                       age, gender, pin_salt, pin_hash
                FROM accounts WHERE username = ?
                """,
                (username,),
            ).fetchone()
            if account is None:
                return None
            salt = bytes.fromhex(account["pin_salt"])
            supplied_hash = _pin_hash(pin, salt)
            if not secrets.compare_digest(supplied_hash, account["pin_hash"]):
                return None
            token = secrets.token_urlsafe(32)
            connection.execute(
                "UPDATE accounts SET access_token_hash = ? WHERE id = ?",
                (_token_hash(token), account["id"]),
            )
            connection.commit()
        return AuthenticatedAccount(
            account_id=account["id"],
            username=account["username"],
            name=account["name"],
            role=account["role"],
            preferred_language=account["preferred_language"],
            location=account["location"],
            age=account["age"],
            gender=account["gender"],
            access_token=token,
        )

    def resolve_access_token(self, token: str) -> AuthenticatedIdentity | None:
        with self.connect() as connection:
            account = connection.execute(
                "SELECT id, role FROM accounts WHERE access_token_hash = ?",
                (_token_hash(token),),
            ).fetchone()
        if account is None:
            return None
        return AuthenticatedIdentity(
            account_id=account["id"],
            role=account["role"],
        )

    def update_preferred_language(
        self, account_id: int, preferred_language: str
    ) -> None:
        with self.connect() as connection:
            connection.execute(
                "UPDATE accounts SET preferred_language = ? WHERE id = ?",
                (preferred_language, account_id),
            )
            connection.commit()

    def sync_students(
        self, teacher_account_id: int, students: list[StudentProfile]
    ) -> list[StudentProfile]:
        now = _now()
        with self.connect() as connection:
            connection.execute("BEGIN IMMEDIATE")
            for student in students:
                connection.execute(
                    """
                    INSERT INTO students(
                        teacher_account_id, client_id, name, location, age,
                        gender, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(teacher_account_id, client_id) DO UPDATE SET
                        name = excluded.name,
                        location = excluded.location,
                        age = excluded.age,
                        gender = excluded.gender,
                        updated_at = excluded.updated_at
                    """,
                    (
                        teacher_account_id,
                        student.client_id,
                        student.name,
                        student.location,
                        student.age,
                        student.gender,
                        now,
                        now,
                    ),
                )
            connection.commit()
        return self.list_students(teacher_account_id)

    def list_students(self, teacher_account_id: int) -> list[StudentProfile]:
        with self.connect() as connection:
            rows = connection.execute(
                """
                SELECT client_id, name, location, age, gender
                FROM students WHERE teacher_account_id = ? ORDER BY id
                """,
                (teacher_account_id,),
            ).fetchall()
        return [StudentProfile(**dict(row)) for row in rows]

    def resolve_installation(
        self, installation_id: int
    ) -> InstallationRegistration | None:
        with self.connect() as connection:
            installation = connection.execute(
                "SELECT id FROM installations WHERE id = ?",
                (installation_id,),
            ).fetchone()
            if installation is None:
                return None
            maximum = connection.execute(
                """
                SELECT COALESCE(MAX(record_number), 0) AS maximum
                FROM play_records
                WHERE installation_id = ?
                """,
                (installation_id,),
            ).fetchone()["maximum"]
        return InstallationRegistration(
            installation_id=installation_id,
            next_record_number=maximum + 1,
        )

    def store_batch(
        self,
        installation_id: int,
        records: list[PlayRecord],
        identity: AuthenticatedIdentity | None = None,
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
                player = self._resolve_record_player(connection, record, identity)
                if player is None:
                    connection.rollback()
                    raise PermissionError("Record player is not owned by this account")
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
                        account_id=player[0],
                        student_id=player[1],
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
        account_id: int | None,
        student_id: int | None,
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
                , account_id, student_id, player_type, student_client_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                account_id,
                student_id,
                record.player_type,
                record.student_client_id,
            ),
        )

    def _resolve_record_player(
        self,
        connection: sqlite3.Connection,
        record: PlayRecord,
        identity: AuthenticatedIdentity | None,
    ) -> tuple[int | None, int | None] | None:
        if record.player_type is None:
            return (None, None)
        if identity is None:
            return None
        if record.player_type == "learner":
            return (identity.account_id, None) if identity.role == "learner" else None
        if identity.role != "teacher":
            return None
        student = connection.execute(
            """
            SELECT id FROM students
            WHERE teacher_account_id = ? AND client_id = ?
            """,
            (identity.account_id, record.student_client_id),
        ).fetchone()
        return None if student is None else (identity.account_id, student["id"])

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
    payload = record.model_dump(mode="json")
    if record.player_type is None:
        payload.pop("player_type", None)
        payload.pop("student_client_id", None)
    return json.dumps(
        payload,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    )


def _now() -> str:
    return datetime.now(UTC).isoformat()


def _pin_hash(pin: str, salt: bytes) -> str:
    return hashlib.scrypt(
        pin.encode(), salt=salt, n=2**14, r=8, p=1, dklen=32
    ).hex()


def _token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()

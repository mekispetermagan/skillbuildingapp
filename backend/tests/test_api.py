from __future__ import annotations

import sqlite3
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


API_KEY = "test-prepilot-key"


@pytest.fixture
def database_path(tmp_path: Path) -> Path:
    return tmp_path / "test.db"


@pytest.fixture
def client(database_path: Path):
    app = create_app(Settings(database_path=database_path, api_key=API_KEY))
    with TestClient(app) as test_client:
        yield test_client


def headers() -> dict[str, str]:
    return {"X-API-Key": API_KEY}


def record(installation_id: int, number: int, *, rating: int = 4) -> dict:
    return {
        "schema_version": 1,
        "installation_id": installation_id,
        "record_number": number,
        "area_id": "literacy",
        "feature_id": "phrase_building",
        "outcome": "won",
        "score": 10,
        "rating": rating,
        "metrics": {
            "type": "attempts",
            "schema_version": 1,
            "correct_answers": 10,
            "incorrect_attempts": 2,
        },
        "started_at": "2026-08-16T09:00:00.000Z",
        "completed_at": "2026-08-16T09:02:00.000Z",
        "elapsed_milliseconds": 118000,
        "app_version": "0.1.0+1",
        "content_version": "en-1",
    }


def register(client: TestClient) -> int:
    response = client.post(
        "/installations",
        headers=headers(),
        json={"installation_id": None},
    )
    assert response.status_code == 201
    assert response.json()["next_record_number"] == 1
    return response.json()["installation_id"]


def test_api_key_is_required(client: TestClient):
    response = client.post("/installations", json={"installation_id": None})

    assert response.status_code == 401


def test_registers_monotonic_installation_ids(client: TestClient):
    first = register(client)
    second = register(client)

    assert second == first + 1


def test_resolves_an_installation_with_the_authoritative_next_number(
    client: TestClient,
):
    installation_id = register(client)
    client.post(
        "/records/batch",
        headers=headers(),
        json={
            "installation_id": installation_id,
            "records": [record(installation_id, 1), record(installation_id, 2)],
        },
    )

    response = client.post(
        "/installations",
        headers=headers(),
        json={"installation_id": installation_id},
    )

    assert response.status_code == 200
    assert response.json() == {
        "installation_id": installation_id,
        "next_record_number": 3,
    }


def test_rejects_an_unknown_installation_during_resolution(client: TestClient):
    response = client.post(
        "/installations",
        headers=headers(),
        json={"installation_id": 999},
    )

    assert response.status_code == 404
    assert response.json() == {"detail": "Installation does not exist."}


def test_accepts_a_batch_and_acknowledges_an_identical_retry(client: TestClient):
    installation_id = register(client)
    payload = {
        "installation_id": installation_id,
        "records": [record(installation_id, 1), record(installation_id, 2)],
    }

    accepted = client.post("/records/batch", headers=headers(), json=payload)
    repeated = client.post("/records/batch", headers=headers(), json=payload)

    assert accepted.status_code == 200
    assert [item["status"] for item in accepted.json()["acknowledgements"]] == [
        "accepted",
        "accepted",
    ]
    assert accepted.json()["next_record_number"] == 3
    assert [item["status"] for item in repeated.json()["acknowledgements"]] == [
        "already_accepted",
        "already_accepted",
    ]


def test_preserves_and_reuses_a_conflicting_duplicate(
    client: TestClient,
    database_path: Path,
):
    installation_id = register(client)
    original = {
        "installation_id": installation_id,
        "records": [record(installation_id, 1)],
    }
    conflicting = {
        "installation_id": installation_id,
        "records": [record(installation_id, 1, rating=1)],
    }
    client.post("/records/batch", headers=headers(), json=original)

    first = client.post("/records/batch", headers=headers(), json=conflicting)
    repeated = client.post("/records/batch", headers=headers(), json=conflicting)

    first_ack = first.json()["acknowledgements"][0]
    repeated_ack = repeated.json()["acknowledgements"][0]
    assert first_ack["status"] == "stored_as_conflict"
    assert first_ack["conflict_reference"] == repeated_ack["conflict_reference"]
    assert first.json()["next_record_number"] == 2

    with sqlite3.connect(database_path) as connection:
        assert connection.execute("SELECT COUNT(*) FROM play_records").fetchone()[0] == 1
        assert (
            connection.execute("SELECT COUNT(*) FROM record_conflicts").fetchone()[0]
            == 1
        )


def test_rejects_unknown_installations_and_invalid_contracts(client: TestClient):
    missing = client.post(
        "/records/batch",
        headers=headers(),
        json={"installation_id": 999, "records": [record(999, 1)]},
    )
    assert missing.status_code == 404

    installation_id = register(client)
    invalid_record = record(installation_id, 1)
    invalid_record["rating"] = 6
    invalid = client.post(
        "/records/batch",
        headers=headers(),
        json={"installation_id": installation_id, "records": [invalid_record]},
    )
    assert invalid.status_code == 422


def test_rejects_oversized_batches(database_path: Path):
    app = create_app(
        Settings(
            database_path=database_path,
            api_key=API_KEY,
            maximum_batch_size=1,
        )
    )
    with TestClient(app) as client:
        installation_id = register(client)
        response = client.post(
            "/records/batch",
            headers=headers(),
            json={
                "installation_id": installation_id,
                "records": [record(installation_id, 1), record(installation_id, 2)],
            },
        )

    assert response.status_code == 413

from __future__ import annotations

import sqlite3
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.database import Database, SCHEMA
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


def account_headers(access_token: str) -> dict[str, str]:
    return {**headers(), "Authorization": f"Bearer {access_token}"}


def register_account(client: TestClient, username: str, role: str) -> dict:
    profile = {
        "name": username.replace(".", " ").title(),
        "preferred_language": "en",
        "location": "Kampala",
        "age": 10 if role == "learner" else None,
        "gender": "female" if role == "learner" else None,
    }
    response = client.post(
        "/auth/register",
        headers=headers(),
        json={
            "username": username,
            "pin": "123456",
            "role": role,
            **profile,
        },
    )
    assert response.status_code == 201
    return response.json()


def test_initialization_migrates_a_legacy_required_rating(database_path: Path):
    legacy_schema = SCHEMA.replace("rating INTEGER,", "rating INTEGER NOT NULL,")
    with sqlite3.connect(database_path) as connection:
        connection.executescript(legacy_schema)

    Database(database_path).initialize()

    with sqlite3.connect(database_path) as connection:
        rating_column = next(
            column
            for column in connection.execute("PRAGMA table_info(play_records)")
            if column[1] == "rating"
        )
    assert rating_column[3] == 0


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


def test_registers_and_authenticates_both_account_roles(client: TestClient):
    for index, role in enumerate(("learner", "teacher"), start=1):
        username = f"User_{index}"
        profile = {
            "preferred_language": "en",
            "location": "Kampala",
            "age": 10 if role == "learner" else None,
            "gender": "female" if role == "learner" else None,
        }
        registered = client.post(
            "/auth/register",
            headers=headers(),
            json={
                "username": username,
                "name": f"User {index}",
                "pin": "123456",
                "role": role,
                **profile,
            },
        )

        assert registered.status_code == 201
        assert registered.json()["username"] == username.lower()
        assert registered.json()["role"] == role
        assert registered.json()["preferred_language"] == "en"
        assert registered.json()["location"] == "Kampala"
        assert registered.json()["age"] == profile["age"]
        assert registered.json()["gender"] == profile["gender"]
        assert registered.json()["access_token"]

        logged_in = client.post(
            "/auth/login",
            headers=headers(),
            json={"username": username.upper(), "pin": "123456"},
        )
        assert logged_in.status_code == 200
        assert logged_in.json()["account_id"] == registered.json()["account_id"]
        assert logged_in.json()["access_token"] != registered.json()["access_token"]


def test_rejects_duplicate_username_and_invalid_credentials(client: TestClient):
    payload = {
        "username": "teacher.one",
        "name": "Teacher One",
        "pin": "654321",
        "role": "teacher",
        "preferred_language": "hu",
        "location": "Budapest",
    }
    assert client.post("/auth/register", headers=headers(), json=payload).status_code == 201

    duplicate = client.post(
        "/auth/register",
        headers=headers(),
        json={**payload, "username": "TEACHER.ONE"},
    )
    wrong_pin = client.post(
        "/auth/login",
        headers=headers(),
        json={"username": payload["username"], "pin": "000000"},
    )

    assert duplicate.status_code == 409
    assert wrong_pin.status_code == 401
    assert wrong_pin.json() == {"detail": "Invalid username or PIN."}


@pytest.mark.parametrize(
    ("overrides"),
    [
        {"username": "ab"},
        {"pin": "12345"},
        {"pin": "abcdef"},
        {"role": "administrator"},
        {"preferred_language": "fr"},
        {"location": "   "},
        {"age": None},
        {"gender": None},
    ],
)
def test_rejects_invalid_account_registration_contracts(
    client: TestClient, overrides: dict
):
    payload = {
        "username": "valid-user",
        "name": "Valid User",
        "pin": "123456",
        "role": "learner",
        "preferred_language": "de",
        "location": "Berlin",
        "age": 12,
        "gender": "other_or_prefer_not_to_say",
    }
    response = client.post(
        "/auth/register",
        headers=headers(),
        json={**payload, **overrides},
    )

    assert response.status_code == 422


def test_rejects_learner_fields_for_a_teacher(client: TestClient):
    response = client.post(
        "/auth/register",
        headers=headers(),
        json={
            "username": "teacher",
            "pin": "123456",
            "role": "teacher",
            "preferred_language": "en",
            "location": "Kampala",
            "age": 30,
            "gender": "male",
        },
    )

    assert response.status_code == 422


def test_teacher_synchronizes_owned_students(client: TestClient):
    teacher = register_account(client, "teacher.sync", "teacher")
    student = {
        "client_id": "device-student-1",
        "name": "Student One",
        "location": "Kampala",
        "age": 10,
        "gender": "female",
    }

    created = client.put(
        "/students/sync",
        headers=account_headers(teacher["access_token"]),
        json={"students": [student]},
    )
    listed = client.get(
        "/students",
        headers=account_headers(teacher["access_token"]),
    )

    assert created.status_code == 200
    assert created.json() == [student]
    assert listed.json() == [student]


def test_students_are_isolated_between_teachers(client: TestClient):
    first = register_account(client, "teacher.first", "teacher")
    second = register_account(client, "teacher.second", "teacher")
    student = {
        "client_id": "shared-looking-id",
        "name": "First Student",
        "location": "Kampala",
        "age": 9,
        "gender": "male",
    }
    client.put(
        "/students/sync",
        headers=account_headers(first["access_token"]),
        json={"students": [student]},
    )

    response = client.get(
        "/students",
        headers=account_headers(second["access_token"]),
    )

    assert response.status_code == 200
    assert response.json() == []


def test_assigns_gameplay_to_owned_student(
    client: TestClient, database_path: Path
):
    teacher = register_account(client, "teacher.records", "teacher")
    student = {
        "client_id": "student-record-owner",
        "name": "Student Owner",
        "location": "Kampala",
        "age": 11,
        "gender": "other_or_prefer_not_to_say",
    }
    client.put(
        "/students/sync",
        headers=account_headers(teacher["access_token"]),
        json={"students": [student]},
    )
    installation_id = register(client)
    assigned = record(installation_id, 1)
    assigned.update(
        {"player_type": "student", "student_client_id": student["client_id"]}
    )

    response = client.post(
        "/records/batch",
        headers=account_headers(teacher["access_token"]),
        json={"installation_id": installation_id, "records": [assigned]},
    )

    assert response.status_code == 200
    with sqlite3.connect(database_path) as connection:
        stored = connection.execute(
            "SELECT account_id, student_id, player_type FROM play_records"
        ).fetchone()
    assert stored[0] == teacher["account_id"]
    assert stored[1] is not None
    assert stored[2] == "student"


def test_rejects_a_student_record_not_owned_by_teacher(client: TestClient):
    teacher = register_account(client, "teacher.no.student", "teacher")
    installation_id = register(client)
    assigned = record(installation_id, 1)
    assigned.update(
        {"player_type": "student", "student_client_id": "unknown-student"}
    )

    response = client.post(
        "/records/batch",
        headers=account_headers(teacher["access_token"]),
        json={"installation_id": installation_id, "records": [assigned]},
    )

    assert response.status_code == 403


def test_assigns_gameplay_to_learner_account(
    client: TestClient, database_path: Path
):
    learner = register_account(client, "learner.records", "learner")
    installation_id = register(client)
    assigned = record(installation_id, 1)
    assigned["player_type"] = "learner"

    response = client.post(
        "/records/batch",
        headers=account_headers(learner["access_token"]),
        json={"installation_id": installation_id, "records": [assigned]},
    )

    assert response.status_code == 200
    with sqlite3.connect(database_path) as connection:
        stored = connection.execute(
            "SELECT account_id, student_id, player_type FROM play_records"
        ).fetchone()
    assert stored == (learner["account_id"], None, "learner")


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


def test_accepts_an_unrated_abandoned_play_with_partial_metrics(
    client: TestClient,
    database_path: Path,
):
    installation_id = register(client)
    abandoned = record(installation_id, 1)
    abandoned.update(
        {
            "outcome": "abandoned",
            "score": None,
            "rating": None,
            "feature_id": "memory_cards",
            "metrics": {
                "type": "memory",
                "schema_version": 1,
                "pair_count": 9,
                "pair_attempts": 4,
                "mismatches": 2,
            },
        }
    )

    response = client.post(
        "/records/batch",
        headers=headers(),
        json={"installation_id": installation_id, "records": [abandoned]},
    )

    assert response.status_code == 200
    assert response.json()["acknowledgements"][0]["status"] == "accepted"
    with sqlite3.connect(database_path) as connection:
        stored = connection.execute(
            "SELECT outcome, rating FROM play_records"
        ).fetchone()
    assert stored == ("abandoned", None)


def test_enforces_rating_for_completed_and_abandoned_plays(client: TestClient):
    installation_id = register(client)
    abandoned_with_rating = record(installation_id, 1)
    abandoned_with_rating["outcome"] = "abandoned"
    completed_without_rating = record(installation_id, 2)
    completed_without_rating["rating"] = None

    for invalid_record in (abandoned_with_rating, completed_without_rating):
        response = client.post(
            "/records/batch",
            headers=headers(),
            json={
                "installation_id": installation_id,
                "records": [invalid_record],
            },
        )
        assert response.status_code == 422


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


@pytest.mark.parametrize(
    "feature_id",
    [
        "number_learning",
        "number_comparison",
        "operations_practice",
        "number_dragging",
        "number_memory",
        "balance_game",
        "logic_game",
        "shopping_game",
        "operator_conveyor",
        "even_odd",
    ],
)
def test_accepts_math_records(client: TestClient, feature_id: str):
    installation_id = register(client)
    math_record = record(installation_id, 1)
    math_record["area_id"] = "math"
    math_record["feature_id"] = feature_id

    response = client.post(
        "/records/batch",
        headers=headers(),
        json={"installation_id": installation_id, "records": [math_record]},
    )

    assert response.status_code == 200
    assert response.json()["acknowledgements"][0]["status"] == "accepted"


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

# Pre-pilot backend

This is the FastAPI service for offline-first accounts, teacher-managed
students and groups, and pre-pilot gameplay records.

## API

All endpoints require the shared `X-API-Key` header. Account, student, group,
and identified gameplay operations also require an account bearer token.

- `POST /installations` accepts a required nullable `installation_id`. `null`
  allocates a new ID; an existing ID returns its authoritative next record number.
- `POST /records/batch` stores a batch and returns one acknowledgement per
  record: `accepted`, `already_accepted`, or `stored_as_conflict`.
- `GET /students` and `PUT /students/sync` expose students owned by a teacher
  or shared through a group.
- `GET /groups` and `PUT /groups/sync` expose group membership.
- `POST /groups/{client_id}/share-code` lets a group owner generate a code.
- `POST /groups/join` grants another teaching account access using that code.

Records are uniquely identified by `(installation_id, record_number)`. An
identical retry is acknowledged without inserting another row. A different
payload claiming an existing identity is preserved in `record_conflicts` and
returned with a reference such as `3-42-e1`.

Completed plays require a rating from 1 to 5. Plays with the `abandoned`
outcome have a null rating and may contain a partial metrics snapshot.
Student gameplay remains attached to the student record independently of group
membership. Removing a student from a group or removing a group therefore does
not alter historical gameplay data.

## Run locally

Create a virtual environment and install the service:

```sh
python3 -m venv .venv
.venv/bin/pip install -e '.[test]'
```

Copy the example environment file and set the preliminary shared key:

```sh
cp .env.example .env
source .venv/bin/activate
uvicorn main:app --reload
```

The local development `.env` uses `dev-key`. It is ignored by Git; only
`.env.example` is tracked. The root `main.py` loads `.env` before creating the
FastAPI application.

SQLite foreign keys, WAL mode, and a ten-second busy timeout are enabled when
the application starts. Back up the database file regularly during testing.

## Test

```sh
.venv/bin/pytest
```

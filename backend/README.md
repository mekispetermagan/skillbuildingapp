# Pre-pilot backend

This is a deliberately small, disposable FastAPI service for anonymous
pre-pilot gameplay records. It has no learner accounts and is not intended to
grow into the later pilot backend.

## API

Both endpoints require the shared `X-API-Key` header.

- `POST /installations` accepts a required nullable `installation_id`. `null`
  allocates a new ID; an existing ID returns its authoritative next record number.
- `POST /records/batch` stores a batch and returns one acknowledgement per
  record: `accepted`, `already_accepted`, or `stored_as_conflict`.

Records are uniquely identified by `(installation_id, record_number)`. An
identical retry is acknowledged without inserting another row. A different
payload claiming an existing identity is preserved in `record_conflicts` and
returned with a reference such as `3-42-e1`.

Completed plays require a rating from 1 to 5. Plays with the `abandoned`
outcome have a null rating and may contain a partial metrics snapshot.

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

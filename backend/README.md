# Pre-pilot backend

This is a deliberately small, disposable FastAPI service for anonymous
pre-pilot gameplay records. It has no learner accounts and is not intended to
grow into the later pilot backend.

## API

Both endpoints require the shared `X-API-Key` header.

- `POST /installations` allocates an installation ID.
- `POST /records/batch` stores a batch and returns one acknowledgement per
  record: `accepted`, `already_accepted`, or `stored_as_conflict`.

Records are uniquely identified by `(installation_id, record_number)`. An
identical retry is acknowledged without inserting another row. A different
payload claiming an existing identity is preserved in `record_conflicts` and
returned with a reference such as `3-42-e1`.

## Run locally

Create a virtual environment and install the service:

```sh
python3 -m venv .venv
.venv/bin/pip install -e '.[test]'
```

Set a preliminary shared key and optionally choose the database path:

```sh
export LITERACY_API_KEY='replace-this-before-running'
export LITERACY_DATABASE_PATH='literacy_prepilot.db'
.venv/bin/uvicorn app.main:create_app --factory --reload
```

SQLite foreign keys, WAL mode, and a ten-second busy timeout are enabled when
the application starts. Back up the database file regularly during testing.

## Test

```sh
.venv/bin/pytest
```

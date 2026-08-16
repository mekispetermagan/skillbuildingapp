from __future__ import annotations

import secrets
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.security import APIKeyHeader

from .config import Settings
from .database import Database
from .models import (
    InstallationRegistration,
    InstallationResolution,
    RecordBatch,
    RecordBatchAcknowledgement,
)


api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def create_router(settings: Settings, database: Database) -> APIRouter:
    router = APIRouter()

    def require_api_key(
        supplied_key: Annotated[str | None, Depends(api_key_header)],
    ) -> None:
        if supplied_key is None or not secrets.compare_digest(
            supplied_key, settings.api_key
        ):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid API key.",
            )

    key_dependency = Depends(require_api_key)

    @router.post(
        "/installations",
        response_model=InstallationRegistration,
        dependencies=[key_dependency],
    )
    def resolve_installation(
        request: InstallationResolution,
        response: Response,
    ) -> InstallationRegistration:
        if request.installation_id is None:
            response.status_code = status.HTTP_201_CREATED
            return database.register_installation()

        registration = database.resolve_installation(request.installation_id)
        if registration is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Installation does not exist.",
            )
        return registration

    @router.post(
        "/records/batch",
        response_model=RecordBatchAcknowledgement,
        dependencies=[key_dependency],
    )
    def submit_records(
        batch: RecordBatch,
    ) -> RecordBatchAcknowledgement:
        if len(batch.records) > settings.maximum_batch_size:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail="Batch contains too many records.",
            )
        result = database.store_batch(batch.installation_id, batch.records)
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Installation does not exist.",
            )
        return result

    return router

from __future__ import annotations

import secrets
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.security import APIKeyHeader, HTTPAuthorizationCredentials, HTTPBearer

from .config import Settings
from .database import Database
from .models import (
    AccountCredentials,
    AccountPreferenceUpdate,
    AccountRegistration,
    AuthenticatedAccount,
    AuthenticatedIdentity,
    InstallationRegistration,
    InstallationResolution,
    GroupJoinRequest,
    GroupShareCode,
    RecordBatch,
    RecordBatchAcknowledgement,
    StudentBatch,
    StudentGroupBatch,
    StudentGroupProfile,
    StudentProfile,
)


api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)
bearer_scheme = HTTPBearer(auto_error=False)


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

    def optional_identity(
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    ) -> AuthenticatedIdentity | None:
        if credentials is None:
            return None
        identity = database.resolve_access_token(credentials.credentials)
        if identity is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid access token.",
            )
        return identity

    def require_identity(
        identity: AuthenticatedIdentity | None = Depends(optional_identity),
    ) -> AuthenticatedIdentity:
        if identity is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Access token is required.",
            )
        return identity

    def require_teacher(
        identity: AuthenticatedIdentity = Depends(require_identity),
    ) -> AuthenticatedIdentity:
        if identity.role != "teacher":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="A teaching account is required.",
            )
        return identity

    @router.post(
        "/auth/register",
        response_model=AuthenticatedAccount,
        status_code=status.HTTP_201_CREATED,
        dependencies=[key_dependency],
    )
    def register_account(
        registration: AccountRegistration,
    ) -> AuthenticatedAccount:
        account = database.register_account(registration)
        if account is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Username is already registered.",
            )
        return account

    @router.post(
        "/auth/login",
        response_model=AuthenticatedAccount,
        dependencies=[key_dependency],
    )
    def login(credentials: AccountCredentials) -> AuthenticatedAccount:
        account = database.authenticate_account(
            credentials.username, credentials.pin
        )
        if account is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or PIN.",
            )
        return account

    @router.patch(
        "/auth/preferences",
        status_code=status.HTTP_204_NO_CONTENT,
        dependencies=[key_dependency],
    )
    def update_preferences(
        update: AccountPreferenceUpdate,
        identity: AuthenticatedIdentity = Depends(require_identity),
    ) -> Response:
        database.update_preferred_language(
            identity.account_id, update.preferred_language
        )
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @router.get(
        "/students",
        response_model=list[StudentProfile],
        dependencies=[key_dependency],
    )
    def list_students(
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> list[StudentProfile]:
        return database.list_students(teacher.account_id)

    @router.put(
        "/students/sync",
        response_model=list[StudentProfile],
        dependencies=[key_dependency],
    )
    def sync_students(
        batch: StudentBatch,
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> list[StudentProfile]:
        try:
            return database.sync_students(teacher.account_id, batch.students)
        except PermissionError as error:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail=str(error)
            ) from error

    @router.get(
        "/groups",
        response_model=list[StudentGroupProfile],
        dependencies=[key_dependency],
    )
    def list_groups(
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> list[StudentGroupProfile]:
        return database.list_student_groups(teacher.account_id)

    @router.put(
        "/groups/sync",
        response_model=list[StudentGroupProfile],
        dependencies=[key_dependency],
    )
    def sync_groups(
        batch: StudentGroupBatch,
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> list[StudentGroupProfile]:
        try:
            return database.sync_student_groups(teacher.account_id, batch.groups)
        except PermissionError as error:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail=str(error)
            ) from error

    @router.post(
        "/groups/{client_id}/share-code",
        response_model=GroupShareCode,
        dependencies=[key_dependency],
    )
    def share_group(
        client_id: str,
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> GroupShareCode:
        try:
            code = database.create_group_share_code(teacher.account_id, client_id)
        except PermissionError as error:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, detail=str(error)
            ) from error
        return GroupShareCode(code=code)

    @router.post(
        "/groups/join",
        response_model=StudentGroupProfile,
        dependencies=[key_dependency],
    )
    def join_group(
        request: GroupJoinRequest,
        teacher: AuthenticatedIdentity = Depends(require_teacher),
    ) -> StudentGroupProfile:
        group = database.join_student_group(teacher.account_id, request.code)
        if group is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Sharing code does not match a group.",
            )
        return group

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
        identity: AuthenticatedIdentity | None = Depends(optional_identity),
    ) -> RecordBatchAcknowledgement:
        if len(batch.records) > settings.maximum_batch_size:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail="Batch contains too many records.",
            )
        try:
            result = database.store_batch(
                batch.installation_id, batch.records, identity=identity
            )
        except PermissionError as error:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=str(error),
            ) from error
        if result is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Installation does not exist.",
            )
        return result

    return router

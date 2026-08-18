from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

from .config import Settings
from .database import Database
from .router import create_router


def create_app(settings: Settings | None = None) -> FastAPI:
    resolved_settings = settings or Settings.from_environment()
    resolved_settings.validate()
    database = Database(resolved_settings.database_path)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        database.initialize()
        yield

    app = FastAPI(
        title="Skill Building API",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if resolved_settings.environment == "dev" else None,
        redoc_url="/redoc" if resolved_settings.environment == "dev" else None,
        openapi_url="/openapi.json" if resolved_settings.environment == "dev" else None,
    )

    @app.middleware("http")
    async def limit_request_size(request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length is not None:
            try:
                request_bytes = int(content_length)
            except ValueError:
                return JSONResponse(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    content={"detail": "Invalid Content-Length header."},
                )
            if request_bytes > resolved_settings.maximum_request_bytes:
                return JSONResponse(
                    status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                    content={"detail": "Request body is too large."},
                )
        return await call_next(request)

    app.include_router(create_router(resolved_settings, database))
    return app

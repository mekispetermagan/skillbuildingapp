from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Settings:
    database_path: Path
    api_key: str
    maximum_batch_size: int = 100
    maximum_request_bytes: int = 256 * 1024

    @classmethod
    def from_environment(cls) -> Settings:
        api_key = os.environ.get("LITERACY_API_KEY", "")
        if not api_key:
            raise RuntimeError("LITERACY_API_KEY must be set.")
        database_path = Path(
            os.environ.get("LITERACY_DATABASE_PATH", "literacy_prepilot.db")
        )
        return cls(database_path=database_path, api_key=api_key)

    def validate(self) -> None:
        if not self.api_key:
            raise ValueError("api_key must not be empty")
        if self.maximum_batch_size <= 0:
            raise ValueError("maximum_batch_size must be positive")
        if self.maximum_request_bytes <= 0:
            raise ValueError("maximum_request_bytes must be positive")


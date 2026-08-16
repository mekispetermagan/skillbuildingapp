from __future__ import annotations

from datetime import datetime
from typing import Annotated, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StrictInt,
    field_validator,
    model_validator,
)


class ContractModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


PositiveStrictInt = Annotated[StrictInt, Field(gt=0)]


class AttemptMetrics(ContractModel):
    type: Literal["attempts"]
    schema_version: Literal[1]
    correct_answers: Annotated[StrictInt, Field(ge=0)]
    incorrect_attempts: Annotated[StrictInt, Field(ge=0)]


class TimedWordMetrics(ContractModel):
    type: Literal["timed_words"]
    schema_version: Literal[1]
    correct_answers: Annotated[StrictInt, Field(ge=0)]
    passed_items: Annotated[StrictInt, Field(ge=0)]


class LivesMetrics(ContractModel):
    type: Literal["lives"]
    schema_version: Literal[1]
    correct_answers: Annotated[StrictInt, Field(ge=0)]
    incorrect_attempts: Annotated[StrictInt, Field(ge=0)]
    starting_lives: PositiveStrictInt
    remaining_lives: Annotated[StrictInt, Field(ge=0)]

    @model_validator(mode="after")
    def validate_remaining_lives(self) -> LivesMetrics:
        if self.remaining_lives > self.starting_lives:
            raise ValueError("remaining_lives must not exceed starting_lives")
        return self


class MemoryMetrics(ContractModel):
    type: Literal["memory"]
    schema_version: Literal[1]
    pair_count: PositiveStrictInt
    pair_attempts: PositiveStrictInt
    mismatches: Annotated[StrictInt, Field(ge=0)]

    @model_validator(mode="after")
    def validate_attempt_count(self) -> MemoryMetrics:
        if self.pair_attempts != self.pair_count + self.mismatches:
            raise ValueError("pair_attempts must equal pair_count plus mismatches")
        return self


FeatureMetrics = Annotated[
    AttemptMetrics | TimedWordMetrics | LivesMetrics | MemoryMetrics,
    Field(discriminator="type"),
]


LITERACY_FEATURES = frozenset(
    {
        "letter_learning",
        "letter_practice",
        "phrase_building",
        "letter_dragging",
        "missing_letters",
        "letter_shooting",
        "memory_cards",
        "letter_catching",
        "word_conveyor",
        "sentence_quiz",
        "sentence_composer",
        "spelling_quiz",
        "crossword",
    }
)


class PlayRecord(ContractModel):
    schema_version: Literal[1]
    installation_id: PositiveStrictInt
    record_number: PositiveStrictInt
    area_id: Literal["literacy"]
    feature_id: str = Field(min_length=1, max_length=64)
    outcome: Literal["completed", "won", "lost"]
    score: Annotated[StrictInt, Field(ge=0)] | None
    rating: Annotated[StrictInt, Field(ge=1, le=5)]
    metrics: FeatureMetrics
    started_at: datetime
    completed_at: datetime
    elapsed_milliseconds: Annotated[StrictInt, Field(ge=0)]
    app_version: str = Field(min_length=1, max_length=64)
    content_version: str = Field(min_length=1, max_length=64)

    @field_validator("started_at", "completed_at")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("timestamps must include a UTC offset")
        return value

    @model_validator(mode="after")
    def validate_record(self) -> PlayRecord:
        if self.feature_id not in LITERACY_FEATURES:
            raise ValueError("feature_id is not registered in area_id")
        if self.completed_at < self.started_at:
            raise ValueError("completed_at must not be before started_at")
        return self


class RecordBatch(ContractModel):
    installation_id: PositiveStrictInt
    records: list[PlayRecord] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_records(self) -> RecordBatch:
        numbers: set[int] = set()
        for record in self.records:
            if record.installation_id != self.installation_id:
                raise ValueError("every record must have the batch installation_id")
            if record.record_number in numbers:
                raise ValueError("record_number must be unique within a batch")
            numbers.add(record.record_number)
        return self


class InstallationResolution(ContractModel):
    installation_id: PositiveStrictInt | None


class InstallationRegistration(ContractModel):
    installation_id: PositiveStrictInt
    next_record_number: PositiveStrictInt


class RecordAcknowledgement(ContractModel):
    record_number: PositiveStrictInt
    status: Literal["accepted", "already_accepted", "stored_as_conflict"]
    conflict_reference: str | None = None

    @model_validator(mode="after")
    def validate_conflict_reference(self) -> RecordAcknowledgement:
        if self.status == "stored_as_conflict":
            if self.conflict_reference is None or not self.conflict_reference.strip():
                raise ValueError("stored conflicts require a conflict_reference")
        elif self.conflict_reference is not None:
            raise ValueError("only stored conflicts may have a conflict_reference")
        return self


class RecordBatchAcknowledgement(ContractModel):
    installation_id: PositiveStrictInt
    next_record_number: PositiveStrictInt
    acknowledgements: list[RecordAcknowledgement]

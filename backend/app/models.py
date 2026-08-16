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
    pair_attempts: Annotated[StrictInt, Field(ge=0)]
    mismatches: Annotated[StrictInt, Field(ge=0)]

    @model_validator(mode="after")
    def validate_attempt_count(self) -> MemoryMetrics:
        if not self.mismatches <= self.pair_attempts <= (
            self.pair_count + self.mismatches
        ):
            raise ValueError(
                "pair_attempts must represent at most pair_count matches"
            )
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
MATH_FEATURES = frozenset({"number_learning"})


class PlayRecord(ContractModel):
    schema_version: Literal[1]
    installation_id: PositiveStrictInt
    record_number: PositiveStrictInt
    area_id: Literal["literacy", "math"]
    feature_id: str = Field(min_length=1, max_length=64)
    outcome: Literal["completed", "won", "lost", "abandoned"]
    score: Annotated[StrictInt, Field(ge=0)] | None
    rating: Annotated[StrictInt, Field(ge=1, le=5)] | None
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
        features = LITERACY_FEATURES if self.area_id == "literacy" else MATH_FEATURES
        if self.feature_id not in features:
            raise ValueError("feature_id is not registered in area_id")
        if self.completed_at < self.started_at:
            raise ValueError("completed_at must not be before started_at")
        if self.outcome == "abandoned":
            if self.rating is not None:
                raise ValueError("abandoned records must not have a rating")
        elif self.rating is None:
            raise ValueError("completed records require a rating")
        if (
            self.outcome != "abandoned"
            and isinstance(self.metrics, MemoryMetrics)
            and self.metrics.pair_attempts
            != self.metrics.pair_count + self.metrics.mismatches
        ):
            raise ValueError("completed memory records must include every pair")
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

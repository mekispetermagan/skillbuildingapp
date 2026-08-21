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


class AccountCredentials(ContractModel):
    username: str = Field(min_length=3, max_length=32, pattern=r"^[A-Za-z0-9_.-]+$")
    pin: str = Field(pattern=r"^\d{6}$")

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        return value.lower()


class AccountRegistration(AccountCredentials):
    name: str = Field(min_length=1, max_length=100)
    role: Literal["learner", "teacher"]
    preferred_language: Literal["en", "de", "hu"]
    location: str = Field(min_length=1, max_length=100)
    age: Annotated[StrictInt, Field(ge=1, le=120)] | None = None
    gender: Literal["male", "female", "other_or_prefer_not_to_say"] | None = None

    @field_validator("name", "location")
    @classmethod
    def normalize_location(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("value must not be blank")
        return stripped

    @model_validator(mode="after")
    def validate_role_fields(self) -> AccountRegistration:
        if self.role == "learner":
            if self.age is None or self.gender is None:
                raise ValueError("learner accounts require age and gender")
        elif self.age is not None or self.gender is not None:
            raise ValueError("teacher accounts must not include age or gender")
        return self


class AuthenticatedAccount(ContractModel):
    account_id: PositiveStrictInt
    username: str
    name: str
    role: Literal["learner", "teacher"]
    preferred_language: Literal["en", "de", "hu"]
    location: str
    age: Annotated[StrictInt, Field(ge=1, le=120)] | None
    gender: Literal["male", "female", "other_or_prefer_not_to_say"] | None
    access_token: str


class AuthenticatedIdentity(ContractModel):
    account_id: PositiveStrictInt
    role: Literal["learner", "teacher"]


class StudentProfile(ContractModel):
    client_id: str = Field(min_length=1, max_length=64)
    name: str = Field(min_length=1, max_length=100)
    location: str = Field(min_length=1, max_length=100)
    age: Annotated[StrictInt, Field(ge=1, le=120)]
    gender: Literal["male", "female", "other_or_prefer_not_to_say"]

    @field_validator("client_id", "name", "location")
    @classmethod
    def reject_blank_values(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("value must not be blank")
        return stripped


class StudentBatch(ContractModel):
    students: list[StudentProfile]

    @model_validator(mode="after")
    def require_unique_client_ids(self) -> StudentBatch:
        ids = [student.client_id for student in self.students]
        if len(ids) != len(set(ids)):
            raise ValueError("student client_id values must be unique")
        return self


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
MATH_FEATURES = frozenset(
    {
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
    }
)


class PlayRecord(ContractModel):
    schema_version: Literal[1]
    installation_id: PositiveStrictInt
    record_number: PositiveStrictInt
    player_type: Literal["learner", "student"] | None = None
    student_client_id: str | None = Field(default=None, min_length=1, max_length=64)
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
        if self.player_type == "student" and self.student_client_id is None:
            raise ValueError("student records require student_client_id")
        if self.player_type != "student" and self.student_client_id is not None:
            raise ValueError("only student records may include student_client_id")
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

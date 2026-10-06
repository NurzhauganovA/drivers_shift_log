from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum

from shift_log.domain.errors import InvalidTripError


class PaymentMethod(StrEnum):
    CASH = "cash"
    CARD = "card"


@dataclass(frozen=True, slots=True)
class Trip:
    """A single paid ride. Money is stored in whole tenge."""

    id: str
    start: datetime
    end: datetime
    amount: int
    payment: PaymentMethod
    commission: int

    def __post_init__(self) -> None:
        if not self.id.strip():
            raise InvalidTripError("id", "Trip id must not be empty")
        for field in ("start", "end"):
            value: datetime = getattr(self, field)
            if value.tzinfo is None or value.utcoffset() is None:
                raise InvalidTripError(field, "Time must include a UTC offset")
        if self.end <= self.start:
            raise InvalidTripError("end", "Trip must end after it starts")
        if self.amount <= 0:
            raise InvalidTripError("amount", "Amount must be greater than zero")
        if self.commission < 0:
            raise InvalidTripError("commission", "Commission must not be negative")
        if self.commission > self.amount:
            raise InvalidTripError("commission", "Commission must not exceed the amount")

    @property
    def duration(self) -> timedelta:
        return self.end - self.start

    @property
    def net(self) -> int:
        return self.amount - self.commission

    def overlaps(self, start: datetime, end: datetime) -> bool:
        return self.start < end and start < self.end

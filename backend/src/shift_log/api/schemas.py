from datetime import date
from typing import Annotated, Literal

from pydantic import AwareDatetime, BaseModel, ConfigDict, StrictInt, StringConstraints

from shift_log.application import DayOverview, DayReport
from shift_log.domain import DaySummary, PaymentBreakdown, PaymentMethod, Trip

TripId = Annotated[str, StringConstraints(pattern=r"^[A-Za-z0-9_-]{1,64}$")]


class TripIn(BaseModel):
    """Shape and types only. Business rules (amount > 0, end > start) live in the domain."""

    model_config = ConfigDict(extra="forbid")

    id: TripId
    start: AwareDatetime
    end: AwareDatetime
    amount: StrictInt
    payment: PaymentMethod
    commission: StrictInt


class TripOut(BaseModel):
    id: str
    start: AwareDatetime
    end: AwareDatetime
    amount: int
    payment: PaymentMethod
    commission: int

    @classmethod
    def from_domain(cls, trip: Trip) -> "TripOut":
        return cls(
            id=trip.id,
            start=trip.start,
            end=trip.end,
            amount=trip.amount,
            payment=trip.payment,
            commission=trip.commission,
        )


class PaymentBreakdownOut(BaseModel):
    count: int
    amount: int

    @classmethod
    def from_domain(cls, value: PaymentBreakdown) -> "PaymentBreakdownOut":
        return cls(count=value.count, amount=value.amount)


class SummaryOut(BaseModel):
    date: date
    currency: Literal["KZT"] = "KZT"
    trips_count: int
    revenue: int
    commission: int
    net: int
    busy_seconds: int
    cash: PaymentBreakdownOut
    card: PaymentBreakdownOut

    @classmethod
    def from_domain(cls, summary: DaySummary) -> "SummaryOut":
        return cls(
            date=summary.date,
            trips_count=summary.trips_count,
            revenue=summary.revenue,
            commission=summary.commission,
            net=summary.net,
            busy_seconds=summary.busy_seconds,
            cash=PaymentBreakdownOut.from_domain(summary.cash),
            card=PaymentBreakdownOut.from_domain(summary.card),
        )


class DayOut(BaseModel):
    summary: SummaryOut
    trips: list[TripOut]

    @classmethod
    def from_domain(cls, report: DayReport) -> "DayOut":
        return cls(
            summary=SummaryOut.from_domain(report.summary),
            trips=[TripOut.from_domain(t) for t in report.trips],
        )


class DayOverviewOut(BaseModel):
    date: date
    trips_count: int
    net: int

    @classmethod
    def from_domain(cls, overview: DayOverview) -> "DayOverviewOut":
        return cls(date=overview.date, trips_count=overview.trips_count, net=overview.net)


class FieldError(BaseModel):
    field: str
    message: str


class ErrorBody(BaseModel):
    code: str
    message: str
    fields: list[FieldError] = []


class ErrorResponse(BaseModel):
    error: ErrorBody

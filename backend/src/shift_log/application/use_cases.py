from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime

from shift_log.application.calendar import DriverCalendar
from shift_log.application.ports import TripRepository
from shift_log.domain import (
    DaySummary,
    PaymentMethod,
    Trip,
    TripIdConflictError,
    TripOverlapError,
    summarize_day,
)


@dataclass(frozen=True, slots=True)
class DayReport:
    summary: DaySummary
    trips: list[Trip]


@dataclass(frozen=True, slots=True)
class DayOverview:
    date: date
    trips_count: int
    net: int


class GetDayReport:
    def __init__(self, repository: TripRepository, calendar: DriverCalendar) -> None:
        self._repository = repository
        self._calendar = calendar

    def execute(self, day: date) -> DayReport:
        start, end = self._calendar.bounds(day)
        trips = self._repository.list_starting_between(start, end)
        return DayReport(summary=summarize_day(day, trips), trips=trips)


class ListShiftDays:
    """Days that have at least one trip, newest first. Lets the client jump between shifts."""

    def __init__(self, repository: TripRepository, calendar: DriverCalendar) -> None:
        self._repository = repository
        self._calendar = calendar

    def execute(self) -> list[DayOverview]:
        grouped: dict[date, list[Trip]] = defaultdict(list)
        for trip in self._repository.list_all():
            grouped[self._calendar.day_of(trip.start)].append(trip)
        return [
            DayOverview(
                date=day,
                trips_count=len(trips),
                net=sum(trip.net for trip in trips),
            )
            for day, trips in sorted(grouped.items(), reverse=True)
        ]


@dataclass(frozen=True, slots=True)
class NewTrip:
    id: str
    start: datetime
    end: datetime
    amount: int
    payment: PaymentMethod
    commission: int


@dataclass(frozen=True, slots=True)
class AddTripResult:
    trip: Trip
    created: bool
    """False when the same trip was already stored, i.e. the request was a retry."""


class AddTrip:
    """Stores a trip idempotently.

    The client generates the trip id once and reuses it on every retry, so the id
    doubles as an idempotency key:
      * same id, same data      -> existing trip is returned, nothing is written;
      * same id, different data -> TripIdConflictError;
      * new id overlapping an existing trip in time -> TripOverlapError, which also
        catches a resubmission that accidentally got a fresh id.
    """

    def __init__(self, repository: TripRepository) -> None:
        self._repository = repository

    def execute(self, command: NewTrip) -> AddTripResult:
        trip = Trip(
            id=command.id,
            start=command.start,
            end=command.end,
            amount=command.amount,
            payment=command.payment,
            commission=command.commission,
        )
        with self._repository.atomic():
            existing = self._repository.get(trip.id)
            if existing is not None:
                if existing == trip:
                    return AddTripResult(trip=existing, created=False)
                raise TripIdConflictError(trip.id)

            overlapping = self._repository.find_overlapping(trip.start, trip.end)
            if overlapping is not None:
                raise TripOverlapError(overlapping.id)

            self._repository.add(trip)
            return AddTripResult(trip=trip, created=True)

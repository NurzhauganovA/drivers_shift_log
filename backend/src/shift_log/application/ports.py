from contextlib import AbstractContextManager
from datetime import datetime
from typing import Protocol

from shift_log.domain import Trip


class TripRepository(Protocol):
    def get(self, trip_id: str) -> Trip | None: ...

    def list_all(self) -> list[Trip]:
        """All trips ordered by start time."""
        ...

    def list_starting_between(self, start: datetime, end: datetime) -> list[Trip]:
        """Trips with `start <= trip.start < end`, ordered by start time."""
        ...

    def find_overlapping(self, start: datetime, end: datetime) -> Trip | None: ...

    def add(self, trip: Trip) -> None: ...

    def atomic(self) -> AbstractContextManager[None]:
        """Serializes check-then-write sequences so concurrent requests cannot interleave."""
        ...

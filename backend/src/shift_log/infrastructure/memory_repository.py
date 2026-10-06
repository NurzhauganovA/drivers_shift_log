import threading
from collections.abc import Iterable, Iterator
from contextlib import contextmanager
from datetime import datetime

from shift_log.domain import Trip


class InMemoryTripRepository:
    """Process-local storage. A re-entrant lock guards every read and write."""

    def __init__(self, trips: Iterable[Trip] = ()) -> None:
        self._lock = threading.RLock()
        self._trips: dict[str, Trip] = {}
        for trip in trips:
            if trip.id in self._trips:
                raise ValueError(f"Duplicate trip id in initial data: {trip.id}")
            self._trips[trip.id] = trip

    @contextmanager
    def atomic(self) -> Iterator[None]:
        with self._lock:
            yield

    def get(self, trip_id: str) -> Trip | None:
        with self._lock:
            return self._trips.get(trip_id)

    def list_all(self) -> list[Trip]:
        with self._lock:
            return self._sorted(self._trips.values())

    def list_starting_between(self, start: datetime, end: datetime) -> list[Trip]:
        with self._lock:
            return self._sorted(t for t in self._trips.values() if start <= t.start < end)

    def find_overlapping(self, start: datetime, end: datetime) -> Trip | None:
        with self._lock:
            return next((t for t in self._trips.values() if t.overlaps(start, end)), None)

    def add(self, trip: Trip) -> None:
        with self._lock:
            if trip.id in self._trips:
                raise ValueError(f"Trip already stored: {trip.id}")
            self._trips[trip.id] = trip

    def _discard(self, trip_id: str) -> None:
        with self._lock:
            self._trips.pop(trip_id, None)

    @staticmethod
    def _sorted(trips: Iterable[Trip]) -> list[Trip]:
        return sorted(trips, key=lambda t: (t.start, t.id))

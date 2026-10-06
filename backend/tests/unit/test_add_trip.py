import threading
from dataclasses import replace
from datetime import timedelta

import pytest

from shift_log.application import AddTrip
from shift_log.domain import InvalidTripError, TripIdConflictError, TripOverlapError
from shift_log.infrastructure import InMemoryTripRepository
from tests.factories import ALMATY, at, make_trip, new_trip_from


@pytest.fixture
def repository() -> InMemoryTripRepository:
    return InMemoryTripRepository()


@pytest.fixture
def add_trip(repository: InMemoryTripRepository) -> AddTrip:
    return AddTrip(repository)


def test_new_trip_is_stored(add_trip: AddTrip, repository: InMemoryTripRepository) -> None:
    trip = make_trip()

    result = add_trip.execute(new_trip_from(trip))

    assert result.created
    assert result.trip == trip
    assert repository.list_all() == [trip]


def test_resending_same_trip_does_not_create_duplicate(
    add_trip: AddTrip, repository: InMemoryTripRepository
) -> None:
    command = new_trip_from(make_trip())

    first = add_trip.execute(command)
    second = add_trip.execute(command)

    assert first.created
    assert not second.created
    assert second.trip == first.trip
    assert len(repository.list_all()) == 1


def test_same_trip_with_other_utc_offset_is_recognized_as_retry(add_trip: AddTrip) -> None:
    trip = make_trip(start=at(1, 8))
    add_trip.execute(new_trip_from(trip))
    in_utc = replace(
        new_trip_from(trip),
        start=trip.start.astimezone(ALMATY.utc),
        end=trip.end.astimezone(ALMATY.utc),
    )

    assert not add_trip.execute(in_utc).created


def test_same_id_with_different_data_is_a_conflict(
    add_trip: AddTrip, repository: InMemoryTripRepository
) -> None:
    add_trip.execute(new_trip_from(make_trip(amount=2000)))

    with pytest.raises(TripIdConflictError):
        add_trip.execute(new_trip_from(make_trip(amount=2500)))

    assert repository.get("t1") is not None
    assert repository.get("t1").amount == 2000  # type: ignore[union-attr]


def test_resubmission_with_new_id_is_caught_as_overlap(
    add_trip: AddTrip, repository: InMemoryTripRepository
) -> None:
    add_trip.execute(new_trip_from(make_trip("t1")))

    with pytest.raises(TripOverlapError) as error:
        add_trip.execute(new_trip_from(make_trip("t1-copy")))

    assert error.value.existing_id == "t1"
    assert len(repository.list_all()) == 1


def test_back_to_back_trips_are_allowed(add_trip: AddTrip) -> None:
    first = make_trip("a", start=at(1, 8), minutes=30)
    second = make_trip("b", start=first.end, minutes=10)

    add_trip.execute(new_trip_from(first))

    assert add_trip.execute(new_trip_from(second)).created


def test_invalid_trip_is_not_stored(add_trip: AddTrip, repository: InMemoryTripRepository) -> None:
    command = replace(new_trip_from(make_trip()), amount=0)

    with pytest.raises(InvalidTripError):
        add_trip.execute(command)

    assert repository.list_all() == []


def test_concurrent_retries_store_exactly_one_trip(
    add_trip: AddTrip, repository: InMemoryTripRepository
) -> None:
    command = new_trip_from(make_trip())
    barrier = threading.Barrier(16)
    created: list[bool] = []

    def submit() -> None:
        barrier.wait()
        created.append(add_trip.execute(command).created)

    threads = [threading.Thread(target=submit) for _ in range(16)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=timedelta(seconds=5).total_seconds())

    assert created.count(True) == 1
    assert created.count(False) == 15
    assert len(repository.list_all()) == 1

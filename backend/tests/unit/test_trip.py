from datetime import datetime, timedelta

import pytest

from shift_log.domain import InvalidTripError
from tests.factories import at, make_trip


def test_valid_trip_exposes_duration_and_net() -> None:
    trip = make_trip(minutes=22, amount=2400, commission=360)

    assert trip.duration == timedelta(minutes=22)
    assert trip.net == 2040


@pytest.mark.parametrize(
    ("overrides", "field"),
    [
        ({"amount": 0}, "amount"),
        ({"amount": -100}, "amount"),
        ({"commission": -1}, "commission"),
        ({"amount": 1000, "commission": 1001}, "commission"),
        ({"minutes": 0}, "end"),
        ({"minutes": -5}, "end"),
        ({"trip_id": "  "}, "id"),
    ],
)
def test_invalid_trip_is_rejected_with_field(overrides: dict[str, object], field: str) -> None:
    with pytest.raises(InvalidTripError) as error:
        make_trip(**overrides)  # type: ignore[arg-type]

    assert error.value.field == field


def test_naive_datetime_is_rejected() -> None:
    with pytest.raises(InvalidTripError) as error:
        make_trip(start=datetime(2026, 10, 1, 8, 0))

    assert error.value.field == "start"


def test_commission_equal_to_amount_is_allowed() -> None:
    assert make_trip(amount=500, commission=500).net == 0


def test_overlap_uses_half_open_intervals() -> None:
    trip = make_trip(start=at(1, 8), minutes=30)

    assert trip.overlaps(at(1, 8, 29), at(1, 9))
    assert not trip.overlaps(at(1, 8, 30), at(1, 9)), "touching end-to-start is not an overlap"
    assert not trip.overlaps(at(1, 7), at(1, 8))

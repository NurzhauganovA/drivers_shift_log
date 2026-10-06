import json
from datetime import datetime
from pathlib import Path
from typing import Any

from shift_log.domain import InvalidTripError, PaymentMethod, Trip


def trip_to_json(trip: Trip) -> dict[str, Any]:
    return {
        "id": trip.id,
        "start": trip.start.isoformat(),
        "end": trip.end.isoformat(),
        "amount": trip.amount,
        "payment": trip.payment.value,
        "commission": trip.commission,
    }


def trip_from_json(raw: dict[str, Any]) -> Trip:
    return Trip(
        id=_require(raw, "id", str),
        start=datetime.fromisoformat(_require(raw, "start", str)),
        end=datetime.fromisoformat(_require(raw, "end", str)),
        amount=_require(raw, "amount", int),
        payment=PaymentMethod(_require(raw, "payment", str)),
        commission=_require(raw, "commission", int),
    )


def load_trips(path: Path) -> list[Trip]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path}: expected a JSON array of trips")
    trips = []
    for index, raw in enumerate(data):
        try:
            trips.append(trip_from_json(raw))
        except (InvalidTripError, KeyError, TypeError, ValueError) as error:
            raise ValueError(f"{path}: invalid trip at index {index}: {error}") from error
    return trips


def _require[T](raw: dict[str, Any], key: str, kind: type[T]) -> T:
    value = raw[key]
    # bool is a subclass of int; `true` is not a valid amount.
    if not isinstance(value, kind) or isinstance(value, bool):
        raise TypeError(f"'{key}' must be {kind.__name__}")
    return value

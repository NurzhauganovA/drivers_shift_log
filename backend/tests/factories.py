from datetime import datetime, timedelta, timezone

from shift_log.application import NewTrip
from shift_log.domain import PaymentMethod, Trip

ALMATY = timezone(timedelta(hours=5))


def at(day: int, hour: int, minute: int = 0, month: int = 10) -> datetime:
    return datetime(2026, month, day, hour, minute, tzinfo=ALMATY)


def make_trip(
    trip_id: str = "t1",
    start: datetime | None = None,
    minutes: int = 20,
    amount: int = 2000,
    payment: PaymentMethod = PaymentMethod.CARD,
    commission: int = 300,
) -> Trip:
    start = start or at(1, 8)
    return Trip(
        id=trip_id,
        start=start,
        end=start + timedelta(minutes=minutes),
        amount=amount,
        payment=payment,
        commission=commission,
    )


def new_trip_from(trip: Trip) -> NewTrip:
    return NewTrip(
        id=trip.id,
        start=trip.start,
        end=trip.end,
        amount=trip.amount,
        payment=trip.payment,
        commission=trip.commission,
    )

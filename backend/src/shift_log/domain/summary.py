from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date

from shift_log.domain.trip import PaymentMethod, Trip


@dataclass(frozen=True, slots=True)
class PaymentBreakdown:
    count: int
    amount: int


@dataclass(frozen=True, slots=True)
class DaySummary:
    date: date
    trips_count: int
    revenue: int
    commission: int
    net: int
    """Revenue minus commission: what the driver keeps."""
    busy_seconds: int
    cash: PaymentBreakdown
    card: PaymentBreakdown


def summarize_day(day: date, trips: Iterable[Trip]) -> DaySummary:
    count = revenue = commission = busy = 0
    by_payment = {method: [0, 0] for method in PaymentMethod}

    for trip in trips:
        count += 1
        revenue += trip.amount
        commission += trip.commission
        busy += int(trip.duration.total_seconds())
        bucket = by_payment[trip.payment]
        bucket[0] += 1
        bucket[1] += trip.amount

    cash, card = by_payment[PaymentMethod.CASH], by_payment[PaymentMethod.CARD]
    return DaySummary(
        date=day,
        trips_count=count,
        revenue=revenue,
        commission=commission,
        net=revenue - commission,
        busy_seconds=busy,
        cash=PaymentBreakdown(count=cash[0], amount=cash[1]),
        card=PaymentBreakdown(count=card[0], amount=card[1]),
    )

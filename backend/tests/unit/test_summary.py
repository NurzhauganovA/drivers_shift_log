from datetime import date

from shift_log.domain import PaymentBreakdown, PaymentMethod, summarize_day
from tests.factories import at, make_trip

DAY = date(2026, 10, 1)


def test_summary_of_sample_from_task() -> None:
    trips = [
        make_trip("t1", at(1, 8, 10), 22, 2400, PaymentMethod.CARD, 360),
        make_trip("t2", at(1, 9, 5), 15, 1500, PaymentMethod.CASH, 225),
    ]

    summary = summarize_day(DAY, trips)

    assert summary.date == DAY
    assert summary.trips_count == 2
    assert summary.revenue == 3900
    assert summary.commission == 585
    assert summary.net == 3315
    assert summary.busy_seconds == 37 * 60
    assert summary.card == PaymentBreakdown(count=1, amount=2400)
    assert summary.cash == PaymentBreakdown(count=1, amount=1500)


def test_summary_of_empty_day_is_all_zeros() -> None:
    summary = summarize_day(DAY, [])

    assert summary.trips_count == 0
    assert summary.revenue == summary.commission == summary.net == summary.busy_seconds == 0
    assert summary.cash == summary.card == PaymentBreakdown(count=0, amount=0)


def test_breakdown_sums_to_revenue() -> None:
    trips = [
        make_trip("a", at(1, 8), amount=1000, payment=PaymentMethod.CASH, commission=150),
        make_trip("b", at(1, 9), amount=2500, payment=PaymentMethod.CARD, commission=375),
        make_trip("c", at(1, 10), amount=1700, payment=PaymentMethod.CASH, commission=255),
    ]

    summary = summarize_day(DAY, trips)

    assert summary.cash == PaymentBreakdown(count=2, amount=2700)
    assert summary.card == PaymentBreakdown(count=1, amount=2500)
    assert summary.cash.amount + summary.card.amount == summary.revenue
    assert summary.revenue - summary.commission == summary.net == 4420


def test_summary_accepts_a_generator() -> None:
    summary = summarize_day(DAY, (make_trip(str(i), at(1, 8 + i)) for i in range(3)))

    assert summary.trips_count == 3

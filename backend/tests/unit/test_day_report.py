from datetime import date
from zoneinfo import ZoneInfo

from shift_log.application import DayOverview, DriverCalendar, GetDayReport, ListShiftDays
from shift_log.infrastructure import InMemoryTripRepository
from tests.factories import ALMATY, at, make_trip

CALENDAR = DriverCalendar(ZoneInfo("Asia/Almaty"))


def test_day_report_contains_only_trips_started_that_local_day() -> None:
    before = make_trip("before", start=at(30, 23, 50, month=9), minutes=30)
    morning = make_trip("morning", start=at(1, 8))
    late = make_trip("late", start=at(1, 23, 48), minutes=26)
    next_day = make_trip("next", start=at(2, 0, 30))
    repository = InMemoryTripRepository([next_day, late, morning, before])

    report = GetDayReport(repository, CALENDAR).execute(date(2026, 10, 1))

    assert [t.id for t in report.trips] == ["morning", "late"]
    assert report.summary.trips_count == 2


def test_day_is_resolved_in_driver_timezone_not_utc() -> None:
    # 02:00 in Almaty on Oct 2 is still Oct 1 in UTC.
    early = make_trip("early", start=at(2, 2).astimezone(ALMATY.utc))
    repository = InMemoryTripRepository([early])
    report = GetDayReport(repository, CALENDAR)

    assert [t.id for t in report.execute(date(2026, 10, 2)).trips] == ["early"]
    assert report.execute(date(2026, 10, 1)).trips == []


def test_list_shift_days_groups_newest_first() -> None:
    repository = InMemoryTripRepository(
        [
            make_trip("a", start=at(1, 8), amount=1000, commission=100),
            make_trip("b", start=at(1, 9), amount=2000, commission=200),
            make_trip("c", start=at(3, 9), amount=1500, commission=150),
        ]
    )

    days = ListShiftDays(repository, CALENDAR).execute()

    assert days == [
        DayOverview(date=date(2026, 10, 3), trips_count=1, net=1350),
        DayOverview(date=date(2026, 10, 1), trips_count=2, net=2700),
    ]

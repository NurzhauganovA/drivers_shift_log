from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo


@dataclass(frozen=True, slots=True)
class DriverCalendar:
    """Maps instants to the driver's local calendar days.

    A trip belongs to the day on which it started, so a ride from 23:50 to 00:20
    is counted in the earlier day.
    """

    timezone: ZoneInfo

    def day_of(self, moment: datetime) -> date:
        return moment.astimezone(self.timezone).date()

    def bounds(self, day: date) -> tuple[datetime, datetime]:
        start = datetime.combine(day, time.min, tzinfo=self.timezone)
        end = datetime.combine(day + timedelta(days=1), time.min, tzinfo=self.timezone)
        return start, end

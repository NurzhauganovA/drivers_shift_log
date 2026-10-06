from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Request

from shift_log.application import (
    AddTrip,
    DriverCalendar,
    GetDayReport,
    ListShiftDays,
    TripRepository,
)


@dataclass(frozen=True, slots=True)
class Container:
    get_day_report: GetDayReport
    list_shift_days: ListShiftDays
    add_trip: AddTrip

    @classmethod
    def build(cls, repository: TripRepository, calendar: DriverCalendar) -> "Container":
        return cls(
            get_day_report=GetDayReport(repository, calendar),
            list_shift_days=ListShiftDays(repository, calendar),
            add_trip=AddTrip(repository),
        )


def _container(request: Request) -> Container:
    container: Container = request.app.state.container
    return container


def _get_day_report(c: Annotated[Container, Depends(_container)]) -> GetDayReport:
    return c.get_day_report


def _list_shift_days(c: Annotated[Container, Depends(_container)]) -> ListShiftDays:
    return c.list_shift_days


def _add_trip(c: Annotated[Container, Depends(_container)]) -> AddTrip:
    return c.add_trip


GetDayReportDep = Annotated[GetDayReport, Depends(_get_day_report)]
ListShiftDaysDep = Annotated[ListShiftDays, Depends(_list_shift_days)]
AddTripDep = Annotated[AddTrip, Depends(_add_trip)]

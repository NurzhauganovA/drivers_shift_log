from datetime import date
from typing import Annotated

from fastapi import APIRouter, Query, Response, status

from shift_log.api.dependencies import AddTripDep, GetDayReportDep, ListShiftDaysDep
from shift_log.api.schemas import (
    DayOut,
    DayOverviewOut,
    ErrorResponse,
    SummaryOut,
    TripIn,
    TripOut,
)
from shift_log.application import NewTrip

router = APIRouter(prefix="/api/v1", tags=["shift log"])

DayQuery = Annotated[date, Query(alias="date", description="Local day, YYYY-MM-DD")]
REPLAY_HEADER = "Idempotent-Replayed"


@router.get("/trips", response_model=list[TripOut], summary="Trips started on a day")
def list_trips(day: DayQuery, use_case: GetDayReportDep) -> list[TripOut]:
    return [TripOut.from_domain(t) for t in use_case.execute(day).trips]


@router.get("/summary", response_model=SummaryOut, summary="Totals for a day")
def get_summary(day: DayQuery, use_case: GetDayReportDep) -> SummaryOut:
    return SummaryOut.from_domain(use_case.execute(day).summary)


@router.get("/days", response_model=list[DayOverviewOut], summary="Days with trips")
def list_days(use_case: ListShiftDaysDep) -> list[DayOverviewOut]:
    return [DayOverviewOut.from_domain(d) for d in use_case.execute()]


@router.get("/days/{day}", response_model=DayOut, summary="Summary and trips in one call")
def get_day(day: date, use_case: GetDayReportDep) -> DayOut:
    return DayOut.from_domain(use_case.execute(day))


@router.post(
    "/trips",
    response_model=TripOut,
    status_code=status.HTTP_201_CREATED,
    summary="Add a trip (idempotent by id)",
    responses={
        200: {"model": TripOut, "description": "Same trip was already stored; nothing changed"},
        409: {"model": ErrorResponse, "description": "Id reused with other data, or overlap"},
        422: {"model": ErrorResponse, "description": "Invalid trip"},
    },
)
def add_trip(payload: TripIn, response: Response, use_case: AddTripDep) -> TripOut:
    result = use_case.execute(NewTrip(**payload.model_dump()))
    if not result.created:
        response.status_code = status.HTTP_200_OK
        response.headers[REPLAY_HEADER] = "true"
    return TripOut.from_domain(result.trip)

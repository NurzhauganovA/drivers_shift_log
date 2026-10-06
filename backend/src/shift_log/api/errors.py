from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from shift_log.api.schemas import ErrorBody, ErrorResponse, FieldError
from shift_log.domain import DomainError, InvalidTripError

_STATUS_BY_ERROR: dict[type[DomainError], int] = {
    InvalidTripError: status.HTTP_422_UNPROCESSABLE_CONTENT,
}


def _respond(status_code: int, body: ErrorBody) -> JSONResponse:
    return JSONResponse(
        status_code=status_code, content=ErrorResponse(error=body).model_dump(mode="json")
    )


async def _domain_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, DomainError)
    fields = (
        [FieldError(field=exc.field, message=exc.message)]
        if isinstance(exc, InvalidTripError)
        else []
    )
    return _respond(
        _STATUS_BY_ERROR.get(type(exc), status.HTTP_409_CONFLICT),
        ErrorBody(code=exc.code, message=exc.message, fields=fields),
    )


async def _validation_error(_: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, RequestValidationError)
    fields = [
        FieldError(
            # loc looks like ("body", "amount") or ("query", "date").
            field=".".join(str(part) for part in err["loc"][1:]) or str(err["loc"][0]),
            message=err["msg"],
        )
        for err in exc.errors()
    ]
    return _respond(
        status.HTTP_422_UNPROCESSABLE_CONTENT,
        ErrorBody(code="validation_error", message="Request validation failed", fields=fields),
    )


def register_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(DomainError, _domain_error)
    app.add_exception_handler(RequestValidationError, _validation_error)

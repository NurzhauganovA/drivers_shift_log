class DomainError(Exception):
    """Base class for business rule violations. `code` is stable and exposed via the API."""

    code: str = "domain_error"

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class InvalidTripError(DomainError):
    code = "invalid_trip"

    def __init__(self, field: str, message: str) -> None:
        super().__init__(message)
        self.field = field


class TripIdConflictError(DomainError):
    """A trip with the same id already exists but its data differs."""

    code = "trip_id_conflict"

    def __init__(self, trip_id: str) -> None:
        super().__init__(f"Trip '{trip_id}' already exists with different data")
        self.trip_id = trip_id


class TripOverlapError(DomainError):
    """A driver cannot be on two trips at once."""

    code = "trip_overlap"

    def __init__(self, existing_id: str) -> None:
        super().__init__(f"Trip overlaps in time with existing trip '{existing_id}'")
        self.existing_id = existing_id

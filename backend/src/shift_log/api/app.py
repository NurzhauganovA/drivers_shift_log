from zoneinfo import ZoneInfo

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from shift_log.api.dependencies import Container
from shift_log.api.errors import register_error_handlers
from shift_log.api.routes import REPLAY_HEADER, router
from shift_log.application import DriverCalendar, TripRepository
from shift_log.config import Settings
from shift_log.infrastructure import JsonFileTripRepository


def create_app(
    settings: Settings | None = None, repository: TripRepository | None = None
) -> FastAPI:
    settings = settings or Settings()
    repository = repository or JsonFileTripRepository(settings.data_file, settings.seed_file)
    calendar = DriverCalendar(ZoneInfo(settings.timezone))

    app = FastAPI(title="Driver Shift Log API", version="1.0.0")
    app.state.container = Container.build(repository, calendar)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
        expose_headers=[REPLAY_HEADER],
    )
    register_error_handlers(app)
    app.include_router(router)

    @app.get("/health", include_in_schema=False)
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app

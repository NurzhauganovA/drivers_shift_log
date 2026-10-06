"""ASGI entry point: `uvicorn shift_log.main:app`."""

from shift_log.api import create_app

app = create_app()

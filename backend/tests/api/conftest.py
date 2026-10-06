from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from shift_log.api import create_app
from shift_log.config import Settings
from shift_log.infrastructure import InMemoryTripRepository
from tests.factories import make_trip


@pytest.fixture
def repository() -> InMemoryTripRepository:
    return InMemoryTripRepository(
        [
            make_trip("t1", amount=2400, commission=360),
        ]
    )


@pytest.fixture
def client(repository: InMemoryTripRepository) -> Iterator[TestClient]:
    app = create_app(Settings(timezone="Asia/Almaty"), repository)
    with TestClient(app) as test_client:
        yield test_client

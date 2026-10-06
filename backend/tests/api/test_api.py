from typing import Any

from fastapi.testclient import TestClient

from shift_log.infrastructure import InMemoryTripRepository

SAMPLE = [
    {
        "id": "t1",
        "start": "2026-10-01T08:10:00+05:00",
        "end": "2026-10-01T08:32:00+05:00",
        "amount": 2400,
        "payment": "card",
        "commission": 360,
    },
    {
        "id": "t2",
        "start": "2026-10-01T09:05:00+05:00",
        "end": "2026-10-01T09:20:00+05:00",
        "amount": 1500,
        "payment": "cash",
        "commission": 225,
    },
]


def new_trip(**overrides: Any) -> dict[str, Any]:
    return SAMPLE[1] | overrides


def test_health(client: TestClient) -> None:
    assert client.get("/health").json() == {"status": "ok"}


def test_post_then_read_day(client: TestClient) -> None:
    assert client.post("/api/v1/trips", json=new_trip()).status_code == 201

    day = client.get("/api/v1/days/2026-10-01").json()

    assert [t["id"] for t in day["trips"]] == ["t1", "t2"]
    assert day["summary"] == {
        "date": "2026-10-01",
        "currency": "KZT",
        "trips_count": 2,
        "revenue": 3900,
        "commission": 585,
        "net": 3315,
        "busy_seconds": 1200 + 900,
        "cash": {"count": 1, "amount": 1500},
        "card": {"count": 1, "amount": 2400},
    }


def test_separate_trips_and_summary_endpoints(client: TestClient) -> None:
    trips = client.get("/api/v1/trips", params={"date": "2026-10-01"})
    summary = client.get("/api/v1/summary", params={"date": "2026-10-01"})

    assert trips.status_code == summary.status_code == 200
    assert [t["id"] for t in trips.json()] == ["t1"]
    assert summary.json()["net"] == 2040


def test_empty_day_returns_zero_summary(client: TestClient) -> None:
    day = client.get("/api/v1/days/2026-12-31").json()

    assert day["trips"] == []
    assert day["summary"]["trips_count"] == 0
    assert day["summary"]["net"] == 0


def test_list_days(client: TestClient) -> None:
    client.post(
        "/api/v1/trips",
        json=new_trip(id="x", start="2026-10-03T10:00:00+05:00", end="2026-10-03T10:30:00+05:00"),
    )

    assert client.get("/api/v1/days").json() == [
        {"date": "2026-10-03", "trips_count": 1, "net": 1275},
        {"date": "2026-10-01", "trips_count": 1, "net": 2040},
    ]


def test_repeated_post_is_idempotent(
    client: TestClient, repository: InMemoryTripRepository
) -> None:
    first = client.post("/api/v1/trips", json=new_trip())
    second = client.post("/api/v1/trips", json=new_trip())

    assert first.status_code == 201
    assert "Idempotent-Replayed" not in first.headers
    assert second.status_code == 200
    assert second.headers["Idempotent-Replayed"] == "true"
    assert second.json() == first.json()
    assert len(repository.list_all()) == 2


def test_reused_id_with_other_data_returns_409(client: TestClient) -> None:
    response = client.post("/api/v1/trips", json=SAMPLE[0] | {"amount": 9999})

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "trip_id_conflict"


def test_overlapping_trip_returns_409(client: TestClient) -> None:
    response = client.post("/api/v1/trips", json=SAMPLE[0] | {"id": "t1-again"})

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "trip_overlap"


def test_business_rule_violation_returns_field_error(client: TestClient) -> None:
    response = client.post("/api/v1/trips", json=new_trip(amount=0))

    assert response.status_code == 422
    assert response.json()["error"] == {
        "code": "invalid_trip",
        "message": "Amount must be greater than zero",
        "fields": [{"field": "amount", "message": "Amount must be greater than zero"}],
    }


def test_end_before_start_is_rejected(client: TestClient) -> None:
    response = client.post("/api/v1/trips", json=new_trip(end="2026-10-01T09:00:00+05:00"))

    assert response.status_code == 422
    assert response.json()["error"]["fields"][0]["field"] == "end"


def test_schema_violations_are_reported_per_field(client: TestClient) -> None:
    response = client.post(
        "/api/v1/trips",
        json=new_trip(amount="1500", payment="crypto", start="2026-10-01T09:05:00", extra=1),
    )

    body = response.json()["error"]
    assert response.status_code == 422
    assert body["code"] == "validation_error"
    assert {f["field"] for f in body["fields"]} == {"amount", "payment", "start", "extra"}


def test_bad_date_query_is_rejected(client: TestClient) -> None:
    response = client.get("/api/v1/trips", params={"date": "01.10.2026"})

    assert response.status_code == 422
    assert response.json()["error"]["fields"][0]["field"] == "date"

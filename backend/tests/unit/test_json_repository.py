import json
from itertools import pairwise
from pathlib import Path

import pytest

from shift_log.infrastructure import JsonFileTripRepository
from shift_log.infrastructure.json_codec import load_trips, trip_to_json
from tests.factories import at, make_trip

SEED = Path(__file__).parents[2] / "data" / "seed_trips.json"


def test_committed_seed_is_valid_and_has_no_overlaps() -> None:
    trips = load_trips(SEED)

    assert {"t1", "t2"} <= {t.id for t in trips}
    ordered = sorted(trips, key=lambda t: t.start)
    for previous, current in pairwise(ordered):
        assert previous.end <= current.start, f"{previous.id} overlaps {current.id}"


def test_seed_is_used_on_first_start_and_left_untouched(tmp_path: Path) -> None:
    seed = tmp_path / "seed.json"
    seed.write_text(json.dumps([trip_to_json(make_trip("s1"))]))
    data = tmp_path / "var" / "trips.json"

    repository = JsonFileTripRepository(data, seed)
    repository.add(make_trip("n1", start=at(2, 8)))

    assert json.loads(seed.read_text()) == [trip_to_json(make_trip("s1"))]
    assert [t["id"] for t in json.loads(data.read_text())] == ["s1", "n1"]


def test_trips_survive_restart(tmp_path: Path) -> None:
    data = tmp_path / "trips.json"
    JsonFileTripRepository(data).add(make_trip("t1"))

    reloaded = JsonFileTripRepository(data)

    assert reloaded.get("t1") == make_trip("t1")


def test_failed_write_does_not_keep_trip_in_memory(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    repository = JsonFileTripRepository(tmp_path / "trips.json")

    def broken_flush() -> None:
        raise OSError("disk full")

    monkeypatch.setattr(repository, "_flush", broken_flush)

    with pytest.raises(OSError, match="disk full"):
        repository.add(make_trip("t1"))
    assert repository.get("t1") is None


@pytest.mark.parametrize(
    "bad",
    [
        {"amount": "2400"},
        {"amount": True},
        {"amount": 0},
        {"payment": "crypto"},
        {"start": "2026-10-01T08:10:00"},
    ],
)
def test_malformed_seed_fails_loudly(tmp_path: Path, bad: dict[str, object]) -> None:
    raw = trip_to_json(make_trip()) | bad
    path = tmp_path / "trips.json"
    path.write_text(json.dumps([raw]))

    with pytest.raises(ValueError, match="index 0"):
        load_trips(path)

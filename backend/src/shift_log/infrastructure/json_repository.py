import json
import os
import tempfile
from pathlib import Path

from shift_log.domain import Trip
from shift_log.infrastructure.json_codec import load_trips, trip_to_json
from shift_log.infrastructure.memory_repository import InMemoryTripRepository


class JsonFileTripRepository(InMemoryTripRepository):
    """Keeps trips in memory and persists them to a JSON file after every write.

    On first start the file does not exist yet and data is taken from `seed_path`,
    so the committed sample data is never modified. Writes go to a temporary file
    that atomically replaces the target, so a crash cannot leave half-written JSON.
    Designed for a single server process.
    """

    def __init__(self, path: Path, seed_path: Path | None = None) -> None:
        source = path if path.exists() else seed_path
        super().__init__(load_trips(source) if source is not None and source.exists() else [])
        self._path = path

    def add(self, trip: Trip) -> None:
        with self._lock:
            super().add(trip)
            try:
                self._flush()
            except OSError:
                self._discard(trip.id)
                raise

    def _flush(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        payload = json.dumps(
            [trip_to_json(t) for t in self.list_all()], ensure_ascii=False, indent=2
        )
        fd, tmp_name = tempfile.mkstemp(dir=self._path.parent, prefix=".trips-", suffix=".json")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as tmp:
                tmp.write(payload + "\n")
                tmp.flush()
                os.fsync(tmp.fileno())
            os.replace(tmp_name, self._path)
        except BaseException:
            Path(tmp_name).unlink(missing_ok=True)
            raise

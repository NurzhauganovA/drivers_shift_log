from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configured through SHIFT_LOG_* environment variables. Paths are relative to the cwd."""

    model_config = SettingsConfigDict(env_prefix="SHIFT_LOG_", env_file=".env", extra="ignore")

    data_file: Path = Path("var/trips.json")
    seed_file: Path | None = Path("data/seed_trips.json")
    timezone: str = "Asia/Almaty"
    cors_origins: list[str] = ["*"]

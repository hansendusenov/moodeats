"""MoodEats ADK Agent - Application Settings"""

import os
from pathlib import Path
from pydantic_settings import BaseSettings
from functools import lru_cache

# Search hierarchy: adk_agent/.env.local -> adk_agent/.env -> root/.env.local -> root/.env
_curr_dir = Path(__file__).resolve().parent.parent
_root_dir = _curr_dir.parent

_env_files = [
    _curr_dir / ".env.local",
    _curr_dir / ".env",
    _root_dir / ".env.local",
    _root_dir / ".env",
]

_valid_env_file = next((str(p) for p in _env_files if p.exists()), ".env")


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_role_key: str = ""
    supabase_db_host: str = ""
    supabase_db_port: int = 5432
    supabase_db_name: str = "postgres"
    supabase_db_user: str = "postgres"
    supabase_db_password: str = ""

    # Google APIs
    google_places_api_key: str = ""
    google_gemini_api_key: str = ""
    google_places_daily_quota: int = 150

    # App Config
    app_env: str = "local"
    app_debug: bool = True
    app_port: int = 8080
    voucher_countdown_minutes: int = 15
    rate_limit_per_3s: int = 1
    rate_limit_daily: int = 20

    model_config = {
        "env_file": _valid_env_file,
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }

    @property
    def db_connection_string(self) -> str:
        return (
            f"postgresql://{self.supabase_db_user}:{self.supabase_db_password}"
            f"@{self.supabase_db_host}:{self.supabase_db_port}/{self.supabase_db_name}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()

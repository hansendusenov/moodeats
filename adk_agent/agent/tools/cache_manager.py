"""
MoodEats ADK Agent - Places Cache Manager
Implements Section 6.3 hybrid quota-saver caching in PostgreSQL Supabase.
"""

import json
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Dict, Any
import psycopg2
from adk_agent.config import get_settings


class PlacesCacheManager:
    def __init__(self):
        self.settings = get_settings()

    def _get_connection(self):
        return psycopg2.connect(
            host=self.settings.supabase_db_host,
            port=self.settings.supabase_db_port,
            dbname=self.settings.supabase_db_name,
            user=self.settings.supabase_db_user,
            password=self.settings.supabase_db_password,
        )

    def get_cached_places(self, cache_key: str) -> Optional[List[Dict[str, Any]]]:
        """Retrieve non-expired cached places by cache_key."""
        try:
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT places_payload 
                        FROM places_cache 
                        WHERE cache_key = %s AND expires_at > NOW();
                        """,
                        (cache_key,),
                    )
                    row = cur.fetchone()
                    if row:
                        return row[0]
        except Exception:
            pass
        return None

    def set_cached_places(
        self,
        cache_key: str,
        keyword: str,
        places: List[Dict[str, Any]],
        provider: str = "google_places_v1",
        ttl_days: int = 7,
    ) -> bool:
        """Store places in cache with TTL."""
        try:
            expires_at = datetime.now(timezone.utc) + timedelta(days=ttl_days)
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        INSERT INTO places_cache (cache_key, keyword, source_provider, places_payload, expires_at)
                        VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (cache_key) 
                        DO UPDATE SET places_payload = EXCLUDED.places_payload, expires_at = EXCLUDED.expires_at;
                        """,
                        (cache_key, keyword, provider, json.dumps(places), expires_at),
                    )
                conn.commit()
            return True
        except Exception:
            return False

"""
MoodEats ADK Agent - Quota & Rate Limiter Middleware
Enforces PRD Section 6.4: 1 req/3s burst limit and 20 req/day quota.
"""

import time
from typing import Dict, Tuple
from fastapi import Request, HTTPException, status


class RateLimiter:
    def __init__(self, burst_seconds: float = 3.0, daily_limit: int = 20):
        self.burst_seconds = burst_seconds
        self.daily_limit = daily_limit
        # Format: {identifier: (last_timestamp, today_date_str, daily_count)}
        self._history: Dict[str, Tuple[float, str, int]] = {}

    def check(self, request: Request, user_id: str = None):
        identifier = user_id or request.client.host if request.client else "anonymous"
        now = time.time()
        today = time.strftime("%Y-%m-%d")

        last_time, recorded_date, count = self._history.get(identifier, (0.0, today, 0))

        # Check burst limit (1 request per 3 seconds)
        if (now - last_time) < self.burst_seconds:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Terlalu cepat. Harap tunggu beberapa detik sebelum meminta rekomendasi lagi.",
            )

        # Check daily quota
        if recorded_date != today:
            count = 0
            recorded_date = today

        if count >= self.daily_limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Batas kuota harian rekomendasi AI ({self.daily_limit}x/hari) sudah tercapai.",
            )

        self._history[identifier] = (now, recorded_date, count + 1)

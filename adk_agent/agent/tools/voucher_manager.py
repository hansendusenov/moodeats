"""
MoodEats ADK Agent - Sponsored Merchant & Dynamic Voucher Manager
Implements PRD Section 6.3, 7.1 & 7.2.
"""

from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any, List
import psycopg2
from adk_agent.config import get_settings


from adk_agent.agent.tools.places_resolver import calculate_distance_km
import urllib.parse
import uuid


class VoucherManager:
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

    def find_matching_sponsored_merchant(
        self,
        keywords: List[str],
        user_lat: Optional[float] = None,
        user_lng: Optional[float] = None,
        max_distance_km: float = 10.0,
    ) -> Optional[Dict[str, Any]]:
        """
        Finds the highest priority active sponsored merchant within max_distance_km matching food keywords.
        """
        try:
            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT id, merchant_name, category, address, lat, lng, image_url, promo_badge,
                               voucher_code, discount_description, voucher_type, countdown_minutes,
                               max_claim_quota, claimed_count, affiliate_url, priority
                        FROM sponsored_merchants
                        WHERE is_active = TRUE AND claimed_count < max_claim_quota
                        ORDER BY priority ASC;
                        """
                    )
                    rows = cur.fetchall()
                    if not rows:
                        return None

                    candidates = []
                    for row in rows:
                        m_id, name, cat, addr, lat, lng, img, badge, code, disc, v_type, countdown, max_q, claimed, aff, prio = row
                        
                        dist = 1.0
                        if user_lat is not None and user_lng is not None and lat is not None and lng is not None:
                            dist = calculate_distance_km(user_lat, user_lng, float(lat), float(lng))
                            if dist > max_distance_km:
                                continue  # Exclude sponsored merchants beyond 10km!

                        # Check keyword match
                        match_score = 0
                        name_cat = f"{name} {cat} {badge or ''}".lower()
                        for kw in keywords:
                            if kw.lower() in name_cat:
                                match_score += 15

                        candidates.append({
                            "row": row,
                            "dist": round(dist, 1),
                            "score": match_score - (dist * 0.4),  # prefer relevant keyword and closer distance
                        })

                    if not candidates:
                        return None

                    # Pick candidate with highest score
                    candidates.sort(key=lambda x: x["score"], reverse=True)
                    best = candidates[0]
                    m_id, name, cat, addr, lat, lng, img, badge, code, disc, v_type, countdown, max_q, claimed, aff, prio = best["row"]
                    dist = best["dist"]

                    return {
                        "id": str(m_id),
                        "name": name,
                        "category": cat,
                        "address": addr,
                        "distance_km": dist,
                        "rating": 4.8,
                        "photo_url": img or "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400",
                        "mood_badge": badge or "Rekomendasi Sponsor",
                        "price_range": "Rp 25.000 - Rp 45.000",
                        "is_sponsored": True,
                        "is_open": True,
                        "opening_hours": "Buka Sekarang • Promo Aktif",
                        "voucher": {
                            "has_voucher": True,
                            "merchant_id": str(m_id),
                            "voucher_code": code,
                            "type": v_type or "timer",
                            "discount_text": disc,
                            "duration_minutes": countdown or 15,
                        },
                        "action_links": {
                            "google_maps": f"https://maps.google.com/?q={lat},{lng}",
                            "delivery_app": aff or f"https://gofood.co.id/jakarta/search?q={urllib.parse.quote(name)}",
                            "whatsapp_booking": None,
                        },
                    }
        except Exception as e:
            print(f"Error finding sponsored merchant: {e}")

        return None

    def claim_voucher(self, merchant_id: str, user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Claims a dynamic 15-minute countdown voucher (PRD 7.2).
        1. Checks quota
        2. Inserts row into user_vouchers (NOW() + 15 min)
        3. Updates claimed_count
        4. Logs to ad_metrics
        """
        now_utc = datetime.now(timezone.utc)
        duration_minutes = self.settings.voucher_countdown_minutes or 15
        expires_at = now_utc + timedelta(minutes=duration_minutes)

        try:
            # Validate UUID format
            try:
                uuid.UUID(str(merchant_id))
            except (ValueError, AttributeError):
                return {"status": "error", "message": "ID merchant sponsor tidak valid atau bukan mitra resmi."}

            with self._get_connection() as conn:
                with conn.cursor() as cur:
                    # 1. Check merchant & quota
                    cur.execute(
                        """
                        SELECT voucher_code, max_claim_quota, claimed_count
                        FROM sponsored_merchants
                        WHERE id = %s AND is_active = TRUE
                        FOR UPDATE;
                        """,
                        (merchant_id,),
                    )
                    row = cur.fetchone()
                    if not row:
                        return {"status": "error", "message": "Restoran mitra tidak ditemukan atau status promonya tidak aktif."}

                    code, max_q, claimed = row
                    if claimed >= max_q:
                        return {"status": "error", "message": "Kuota klaim voucher promo ini sudah habis."}

                    # 2. Insert user_vouchers
                    cur.execute(
                        """
                        INSERT INTO user_vouchers (merchant_id, user_id, voucher_code, status, claimed_at, expires_at)
                        VALUES (%s, %s, %s, %s, %s, %s);
                        """,
                        (merchant_id, user_id, code, "active", now_utc, expires_at),
                    )

                    # 3. Increment claimed_count
                    cur.execute(
                        """
                        UPDATE sponsored_merchants
                        SET claimed_count = claimed_count + 1
                        WHERE id = %s;
                        """,
                        (merchant_id,),
                    )

                    # 4. Log ad_metric
                    cur.execute(
                        """
                        INSERT INTO ad_metrics (merchant_id, user_id, event_type, city)
                        VALUES (%s, %s, %s, %s);
                        """,
                        (merchant_id, user_id, "voucher_claim", "Jakarta"),
                    )

                conn.commit()

            return {
                "status": "success",
                "voucher_code": code,
                "expires_at": expires_at.isoformat(),
                "countdown_seconds": duration_minutes * 60,
            }

        except Exception as e:
            return {"status": "error", "message": f"Gagal mengklaim voucher: {str(e)}"}

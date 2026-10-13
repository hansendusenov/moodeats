"""
MoodEats ADK Agent - FastAPI Service & Master API Contracts
Implements PRD Section 6, 7 & 9 full API contracts for Mobile & Web clients.
"""

import uuid
import json
import base64
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, Request, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import psycopg2
import logging

logger = logging.getLogger("moodeats")

from adk_agent.config import get_settings
from adk_agent.agent.moodeats_agent import MoodEatsAgent
from adk_agent.agent.tools.voucher_manager import VoucherManager
from adk_agent.middleware.rate_limiter import RateLimiter

app = FastAPI(
    title="MoodEats Culinary Intelligence Engine",
    description="Autonomous Hyperlocal Sentiment Commerce & Discovery Service",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

settings = get_settings()
agent = MoodEatsAgent()
voucher_manager = VoucherManager()
rate_limiter = RateLimiter(burst_seconds=3.0, daily_limit=20)


def get_db_connection():
    return psycopg2.connect(
        host=settings.supabase_db_host,
        port=settings.supabase_db_port,
        dbname=settings.supabase_db_name,
        user=settings.supabase_db_user,
        password=settings.supabase_db_password,
        connect_timeout=3,
    )


# ---------------------------------------------------------
# Schemas (PRD Section 7)
# ---------------------------------------------------------

class RecommendRequest(BaseModel):
    session_id: Optional[str] = Field(default=None, description="UUID sesi multi-turn. Null untuk sesi baru.")
    prompt: str = Field(..., description="Curhatan atau keluhan emosi pengguna.")
    lat: Optional[float] = Field(default=None, description="Latitude GPS")
    lng: Optional[float] = Field(default=None, description="Longitude GPS")
    city: Optional[str] = Field(default="Jakarta Selatan", description="Kota pengguna saat ini")
    local_time: Optional[str] = Field(default=None, description="Waktu lokal pengguna (HH:MM:SS)")
    is_manual_location: bool = Field(default=False, description="Apakah lokasi dipilih manual")
    is_halal_only: bool = Field(default=False, description="Filter wajib halal")
    dietary_type: Optional[str] = Field(default=None, description="Pola diet: none, vegetarian, vegan, low_calorie, low_carb, pescatarian")
    allergies: Optional[List[str]] = Field(default=None, description="Daftar alergi makanan")
    only_open_now: bool = Field(default=False, description="Filter hanya restoran yang sedang buka sekarang")
    user_id: Optional[str] = Field(default=None, description="ID profil user Supabase")
    device_os: Optional[str] = Field(default=None, description="OS perangkat pengguna")
    app_version: Optional[str] = Field(default=None, description="Versi aplikasi mobile")


class UserSyncRequest(BaseModel):
    user_id: str = Field(..., description="ID user dari Firebase UID atau UUID")
    email: str = Field(..., description="Email user")
    display_name: str = Field(..., description="Nama tampilan user")
    birth_date: Optional[str] = Field(default=None, description="Tanggal lahir (YYYY-MM-DD)")
    gender: Optional[str] = Field(default=None, description="Jenis kelamin")
    phone: Optional[str] = Field(default=None, description="Nomor telepon")
    device_model: Optional[str] = Field(default=None, description="Model perangkat (misal Xiaomi POCO X3 NFC)")
    device_os: Optional[str] = Field(default=None, description="Sistem Operasi (misal Android 12)")
    app_version: Optional[str] = Field(default=None, description="Versi aplikasi (misal v1.0.2)")
    is_halal_only: Optional[bool] = Field(default=None, description="Preferensi wajib halal")
    dietary_type: Optional[str] = Field(default=None, description="Pola diet")
    allergies: Optional[List[str]] = Field(default=None, description="Daftar alergi makanan")


class ClaimVoucherRequest(BaseModel):
    merchant_id: str = Field(..., description="UUID merchant dari tabel sponsored_merchants")
    user_id: Optional[str] = Field(default=None, description="ID user")


class AnalyzeImageRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded string of image")
    mime_type: Optional[str] = Field(default="image/jpeg", description="MIME type of image")
    lang: Optional[str] = Field(default="id", description="Language code: 'id' or 'en'")


# ---------------------------------------------------------
# Endpoints
# ---------------------------------------------------------

@app.get("/")
def root():
    return {
        "service": "MoodEats Culinary Intelligence Engine",
        "status": "online",
        "model": "gemini-2.5-flash",
        "api_docs": "/docs",
    }


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "gemini_api": bool(settings.google_gemini_api_key),
        "places_api": bool(settings.google_places_api_key),
        "db_host": settings.supabase_db_host,
    }


def check_user_active(user_id: Optional[str]):
    """
    Enforce ban status from user_profiles. If banned, reject with 403 Forbidden.
    """
    if not user_id:
        return
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT is_banned, banned_reason FROM user_profiles WHERE id = %s;", (user_id,))
                row = cur.fetchone()
                if row and row[0]:
                    reason = row[1] or "Akun Anda dinonaktifkan oleh administrator MoodEats."
                    raise HTTPException(status_code=403, detail=f"Akun Anda diblokir: {reason}")
    except HTTPException:
        raise
    except Exception as e:
        logger.warning(f"Could not verify user ban status: {e}")


@app.post("/api/v1/agent/recommend")
async def recommend(payload: RecommendRequest, request: Request):
    """
    PRD 7.1 POST /api/v1/agent/recommend
    Consultation endpoint mapping mood, time, and GPS to physical dishes & sponsored vouchers.
    """
    # Ban status check
    check_user_active(payload.user_id)

    # Rate Limiting Guardrail (PRD 10.3)
    rate_limiter.check(request, user_id=payload.user_id)

    session_id = payload.session_id or str(uuid.uuid4())

    # Run AI inference + Places resolution
    result = await agent.analyze_and_discover(
        prompt=payload.prompt,
        user_lat=payload.lat,
        user_lng=payload.lng,
        city=payload.city,
        local_time=payload.local_time,
        is_halal_only=payload.is_halal_only,
        dietary_type=payload.dietary_type,
        allergies=payload.allergies,
        only_open_now=payload.only_open_now,
    )

    is_relevant = result.get("is_relevant", True)

    # Persist session to mood_sessions table in Supabase
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO mood_sessions 
                    (session_id, user_id, role, message_text, detected_mood, food_categories, location_lat, location_lng, city_detected, ai_response_payload, device_os, app_version)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """,
                    (
                        session_id,
                        payload.user_id,
                        "user",
                        payload.prompt,
                        result.get("detected_mood"),
                        json.dumps(result.get("food_categories", [])),
                        payload.lat,
                        payload.lng,
                        payload.city,
                        json.dumps(result),
                        payload.device_os,
                        payload.app_version,
                    ),
                )
                if payload.user_id:
                    cur.execute(
                        """
                        UPDATE user_profiles 
                        SET last_active_at = NOW(),
                            device_os = COALESCE(%s, device_os),
                            app_version = COALESCE(%s, app_version),
                            updated_at = NOW()
                        WHERE id = %s;
                        """,
                        (payload.device_os, payload.app_version, payload.user_id),
                    )
            conn.commit()
    except Exception as e:
        logger.warning(f"Error persisting session telemetry: {e}")

    status_str = "success" if is_relevant else "rejected"

    return {
        "status": status_str,
        "session_id": session_id,
        "data": result,
    }


@app.get("/api/v1/sessions/history")
def get_session_history(
    user_id: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    offset: int = Query(0),
    limit: int = Query(10),
):
    """
    Returns consultation history from mood_sessions table for mobile client.
    Supports today-only default filter, custom date ranges, and offset-based pagination.
    Includes full cached_response for 0-latency offline review.
    """
    sessions = []
    total_count = 0
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                where_clauses = []
                params = []

                if user_id:
                    where_clauses.append("user_id = %s")
                    params.append(user_id)

                if start_date == "ALL":
                    # Explicitly requested all history without date filtering
                    pass
                elif start_date and end_date:
                    where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date >= %s::date")
                    params.append(start_date)
                    where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date <= %s::date")
                    params.append(end_date)
                elif start_date:
                    where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date = %s::date")
                    params.append(start_date)
                else:
                    # Default: Hari ini (Today) in WIB (Asia/Jakarta)
                    where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Jakarta')::date")

                where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

                # 1. Count total records matching criteria
                count_query = f"SELECT COUNT(*) FROM mood_sessions {where_sql};"
                cur.execute(count_query, params)
                count_res = cur.fetchone()
                total_count = count_res[0] if count_res else 0

                # 2. Fetch paginated records
                data_query = f"""
                    SELECT id, session_id, message_text, detected_mood, food_categories, 
                           city_detected, ai_response_payload, created_at
                    FROM mood_sessions
                    {where_sql}
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s;
                """
                fetch_params = list(params) + [limit, offset]
                cur.execute(data_query, fetch_params)

                for row in cur.fetchall():
                    row_id, sess_id, msg, mood, foods, city, payload, created_at = row
                    
                    first_restaurant = None
                    has_voucher = False
                    p_data = None
                    if payload:
                        try:
                            p_data = json.loads(payload) if isinstance(payload, str) else payload
                            places = p_data.get("places", [])
                            if places:
                                first_restaurant = places[0].get("name")
                                has_voucher = any(p.get("voucher", {}).get("has_voucher", False) for p in places)
                        except Exception:
                            pass
                    
                    food_cats = []
                    if foods:
                        try:
                            food_cats = json.loads(foods) if isinstance(foods, str) else foods
                        except Exception:
                            food_cats = [foods]

                    sessions.append({
                        "id": str(row_id),
                        "session_id": sess_id,
                        "title": msg,
                        "detected_mood": mood or "Mood Seimbang",
                        "restaurant": first_restaurant or (food_cats[0] if food_cats else "Rekomendasi Kuliner"),
                        "food_categories": food_cats,
                        "city": city,
                        "has_voucher": has_voucher,
                        "cached_response": p_data,
                        "created_at": created_at.isoformat() if created_at else None,
                    })
    except Exception as e:
        print(f"Error fetching session history: {e}")

    return {
        "status": "success",
        "count": len(sessions),
        "total": total_count,
        "has_more": (offset + len(sessions)) < total_count,
        "offset": offset,
        "limit": limit,
        "history": sessions,
    }


@app.post("/api/v1/users/sync")
def sync_user_profile(payload: UserSyncRequest):
    """
    Syncs mobile user profile (Firebase or guest) into Postgres user_profiles table.
    """
    try:
        allergies_json = json.dumps(payload.allergies) if payload.allergies is not None else None
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO user_profiles (
                        id, display_name, email, phone, gender, birth_date, is_banned,
                        device_model, device_os, app_version, is_halal_only, dietary_type, allergies,
                        last_active_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, FALSE, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                    ON CONFLICT (id) DO UPDATE SET
                        display_name = EXCLUDED.display_name,
                        email = EXCLUDED.email,
                        phone = COALESCE(EXCLUDED.phone, user_profiles.phone),
                        gender = COALESCE(EXCLUDED.gender, user_profiles.gender),
                        birth_date = COALESCE(EXCLUDED.birth_date, user_profiles.birth_date),
                        device_model = COALESCE(EXCLUDED.device_model, user_profiles.device_model),
                        device_os = COALESCE(EXCLUDED.device_os, user_profiles.device_os),
                        app_version = COALESCE(EXCLUDED.app_version, user_profiles.app_version),
                        is_halal_only = COALESCE(EXCLUDED.is_halal_only, user_profiles.is_halal_only),
                        dietary_type = COALESCE(EXCLUDED.dietary_type, user_profiles.dietary_type),
                        allergies = COALESCE(EXCLUDED.allergies, user_profiles.allergies),
                        last_active_at = NOW(),
                        updated_at = NOW();
                    """,
                    (
                        payload.user_id,
                        payload.display_name,
                        payload.email,
                        payload.phone,
                        payload.gender,
                        payload.birth_date,
                        payload.device_model,
                        payload.device_os,
                        payload.app_version,
                        payload.is_halal_only,
                        payload.dietary_type,
                        allergies_json,
                    ),
                )
                conn.commit()
        return {"status": "success", "message": "User profile synchronized successfully"}
    except Exception as e:
        logger.error(f"Failed to sync user profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/vouchers/claim")
def claim_voucher(payload: ClaimVoucherRequest):
    """
    PRD 7.2 POST /api/v1/vouchers/claim
    Claims a 15-minute countdown promotional voucher for a sponsored merchant.
    """
    check_user_active(payload.user_id)
    response = voucher_manager.claim_voucher(
        merchant_id=payload.merchant_id,
        user_id=payload.user_id,
    )
    if response.get("status") == "error":
        raise HTTPException(status_code=400, detail=response.get("message"))

    return response


@app.get("/api/v1/vouchers/my")
def get_user_active_vouchers(user_id: str = Query(...)):
    """
    Returns active vouchers for a specific user (including admin-injected vouchers).
    """
    check_user_active(user_id)
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT uv.id, uv.merchant_id, uv.voucher_code, uv.status, uv.discount_description,
                           uv.claimed_at, uv.expires_at, sm.merchant_name, sm.discount_description, sm.image_url
                    FROM user_vouchers uv
                    LEFT JOIN sponsored_merchants sm ON uv.merchant_id = sm.id
                    WHERE uv.user_id = %s AND uv.status = 'active' AND uv.expires_at > NOW()
                    ORDER BY uv.claimed_at DESC;
                    """,
                    (user_id,),
                )
                rows = cur.fetchall()
                vouchers = []
                now_utc = datetime.now(timezone.utc)
                for r in rows:
                    expires_dt = r[6]
                    seconds_left = max(0, int((expires_dt - now_utc).total_seconds())) if expires_dt else 0
                    vouchers.append({
                        "id": str(r[0]),
                        "merchant_id": str(r[1]) if r[1] else None,
                        "voucher_code": r[2],
                        "status": r[3],
                        "discount_description": r[4] or r[8] or "Diskon Spesial Injeksi Admin",
                        "claimed_at": r[5].isoformat() if r[5] else None,
                        "expires_at": r[6].isoformat() if r[6] else None,
                        "merchant_name": r[7] or "MoodEats Platform Promo",
                        "image_url": r[9],
                        "seconds_remaining": seconds_left,
                    })
                return {"status": "success", "vouchers": vouchers}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch user vouchers: {e}")
        return {"status": "error", "message": str(e), "vouchers": []}


@app.get("/api/v1/roulette")
def get_roulette_items():
    """
    PRD 9.3 Bite Roulette (Roda Keberuntungan Kuliner)
    Returns curated comfort food segments for the spinning wheel gamification.
    Provides bilingual Indonesian & English metadata.
    """
    return {
        "status": "success",
        "items": [
            {
                "id": "r1",
                "label": "Soto Hangat",
                "label_en": "Warm Soto Soup",
                "emoji": "🍲",
                "mood_benefit": "Menenangkan pikiran lelah & hangatkan badan",
                "mood_benefit_en": "Calms tired minds & warms the body",
                "color_hex": "#DC2626",
                "search_keyword": "soto ayam soto daging",
            },
            {
                "id": "r2",
                "label": "Bakso Mercon",
                "label_en": "Spicy Meatball",
                "emoji": "🌶️",
                "mood_benefit": "Pelepas stres & pemicu adrenalin semangat",
                "mood_benefit_en": "Stress reliever & energizing spice kick",
                "color_hex": "#EA580C",
                "search_keyword": "bakso mercon pedas",
            },
            {
                "id": "r3",
                "label": "Nasi Gila",
                "label_en": "Crazy Rice Bowl",
                "emoji": "🍳",
                "mood_benefit": "Kenikmatan gurih cepat saji pengusir lapar",
                "mood_benefit_en": "Savory street stir-fry to beat hunger fast",
                "color_hex": "#CA8A04",
                "search_keyword": "nasi gila spesial",
            },
            {
                "id": "r4",
                "label": "Kopi & Toast",
                "label_en": "Coffee & Toast",
                "emoji": "☕",
                "mood_benefit": "Dopamine booster penambah fokus kerja",
                "mood_benefit_en": "Dopamine booster to enhance focus",
                "color_hex": "#059669",
                "search_keyword": "kopi susu aren toast",
            },
            {
                "id": "r5",
                "label": "Mie Ayam Bakso",
                "label_en": "Chicken Noodles",
                "emoji": "🍜",
                "mood_benefit": "Comfort food legendaris penyejuk nostalgia",
                "mood_benefit_en": "Legendary comfort food with nostalgic flavor",
                "color_hex": "#2563EB",
                "search_keyword": "mie ayam bakso pangsit",
            },
            {
                "id": "r6",
                "label": "Nasi Uduk Komplit",
                "label_en": "Coconut Rice",
                "emoji": "🍚",
                "mood_benefit": "Kenyang gurih santan mantap",
                "mood_benefit_en": "Rich coconut aroma for satisfying warmth",
                "color_hex": "#7C3AED",
                "search_keyword": "nasi uduk betawi komplit",
            },
        ],
    }


@app.post("/api/v1/agent/analyze-image")
async def analyze_image(payload: AnalyzeImageRequest):
    """
    Multimodal image analysis via Gemini 2.5 Flash.
    Accepts base64 encoded photo and returns natural mood/food craving text.
    """
    try:
        b64_str = payload.image_base64
        if "," in b64_str:
            b64_str = b64_str.split(",", 1)[1]
        img_bytes = base64.b64decode(b64_str)
        result = await agent.analyze_image_sentiment(
            image_bytes=img_bytes,
            mime_type=payload.mime_type or "image/jpeg",
            lang=payload.lang or "id",
        )
        return result
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Gagal memproses gambar: {str(e)}",
        )


@app.get("/api/v1/banners")
def get_active_banners(city: Optional[str] = Query(None)):
    """
    PRD 9.1 Dynamic Geofenced & Time-Parted Banners Feed
    Returns currently active banners filtered by date, time-parting, and city.
    """
    now = datetime.now()
    current_time_str = now.strftime("%H:%M:%S")

    banners = []
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT id, title, image_url, target_url, targeting_type, target_city, radius_km, priority
                    FROM banners
                    WHERE is_active = TRUE
                      AND start_date <= NOW()
                      AND end_date >= NOW()
                      AND (start_hour IS NULL OR (start_hour <= %s AND end_hour >= %s))
                      AND (targeting_type = 'global' OR (%s IS NOT NULL AND LOWER(target_city) = LOWER(%s)))
                    ORDER BY priority ASC;
                    """,
                    (current_time_str, current_time_str, city, city),
                )
                for row in cur.fetchall():
                    b_id, title, img, target, t_type, t_city, rad, prio = row
                    banners.append({
                        "id": str(b_id),
                        "title": title,
                        "image_url": img,
                        "target_url": target,
                        "targeting_type": t_type,
                        "target_city": t_city,
                        "radius_km": rad,
                        "priority": prio,
                    })
    except Exception:
        pass



    return {
        "status": "success",
        "count": len(banners),
        "banners": banners,
    }


@app.get("/api/v1/menus/default")
def get_default_menus():
    """
    PRD 9.1 Default Recommended Feed
    Returns active curated menus to display on Mobile Home before user invokes AI.
    """
    menus = []
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT id, food_name, category, image_url, price_est, description, display_order
                    FROM default_menus
                    WHERE is_active = TRUE
                    ORDER BY display_order ASC;
                    """
                )
                for row in cur.fetchall():
                    m_id, name, cat, img, price, desc, order = row
                    menus.append({
                        "id": str(m_id),
                        "food_name": name,
                        "category": cat,
                        "image_url": img,
                        "price_est": price,
                        "description": desc,
                        "display_order": order,
                    })
    except Exception:
        pass

    if not menus:
        menus = [
            {
                "id": "m1",
                "food_name": "Sop Buntut Hangat Rempah",
                "category": "Kuah Hangat",
                "image_url": "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400",
                "price_est": "Rp 45.000 - Rp 65.000",
                "description": "Kuah rempah kaya rasa penghilang lelah dan penenang pikiran.",
                "display_order": 1,
            },
            {
                "id": "m2",
                "food_name": "Bakso Urat Kuah Pedas Rawit",
                "category": "Pedas Nampol",
                "image_url": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400",
                "price_est": "Rp 25.000 - Rp 35.000",
                "description": "Sensasi pedas membakar pemicu semangat dan pelepasan endorfin.",
                "display_order": 2,
            },
            {
                "id": "m3",
                "food_name": "Matcha Latte & Toast Manis",
                "category": "Manis Creamy",
                "image_url": "https://images.unsplash.com/photo-1517256064527-09c73fc73e38?w=400",
                "price_est": "Rp 28.000 - Rp 40.000",
                "description": "Kombinasi manis lembut untuk recharge energi di sore hari.",
                "display_order": 3,
            },
        ]

    return {
        "status": "success",
        "count": len(menus),
        "menus": menus,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=settings.app_port, reload=settings.app_debug)

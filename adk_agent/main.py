"""
MoodEats ADK Agent - FastAPI Service & Master API Contracts
Implements PRD Section 6, 7 & 9 full API contracts for Mobile & Web clients.
Complies with UU PDP No. 27/2022 (Data Minimisation, Audit Trails, and Subject Rights).
"""

import uuid
import json
import base64
import hashlib
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
from adk_agent.services.media_sanitizer import sanitize_image_buffer
from adk_agent.services.audit_service import (
    record_security_audit,
    purge_logs_ttl,
    unlink_user_session_history,
    request_user_deletion,
    cancel_user_deletion,
    run_account_lifecycle,
    get_user_status_and_ban_check,
)

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
    )


# ---------------------------------------------------------
# Request / Response Schemas
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


class UserDeletionRequest(BaseModel):
    user_id: str = Field(..., description="UUID user profile requesting deletion")
    reason: Optional[str] = Field(default="User requested account deletion", description="Alasan penghapusan")


class UserCancelDeletionRequest(BaseModel):
    user_id: str = Field(..., description="UUID user profile cancelling deletion")


# ---------------------------------------------------------
# Security Guardrails & Moderation Helpers
# ---------------------------------------------------------

def check_user_active(user_id: Optional[str]):
    """
    Enforces ban status and dormant reactivation from user_profiles.
    Complies with UU PDP Article 35 security controls.
    """
    if not user_id:
        return
    status_info = get_user_status_and_ban_check(user_id)
    if status_info.get("is_banned"):
        reason = status_info.get("ban_reason") or "Akun Anda dinonaktifkan oleh administrator MoodEats."
        record_security_audit(
            event_type="SECURITY_BLOCKED_BANNED_USER",
            severity="critical",
            action="BLOCK_ACCESS",
            actor_id=user_id,
            details={"reason": reason},
            is_suspicious=True,
        )
        raise HTTPException(status_code=403, detail=f"Akun Anda diblokir: {reason}")

    # Auto-reactivate dormant accounts when user performs activity
    if status_info.get("status") == "dormant":
        try:
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "UPDATE user_profiles SET status = 'active', last_active_at = NOW(), updated_at = NOW() WHERE id = %s;",
                        (user_id,),
                    )
                conn.commit()
            record_security_audit(
                event_type="USER_DORMANT_REACTIVATED",
                severity="info",
                action="REACTIVATE_ACCOUNT",
                actor_id=user_id,
                details={"previous_status": "dormant"},
            )
        except Exception as e:
            logger.warning(f"Could not reactivate dormant account: {e}")


# ---------------------------------------------------------
# Endpoints
# ---------------------------------------------------------

@app.get("/")
def root():
    return {
        "service": "MoodEats Culinary Intelligence Engine",
        "status": "online",
        "model": settings.gemini_model,
        "pdp_compliance": "UU PDP No. 27/2022 Enabled",
        "api_docs": "/docs",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "gemini_api": bool(settings.google_gemini_api_key or settings.gemini_api_key),
        "gemini_model": settings.gemini_model,
        "places_api": bool(settings.google_places_api_key),
        "db_host": settings.supabase_db_host,
    }


@app.post("/api/v1/agent/recommend")
async def recommend(payload: RecommendRequest, request: Request):
    """
    PRD 7.1 POST /api/v1/agent/recommend
    Consultation endpoint mapping mood, time, and GPS to physical dishes & sponsored vouchers.
    UU PDP Compliance: Raw personal venting text is NOT stored. Only extracted culinary intent,
    sentiment category, and merchant matching metadata are retained for analytics.
    """
    # Ban status & dormant check
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

    # Persist session to mood_sessions table in Supabase (Data Minimisation)
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Extracted intent schema - strips user raw text to satisfy UU PDP
                extracted_intent_data = {
                    "detected_mood": result.get("detected_mood"),
                    "food_categories": result.get("food_categories", []),
                    "sentiment_score": result.get("sentiment_score", 0),
                    "dietary_type": payload.dietary_type,
                    "is_halal_only": payload.is_halal_only,
                    "city": payload.city,
                }
                cur.execute(
                    """
                    INSERT INTO mood_sessions 
                    (session_id, user_id, role, message_text, detected_mood, food_categories, location_lat, location_lng, city_detected, ai_response_payload, device_os, app_version, extracted_intent, is_unlinked)
                    VALUES (%s, %s, %s, NULL, %s, %s, %s, %s, %s, %s, %s, %s, %s, FALSE);
                    """,
                    (
                        session_id,
                        payload.user_id,
                        "user",
                        result.get("detected_mood"),
                        json.dumps(result.get("food_categories", [])),
                        payload.lat,
                        payload.lng,
                        payload.city,
                        json.dumps(result),
                        payload.device_os,
                        payload.app_version,
                        json.dumps(extracted_intent_data),
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

    detected_mood = result.get("detected_mood") or "Comfort Seeking"
    rationale = result.get("rationale") or result.get("mood_rationale") or "Pilihan kuliner terbaik yang cocok untuk menghangatkan suasana hatimu."
    places = result.get("places", [])
    home_recipes = result.get("home_recipes", [])

    return {
        "status": status_str,
        "is_relevant": is_relevant,
        "session_id": session_id,
        "detected_mood": detected_mood,
        "rationale": rationale,
        "sentiment": {
            "detected_mood": detected_mood,
            "sentiment_score": result.get("sentiment_score", 0),
            "emotional_intensity": result.get("emotional_intensity", "medium"),
            "mood_rationale": rationale,
            "rationale": rationale,
        },
        "food_recommendations": {
            "categories": result.get("food_categories", []),
            "nutrition_tags": result.get("nutrition_tags", []),
        },
        "places": places,
        "home_recipes": home_recipes,
        "disclaimer": result.get("disclaimer"),
        "data": {
            "is_relevant": is_relevant,
            "detected_mood": detected_mood,
            "rationale": rationale,
            "places": places,
            "home_recipes": home_recipes,
        },
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
    Only returns linked, non-erased history for the user.
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
                    # Filter out unlinked sessions
                    where_clauses.append("(is_unlinked = FALSE OR is_unlinked IS NULL)")

                if start_date and start_date != "ALL":
                    if end_date:
                        where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date >= %s::date")
                        params.append(start_date)
                        where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date <= %s::date")
                        params.append(end_date)
                    else:
                        where_clauses.append("(created_at AT TIME ZONE 'Asia/Jakarta')::date = %s::date")
                        params.append(start_date)

                where_sql = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""

                # 1. Count total records matching criteria
                count_query = f"SELECT COUNT(*) FROM mood_sessions {where_sql};"
                cur.execute(count_query, params)
                count_res = cur.fetchone()
                total_count = count_res[0] if count_res else 0

                # 2. Fetch paginated records
                data_query = f"""
                    SELECT id, session_id, message_text, detected_mood, food_categories, 
                           city_detected, ai_response_payload, created_at, extracted_intent
                    FROM mood_sessions
                    {where_sql}
                    ORDER BY created_at DESC
                    LIMIT %s OFFSET %s;
                """
                fetch_params = list(params) + [limit, offset]
                cur.execute(data_query, fetch_params)

                for row in cur.fetchall():
                    row_id, sess_id, msg, mood, foods, city, payload, created_at, intent_data = row
                    
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

                    # User prompt display: use mood summary to avoid displaying sensitive rants
                    display_prompt = f"Suasana hati: {mood}" if mood else "Sesi Rekomendasi Kuliner"

                    sessions.append({
                        "id": str(row_id),
                        "session_id": str(sess_id),
                        "prompt": display_prompt,
                        "detected_mood": mood or "Netral",
                        "food_categories": food_cats,
                        "city": city or "Jakarta",
                        "first_restaurant_name": first_restaurant,
                        "has_voucher": has_voucher,
                        "cached_response": p_data,
                        "created_at": created_at.isoformat() if created_at else None,
                    })

        return {
            "status": "success",
            "count": len(sessions),
            "total_count": total_count,
            "offset": offset,
            "limit": limit,
            "has_more": (offset + len(sessions)) < total_count,
            "sessions": sessions,
        }
    except Exception as e:
        logger.error(f"Error fetching session history: {e}")
        return {
            "status": "error",
            "message": str(e),
            "sessions": [],
            "total_count": 0,
            "offset": offset,
            "limit": limit,
            "has_more": False,
        }


@app.delete("/api/v1/sessions/history")
def delete_session_history(user_id: str = Query(..., description="UUID user profile to unlink history for")):
    """
    Right to Erasure (History): Unlinks all session history for the user.
    Preserves aggregate culinary & merchant trends by setting user_id = NULL and is_unlinked = TRUE,
    while removing all personal associations.
    """
    if not user_id:
        raise HTTPException(status_code=400, detail="user_id is required")
    
    try:
        unlinked_count = unlink_user_session_history(user_id)
        return {
            "status": "success",
            "message": "Riwayat sesi berhasil diputus dari profil pengguna untuk melindungi privasi Anda.",
            "unlinked_sessions_count": unlinked_count,
        }
    except Exception as e:
        logger.error(f"Error unlinking user history: {e}")
        raise HTTPException(status_code=500, detail=f"Gagal memutus riwayat sesi: {str(e)}")


@app.post("/api/v1/users/sync")
def sync_user_profile(payload: UserSyncRequest):
    """
    Syncs mobile user profile into Postgres user_profiles table.
    Enforces anti-fraud ban check via SHA-256 email hashing and retains device telemetry signature.
    """
    try:
        norm_email = payload.email.strip().lower()
        email_hash = hashlib.sha256(norm_email.encode("utf-8")).hexdigest()
        allergies_json = json.dumps(payload.allergies) if payload.allergies is not None else None

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # Anti-ban evasion check: check if user_id or email_hash is banned
                cur.execute(
                    """
                    SELECT id, ban_reason FROM user_profiles 
                    WHERE (id = %s OR email_hash = %s) AND status = 'banned';
                    """,
                    (payload.user_id, email_hash),
                )
                banned_match = cur.fetchone()
                if banned_match:
                    reason = banned_match[1] or "Akun Anda dinonaktifkan secara permanen."
                    record_security_audit(
                        event_type="SECURITY_BLOCKED_BANNED_RE_REGISTRATION",
                        severity="critical",
                        action="BLOCK_SYNC",
                        actor_id=payload.user_id,
                        details={"email_hash": email_hash, "ban_reason": reason},
                        is_suspicious=True,
                    )
                    raise HTTPException(status_code=403, detail=f"Registrasi diblokir: {reason}")

                device_sig = f"{payload.device_model or ''}|{payload.device_os or ''}".strip()

                cur.execute(
                    """
                    INSERT INTO user_profiles (
                        id, display_name, email, phone, gender, birth_date, is_banned,
                        device_model, device_os, app_version, is_halal_only, dietary_type, allergies,
                        status, email_hash, device_telemetry_signature, last_active_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, FALSE, %s, %s, %s, %s, %s, %s, 'active', %s, %s, NOW(), NOW())
                    ON CONFLICT (id) DO UPDATE SET
                        display_name = EXCLUDED.display_name,
                        email = EXCLUDED.email,
                        phone = CASE WHEN EXCLUDED.phone IS NOT NULL AND EXCLUDED.phone <> '' THEN EXCLUDED.phone ELSE user_profiles.phone END,
                        gender = CASE WHEN EXCLUDED.gender IS NOT NULL AND EXCLUDED.gender <> '' THEN EXCLUDED.gender ELSE user_profiles.gender END,
                        birth_date = CASE WHEN EXCLUDED.birth_date IS NOT NULL AND EXCLUDED.birth_date <> '' THEN EXCLUDED.birth_date ELSE user_profiles.birth_date END,
                        device_model = COALESCE(EXCLUDED.device_model, user_profiles.device_model),
                        device_os = COALESCE(EXCLUDED.device_os, user_profiles.device_os),
                        app_version = COALESCE(EXCLUDED.app_version, user_profiles.app_version),
                        is_halal_only = COALESCE(EXCLUDED.is_halal_only, user_profiles.is_halal_only),
                        dietary_type = COALESCE(EXCLUDED.dietary_type, user_profiles.dietary_type),
                        allergies = COALESCE(EXCLUDED.allergies, user_profiles.allergies),
                        email_hash = EXCLUDED.email_hash,
                        device_telemetry_signature = COALESCE(EXCLUDED.device_telemetry_signature, user_profiles.device_telemetry_signature),
                        status = CASE WHEN user_profiles.status = 'banned' THEN 'banned' ELSE 'active' END,
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
                        email_hash,
                        device_sig or None,
                    ),
                )
                conn.commit()
        return {"status": "success", "message": "User profile synchronized successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to sync user profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/users/profile")
def get_user_profile_endpoint(
    user_id: Optional[str] = Query(default=None),
    email: Optional[str] = Query(default=None),
):
    """
    Fetches user profile (birth_date, gender, display_name, preferences) from database.
    Used by mobile and web clients to populate user state on login.
    """
    if not user_id and not email:
        raise HTTPException(status_code=400, detail="user_id atau email diperlukan")

    norm_email = email.strip().lower() if email else None
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                if user_id and norm_email:
                    cur.execute(
                        """
                        SELECT id, display_name, email, phone, gender, birth_date, is_halal_only, dietary_type, allergies
                        FROM user_profiles
                        WHERE (id = %s OR LOWER(email) = %s) AND status != 'banned'
                        ORDER BY updated_at DESC LIMIT 1;
                        """,
                        (user_id, norm_email),
                    )
                elif user_id:
                    cur.execute(
                        """
                        SELECT id, display_name, email, phone, gender, birth_date, is_halal_only, dietary_type, allergies
                        FROM user_profiles
                        WHERE id = %s AND status != 'banned';
                        """,
                        (user_id,),
                    )
                else:
                    cur.execute(
                        """
                        SELECT id, display_name, email, phone, gender, birth_date, is_halal_only, dietary_type, allergies
                        FROM user_profiles
                        WHERE LOWER(email) = %s AND status != 'banned'
                        ORDER BY updated_at DESC LIMIT 1;
                        """,
                        (norm_email,),
                    )
                row = cur.fetchone()
                if not row:
                    return {"status": "not_found", "profile": None}

                return {
                    "status": "success",
                    "profile": {
                        "id": row[0],
                        "display_name": row[1] or "",
                        "email": row[2] or "",
                        "phone": row[3] or "",
                        "gender": row[4] or "",
                        "birth_date": str(row[5]) if row[5] else "",
                        "is_halal_only": bool(row[6]) if row[6] is not None else False,
                        "dietary_type": row[7] or "none",
                        "allergies": row[8] or [],
                    },
                }
    except Exception as e:
        logger.error(f"Error fetching user profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))



@app.post("/api/v1/users/delete-request")
def request_account_deletion_endpoint(payload: UserDeletionRequest):
    """
    Right to Erasure (Account): Initiates 30-day grace period for account deletion.
    Status updated to 'pending_deletion'. Users can cancel within 30 days.
    """
    check_user_active(payload.user_id)
    try:
        request_user_deletion(payload.user_id, payload.reason or "User requested account deletion")
        return {
            "status": "pending_deletion",
            "message": "Permintaan penghapusan akun berhasil dicatat. Sesuai UU PDP, akun Anda memasuki masa tenggang 30 hari sebelum data pribadi di-anonymize secara permanen.",
            "grace_period_days": 30,
        }
    except Exception as e:
        logger.error(f"Error requesting account deletion: {e}")
        raise HTTPException(status_code=500, detail=f"Gagal memproses permintaan hapus akun: {str(e)}")


@app.post("/api/v1/users/cancel-delete")
def cancel_account_deletion_endpoint(payload: UserCancelDeletionRequest):
    """
    Cancels account deletion during 30-day grace period. Restores account to active status.
    """
    try:
        cancel_user_deletion(payload.user_id)
        return {
            "status": "active",
            "message": "Permintaan penghapusan akun berhasil dibatalkan. Akun MoodEats Anda kembali aktif sepenuhnya.",
        }
    except Exception as e:
        logger.error(f"Error cancelling account deletion: {e}")
        raise HTTPException(status_code=500, detail=f"Gagal membatalkan penghapusan akun: {str(e)}")


@app.post("/api/v1/admin/maintenance/pdp-lifecycle")
def run_pdp_maintenance_lifecycle(retention_days: int = Query(90)):
    """
    Automated Maintenance Runner:
    1. Executes purge_expired_audit_logs(retention_days) for security audit log TTL.
    2. Runs process_dormant_and_expired_accounts() to auto-flag dormant accounts and crypto-shred expired deletion requests.
    """
    try:
        purged_logs = purge_logs_ttl(retention_days)
        lifecycle_stats = run_account_lifecycle()
        record_security_audit(
            event_type="MAINTENANCE_LIFECYCLE_RUN",
            severity="info",
            action="RUN_MAINTENANCE",
            actor_role="scheduler",
            details={"purged_logs": purged_logs, "lifecycle_stats": lifecycle_stats},
        )
        return {
            "status": "success",
            "purged_audit_logs": purged_logs,
            "lifecycle_stats": lifecycle_stats,
        }
    except Exception as e:
        logger.error(f"Maintenance lifecycle error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/vouchers/claim")
def claim_voucher(payload: ClaimVoucherRequest):
    """
    PRD 7.2 POST /api/v1/vouchers/claim
    Claims a 15-minute countdown promotional voucher for a sponsored merchant.
    """
    check_user_active(payload.user_id)

    if not payload.user_id:
        return {
            "status": "error",
            "message": "Silakan login terlebih dahulu untuk mengklaim voucher promosi.",
        }

    try:
        res = voucher_manager.claim_voucher(payload.merchant_id, payload.user_id)
        return res
    except Exception as e:
        logger.error(f"Error claiming voucher: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/vouchers/my")
def get_my_vouchers(user_id: str = Query(..., description="ID user")):
    """
    PRD 7.2 GET /api/v1/vouchers/my
    Returns all claimed active vouchers with remaining seconds.
    """
    check_user_active(user_id)
    try:
        vouchers = voucher_manager.get_active_vouchers(user_id)
        return {
            "status": "success",
            "count": len(vouchers),
            "vouchers": vouchers,
        }
    except Exception as e:
        logger.error(f"Error fetching active vouchers: {e}")
        return {
            "status": "error",
            "message": str(e),
            "vouchers": [],
        }


@app.get("/api/v1/roulette")
def get_roulette_dishes():
    """
    PRD 6.3 Bite Roulette Random Dish Generator
    Returns 6 curated dishes with colors and emojis for the lucky wheel.
    """
    return {
        "status": "success",
        "items": [
            {
                "id": "r1",
                "label": "Soto Kudus Daging",
                "label_en": "Kudus Beef Soup",
                "emoji": "🍲",
                "mood_benefit": "Kuah kaldu bening penenang stres & lelah",
                "mood_benefit_en": "Clear broth comfort to ease stress and fatigue",
                "color_hex": "#EF4444",
                "search_keyword": "soto kudus daging sapi",
            },
            {
                "id": "r2",
                "label": "Ayam Geprek Mercon",
                "label_en": "Spicy Smashed Chicken",
                "emoji": "🍗",
                "mood_benefit": "Pedas membakar pemompa adrenalin & fokus",
                "mood_benefit_en": "Spicy punch to boost adrenaline and alertness",
                "color_hex": "#F97316",
                "search_keyword": "ayam geprek cabe rawit",
            },
            {
                "id": "r3",
                "label": "Bubur Ayam Sukabumi",
                "label_en": "Savory Chicken Porridge",
                "emoji": "🥣",
                "mood_benefit": "Tekstur lembut ramah lambung pemulih energi",
                "mood_benefit_en": "Soft texture gentle on stomach for easy recharge",
                "color_hex": "#F59E0B",
                "search_keyword": "bubur ayam sukabumi",
            },
            {
                "id": "r4",
                "label": "Kopi Susu & Toast",
                "label_en": "Iced Coffee & Toast",
                "emoji": "☕",
                "mood_benefit": "Dopamin kafein & karbohidrat pengusir suntuk",
                "mood_benefit_en": "Caffeine and carbs boost to beat the afternoon slump",
                "color_hex": "#10B981",
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
    Strictly in-memory: raw image bytes exist ONLY in RAM, EXIF GPS / device tags
    are stripped before inference, and buffers are immediately dropped.
    Zero disk storage guaranteed (Complies with UU PDP No. 27/2022).
    """
    try:
        b64_str = payload.image_base64
        if "," in b64_str:
            b64_str = b64_str.split(",", 1)[1]
        raw_bytes = base64.b64decode(b64_str)

        # 1. In-memory EXIF metadata stripping (cleans GPS coordinates, camera maker, timestamps)
        clean_bytes, clean_mime = sanitize_image_buffer(
            raw_bytes=raw_bytes,
            mime_type=payload.mime_type or "image/jpeg",
        )
        del raw_bytes  # Immediately discard raw buffer

        # 2. In-memory Gemini multimodal inference
        result = await agent.analyze_image_sentiment(
            image_bytes=clean_bytes,
            mime_type=clean_mime,
            lang=payload.lang or "id",
        )
        del clean_bytes  # Immediately discard cleaned buffer

        return result
    except Exception as e:
        logger.error(f"Image analysis error: {e}")
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
                seen_names = set()
                for row in cur.fetchall():
                    m_id, name, cat, img, price, desc, order = row
                    if name in seen_names:
                        continue
                    seen_names.add(name)
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
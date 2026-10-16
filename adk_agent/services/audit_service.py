"""
MoodEats - Security Audit Logging & Account Lifecycle Service
Complies with UU PDP No. 27/2022 (Audit Trail, Separation of Concerns, RBAC & Lifecycle).
Manages independent forensic audit trails, automated TTL retentions, and user subject rights.
"""

import json
import logging
from typing import Optional, Dict, Any, List
import psycopg2
from adk_agent.config import get_settings

logger = logging.getLogger("moodeats.audit")
settings = get_settings()


def _get_db():
    return psycopg2.connect(
        host=settings.supabase_db_host,
        port=settings.supabase_db_port,
        dbname=settings.supabase_db_name,
        user=settings.supabase_db_user,
        password=settings.supabase_db_password,
    )


def record_security_audit(
    event_type: str,
    severity: str,
    action: str,
    actor_id: Optional[str] = None,
    actor_role: str = "system",
    target_resource: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None,
    is_suspicious: bool = False,
) -> bool:
    """
    Inserts a security audit record into security_audit_logs table.
    Isolated from operational telemetry logs.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO security_audit_logs 
                    (event_type, severity, actor_id, actor_role, target_resource, action, ip_address, user_agent, details, is_suspicious)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
                    """,
                    (
                        event_type,
                        severity,
                        actor_id,
                        actor_role,
                        target_resource,
                        action,
                        ip_address,
                        user_agent,
                        json.dumps(details or {}),
                        is_suspicious,
                    ),
                )
            conn.commit()
        return True
    except Exception as e:
        logger.error(f"[Audit Log Error] Failed to write security audit log: {e}")
        return False


def purge_logs_ttl(retention_days: int = 90) -> int:
    """
    Purges audit logs older than retention_days (Default: 90 days TTL).
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT purge_expired_audit_logs(%s);", (retention_days,))
                purged_count = cur.fetchone()[0]
            conn.commit()
        logger.info(f"[Audit TTL] Purged {purged_count} audit logs older than {retention_days} days.")
        return purged_count
    except Exception as e:
        logger.error(f"[Audit TTL Error] Failed to purge audit logs: {e}")
        return 0


def unlink_user_session_history(user_id: str) -> int:
    """
    Right to Erasure (History): Unlinks user_id on mood_sessions and scrubs raw prompt text,
    preserving aggregate culinary & merchant statistics.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT unlink_user_sessions(%s);", (user_id,))
                unlinked_count = cur.fetchone()[0]
            conn.commit()
        return unlinked_count
    except Exception as e:
        logger.error(f"[History Unlink Error] Failed to unlink sessions for user {user_id}: {e}")
        raise e


def request_user_deletion(user_id: str, reason: str = "User requested account deletion") -> None:
    """
    Right to Erasure (Account): Initiates 30-day grace period.
    Account enters 'pending_deletion' status.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT request_account_deletion(%s, %s);", (user_id, reason))
            conn.commit()
    except Exception as e:
        logger.error(f"[Account Deletion Request Error] Failed for user {user_id}: {e}")
        raise e


def cancel_user_deletion(user_id: str) -> None:
    """
    Cancels account deletion during the 30-day grace period.
    Restores status to 'active'.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT cancel_account_deletion(%s);", (user_id,))
            conn.commit()
    except Exception as e:
        logger.error(f"[Account Deletion Cancel Error] Failed for user {user_id}: {e}")
        raise e


def run_account_lifecycle() -> Dict[str, int]:
    """
    Automated Account Lifecycle Runner:
    - Marks inactive accounts (>30d) as 'dormant'.
    - Auto-purges dormant accounts (>180d).
    - Crypto-shreds accounts whose 30-day grace period has elapsed.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM process_dormant_and_expired_accounts();")
                row = cur.fetchone()
                dormant_count, purged_count = row if row else (0, 0)
            conn.commit()
        return {"dormant_flagged": dormant_count, "crypto_shredded": purged_count}
    except Exception as e:
        logger.error(f"[Lifecycle Error] Failed running account lifecycle: {e}")
        return {"dormant_flagged": 0, "crypto_shredded": 0}


def get_user_status_and_ban_check(user_id: str) -> Dict[str, Any]:
    """
    Checks user status and ban condition.
    Returns user record status.
    """
    try:
        with _get_db() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT status, ban_reason, grace_period_ends_at 
                    FROM user_profiles 
                    WHERE id = %s;
                    """,
                    (user_id,),
                )
                row = cur.fetchone()
                if not row:
                    return {"exists": False, "status": "active", "is_banned": False}
                
                status_val, ban_reason, grace_ends = row
                return {
                    "exists": True,
                    "status": status_val or "active",
                    "is_banned": status_val == "banned",
                    "ban_reason": ban_reason,
                    "grace_period_ends_at": grace_ends,
                }
    except Exception as e:
        logger.warning(f"Failed to check user status for {user_id}: {e}")
        return {"exists": True, "status": "active", "is_banned": False}

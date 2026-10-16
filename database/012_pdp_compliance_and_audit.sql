-- ==============================================================================
-- MoodEats: UU PDP (No. 27/2022) Compliance & Security Audit Refactoring
-- Migration: 012_pdp_compliance_and_audit.sql
-- ==============================================================================

-- 1. Ensure required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. User Profiles Refactoring (Lifecycle & Data Subject Rights)
-- Add status and lifecycle columns to user_profiles
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS status VARCHAR(30) DEFAULT 'active';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMPTZ;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS grace_period_ends_at TIMESTAMPTZ;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS anonymized_at TIMESTAMPTZ;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS phone VARCHAR(50);

-- Anti-Fraud & Ban Enforcement Identifiers (Strictly Non-Anonymizable on Banned Accounts)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS ban_reason TEXT;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS email_hash VARCHAR(64);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS device_telemetry_signature VARCHAR(128);

-- Update email_hash for existing profiles if email is present
UPDATE user_profiles
SET email_hash = encode(digest(lower(email), 'sha256'), 'hex')
WHERE email IS NOT NULL AND email_hash IS NULL;

-- Safe check constraint for user status
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_user_profiles_status'
    ) THEN
        ALTER TABLE user_profiles 
        ADD CONSTRAINT chk_user_profiles_status 
        CHECK (status IN ('active', 'dormant', 'banned', 'pending_deletion', 'anonymized'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email_hash ON user_profiles(email_hash);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active ON user_profiles(last_active_at);

-- 3. Mood Sessions Refactoring (Data Minimisation & History Unlink)
-- Make message_text nullable (data minimisation: raw personal venting not retained)
ALTER TABLE mood_sessions ALTER COLUMN message_text DROP NOT NULL;

-- Add structured intent/tags storage
ALTER TABLE mood_sessions ADD COLUMN IF NOT EXISTS extracted_intent JSONB DEFAULT '{}'::jsonb;
ALTER TABLE mood_sessions ADD COLUMN IF NOT EXISTS is_unlinked BOOLEAN DEFAULT FALSE;

-- 4. Admin Users Role Expansion (Forensic Audit & RBAC)
-- Expand role check constraint to support security_lead, superadmin, and standard analyst roles
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'admin_users_role_check'
    ) THEN
        ALTER TABLE admin_users DROP CONSTRAINT admin_users_role_check;
    END IF;

    ALTER TABLE admin_users 
    ADD CONSTRAINT admin_users_role_check 
    CHECK (role IN ('superadmin', 'security_lead', 'campaign_manager', 'analyst', 'support', 'developer'));
END $$;

-- 5. Security Audit Logs Table (Independent Forensic Log Storage)
CREATE TABLE IF NOT EXISTS security_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) DEFAULT 'info' 
        CHECK (severity IN ('info', 'low', 'medium', 'high', 'critical')),
    actor_id VARCHAR(128),
    actor_role VARCHAR(50) DEFAULT 'system',
    target_resource VARCHAR(150),
    action VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    is_suspicious BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- In case actor_id was UUID, alter to VARCHAR(128)
ALTER TABLE security_audit_logs ALTER COLUMN actor_id TYPE VARCHAR(128) USING actor_id::text;

CREATE INDEX IF NOT EXISTS idx_audit_created_at ON security_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_severity ON security_audit_logs(severity);
CREATE INDEX IF NOT EXISTS idx_audit_event_type ON security_audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON security_audit_logs(actor_id);

-- 6. Automated TTL & Retention Procedure for Security Audit Logs
CREATE OR REPLACE FUNCTION purge_expired_audit_logs(retention_days INT DEFAULT 90)
RETURNS INT AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM security_audit_logs
    WHERE created_at < NOW() - (retention_days || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 7. Stored Procedure: Unlink User Sessions (Right to Erasure for Session History)
-- Drops older UUID signature if present
DROP FUNCTION IF EXISTS unlink_user_sessions(UUID);

CREATE OR REPLACE FUNCTION unlink_user_sessions(p_user_id VARCHAR)
RETURNS INT AS $$
DECLARE
    affected_rows INT;
BEGIN
    UPDATE mood_sessions
    SET user_id = NULL,
        message_text = NULL,
        is_unlinked = TRUE
    WHERE user_id = p_user_id;

    GET DIAGNOSTICS affected_rows = ROW_COUNT;

    INSERT INTO security_audit_logs (
        event_type, severity, actor_id, actor_role, target_resource, action, details
    ) VALUES (
        'USER_HISTORY_UNLINKED',
        'info',
        p_user_id,
        'user',
        'sessions:' || p_user_id,
        'UNLINK_HISTORY',
        jsonb_build_object('unlinked_sessions_count', affected_rows)
    );

    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql;

-- 8. Stored Procedure: Request Account Deletion (30-Day Grace Period)
DROP FUNCTION IF EXISTS request_account_deletion(UUID, TEXT);
DROP FUNCTION IF EXISTS request_account_deletion(UUID);

CREATE OR REPLACE FUNCTION request_account_deletion(p_user_id VARCHAR, p_reason TEXT DEFAULT 'User requested')
RETURNS VOID AS $$
BEGIN
    UPDATE user_profiles
    SET status = 'pending_deletion',
        deletion_requested_at = NOW(),
        grace_period_ends_at = NOW() + INTERVAL '30 days',
        updated_at = NOW()
    WHERE id = p_user_id;

    INSERT INTO security_audit_logs (
        event_type, severity, actor_id, actor_role, target_resource, action, details
    ) VALUES (
        'ACCOUNT_DELETION_REQUESTED',
        'medium',
        p_user_id,
        'user',
        'user:' || p_user_id,
        'REQUEST_DELETION',
        jsonb_build_object('grace_period_days', 30, 'reason', p_reason)
    );
END;
$$ LANGUAGE plpgsql;

-- 9. Stored Procedure: Cancel Account Deletion
DROP FUNCTION IF EXISTS cancel_account_deletion(UUID);

CREATE OR REPLACE FUNCTION cancel_account_deletion(p_user_id VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE user_profiles
    SET status = 'active',
        deletion_requested_at = NULL,
        grace_period_ends_at = NULL,
        updated_at = NOW()
    WHERE id = p_user_id AND status = 'pending_deletion';

    INSERT INTO security_audit_logs (
        event_type, severity, actor_id, actor_role, target_resource, action, details
    ) VALUES (
        'ACCOUNT_DELETION_CANCELLED',
        'info',
        p_user_id,
        'user',
        'user:' || p_user_id,
        'CANCEL_DELETION',
        jsonb_build_object('restored_at', NOW())
    );
END;
$$ LANGUAGE plpgsql;

-- 10. Stored Procedure: Crypto-Shredding / Permanent Anonymization
DROP FUNCTION IF EXISTS crypto_shred_user(UUID);

CREATE OR REPLACE FUNCTION crypto_shred_user(p_user_id VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_status VARCHAR(30);
    v_grace TIMESTAMPTZ;
BEGIN
    SELECT status, grace_period_ends_at INTO v_status, v_grace
    FROM user_profiles
    WHERE id = p_user_id;

    -- Strict Ban Guard: Banned accounts CANNOT be shredded/anonymized to prevent ban evasion
    IF v_status = 'banned' THEN
        RAISE EXCEPTION 'SECURITY VIOLATION: Banned accounts cannot be anonymized or crypto-shredded.';
    END IF;

    -- Check grace period
    IF v_grace IS NOT NULL AND v_grace > NOW() THEN
        RAISE EXCEPTION 'Cannot crypto-shred account: Grace period has not expired yet (expires at %).', v_grace;
    END IF;

    -- Unlink session history first
    PERFORM unlink_user_sessions(p_user_id);

    -- Anonymize user profile (crypto-shred PII)
    UPDATE user_profiles
    SET display_name = 'Anonymous User ' || SUBSTRING(p_user_id FROM 1 FOR 6),
        email = 'anon_' || SUBSTRING(MD5(p_user_id) FROM 1 FOR 10) || '@deleted.moodeats.internal',
        phone = NULL,
        allergies = '[]'::jsonb,
        status = 'anonymized',
        anonymized_at = NOW(),
        updated_at = NOW()
    WHERE id = p_user_id;

    INSERT INTO security_audit_logs (
        event_type, severity, actor_id, actor_role, target_resource, action, details
    ) VALUES (
        'ACCOUNT_CRYPTO_SHREDDED',
        'high',
        p_user_id,
        'system',
        'user:' || p_user_id,
        'CRYPTO_SHRED',
        jsonb_build_object('anonymized_at', NOW())
    );
END;
$$ LANGUAGE plpgsql;

-- 11. Stored Procedure: Account Moderation Ban (Retain Identifiers)
DROP FUNCTION IF EXISTS ban_user_moderation(UUID, TEXT, UUID, VARCHAR);

CREATE OR REPLACE FUNCTION ban_user_moderation(
    p_user_id VARCHAR, 
    p_reason TEXT, 
    p_actor_id VARCHAR DEFAULT NULL, 
    p_device_signature VARCHAR DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_email VARCHAR(150);
    v_hash VARCHAR(64);
BEGIN
    SELECT email INTO v_email FROM user_profiles WHERE id = p_user_id;
    IF v_email IS NOT NULL THEN
        v_hash := encode(digest(lower(v_email), 'sha256'), 'hex');
    END IF;

    UPDATE user_profiles
    SET status = 'banned',
        is_banned = TRUE,
        banned_at = NOW(),
        ban_reason = p_reason,
        banned_reason = p_reason,
        email_hash = COALESCE(email_hash, v_hash),
        device_telemetry_signature = COALESCE(p_device_signature, device_telemetry_signature),
        updated_at = NOW()
    WHERE id = p_user_id;

    INSERT INTO security_audit_logs (
        event_type, severity, actor_id, actor_role, target_resource, action, details
    ) VALUES (
        'USER_BANNED',
        'critical',
        p_actor_id,
        'moderator',
        'user:' || p_user_id,
        'BAN_USER',
        jsonb_build_object('reason', p_reason, 'email_hash', v_hash, 'device_signature', p_device_signature)
    );
END;
$$ LANGUAGE plpgsql;

-- 12. Stored Procedure: Dormant Account Processing (30d Dormant, 180d Auto-purge)
CREATE OR REPLACE FUNCTION process_dormant_and_expired_accounts()
RETURNS TABLE(dormant_count INT, purged_count INT) AS $$
DECLARE
    v_dormant INT := 0;
    v_purged INT := 0;
    r RECORD;
BEGIN
    -- 1. Mark dormant if inactive > 30 days
    UPDATE user_profiles
    SET status = 'dormant',
        updated_at = NOW()
    WHERE status = 'active' 
      AND last_active_at < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS v_dormant = ROW_COUNT;

    -- 2. Auto-shred accounts whose 30-day grace period has passed
    FOR r IN 
        SELECT id FROM user_profiles 
        WHERE status = 'pending_deletion' 
          AND grace_period_ends_at <= NOW()
    LOOP
        PERFORM crypto_shred_user(r.id);
        v_purged := v_purged + 1;
    END LOOP;

    -- 3. Auto-purge dormant accounts inactive > 180 days (not banned)
    FOR r IN 
        SELECT id FROM user_profiles 
        WHERE status = 'dormant' 
          AND last_active_at < NOW() - INTERVAL '180 days'
          AND status != 'banned'
    LOOP
        PERFORM request_account_deletion(r.id, 'Auto-purge: dormant for >180 days');
    END LOOP;

    RETURN QUERY SELECT v_dormant, v_purged;
END;
$$ LANGUAGE plpgsql;

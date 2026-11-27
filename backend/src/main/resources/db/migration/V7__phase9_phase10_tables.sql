-- V7: Phase 9 + Phase 10 tables
-- Adds: emergency_alerts, admin_audit_logs, device_tokens, notification_preferences update
-- All CREATE TABLE / INDEX statements use IF NOT EXISTS for idempotency.

-- ── Emergency Alerts ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS emergency_alerts (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id       UUID        NOT NULL,
    target_department_id  UUID,
    title                 VARCHAR(300) NOT NULL,
    message               TEXT         NOT NULL,
    severity              VARCHAR(20)  NOT NULL DEFAULT 'HIGH'
                              CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    is_active             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_by            UUID,
    expires_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT emergency_alerts_municipality_fk
        FOREIGN KEY (municipality_id)      REFERENCES municipalities (id) ON DELETE CASCADE,
    CONSTRAINT emergency_alerts_dept_fk
        FOREIGN KEY (target_department_id) REFERENCES departments    (id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_emergency_alerts_municipality ON emergency_alerts (municipality_id, created_at DESC);

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'emergency_alerts_set_updated_at'
    ) THEN
        CREATE TRIGGER emergency_alerts_set_updated_at
            BEFORE UPDATE ON emergency_alerts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
    END IF;
END $$;

-- ── Admin Audit Logs (app-level, separate from the partitioned DB audit_logs) ─

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id     UUID,
    performed_by_id     UUID,
    performed_by_name   VARCHAR(200),
    action              VARCHAR(100) NOT NULL,
    entity_type         VARCHAR(100),
    entity_id           VARCHAR(100),
    detail              TEXT,
    ip_address          VARCHAR(45),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_municipality ON admin_audit_logs (municipality_id, created_at DESC)
    WHERE municipality_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admin_audit_action       ON admin_audit_logs (action, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_performed_by ON admin_audit_logs (performed_by_id, created_at DESC)
    WHERE performed_by_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_admin_audit_entity       ON admin_audit_logs (entity_type, entity_id);

-- ── Device Tokens (FCM push) ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS device_tokens (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL,
    token        VARCHAR(500) NOT NULL,
    platform     VARCHAR(20)  NOT NULL DEFAULT 'android'
                     CHECK (platform IN ('android','ios','web')),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT device_tokens_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT device_tokens_token_unique UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens (user_id) WHERE is_active = TRUE;

-- ── Notification Preferences (add push_topic_subscriptions column) ────────────

-- notification_preferences already created in V4 with push_enabled, email_enabled, sms_enabled.
-- Add event_overrides JSONB column if not already present.
ALTER TABLE notification_preferences
    ADD COLUMN IF NOT EXISTS event_overrides JSONB NOT NULL DEFAULT '{}';

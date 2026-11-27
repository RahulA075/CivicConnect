-- V6: Notification Templates, Notifications, Audit Logs, Feature Flags

CREATE TABLE notification_templates (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID,
    event_type      notification_event  NOT NULL,
    channel         notification_channel NOT NULL,
    language_code   CHAR(5)             NOT NULL DEFAULT 'en',
    subject_template VARCHAR(300),
    body_template   TEXT                NOT NULL,
    is_active       BOOLEAN             NOT NULL DEFAULT TRUE,
    created_by      UUID,
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT notif_templates_municipality_fk FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE CASCADE,
    CONSTRAINT notif_templates_unique UNIQUE (municipality_id, event_type, channel, language_code)
);

CREATE TRIGGER notification_templates_set_updated_at
    BEFORE UPDATE ON notification_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE notifications (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID                NOT NULL,
    issue_id        UUID,
    event_type      VARCHAR(50)         NOT NULL,
    channel         notification_channel NOT NULL,
    title           VARCHAR(300)        NOT NULL,
    body            TEXT                NOT NULL,
    action_url      VARCHAR(500),
    is_read         BOOLEAN             NOT NULL DEFAULT FALSE,
    delivered_at    TIMESTAMPTZ,
    read_at         TIMESTAMPTZ,
    failed_at       TIMESTAMPTZ,
    failure_reason  VARCHAR(500),
    retry_count     SMALLINT            NOT NULL DEFAULT 0,
    next_retry_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    CONSTRAINT notifications_user_fk  FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE CASCADE,
    CONSTRAINT notifications_issue_fk FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user_inbox ON notifications (user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_issue_id   ON notifications (issue_id) WHERE issue_id IS NOT NULL;
CREATE INDEX idx_notifications_retry      ON notifications (next_retry_at) WHERE failed_at IS NOT NULL AND retry_count < 3;

CREATE TABLE audit_logs (
    id              UUID            NOT NULL DEFAULT gen_random_uuid(),
    user_id         UUID,
    user_role       user_role,
    ip_address      INET,
    user_agent      TEXT,
    entity_type     audit_entity    NOT NULL,
    entity_id       UUID,
    municipality_id UUID,
    action          audit_action    NOT NULL,
    old_value       JSONB,
    new_value       JSONB,
    description     TEXT,
    metadata        JSONB           NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Current year + next year partitions
CREATE TABLE audit_logs_2024 PARTITION OF audit_logs FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE audit_logs_2025 PARTITION OF audit_logs FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE audit_logs_2026 PARTITION OF audit_logs FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE audit_logs_2027 PARTITION OF audit_logs FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

CREATE INDEX idx_audit_logs_user_id    ON audit_logs (user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_logs_entity     ON audit_logs (entity_type, entity_id, created_at DESC) WHERE entity_id IS NOT NULL;
CREATE INDEX idx_audit_logs_action     ON audit_logs (action, created_at DESC);
CREATE INDEX idx_audit_logs_municipality ON audit_logs (municipality_id, created_at DESC) WHERE municipality_id IS NOT NULL;

CREATE TABLE feature_flags (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID,
    flag_key        VARCHAR(100) NOT NULL,
    flag_value      BOOLEAN      NOT NULL DEFAULT FALSE,
    description     TEXT,
    updated_by      UUID,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT feature_flags_municipality_fk FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE CASCADE,
    CONSTRAINT feature_flags_key_municipality_unique UNIQUE (municipality_id, flag_key)
);

CREATE TRIGGER feature_flags_set_updated_at
    BEFORE UPDATE ON feature_flags FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO feature_flags (municipality_id, flag_key, flag_value, description) VALUES
    (NULL, 'ANONYMOUS_REPORTING',   TRUE,  'Allow citizens to submit reports without logging in'),
    (NULL, 'SMS_NOTIFICATIONS',     FALSE, 'Enable SMS notification channel'),
    (NULL, 'OFFLINE_DRAFTS',        TRUE,  'Allow mobile app to save drafts offline'),
    (NULL, 'CITIZEN_RATING',        TRUE,  'Allow citizens to rate resolved issues'),
    (NULL, 'DUPLICATE_DETECTION',   TRUE,  'Show nearby open issues before report submission'),
    (NULL, 'PUBLIC_STATS_PAGE',     TRUE,  'Show public city statistics on the platform');

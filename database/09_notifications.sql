-- =============================================================================
-- CivicConnect Database
-- Script 09: Notifications
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: notification_templates
-- ---------------------------------------------------------------------------
-- Municipality-configurable message templates per event type and channel.
-- Supports variable interpolation: {{issue_id}}, {{citizen_name}}, etc.
-- A NULL municipality_id = platform-wide default template.
-- ---------------------------------------------------------------------------

CREATE TABLE notification_templates (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID,                           -- NULL = default for all municipalities

    event_type      notification_event  NOT NULL,
    channel         notification_channel NOT NULL,
    language_code   CHAR(5)             NOT NULL DEFAULT 'en',  -- ISO 639-1 + optional region

    -- Template content
    -- Supports Mustache-style variables: {{tracking_id}}, {{citizen_name}}, {{status}}
    subject_template    VARCHAR(300),               -- for EMAIL only
    body_template       TEXT            NOT NULL,

    is_active       BOOLEAN             NOT NULL DEFAULT TRUE,

    -- Audit
    created_by      UUID,
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT notif_templates_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE CASCADE,

    CONSTRAINT notif_templates_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    -- One template per municipality + event + channel + language
    CONSTRAINT notif_templates_unique
        UNIQUE (municipality_id, event_type, channel, language_code)
);

COMMENT ON TABLE notification_templates IS
    'Municipality-configurable notification templates. municipality_id=NULL = platform default.
     Variables interpolated at dispatch time: {{tracking_id}}, {{citizen_name}}, {{status}}.';

CREATE INDEX idx_notif_templates_lookup
    ON notification_templates (event_type, channel, language_code, is_active);

CREATE INDEX idx_notif_templates_municipality
    ON notification_templates (municipality_id)
    WHERE municipality_id IS NOT NULL;

CREATE TRIGGER notification_templates_set_updated_at
    BEFORE UPDATE ON notification_templates
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: notifications
-- ---------------------------------------------------------------------------
-- Notification inbox for every user. One row per notification per user.
-- Stores both in-app (unread dot) and sent external notifications.
-- ---------------------------------------------------------------------------

CREATE TABLE notifications (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID                NOT NULL,

    -- Source
    issue_id        UUID,                           -- NULL for non-issue notifications
    event_type      notification_event  NOT NULL,
    channel         notification_channel NOT NULL,

    -- Content (rendered from template at dispatch time)
    title           VARCHAR(300)        NOT NULL,
    body            TEXT                NOT NULL,
    action_url      VARCHAR(500),                   -- deep link / web URL

    -- State
    is_read         BOOLEAN             NOT NULL DEFAULT FALSE,
    delivered_at    TIMESTAMPTZ,                    -- when successfully sent to FCM/email/SMS
    read_at         TIMESTAMPTZ,
    failed_at       TIMESTAMPTZ,
    failure_reason  VARCHAR(500),

    -- Retry state for failed deliveries
    retry_count     SMALLINT            NOT NULL DEFAULT 0,
    next_retry_at   TIMESTAMPTZ,

    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT notifications_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    CONSTRAINT notifications_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT notifications_read_has_timestamp CHECK (
        is_read = FALSE OR read_at IS NOT NULL
    )
);

COMMENT ON TABLE notifications IS
    'Notification inbox for all users across all channels.
     Unread count is computed from is_read=FALSE rows.
     Delivery failures tracked for retry logic.';

-- User notification inbox query (most common: unread + recent)
CREATE INDEX idx_notifications_user_inbox
    ON notifications (user_id, is_read, created_at DESC);

-- Issue-related notifications (e.g., "all notifications for this issue")
CREATE INDEX idx_notifications_issue_id
    ON notifications (issue_id)
    WHERE issue_id IS NOT NULL;

-- Failed notifications (retry job)
CREATE INDEX idx_notifications_retry
    ON notifications (next_retry_at)
    WHERE failed_at IS NOT NULL AND retry_count < 3;

-- Cleanup: old read notifications (archival job)
CREATE INDEX idx_notifications_created_at
    ON notifications (created_at);

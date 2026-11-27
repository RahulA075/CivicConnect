-- =============================================================================
-- CivicConnect Database
-- Script 11: Platform Configuration Tables
-- =============================================================================
-- Feature flags, webhook configs, and scheduled reports.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: feature_flags
-- ---------------------------------------------------------------------------
-- Boolean feature toggles per municipality (or platform-wide if NULL).
-- Allows progressive feature rollout without code deployments.
-- ---------------------------------------------------------------------------

CREATE TABLE feature_flags (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID,                           -- NULL = platform-wide flag

    flag_key        VARCHAR(100)    NOT NULL,       -- e.g. 'ANONYMOUS_REPORTING', 'SMS_ENABLED'
    flag_value      BOOLEAN         NOT NULL DEFAULT FALSE,
    description     TEXT,

    -- Audit
    updated_by      UUID,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT feature_flags_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE CASCADE,

    CONSTRAINT feature_flags_updated_by_fk
        FOREIGN KEY (updated_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    -- One flag key per municipality (NULL municipality counts as one key)
    CONSTRAINT feature_flags_key_municipality_unique
        UNIQUE (municipality_id, flag_key)
);

COMMENT ON TABLE feature_flags IS
    'Boolean feature toggles. municipality_id=NULL = platform-wide.
     Allows per-city progressive feature rollout.';

CREATE INDEX idx_feature_flags_municipality ON feature_flags (municipality_id, flag_key);

CREATE TRIGGER feature_flags_set_updated_at
    BEFORE UPDATE ON feature_flags
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Seed: default platform-wide flags
INSERT INTO feature_flags (municipality_id, flag_key, flag_value, description) VALUES
    (NULL, 'ANONYMOUS_REPORTING',   TRUE,  'Allow citizens to submit reports without logging in'),
    (NULL, 'SMS_NOTIFICATIONS',     FALSE, 'Enable SMS notification channel'),
    (NULL, 'OFFLINE_DRAFTS',        TRUE,  'Allow mobile app to save drafts offline'),
    (NULL, 'CITIZEN_RATING',        TRUE,  'Allow citizens to rate resolved issues'),
    (NULL, 'DUPLICATE_DETECTION',   TRUE,  'Show nearby open issues before report submission'),
    (NULL, 'PUBLIC_STATS_PAGE',     TRUE,  'Show public city statistics on the platform');

-- ---------------------------------------------------------------------------
-- Table: webhook_configs
-- ---------------------------------------------------------------------------
-- Third-party integration webhooks. Events are dispatched as HTTP POST payloads
-- to the configured URL when the specified events occur.
-- ---------------------------------------------------------------------------

CREATE TABLE webhook_configs (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,

    name            VARCHAR(200)    NOT NULL,
    url             VARCHAR(500)    NOT NULL,

    -- HMAC-SHA256 signing secret (stored as hash; raw secret shown once at creation)
    secret_hash     VARCHAR(255),

    -- Array of notification_event values this webhook subscribes to
    -- e.g. ["ISSUE_SUBMITTED", "ISSUE_RESOLVED"]
    subscribed_events JSONB         NOT NULL DEFAULT '[]',

    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ,
    failure_count   INTEGER         NOT NULL DEFAULT 0,

    -- Audit
    created_by      UUID,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT webhook_configs_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE CASCADE,

    CONSTRAINT webhook_configs_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL
);

COMMENT ON TABLE webhook_configs IS
    'Third-party integration webhooks. Dispatches POST payloads on subscribed events.
     HMAC-SHA256 signature header included for payload verification.';

CREATE INDEX idx_webhook_configs_municipality ON webhook_configs (municipality_id, is_active);

CREATE TRIGGER webhook_configs_set_updated_at
    BEFORE UPDATE ON webhook_configs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: scheduled_reports
-- ---------------------------------------------------------------------------
-- Configuration for automated email report delivery to administrators.
-- ---------------------------------------------------------------------------

CREATE TABLE scheduled_reports (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,
    created_by      UUID            NOT NULL,

    -- Report config
    report_name     VARCHAR(200)    NOT NULL,
    report_type     VARCHAR(50)     NOT NULL,   -- e.g. 'DAILY_SUMMARY', 'DEPT_PERFORMANCE'
    frequency       report_frequency NOT NULL,

    -- Delivery
    -- Array of email addresses
    recipient_emails JSONB          NOT NULL DEFAULT '[]',

    -- Scheduling
    scheduled_hour  SMALLINT        NOT NULL DEFAULT 8 CHECK (scheduled_hour BETWEEN 0 AND 23),
    scheduled_day   SMALLINT        CHECK (                  -- 1=Monday for WEEKLY
        frequency != 'WEEKLY' OR (scheduled_day BETWEEN 1 AND 7)
    ),

    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    last_run_at     TIMESTAMPTZ,
    next_run_at     TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT scheduled_reports_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE CASCADE,

    CONSTRAINT scheduled_reports_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE RESTRICT
);

COMMENT ON TABLE scheduled_reports IS
    'Automated email report schedules configured by municipal admins.
     Application scheduler reads next_run_at to determine dispatch timing.';

CREATE INDEX idx_scheduled_reports_next_run
    ON scheduled_reports (next_run_at)
    WHERE is_active = TRUE;

CREATE INDEX idx_scheduled_reports_municipality
    ON scheduled_reports (municipality_id);

CREATE TRIGGER scheduled_reports_set_updated_at
    BEFORE UPDATE ON scheduled_reports
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

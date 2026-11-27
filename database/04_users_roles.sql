-- =============================================================================
-- CivicConnect Database
-- Script 04: Roles, Users & Auth Tables
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: roles
-- ---------------------------------------------------------------------------
-- Static reference table for system roles.
-- Seeded once; not created by users.
-- ---------------------------------------------------------------------------

CREATE TABLE roles (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name        user_role       NOT NULL UNIQUE,
    description TEXT            NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE roles IS
    'Static role reference table. Seeded at install. Maps to user_role enum.';

-- Seed data
INSERT INTO roles (name, description) VALUES
    ('CITIZEN',          'Self-registered public user. Can report and track civic issues.'),
    ('FIELD_WORKER',     'Municipal ground staff. Receives and resolves assigned tasks.'),
    ('DEPT_SUPERVISOR',  'Department manager. Assigns issues and monitors team performance.'),
    ('MUNICIPAL_ADMIN',  'City-level administrator. Manages all departments and configuration.'),
    ('SYSTEM_ADMIN',     'Platform-level super-admin. Manages municipalities and platform config.');

-- ---------------------------------------------------------------------------
-- Table: users
-- ---------------------------------------------------------------------------
-- Single users table for ALL roles. Role is determined by roles.name.
-- Citizen: municipality_id and department_id are NULL.
-- Authority roles: municipality_id is required; department_id optional.
-- ---------------------------------------------------------------------------

CREATE TABLE users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id         UUID            NOT NULL,
    municipality_id UUID,                       -- NULL for citizens
    department_id   UUID,                       -- NULL for citizens + municipal admins

    -- Identity
    full_name       VARCHAR(200)    NOT NULL,
    email           VARCHAR(255),               -- unique when not null
    phone           VARCHAR(20),                -- unique when not null; E.164 format

    -- Authentication
    password_hash   VARCHAR(255),               -- bcrypt; NULL for OAuth-only accounts
    auth_provider   auth_provider   NOT NULL DEFAULT 'LOCAL',
    provider_id     VARCHAR(255),               -- OAuth subject ID (Google sub)

    -- Profile
    avatar_url      VARCHAR(500),
    city            VARCHAR(100),
    ward_id         UUID,                       -- citizen's home ward (optional)

    -- Verification
    is_email_verified   BOOLEAN     NOT NULL DEFAULT FALSE,
    is_phone_verified   BOOLEAN     NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,

    -- Tracking
    last_login_at       TIMESTAMPTZ,
    login_count         INTEGER     NOT NULL DEFAULT 0,

    -- Soft delete
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,            -- soft delete; NULL = not deleted

    -- Foreign Keys
    CONSTRAINT users_role_fk
        FOREIGN KEY (role_id)
        REFERENCES roles (id)
        ON DELETE RESTRICT,

    CONSTRAINT users_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    CONSTRAINT users_department_fk
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
        ON DELETE SET NULL,

    CONSTRAINT users_ward_fk
        FOREIGN KEY (ward_id)
        REFERENCES wards (id)
        ON DELETE SET NULL,

    -- Constraints
    -- At least one of email or phone must be present
    CONSTRAINT users_email_or_phone CHECK (
        email IS NOT NULL OR phone IS NOT NULL
    ),

    -- OAuth accounts don't need a password
    CONSTRAINT users_local_needs_password CHECK (
        auth_provider != 'LOCAL' OR password_hash IS NOT NULL
    ),

    -- provider_id required for OAuth providers
    CONSTRAINT users_oauth_needs_provider_id CHECK (
        auth_provider = 'LOCAL' OR provider_id IS NOT NULL
    )
);

COMMENT ON TABLE users IS
    'Single unified users table for all roles. Citizens have NULL municipality_id.
     Authority users (FIELD_WORKER through SYSTEM_ADMIN) require municipality_id.';

-- Partial unique indexes (handle NULLs correctly)
CREATE UNIQUE INDEX idx_users_email_unique
    ON users (LOWER(email))
    WHERE email IS NOT NULL AND deleted_at IS NULL;

CREATE UNIQUE INDEX idx_users_phone_unique
    ON users (phone)
    WHERE phone IS NOT NULL AND deleted_at IS NULL;

CREATE UNIQUE INDEX idx_users_provider_id_unique
    ON users (auth_provider, provider_id)
    WHERE provider_id IS NOT NULL;

-- Query indexes
CREATE INDEX idx_users_role_id         ON users (role_id);
CREATE INDEX idx_users_municipality    ON users (municipality_id) WHERE municipality_id IS NOT NULL;
CREATE INDEX idx_users_department      ON users (department_id)   WHERE department_id IS NOT NULL;
CREATE INDEX idx_users_is_active       ON users (is_active)       WHERE deleted_at IS NULL;
CREATE INDEX idx_users_deleted_at      ON users (deleted_at)      WHERE deleted_at IS NOT NULL;

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: otp_verifications
-- ---------------------------------------------------------------------------
-- Stores hashed OTPs for registration, password reset, and MFA.
-- Raw OTP is never stored; only bcrypt hash.
-- ---------------------------------------------------------------------------

CREATE TABLE otp_verifications (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Who is this for (email or phone — we don't require a user_id yet)
    identifier      VARCHAR(255)    NOT NULL,   -- email or phone number
    purpose         otp_purpose     NOT NULL,

    -- Security
    otp_hash        VARCHAR(255)    NOT NULL,   -- bcrypt hash of the OTP code
    attempts        SMALLINT        NOT NULL DEFAULT 0,
    max_attempts    SMALLINT        NOT NULL DEFAULT 5,
    is_used         BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Expiry
    expires_at      TIMESTAMPTZ     NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT otp_max_attempts_valid CHECK (max_attempts BETWEEN 1 AND 10),
    CONSTRAINT otp_attempts_within_max CHECK (attempts <= max_attempts)
);

COMMENT ON TABLE otp_verifications IS
    'Hashed OTP codes for registration, password reset, and MFA. Raw codes are never stored.';

CREATE INDEX idx_otp_identifier_purpose ON otp_verifications (identifier, purpose, is_used);
CREATE INDEX idx_otp_expires_at         ON otp_verifications (expires_at);

-- ---------------------------------------------------------------------------
-- Table: refresh_tokens
-- ---------------------------------------------------------------------------
-- JWT refresh token registry. Enables token revocation and rotation.
-- Only the SHA-256 hash of the token is stored, not the raw token.
-- ---------------------------------------------------------------------------

CREATE TABLE refresh_tokens (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL,

    -- The hashed token value (SHA-256 hex of the raw token)
    token_hash      CHAR(64)        NOT NULL UNIQUE,

    -- Context
    device_info     VARCHAR(500),               -- user-agent / device name
    ip_address      INET,

    -- Lifecycle
    expires_at      TIMESTAMPTZ     NOT NULL,
    is_revoked      BOOLEAN         NOT NULL DEFAULT FALSE,
    revoked_at      TIMESTAMPTZ,
    revocation_reason VARCHAR(100),

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT refresh_tokens_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT refresh_tokens_revoke_has_date CHECK (
        is_revoked = FALSE OR revoked_at IS NOT NULL
    )
);

COMMENT ON TABLE refresh_tokens IS
    'Hashed JWT refresh tokens. Supports per-device revocation and rotation.';

CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens (expires_at) WHERE is_revoked = FALSE;

-- ---------------------------------------------------------------------------
-- Table: notification_preferences
-- ---------------------------------------------------------------------------
-- Per-user opt-in/opt-out settings for each notification channel.
-- Created automatically on user registration.
-- ---------------------------------------------------------------------------

CREATE TABLE notification_preferences (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL UNIQUE,

    push_enabled    BOOLEAN         NOT NULL DEFAULT TRUE,
    email_enabled   BOOLEAN         NOT NULL DEFAULT TRUE,
    sms_enabled     BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Granular per-event preferences stored as JSONB for flexibility
    -- e.g. {"ISSUE_ASSIGNED": {"push": true, "email": false}, ...}
    event_overrides JSONB           NOT NULL DEFAULT '{}',

    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT notification_prefs_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE
);

COMMENT ON TABLE notification_preferences IS
    'User-level notification channel preferences. event_overrides allows per-event granularity.';

CREATE INDEX idx_notif_prefs_user_id ON notification_preferences (user_id);

-- ---------------------------------------------------------------------------
-- Table: device_tokens
-- ---------------------------------------------------------------------------
-- FCM / APNs push notification tokens registered per device.
-- A user can have multiple devices (up to 5 active tokens enforced by app).
-- ---------------------------------------------------------------------------

CREATE TABLE device_tokens (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL,

    token           TEXT            NOT NULL,
    platform        device_platform NOT NULL,
    device_name     VARCHAR(200),               -- e.g. "Priya's iPhone 14"

    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    last_used_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT device_tokens_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- A device token must be globally unique
    CONSTRAINT device_tokens_token_unique UNIQUE (token)
);

COMMENT ON TABLE device_tokens IS
    'FCM/APNs device push tokens. One user may have tokens from multiple devices.';

CREATE INDEX idx_device_tokens_user_id   ON device_tokens (user_id);
CREATE INDEX idx_device_tokens_is_active ON device_tokens (user_id, is_active);

-- ---------------------------------------------------------------------------
-- Back-fill FK from departments → users (head_user_id)
-- Defined after users table exists
-- ---------------------------------------------------------------------------

ALTER TABLE departments
    ADD CONSTRAINT departments_head_user_fk
        FOREIGN KEY (head_user_id)
        REFERENCES users (id)
        ON DELETE SET NULL;

ALTER TABLE departments
    ADD CONSTRAINT departments_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL;

ALTER TABLE issue_categories
    ADD CONSTRAINT issue_categories_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL;

ALTER TABLE sla_policies
    ADD CONSTRAINT sla_policies_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL;

ALTER TABLE escalation_rules
    ADD CONSTRAINT escalation_rules_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users (id)
        ON DELETE SET NULL;

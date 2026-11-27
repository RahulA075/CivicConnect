-- V4: Roles, Users, OTP, Refresh Tokens, Device Tokens, Notification Prefs

CREATE TABLE roles (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        user_role   NOT NULL UNIQUE,
    description TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO roles (name, description) VALUES
    ('CITIZEN',         'Self-registered public user. Can report and track civic issues.'),
    ('FIELD_WORKER',    'Municipal ground staff. Receives and resolves assigned tasks.'),
    ('DEPT_SUPERVISOR', 'Department manager. Assigns issues and monitors team performance.'),
    ('MUNICIPAL_ADMIN', 'City-level administrator. Manages all departments and configuration.'),
    ('SYSTEM_ADMIN',    'Platform-level super-admin. Manages municipalities and platform config.');

CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id             UUID            NOT NULL,
    municipality_id     UUID,
    department_id       UUID,
    full_name           VARCHAR(200)    NOT NULL,
    email               VARCHAR(255),
    phone               VARCHAR(20),
    password_hash       VARCHAR(255),
    auth_provider       auth_provider   NOT NULL DEFAULT 'LOCAL',
    provider_id         VARCHAR(255),
    avatar_url          VARCHAR(500),
    city                VARCHAR(100),
    ward_id             UUID,
    is_email_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_phone_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    last_login_at       TIMESTAMPTZ,
    login_count         INTEGER         NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_by          UUID,
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT users_role_fk         FOREIGN KEY (role_id)         REFERENCES roles         (id) ON DELETE RESTRICT,
    CONSTRAINT users_municipality_fk FOREIGN KEY (municipality_id) REFERENCES municipalities(id) ON DELETE RESTRICT,
    CONSTRAINT users_department_fk   FOREIGN KEY (department_id)   REFERENCES departments   (id) ON DELETE SET NULL,
    CONSTRAINT users_ward_fk         FOREIGN KEY (ward_id)         REFERENCES wards         (id) ON DELETE SET NULL,
    CONSTRAINT users_email_or_phone CHECK (email IS NOT NULL OR phone IS NOT NULL),
    CONSTRAINT users_local_needs_password CHECK (auth_provider != 'LOCAL' OR password_hash IS NOT NULL),
    CONSTRAINT users_oauth_needs_provider_id CHECK (auth_provider = 'LOCAL' OR provider_id IS NOT NULL)
);

CREATE UNIQUE INDEX idx_users_email_unique    ON users (LOWER(email))             WHERE email      IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_phone_unique    ON users (phone)                    WHERE phone      IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_users_provider_unique ON users (auth_provider, provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX idx_users_role_id             ON users (role_id);
CREATE INDEX idx_users_municipality        ON users (municipality_id) WHERE municipality_id IS NOT NULL;
CREATE INDEX idx_users_department          ON users (department_id)   WHERE department_id   IS NOT NULL;

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Back-fill FKs on departments that reference users
ALTER TABLE departments
    ADD CONSTRAINT departments_head_user_fk    FOREIGN KEY (head_user_id) REFERENCES users (id) ON DELETE SET NULL,
    ADD CONSTRAINT departments_created_by_fk   FOREIGN KEY (created_by)   REFERENCES users (id) ON DELETE SET NULL;

ALTER TABLE issue_categories
    ADD CONSTRAINT issue_categories_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL;

ALTER TABLE sla_policies
    ADD CONSTRAINT sla_policies_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL;

ALTER TABLE escalation_rules
    ADD CONSTRAINT escalation_rules_created_by_fk FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE TABLE otp_verifications (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier  VARCHAR(255) NOT NULL,
    purpose     otp_purpose  NOT NULL,
    otp_hash    VARCHAR(255) NOT NULL,
    attempts    SMALLINT     NOT NULL DEFAULT 0,
    max_attempts SMALLINT    NOT NULL DEFAULT 5,
    is_used     BOOLEAN      NOT NULL DEFAULT FALSE,
    expires_at  TIMESTAMPTZ  NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otp_identifier_purpose ON otp_verifications (identifier, purpose, is_used);
CREATE INDEX idx_otp_expires_at         ON otp_verifications (expires_at);

CREATE TABLE refresh_tokens (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL,
    token_hash          CHAR(64)    NOT NULL UNIQUE,
    device_info         VARCHAR(500),
    ip_address          INET,
    expires_at          TIMESTAMPTZ NOT NULL,
    is_revoked          BOOLEAN     NOT NULL DEFAULT FALSE,
    revoked_at          TIMESTAMPTZ,
    revocation_reason   VARCHAR(100),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT refresh_tokens_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens (expires_at) WHERE is_revoked = FALSE;

CREATE TABLE notification_preferences (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL UNIQUE,
    push_enabled    BOOLEAN     NOT NULL DEFAULT TRUE,
    email_enabled   BOOLEAN     NOT NULL DEFAULT TRUE,
    sms_enabled     BOOLEAN     NOT NULL DEFAULT FALSE,
    event_overrides JSONB       NOT NULL DEFAULT '{}',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT notification_prefs_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE device_tokens (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL,
    token       TEXT            NOT NULL UNIQUE,
    platform    device_platform NOT NULL,
    device_name VARCHAR(200),
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT device_tokens_user_fk FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_device_tokens_user_id   ON device_tokens (user_id);
CREATE INDEX idx_device_tokens_is_active ON device_tokens (user_id, is_active);

-- V11: Fix column type mismatches between JPA entities and database schema
-- Hibernate maps Java String fields to VARCHAR; PostgreSQL CHAR causes bpchar mismatch.
-- V4 created device_tokens with device_platform enum; entity expects VARCHAR(20).

-- 1. departments.color_hex: CHAR(7) → VARCHAR(7)
ALTER TABLE departments
    ALTER COLUMN color_hex TYPE VARCHAR(7);

-- 2. issue_categories.color_hex: CHAR(7) → VARCHAR(7)
ALTER TABLE issue_categories
    ALTER COLUMN color_hex TYPE VARCHAR(7);

-- 3. refresh_tokens.token_hash: CHAR(64) → VARCHAR(64)
ALTER TABLE refresh_tokens
    ALTER COLUMN token_hash TYPE VARCHAR(64);

-- 4. notification_templates.language_code: CHAR(5) → VARCHAR(5)
ALTER TABLE notification_templates
    ALTER COLUMN language_code TYPE VARCHAR(5);

-- 5. device_tokens: V4 created this table with device_platform enum and TEXT token.
--    The DeviceToken entity expects VARCHAR(500) token and VARCHAR(20) platform.
--    Drop V4 device_tokens and recreate matching the entity exactly.
DROP TABLE IF EXISTS device_tokens CASCADE;

CREATE TABLE device_tokens (
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

CREATE INDEX idx_device_tokens_user ON device_tokens (user_id) WHERE is_active = TRUE;

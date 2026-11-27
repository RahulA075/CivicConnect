-- =============================================================================
-- CivicConnect Database
-- Script 01: Extensions & Custom Types
-- =============================================================================
-- Run this script first. Requires superuser / rds_superuser privileges.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------

-- PostGIS: geospatial types and functions (ward boundaries, proximity search)
CREATE EXTENSION IF NOT EXISTS postgis;

-- pgcrypto: gen_random_uuid() and digest() for secure hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- pg_trgm: trigram-based fuzzy text search on issue titles/descriptions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- btree_gist: allows GIST indexes on non-geometric types (used for exclusion constraints)
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ---------------------------------------------------------------------------
-- Custom ENUM Types
-- ---------------------------------------------------------------------------

-- User authentication provider
CREATE TYPE auth_provider AS ENUM (
    'LOCAL',        -- email + password
    'GOOGLE',       -- OAuth 2.0 Google
    'PHONE_OTP'     -- mobile OTP registration
);

-- Platform roles (maps 1:1 to roles table but used inline where needed)
CREATE TYPE user_role AS ENUM (
    'CITIZEN',
    'FIELD_WORKER',
    'DEPT_SUPERVISOR',
    'MUNICIPAL_ADMIN',
    'SYSTEM_ADMIN'
);

-- Issue lifecycle states (strict state machine)
CREATE TYPE issue_status AS ENUM (
    'DRAFT',            -- saved locally, not submitted to server
    'SUBMITTED',        -- submitted, awaiting department routing
    'ASSIGNED',         -- routed to department, assigned to field worker
    'IN_PROGRESS',      -- field worker has accepted and started work
    'RESOLVED',         -- field worker marked complete, awaiting citizen verify
    'VERIFIED',         -- citizen confirmed resolution
    'REOPENED',         -- citizen rejected resolution
    'CLOSED',           -- final state: verified or auto-closed after timeout
    'REJECTED'          -- department rejected the report (invalid/spam)
);

-- Issue severity / priority
CREATE TYPE issue_priority AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);

-- Notification delivery channel
CREATE TYPE notification_channel AS ENUM (
    'PUSH',     -- FCM / APNs
    'EMAIL',
    'SMS'
);

-- Notification event types (maps to templates)
CREATE TYPE notification_event AS ENUM (
    'ISSUE_SUBMITTED',
    'ISSUE_ASSIGNED',
    'ISSUE_IN_PROGRESS',
    'ISSUE_RESOLVED',
    'ISSUE_CLOSED',
    'ISSUE_REOPENED',
    'ISSUE_REJECTED',
    'ISSUE_OVERDUE',
    'ISSUE_ESCALATED',
    'ASSIGNMENT_RECEIVED',      -- field worker gets new task
    'SLA_BREACH_WARNING',       -- supervisor alert
    'SLA_BREACHED',             -- supervisor alert
    'RESOLUTION_VERIFY_REQUEST',-- citizen to verify
    'UPVOTE_RECEIVED',
    'COMMENT_ADDED',
    'ACCOUNT_CREATED',
    'PASSWORD_RESET',
    'OTP_SENT'
);

-- OTP purpose
CREATE TYPE otp_purpose AS ENUM (
    'REGISTRATION',
    'PASSWORD_RESET',
    'PHONE_CHANGE',
    'LOGIN_MFA'
);

-- Image context / type within an issue
CREATE TYPE image_type AS ENUM (
    'EVIDENCE',     -- submitted by citizen with the report
    'PROGRESS',     -- uploaded by field worker during work
    'RESOLUTION'    -- uploaded by field worker as proof of completion
);

-- Mobile device platform (for push tokens)
CREATE TYPE device_platform AS ENUM (
    'ANDROID',
    'IOS'
);

-- Audit log entity types
CREATE TYPE audit_entity AS ENUM (
    'USER',
    'ISSUE',
    'DEPARTMENT',
    'CATEGORY',
    'SLA_POLICY',
    'ESCALATION_RULE',
    'MUNICIPALITY',
    'NOTIFICATION_TEMPLATE',
    'WEBHOOK',
    'FEATURE_FLAG',
    'ROLE',
    'SCHEDULED_REPORT'
);

-- Audit log action types
CREATE TYPE audit_action AS ENUM (
    'CREATE',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'LOGIN_FAILED',
    'PASSWORD_RESET',
    'ROLE_CHANGE',
    'DEACTIVATE',
    'REACTIVATE',
    'ASSIGN',
    'ESCALATE',
    'MERGE',
    'EXPORT'
);

-- Scheduled report frequency
CREATE TYPE report_frequency AS ENUM (
    'DAILY',
    'WEEKLY',
    'MONTHLY'
);

-- ---------------------------------------------------------------------------
-- Utility Functions
-- ---------------------------------------------------------------------------

-- Generate a human-readable tracking ID: CC-YYYY-NNNNN
-- e.g. CC-2024-00142
CREATE OR REPLACE FUNCTION generate_tracking_id()
RETURNS TEXT AS $$
DECLARE
    year_part   TEXT;
    seq_part    TEXT;
BEGIN
    year_part := EXTRACT(YEAR FROM NOW())::TEXT;
    -- Pad sequence from a global counter (managed by application layer)
    -- Here we use a pseudo-random 5-digit suffix for the function definition.
    -- In production, replace with a per-municipality sequence.
    seq_part  := LPAD((FLOOR(RANDOM() * 99999 + 1))::TEXT, 5, '0');
    RETURN 'CC-' || year_part || '-' || seq_part;
END;
$$ LANGUAGE plpgsql;

-- Automatically update updated_at on row modification
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Validate issue status transitions (enforced by trigger)
CREATE OR REPLACE FUNCTION validate_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- Allow same-state updates (idempotent)
    IF NEW.status = OLD.status THEN
        RETURN NEW;
    END IF;

    -- Valid transitions map
    IF NOT (
        (OLD.status = 'DRAFT'       AND NEW.status IN ('SUBMITTED'))                         OR
        (OLD.status = 'SUBMITTED'   AND NEW.status IN ('ASSIGNED', 'REJECTED'))              OR
        (OLD.status = 'ASSIGNED'    AND NEW.status IN ('IN_PROGRESS', 'REJECTED', 'SUBMITTED')) OR
        (OLD.status = 'IN_PROGRESS' AND NEW.status IN ('RESOLVED', 'ASSIGNED'))              OR
        (OLD.status = 'RESOLVED'    AND NEW.status IN ('VERIFIED', 'REOPENED', 'CLOSED'))    OR
        (OLD.status = 'VERIFIED'    AND NEW.status IN ('CLOSED'))                            OR
        (OLD.status = 'REOPENED'    AND NEW.status IN ('SUBMITTED', 'ASSIGNED'))             OR
        (OLD.status = 'REJECTED'    AND NEW.status IN ('SUBMITTED'))                         OR
        (OLD.status = 'CLOSED'      AND NEW.status IN ('SUBMITTED'))  -- re-open after close
    ) THEN
        RAISE EXCEPTION 'Invalid status transition from % to %', OLD.status, NEW.status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

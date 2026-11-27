-- =============================================================================
-- CivicConnect Database
-- Script 15: Row-Level Security (RLS) Policies
-- =============================================================================
-- RLS is an optional defense-in-depth layer. The primary authorization
-- enforcement is in the Spring Security application layer (RBAC).
-- RLS provides a database-level guarantee that prevents data leaks
-- even if application-layer checks are bypassed.
--
-- Pattern: Application connects as app role 'civicconnect_app'.
-- The JWT claims are passed via session variables which RLS policies read.
--
-- Usage in Spring Boot:
--   Connection setup: SET LOCAL app.current_user_id = '<uuid>';
--                     SET LOCAL app.current_role = 'CITIZEN';
--                     SET LOCAL app.current_municipality = '<uuid>';
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Application roles (database-level, not to be confused with user roles)
-- ---------------------------------------------------------------------------

-- Main application connection role (used by Spring Boot connection pool)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'civicconnect_app') THEN
        CREATE ROLE civicconnect_app LOGIN;
    END IF;
END
$$;

-- Read-only analytics role (used by reporting / BI tools)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'civicconnect_readonly') THEN
        CREATE ROLE civicconnect_readonly LOGIN;
    END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- Grant privileges
-- ---------------------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO civicconnect_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO civicconnect_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO civicconnect_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO civicconnect_app;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO civicconnect_app;

GRANT USAGE ON SCHEMA public TO civicconnect_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO civicconnect_readonly;

-- Prevent app role from modifying audit_logs and issue_status_history
-- (these are append-only; app inserts are allowed but no updates/deletes)
REVOKE UPDATE, DELETE ON audit_logs             FROM civicconnect_app;
REVOKE UPDATE, DELETE ON issue_status_history   FROM civicconnect_app;
REVOKE UPDATE, DELETE ON votes                  FROM civicconnect_app; -- only INSERT + DELETE

-- ---------------------------------------------------------------------------
-- Enable RLS on tenant-sensitive tables
-- ---------------------------------------------------------------------------

ALTER TABLE issues              ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_images        ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes               ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE issue_assignments   ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Helper function: current app user's role (from session variable)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION app_current_user_role()
RETURNS user_role AS $$
BEGIN
    RETURN current_setting('app.current_role', TRUE)::user_role;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION app_current_municipality()
RETURNS UUID AS $$
BEGIN
    RETURN current_setting('app.current_municipality', TRUE)::UUID;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION app_current_user_id()
RETURNS UUID AS $$
BEGIN
    RETURN current_setting('app.current_user_id', TRUE)::UUID;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ---------------------------------------------------------------------------
-- RLS Policy: issues
-- ---------------------------------------------------------------------------
-- CITIZEN: can only see issues in their municipality (or their own)
-- AUTHORITY roles: scoped to their municipality
-- SYSTEM_ADMIN: sees everything
-- ---------------------------------------------------------------------------

CREATE POLICY issues_municipality_isolation ON issues
    AS PERMISSIVE FOR ALL TO civicconnect_app
    USING (
        -- System admins see all
        app_current_user_role() = 'SYSTEM_ADMIN'
        OR
        -- All others scoped to their municipality
        municipality_id = app_current_municipality()
    );

-- ---------------------------------------------------------------------------
-- RLS Policy: notifications
-- ---------------------------------------------------------------------------
-- Users only see their own notifications.
-- ---------------------------------------------------------------------------

CREATE POLICY notifications_own_only ON notifications
    AS PERMISSIVE FOR ALL TO civicconnect_app
    USING (
        user_id = app_current_user_id()
        OR app_current_user_role() IN ('MUNICIPAL_ADMIN', 'SYSTEM_ADMIN')
    );

-- ---------------------------------------------------------------------------
-- RLS Policy: comments
-- ---------------------------------------------------------------------------
-- Citizens cannot see internal (is_internal = TRUE) comments.
-- ---------------------------------------------------------------------------

CREATE POLICY comments_visibility ON comments
    AS PERMISSIVE FOR SELECT TO civicconnect_app
    USING (
        -- Internal notes only for authority roles
        (is_internal = FALSE)
        OR
        (is_internal = TRUE AND app_current_user_role() IN (
            'FIELD_WORKER', 'DEPT_SUPERVISOR', 'MUNICIPAL_ADMIN', 'SYSTEM_ADMIN'
        ))
    );

CREATE POLICY comments_insert ON comments
    AS PERMISSIVE FOR INSERT TO civicconnect_app
    WITH CHECK (
        -- Citizens can only add public comments
        (app_current_user_role() = 'CITIZEN' AND is_internal = FALSE)
        OR
        -- Authority roles can add internal or public
        app_current_user_role() IN ('FIELD_WORKER', 'DEPT_SUPERVISOR', 'MUNICIPAL_ADMIN', 'SYSTEM_ADMIN')
    );

-- ---------------------------------------------------------------------------
-- RLS Policy: votes
-- ---------------------------------------------------------------------------
-- Users only manage their own votes.
-- ---------------------------------------------------------------------------

CREATE POLICY votes_own_only ON votes
    AS PERMISSIVE FOR ALL TO civicconnect_app
    USING (user_id = app_current_user_id());

-- ---------------------------------------------------------------------------
-- RLS Policy: issue_images
-- ---------------------------------------------------------------------------

CREATE POLICY issue_images_municipality ON issue_images
    AS PERMISSIVE FOR ALL TO civicconnect_app
    USING (
        app_current_user_role() = 'SYSTEM_ADMIN'
        OR EXISTS (
            SELECT 1 FROM issues i
            WHERE  i.id             = issue_images.issue_id
              AND  i.municipality_id = app_current_municipality()
        )
    );

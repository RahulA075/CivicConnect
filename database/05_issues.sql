-- =============================================================================
-- CivicConnect Database
-- Script 05: Issues (Core Domain Table)
-- =============================================================================
-- The central entity of the platform. Every other table either feeds into
-- issues or extends it. Contains PostGIS point geometry for geospatial ops.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: issues
-- ---------------------------------------------------------------------------

CREATE TABLE issues (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Multi-tenancy: every issue is scoped to exactly one municipality
    municipality_id     UUID            NOT NULL,

    -- Classification
    category_id         UUID            NOT NULL,
    ward_id             UUID,                       -- resolved from GPS on submission

    -- Routing & assignment (denormalized for query performance)
    department_id       UUID,                       -- set by routing engine on submission
    assigned_to         UUID,                       -- FK → users (field worker)

    -- Reporter
    reported_by         UUID,                       -- NULL for anonymous reports
    is_anonymous        BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Tracking
    tracking_id         VARCHAR(20)     NOT NULL UNIQUE,  -- e.g. CC-2024-00142

    -- Content
    title               VARCHAR(300)    NOT NULL,
    description         TEXT            NOT NULL,

    -- Geospatial (PostGIS)
    -- SRID 4326 = WGS 84 (latitude/longitude in degrees)
    location            GEOMETRY(POINT, 4326)  NOT NULL,
    address_text        VARCHAR(500),               -- human-readable reverse-geocoded address

    -- Workflow
    status              issue_status    NOT NULL DEFAULT 'SUBMITTED',
    priority            issue_priority  NOT NULL DEFAULT 'MEDIUM',

    -- SLA
    sla_deadline        TIMESTAMPTZ,                -- computed from sla_policies on submission
    is_overdue          BOOLEAN         NOT NULL DEFAULT FALSE,
    sla_policy_id       UUID,                       -- which policy was applied (for audit)

    -- Engagement (denormalized counters — updated by triggers)
    upvote_count        INTEGER         NOT NULL DEFAULT 0 CHECK (upvote_count >= 0),
    comment_count       INTEGER         NOT NULL DEFAULT 0 CHECK (comment_count >= 0),

    -- Resolution
    resolved_at         TIMESTAMPTZ,
    resolution_note     TEXT,

    -- Citizen verification
    verified_at         TIMESTAMPTZ,
    rejection_reason    TEXT,                       -- citizen's reason for rejecting resolution
    citizen_rating      SMALLINT        CHECK (citizen_rating BETWEEN 1 AND 5),
    citizen_comment     TEXT,

    -- Closure
    closed_at           TIMESTAMPTZ,

    -- Duplicate / merge management
    -- When an issue is merged into another, merged_into_id points to the primary issue
    merged_into_id      UUID,                       -- self-referencing FK
    is_merged           BOOLEAN         NOT NULL DEFAULT FALSE,

    -- Soft delete
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,

    -- -------------------------------------------------------------------------
    -- Foreign Keys
    -- -------------------------------------------------------------------------
    CONSTRAINT issues_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    CONSTRAINT issues_category_fk
        FOREIGN KEY (category_id)
        REFERENCES issue_categories (id)
        ON DELETE RESTRICT,

    CONSTRAINT issues_ward_fk
        FOREIGN KEY (ward_id)
        REFERENCES wards (id)
        ON DELETE SET NULL,

    CONSTRAINT issues_department_fk
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
        ON DELETE SET NULL,

    CONSTRAINT issues_reported_by_fk
        FOREIGN KEY (reported_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    CONSTRAINT issues_assigned_to_fk
        FOREIGN KEY (assigned_to)
        REFERENCES users (id)
        ON DELETE SET NULL,

    CONSTRAINT issues_sla_policy_fk
        FOREIGN KEY (sla_policy_id)
        REFERENCES sla_policies (id)
        ON DELETE SET NULL,

    CONSTRAINT issues_merged_into_fk
        FOREIGN KEY (merged_into_id)
        REFERENCES issues (id)
        ON DELETE SET NULL,

    -- -------------------------------------------------------------------------
    -- Check Constraints
    -- -------------------------------------------------------------------------

    -- Anonymous reports must not have a reporter
    CONSTRAINT issues_anonymous_no_reporter CHECK (
        NOT (is_anonymous = TRUE AND reported_by IS NOT NULL)
    ),

    -- Merged issues must have a target
    CONSTRAINT issues_merge_consistency CHECK (
        NOT (is_merged = TRUE AND merged_into_id IS NULL)
    ),

    -- resolved_at must be set when status is RESOLVED or later
    CONSTRAINT issues_resolved_at_check CHECK (
        status NOT IN ('RESOLVED', 'VERIFIED', 'CLOSED') OR resolved_at IS NOT NULL
    ),

    -- citizen_rating only on VERIFIED or CLOSED issues
    CONSTRAINT issues_rating_only_on_verified CHECK (
        citizen_rating IS NULL OR status IN ('VERIFIED', 'CLOSED')
    )
);

COMMENT ON TABLE issues IS
    'Core domain table. Every civic issue report lives here.
     PostGIS POINT geometry enables proximity search and heatmap generation.
     upvote_count and comment_count are denormalized for list query performance.';

-- -------------------------------------------------------------------------
-- Indexes
-- -------------------------------------------------------------------------

-- Primary geospatial index — used for proximity search (nearby issues)
-- and heatmap queries
CREATE INDEX idx_issues_location_gist
    ON issues USING GIST (location);

-- Spatial index for ward boundary lookup during submission
CREATE INDEX idx_issues_location_municipality
    ON issues USING GIST (location)
    WHERE deleted_at IS NULL;

-- Composite index for the most common authority dashboard query:
-- "Show me all open issues in my department, ordered by created_at"
CREATE INDEX idx_issues_dept_status_created
    ON issues (department_id, status, created_at DESC)
    WHERE deleted_at IS NULL;

-- Citizen "My Issues" query: all issues reported by a user
CREATE INDEX idx_issues_reported_by
    ON issues (reported_by, created_at DESC)
    WHERE reported_by IS NOT NULL AND deleted_at IS NULL;

-- Assigned field worker task list
CREATE INDEX idx_issues_assigned_to
    ON issues (assigned_to, status)
    WHERE assigned_to IS NOT NULL AND deleted_at IS NULL;

-- Municipality-scoped status filter (admin overview)
CREATE INDEX idx_issues_municipality_status
    ON issues (municipality_id, status, created_at DESC)
    WHERE deleted_at IS NULL;

-- SLA monitoring: find all overdue issues efficiently
CREATE INDEX idx_issues_overdue
    ON issues (municipality_id, is_overdue, department_id)
    WHERE is_overdue = TRUE AND deleted_at IS NULL;

-- SLA deadline scan (for the scheduled SLA checker job)
CREATE INDEX idx_issues_sla_deadline
    ON issues (sla_deadline)
    WHERE status NOT IN ('CLOSED', 'VERIFIED', 'REJECTED') AND deleted_at IS NULL;

-- Ward-level analytics
CREATE INDEX idx_issues_ward_id
    ON issues (ward_id, status)
    WHERE ward_id IS NOT NULL;

-- Category analytics
CREATE INDEX idx_issues_category_id
    ON issues (category_id, municipality_id, status);

-- Tracking ID lookup (exact match — already unique, but explicit index for speed)
CREATE INDEX idx_issues_tracking_id
    ON issues (tracking_id);

-- Full-text search on title + description
CREATE INDEX idx_issues_fts
    ON issues USING GIN (to_tsvector('english', title || ' ' || description))
    WHERE deleted_at IS NULL;

-- Soft delete filter
CREATE INDEX idx_issues_deleted_at
    ON issues (deleted_at)
    WHERE deleted_at IS NOT NULL;

-- -------------------------------------------------------------------------
-- Trigger: enforce state machine transitions
-- -------------------------------------------------------------------------
CREATE TRIGGER issues_validate_status_transition
    BEFORE UPDATE OF status ON issues
    FOR EACH ROW EXECUTE FUNCTION validate_status_transition();

-- -------------------------------------------------------------------------
-- Trigger: set updated_at
-- -------------------------------------------------------------------------
CREATE TRIGGER issues_set_updated_at
    BEFORE UPDATE ON issues
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -------------------------------------------------------------------------
-- Trigger: set resolved_at automatically when status → RESOLVED
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_issue_resolved_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'RESOLVED' AND OLD.status != 'RESOLVED' THEN
        NEW.resolved_at = NOW();
    END IF;
    IF NEW.status = 'CLOSED' AND OLD.status != 'CLOSED' THEN
        NEW.closed_at = NOW();
    END IF;
    IF NEW.status = 'VERIFIED' AND OLD.status != 'VERIFIED' THEN
        NEW.verified_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER issues_set_timestamps_on_status
    BEFORE UPDATE OF status ON issues
    FOR EACH ROW EXECUTE FUNCTION set_issue_resolved_at();

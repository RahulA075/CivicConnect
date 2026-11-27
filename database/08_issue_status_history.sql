-- =============================================================================
-- CivicConnect Database
-- Script 08: Issue Status History & Assignments
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: issue_status_history
-- ---------------------------------------------------------------------------
-- Immutable append-only ledger of every state change on every issue.
-- Never updated or deleted. This is the canonical audit trail for issues.
-- Populated automatically by a trigger on issues.status change.
-- ---------------------------------------------------------------------------

CREATE TABLE issue_status_history (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID            NOT NULL,

    -- Who made the change
    changed_by      UUID,                           -- NULL for system-initiated changes
    changed_by_role user_role,                      -- snapshot of role at time of change

    -- What changed
    old_status      issue_status,                   -- NULL for the initial SUBMITTED entry
    new_status      issue_status    NOT NULL,
    old_priority    issue_priority,
    new_priority    issue_priority,

    -- Context
    note            TEXT,                           -- reason / message from the actor
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,  -- TRUE = automated system action

    -- Department / assignment snapshot (for analytics)
    department_id   UUID,
    assigned_to     UUID,

    -- Immutable timestamp
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT issue_history_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    CONSTRAINT issue_history_changed_by_fk
        FOREIGN KEY (changed_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    CONSTRAINT issue_history_department_fk
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
        ON DELETE SET NULL
);

COMMENT ON TABLE issue_status_history IS
    'Immutable append-only ledger of all issue status and priority changes.
     Auto-populated by trigger on issues table. Never update or delete rows here.';

-- Timeline view for a single issue (ordered by time)
CREATE INDEX idx_issue_history_issue_id
    ON issue_status_history (issue_id, created_at ASC);

-- Analytics: all status changes in a municipality in a date range
CREATE INDEX idx_issue_history_municipality
    ON issue_status_history (department_id, new_status, created_at);

-- -------------------------------------------------------------------------
-- Trigger: auto-insert into issue_status_history on status change
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_issue_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only record if status or priority actually changed
    IF (NEW.status IS DISTINCT FROM OLD.status) OR
       (NEW.priority IS DISTINCT FROM OLD.priority) THEN
        INSERT INTO issue_status_history (
            issue_id,
            changed_by,
            old_status,
            new_status,
            old_priority,
            new_priority,
            department_id,
            assigned_to,
            is_system
        ) VALUES (
            NEW.id,
            NEW.updated_by,         -- application sets this before update
            OLD.status,
            NEW.status,
            OLD.priority,
            NEW.priority,
            NEW.department_id,
            NEW.assigned_to,
            FALSE
        );
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER issues_record_history
    AFTER UPDATE OF status, priority ON issues
    FOR EACH ROW EXECUTE FUNCTION record_issue_status_change();

-- Note: The application layer sets a session variable or passes changed_by
-- via a dedicated column. The trigger above uses NEW.updated_by.
-- Add updated_by column to issues for trigger use:
ALTER TABLE issues ADD COLUMN IF NOT EXISTS updated_by UUID
    REFERENCES users (id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- Table: issue_assignments
-- ---------------------------------------------------------------------------
-- Full assignment history for an issue. One row per assignment action.
-- The current active assignment is also denormalized to issues.assigned_to
-- for query performance.
-- ---------------------------------------------------------------------------

CREATE TABLE issue_assignments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID            NOT NULL,

    -- Assignment actors
    assigned_by     UUID            NOT NULL,       -- supervisor who made the assignment
    assigned_to     UUID            NOT NULL,       -- field worker assigned

    -- Context
    assignment_note TEXT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,  -- only one active at a time

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    revoked_at      TIMESTAMPTZ,                    -- set when a reassignment happens

    -- Foreign Keys
    CONSTRAINT issue_assignments_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    CONSTRAINT issue_assignments_assigned_by_fk
        FOREIGN KEY (assigned_by)
        REFERENCES users (id)
        ON DELETE RESTRICT,

    CONSTRAINT issue_assignments_assigned_to_fk
        FOREIGN KEY (assigned_to)
        REFERENCES users (id)
        ON DELETE RESTRICT
);

COMMENT ON TABLE issue_assignments IS
    'Full assignment history per issue. Only one row per issue should have is_active=TRUE.
     Application deactivates previous assignment when reassigning.';

-- Current active assignment per issue
CREATE UNIQUE INDEX idx_assignments_issue_active
    ON issue_assignments (issue_id)
    WHERE is_active = TRUE;

-- Field worker task list
CREATE INDEX idx_assignments_worker_active
    ON issue_assignments (assigned_to, is_active, created_at DESC);

-- Supervisor's assignment activity
CREATE INDEX idx_assignments_assigned_by
    ON issue_assignments (assigned_by, created_at DESC);

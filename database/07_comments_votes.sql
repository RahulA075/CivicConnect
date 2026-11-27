-- =============================================================================
-- CivicConnect Database
-- Script 07: Comments & Votes
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: comments
-- ---------------------------------------------------------------------------
-- Two types:
--   PUBLIC  — visible to all; citizen comments on their own issues (rating note)
--   INTERNAL — visible only to authority users; supervisor/field worker notes
-- ---------------------------------------------------------------------------

CREATE TABLE comments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID            NOT NULL,
    user_id         UUID            NOT NULL,

    -- Content
    body            TEXT            NOT NULL CHECK (LENGTH(TRIM(body)) > 0),
    is_internal     BOOLEAN         NOT NULL DEFAULT FALSE,  -- TRUE = authority-only note

    -- Soft delete (comments are never hard-deleted for audit trail)
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    deleted_by      UUID,

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT comments_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    CONSTRAINT comments_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE RESTRICT,

    CONSTRAINT comments_deleted_by_fk
        FOREIGN KEY (deleted_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT comments_delete_consistency CHECK (
        is_deleted = FALSE OR deleted_at IS NOT NULL
    )
);

COMMENT ON TABLE comments IS
    'Issue comments. is_internal=TRUE for supervisor/field worker notes (not shown to citizens).
     Soft-deleted for audit trail integrity.';

-- Issue comment thread (public view — citizens and authorities)
CREATE INDEX idx_comments_issue_public
    ON comments (issue_id, created_at)
    WHERE is_internal = FALSE AND is_deleted = FALSE;

-- Internal notes view (authority only)
CREATE INDEX idx_comments_issue_internal
    ON comments (issue_id, created_at)
    WHERE is_internal = TRUE AND is_deleted = FALSE;

-- User's comments (profile / audit)
CREATE INDEX idx_comments_user_id
    ON comments (user_id, created_at DESC);

CREATE TRIGGER comments_set_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -------------------------------------------------------------------------
-- Trigger: maintain issues.comment_count denormalized counter
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_issue_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.is_internal = FALSE THEN
        UPDATE issues SET comment_count = comment_count + 1
        WHERE id = NEW.issue_id;
    ELSIF TG_OP = 'UPDATE' AND NEW.is_deleted = TRUE AND OLD.is_deleted = FALSE
          AND OLD.is_internal = FALSE THEN
        UPDATE issues SET comment_count = GREATEST(0, comment_count - 1)
        WHERE id = NEW.issue_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER comments_update_issue_count
    AFTER INSERT OR UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_issue_comment_count();

-- ---------------------------------------------------------------------------
-- Table: votes
-- ---------------------------------------------------------------------------
-- Citizen upvotes on issues. One vote per user per issue (enforced by UNIQUE).
-- Anonymous users cannot vote (user_id is NOT NULL).
-- issues.upvote_count is maintained by triggers below.
-- ---------------------------------------------------------------------------

CREATE TABLE votes (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id    UUID            NOT NULL,
    user_id     UUID            NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT votes_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    CONSTRAINT votes_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE,

    -- One vote per user per issue
    CONSTRAINT votes_user_issue_unique UNIQUE (issue_id, user_id)
);

COMMENT ON TABLE votes IS
    'Citizen upvotes on issues. One vote per user per issue.
     issues.upvote_count is maintained via triggers for O(1) count reads.';

CREATE INDEX idx_votes_issue_id ON votes (issue_id);
CREATE INDEX idx_votes_user_id  ON votes (user_id);

-- -------------------------------------------------------------------------
-- Trigger: maintain issues.upvote_count denormalized counter
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_issue_upvote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE issues SET upvote_count = upvote_count + 1
        WHERE id = NEW.issue_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE issues SET upvote_count = GREATEST(0, upvote_count - 1)
        WHERE id = OLD.issue_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER votes_update_upvote_count
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW EXECUTE FUNCTION update_issue_upvote_count();

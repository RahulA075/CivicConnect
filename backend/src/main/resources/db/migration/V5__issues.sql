-- V5: Issues, Issue Images, Comments, Votes, Status History, Assignments

CREATE TABLE issues (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id     UUID            NOT NULL,
    category_id         UUID            NOT NULL,
    ward_id             UUID,
    department_id       UUID,
    reported_by         UUID,
    assigned_to         UUID,
    merged_into_id      UUID,
    tracking_id         VARCHAR(20)     NOT NULL UNIQUE,
    title               VARCHAR(300)    NOT NULL,
    description         TEXT            NOT NULL,
    location            GEOMETRY(POINT, 4326) NOT NULL,
    address_text        VARCHAR(500),
    status              issue_status    NOT NULL DEFAULT 'SUBMITTED',
    priority            issue_priority  NOT NULL DEFAULT 'MEDIUM',
    sla_deadline        TIMESTAMPTZ,
    is_overdue          BOOLEAN         NOT NULL DEFAULT FALSE,
    sla_policy_id       UUID,
    upvote_count        INTEGER         NOT NULL DEFAULT 0 CHECK (upvote_count >= 0),
    comment_count       INTEGER         NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
    is_anonymous        BOOLEAN         NOT NULL DEFAULT FALSE,
    resolved_at         TIMESTAMPTZ,
    resolution_note     TEXT,
    verified_at         TIMESTAMPTZ,
    rejection_reason    TEXT,
    citizen_rating      SMALLINT        CHECK (citizen_rating BETWEEN 1 AND 5),
    citizen_comment     TEXT,
    closed_at           TIMESTAMPTZ,
    is_merged           BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_by          UUID,
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT issues_municipality_fk  FOREIGN KEY (municipality_id) REFERENCES municipalities   (id) ON DELETE RESTRICT,
    CONSTRAINT issues_category_fk      FOREIGN KEY (category_id)     REFERENCES issue_categories (id) ON DELETE RESTRICT,
    CONSTRAINT issues_ward_fk          FOREIGN KEY (ward_id)         REFERENCES wards            (id) ON DELETE SET NULL,
    CONSTRAINT issues_department_fk    FOREIGN KEY (department_id)   REFERENCES departments      (id) ON DELETE SET NULL,
    CONSTRAINT issues_reported_by_fk   FOREIGN KEY (reported_by)     REFERENCES users            (id) ON DELETE SET NULL,
    CONSTRAINT issues_assigned_to_fk   FOREIGN KEY (assigned_to)     REFERENCES users            (id) ON DELETE SET NULL,
    CONSTRAINT issues_merged_into_fk   FOREIGN KEY (merged_into_id)  REFERENCES issues           (id) ON DELETE SET NULL,
    CONSTRAINT issues_anon_no_reporter CHECK (NOT (is_anonymous = TRUE AND reported_by IS NOT NULL)),
    CONSTRAINT issues_merge_consistency CHECK (NOT (is_merged = TRUE AND merged_into_id IS NULL))
);

CREATE INDEX idx_issues_location_gist         ON issues USING GIST (location);
CREATE INDEX idx_issues_dept_status_created   ON issues (department_id, status, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_issues_reported_by           ON issues (reported_by, created_at DESC) WHERE reported_by IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_issues_assigned_to           ON issues (assigned_to, status) WHERE assigned_to IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_issues_municipality_status   ON issues (municipality_id, status, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_issues_overdue               ON issues (municipality_id, is_overdue, department_id) WHERE is_overdue = TRUE AND deleted_at IS NULL;
CREATE INDEX idx_issues_sla_deadline          ON issues (sla_deadline) WHERE status NOT IN ('CLOSED','VERIFIED','REJECTED') AND deleted_at IS NULL;
CREATE INDEX idx_issues_fts                   ON issues USING GIN (to_tsvector('english', title || ' ' || description)) WHERE deleted_at IS NULL;

CREATE TRIGGER issues_set_updated_at
    BEFORE UPDATE ON issues FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE issue_images (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id            UUID        NOT NULL,
    uploaded_by         UUID,
    storage_key         VARCHAR(500) NOT NULL UNIQUE,
    cdn_url             VARCHAR(500) NOT NULL,
    original_filename   VARCHAR(255),
    mime_type           VARCHAR(50)  NOT NULL DEFAULT 'image/jpeg',
    file_size_bytes     INTEGER      CHECK (file_size_bytes <= 10485760),
    image_type          image_type   NOT NULL DEFAULT 'EVIDENCE',
    sort_order          SMALLINT     NOT NULL DEFAULT 0,
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    CONSTRAINT issue_images_issue_fk    FOREIGN KEY (issue_id)    REFERENCES issues (id) ON DELETE CASCADE,
    CONSTRAINT issue_images_uploader_fk FOREIGN KEY (uploaded_by) REFERENCES users  (id) ON DELETE SET NULL
);

CREATE INDEX idx_issue_images_issue_id ON issue_images (issue_id, image_type, sort_order) WHERE is_active = TRUE AND deleted_at IS NULL;

CREATE TABLE comments (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id    UUID        NOT NULL,
    user_id     UUID        NOT NULL,
    body        TEXT        NOT NULL CHECK (LENGTH(TRIM(body)) > 0),
    is_internal BOOLEAN     NOT NULL DEFAULT FALSE,
    is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,
    deleted_at  TIMESTAMPTZ,
    deleted_by  UUID,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT comments_issue_fk FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE,
    CONSTRAINT comments_user_fk  FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE RESTRICT
);

CREATE INDEX idx_comments_issue_public   ON comments (issue_id, created_at) WHERE is_internal = FALSE AND is_deleted = FALSE;
CREATE INDEX idx_comments_issue_internal ON comments (issue_id, created_at) WHERE is_internal = TRUE  AND is_deleted = FALSE;
CREATE TRIGGER comments_set_updated_at
    BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE votes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id    UUID        NOT NULL,
    user_id     UUID        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT votes_issue_fk          FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE,
    CONSTRAINT votes_user_fk           FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE CASCADE,
    CONSTRAINT votes_user_issue_unique UNIQUE (issue_id, user_id)
);

CREATE INDEX idx_votes_issue_id ON votes (issue_id);
CREATE INDEX idx_votes_user_id  ON votes (user_id);

-- Trigger: maintain upvote_count
CREATE OR REPLACE FUNCTION update_issue_upvote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE issues SET upvote_count = upvote_count + 1 WHERE id = NEW.issue_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE issues SET upvote_count = GREATEST(0, upvote_count - 1) WHERE id = OLD.issue_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER votes_update_upvote_count
    AFTER INSERT OR DELETE ON votes
    FOR EACH ROW EXECUTE FUNCTION update_issue_upvote_count();

CREATE TABLE issue_status_history (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID            NOT NULL,
    changed_by      UUID,
    changed_by_role user_role,
    old_status      issue_status,
    new_status      issue_status    NOT NULL,
    old_priority    issue_priority,
    new_priority    issue_priority,
    note            TEXT,
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,
    department_id   UUID,
    assigned_to     UUID,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT issue_history_issue_fk      FOREIGN KEY (issue_id)   REFERENCES issues      (id) ON DELETE CASCADE,
    CONSTRAINT issue_history_changed_by_fk FOREIGN KEY (changed_by) REFERENCES users       (id) ON DELETE SET NULL,
    CONSTRAINT issue_history_dept_fk       FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE SET NULL
);

CREATE INDEX idx_issue_history_issue_id ON issue_status_history (issue_id, created_at ASC);

CREATE TABLE issue_assignments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID        NOT NULL,
    assigned_by     UUID        NOT NULL,
    assigned_to     UUID        NOT NULL,
    assignment_note TEXT,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at      TIMESTAMPTZ,
    CONSTRAINT issue_assignments_issue_fk       FOREIGN KEY (issue_id)    REFERENCES issues (id) ON DELETE CASCADE,
    CONSTRAINT issue_assignments_assigned_by_fk FOREIGN KEY (assigned_by) REFERENCES users  (id) ON DELETE RESTRICT,
    CONSTRAINT issue_assignments_assigned_to_fk FOREIGN KEY (assigned_to) REFERENCES users  (id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX idx_assignments_issue_active ON issue_assignments (issue_id) WHERE is_active = TRUE;
CREATE INDEX idx_assignments_worker_active       ON issue_assignments (assigned_to, is_active, created_at DESC);

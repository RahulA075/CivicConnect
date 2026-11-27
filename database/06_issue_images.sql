-- =============================================================================
-- CivicConnect Database
-- Script 06: Issue Images
-- =============================================================================
-- Stores metadata for all images associated with issues.
-- Actual binary files live in S3 / GCS. Only storage_key and CDN URL stored here.
-- Images are typed: EVIDENCE (submitted by citizen), PROGRESS (field worker
-- during work), RESOLUTION (field worker proof of completion).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: issue_images
-- ---------------------------------------------------------------------------

CREATE TABLE issue_images (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id        UUID            NOT NULL,
    uploaded_by     UUID,                           -- NULL = anonymous report image

    -- Storage
    storage_key     VARCHAR(500)    NOT NULL UNIQUE, -- e.g. "issues/uuid/evidence_1.jpg"
    cdn_url         VARCHAR(500)    NOT NULL,
    original_filename VARCHAR(255),
    mime_type       VARCHAR(50)     NOT NULL DEFAULT 'image/jpeg',
    file_size_bytes INTEGER         CHECK (file_size_bytes > 0),

    -- Classification
    image_type      image_type      NOT NULL DEFAULT 'EVIDENCE',
    sort_order      SMALLINT        NOT NULL DEFAULT 0,

    -- Status
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    -- Foreign Keys
    CONSTRAINT issue_images_issue_fk
        FOREIGN KEY (issue_id)
        REFERENCES issues (id)
        ON DELETE CASCADE,

    CONSTRAINT issue_images_uploader_fk
        FOREIGN KEY (uploaded_by)
        REFERENCES users (id)
        ON DELETE SET NULL,

    -- Max 5 evidence images per issue (enforced at application layer too)
    -- Max file size 10MB = 10,485,760 bytes
    CONSTRAINT issue_images_max_size CHECK (
        file_size_bytes IS NULL OR file_size_bytes <= 10485760
    )
);

COMMENT ON TABLE issue_images IS
    'Image metadata for issue evidence, progress, and resolution photos.
     Binary files are stored in S3/GCS. CDN URL used for delivery.
     EXIF metadata stripped by application before upload.';

-- Fetch all images for an issue (ordered by type then sort_order)
CREATE INDEX idx_issue_images_issue_id
    ON issue_images (issue_id, image_type, sort_order)
    WHERE is_active = TRUE AND deleted_at IS NULL;

-- Cleanup job: find orphaned/deleted images
CREATE INDEX idx_issue_images_deleted
    ON issue_images (deleted_at)
    WHERE deleted_at IS NOT NULL;

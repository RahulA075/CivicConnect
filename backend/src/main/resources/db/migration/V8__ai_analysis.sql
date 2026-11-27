-- V8: Phase 11 — AI Issue Analysis
-- Stores AI-generated analysis results per issue.
-- One row per issue, upserted whenever analysis runs.

CREATE TABLE ai_issue_analysis (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id                UUID        NOT NULL UNIQUE,

    -- Category suggestion
    suggested_category_id   UUID,
    suggested_category_name VARCHAR(200),
    category_confidence     NUMERIC(5,4) CHECK (category_confidence BETWEEN 0 AND 1),

    -- Priority / severity suggestion
    suggested_priority      VARCHAR(20)  CHECK (suggested_priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    severity_confidence     NUMERIC(5,4) CHECK (severity_confidence BETWEEN 0 AND 1),
    severity_reasoning      TEXT,

    -- Duplicate detection
    is_potential_duplicate  BOOLEAN      NOT NULL DEFAULT FALSE,
    duplicate_of_issue_id   UUID,
    duplicate_similarity    NUMERIC(5,4) CHECK (duplicate_similarity BETWEEN 0 AND 1),

    -- Spam detection
    is_spam_flagged         BOOLEAN      NOT NULL DEFAULT FALSE,
    spam_confidence         NUMERIC(5,4) CHECK (spam_confidence BETWEEN 0 AND 1),
    spam_reason             TEXT,

    -- Image classification
    image_labels            JSONB        NOT NULL DEFAULT '[]',   -- [{"label":"pothole","confidence":0.92}, ...]
    image_category_hint     VARCHAR(200),

    -- AI-generated complaint summary
    complaint_summary       TEXT,

    -- Smart suggestions for the citizen
    smart_suggestions       JSONB        NOT NULL DEFAULT '[]',   -- ["Consider adding a photo","Check ward X for similar issue"]

    -- Auto-applied flags
    category_auto_applied   BOOLEAN      NOT NULL DEFAULT FALSE,
    priority_auto_applied   BOOLEAN      NOT NULL DEFAULT FALSE,

    -- Meta
    model_used              VARCHAR(100),
    analysis_duration_ms    INTEGER,
    analyzed_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT ai_analysis_issue_fk
        FOREIGN KEY (issue_id) REFERENCES issues (id) ON DELETE CASCADE,
    CONSTRAINT ai_analysis_duplicate_fk
        FOREIGN KEY (duplicate_of_issue_id) REFERENCES issues (id) ON DELETE SET NULL,
    CONSTRAINT ai_analysis_category_fk
        FOREIGN KEY (suggested_category_id) REFERENCES issue_categories (id) ON DELETE SET NULL
);

CREATE INDEX idx_ai_analysis_issue_id      ON ai_issue_analysis (issue_id);
CREATE INDEX idx_ai_analysis_spam_flagged  ON ai_issue_analysis (is_spam_flagged) WHERE is_spam_flagged = TRUE;
CREATE INDEX idx_ai_analysis_duplicate     ON ai_issue_analysis (is_potential_duplicate) WHERE is_potential_duplicate = TRUE;

CREATE TRIGGER ai_analysis_set_updated_at
    BEFORE UPDATE ON ai_issue_analysis FOR EACH ROW EXECUTE FUNCTION set_updated_at();

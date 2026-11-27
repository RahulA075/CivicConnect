-- =============================================================================
-- CivicConnect Database
-- Script 10: Audit Logs
-- =============================================================================
-- Platform-wide immutable audit trail.
-- Captures every significant user action: auth events, data changes,
-- role changes, config changes, exports, and escalations.
-- NEVER updated or deleted. Partitioned by month for performance.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: audit_logs (partitioned by month)
-- ---------------------------------------------------------------------------

CREATE TABLE audit_logs (
    id              UUID            NOT NULL DEFAULT gen_random_uuid(),

    -- Actor
    user_id         UUID,                           -- NULL = system-initiated action
    user_role       user_role,                      -- snapshot of actor's role at time
    ip_address      INET,
    user_agent      TEXT,

    -- Subject
    entity_type     audit_entity    NOT NULL,
    entity_id       UUID,                           -- ID of the record affected (if applicable)
    municipality_id UUID,                           -- for scoped queries; NULL = platform action

    -- Action
    action          audit_action    NOT NULL,

    -- Payload (JSON diff)
    old_value       JSONB,                          -- state before change (NULL for CREATE)
    new_value       JSONB,                          -- state after change  (NULL for DELETE)

    -- Additional context
    description     TEXT,                           -- human-readable summary
    metadata        JSONB           NOT NULL DEFAULT '{}',  -- extra context (request_id, etc.)

    -- Immutable timestamp — used as partition key
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Partition constraint (managed by range partitioning)
    PRIMARY KEY (id, created_at)

) PARTITION BY RANGE (created_at);

COMMENT ON TABLE audit_logs IS
    'Immutable platform-wide audit trail. Partitioned by month for scalable retention.
     Never update or delete rows. old_value/new_value store JSON diffs for change tracking.';

-- ---------------------------------------------------------------------------
-- Monthly partitions (pre-create for current year + 1 year ahead)
-- In production, automate with pg_partman or a scheduled job.
-- ---------------------------------------------------------------------------

CREATE TABLE audit_logs_2024_01 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE audit_logs_2024_02 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE audit_logs_2024_03 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE audit_logs_2024_04 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE audit_logs_2024_05 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE audit_logs_2024_06 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE audit_logs_2024_07 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE audit_logs_2024_08 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE audit_logs_2024_09 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE audit_logs_2024_10 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE audit_logs_2024_11 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE audit_logs_2024_12 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE TABLE audit_logs_2025_01 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE audit_logs_2025_02 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE audit_logs_2025_03 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE audit_logs_2025_04 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE audit_logs_2025_05 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE audit_logs_2025_06 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE audit_logs_2025_07 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE audit_logs_2025_08 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE audit_logs_2025_09 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE audit_logs_2025_10 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE audit_logs_2025_11 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE audit_logs_2025_12 PARTITION OF audit_logs
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE audit_logs_2026_01 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE audit_logs_2026_02 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE audit_logs_2026_03 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE audit_logs_2026_04 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE audit_logs_2026_05 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE audit_logs_2026_06 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE audit_logs_2026_07 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE audit_logs_2026_08 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE audit_logs_2026_09 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE audit_logs_2026_10 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE audit_logs_2026_11 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE audit_logs_2026_12 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- ---------------------------------------------------------------------------
-- Indexes on audit_logs (applied to all partitions automatically)
-- ---------------------------------------------------------------------------

-- Scoped audit trail for an admin (most common admin query)
CREATE INDEX idx_audit_logs_user_id
    ON audit_logs (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

-- Municipality-scoped audit view
CREATE INDEX idx_audit_logs_municipality
    ON audit_logs (municipality_id, created_at DESC)
    WHERE municipality_id IS NOT NULL;

-- Entity-level history (e.g., all changes to a specific issue)
CREATE INDEX idx_audit_logs_entity
    ON audit_logs (entity_type, entity_id, created_at DESC)
    WHERE entity_id IS NOT NULL;

-- Action-type filter (e.g., all LOGIN_FAILED events)
CREATE INDEX idx_audit_logs_action
    ON audit_logs (action, created_at DESC);

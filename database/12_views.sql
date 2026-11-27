-- =============================================================================
-- CivicConnect Database
-- Script 12: Views
-- =============================================================================
-- Pre-built views for common query patterns. These reduce JOIN complexity
-- in the application layer and enforce consistent column projections.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- View: v_issues_summary
-- ---------------------------------------------------------------------------
-- Used by: citizen issue list, authority queue, admin issues list.
-- Joins in category name, department name, reporter name (masked if anon),
-- and assigned worker name.
-- ---------------------------------------------------------------------------

CREATE VIEW v_issues_summary AS
SELECT
    i.id,
    i.tracking_id,
    i.municipality_id,
    i.title,
    i.status,
    i.priority,
    i.is_overdue,
    i.upvote_count,
    i.comment_count,
    i.address_text,
    ST_Y(i.location::geometry) AS latitude,
    ST_X(i.location::geometry) AS longitude,
    i.sla_deadline,
    i.created_at,
    i.resolved_at,
    i.closed_at,
    i.is_anonymous,
    -- Category info
    c.id            AS category_id,
    c.name          AS category_name,
    c.icon_name     AS category_icon,
    c.color_hex     AS category_color,
    -- Department info
    d.id            AS department_id,
    d.name          AS department_name,
    -- Ward info
    w.id            AS ward_id,
    w.name          AS ward_name,
    -- Reporter (masked if anonymous)
    CASE
        WHEN i.is_anonymous THEN NULL
        ELSE i.reported_by
    END             AS reported_by_id,
    CASE
        WHEN i.is_anonymous THEN 'Anonymous'
        ELSE r.full_name
    END             AS reported_by_name,
    -- Assigned worker
    i.assigned_to   AS assigned_to_id,
    a.full_name     AS assigned_to_name,
    -- Image count (from subquery — not included in list view for perf)
    (
        SELECT COUNT(*) FROM issue_images ii
        WHERE ii.issue_id = i.id AND ii.is_active = TRUE
    )               AS image_count
FROM issues i
JOIN  issue_categories c ON i.category_id     = c.id
LEFT JOIN departments  d ON i.department_id   = d.id
LEFT JOIN wards        w ON i.ward_id         = w.id
LEFT JOIN users        r ON i.reported_by     = r.id
LEFT JOIN users        a ON i.assigned_to     = a.id
WHERE i.deleted_at IS NULL
  AND i.is_merged  = FALSE;

COMMENT ON VIEW v_issues_summary IS
    'Flat summary of issues with joined names. Excludes soft-deleted and merged issues.
     Latitude/longitude extracted from PostGIS POINT geometry.';

-- ---------------------------------------------------------------------------
-- View: v_department_stats
-- ---------------------------------------------------------------------------
-- Used by: admin analytics dashboard, department performance table.
-- Real-time aggregate per department. Cache this in Redis (30s TTL).
-- ---------------------------------------------------------------------------

CREATE VIEW v_department_stats AS
SELECT
    d.municipality_id,
    d.id            AS department_id,
    d.name          AS department_name,
    -- Counts by status
    COUNT(*)        FILTER (WHERE i.status NOT IN ('CLOSED', 'REJECTED', 'VERIFIED'))
                    AS open_count,
    COUNT(*)        FILTER (WHERE i.is_overdue = TRUE)
                    AS overdue_count,
    COUNT(*)        FILTER (WHERE i.status IN ('RESOLVED', 'VERIFIED', 'CLOSED'))
                    AS resolved_count,
    COUNT(*)        FILTER (WHERE i.status = 'REJECTED')
                    AS rejected_count,
    COUNT(*)        AS total_count,
    -- SLA compliance rate (resolved within deadline / total resolved)
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE i.status IN ('RESOLVED', 'VERIFIED', 'CLOSED')
            AND   i.resolved_at <= i.sla_deadline
        ) / NULLIF(
            COUNT(*) FILTER (WHERE i.status IN ('RESOLVED', 'VERIFIED', 'CLOSED')),
            0
        ), 1
    )               AS sla_compliance_pct,
    -- Average resolution time in hours
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (i.resolved_at - i.created_at)) / 3600.0
        ) FILTER (WHERE i.resolved_at IS NOT NULL),
        1
    )               AS avg_resolution_hours,
    -- Citizen satisfaction
    ROUND(AVG(i.citizen_rating) FILTER (WHERE i.citizen_rating IS NOT NULL), 2)
                    AS avg_citizen_rating,
    COUNT(*)        FILTER (WHERE i.citizen_rating IS NOT NULL)
                    AS rated_count
FROM departments d
LEFT JOIN issues i ON i.department_id = d.id
    AND i.deleted_at IS NULL
    AND i.is_merged = FALSE
WHERE d.is_active = TRUE
GROUP BY d.municipality_id, d.id, d.name;

COMMENT ON VIEW v_department_stats IS
    'Real-time department performance metrics. Used for analytics dashboard.
     Cache result in Redis with ~30 second TTL to avoid repeated aggregation.';

-- ---------------------------------------------------------------------------
-- View: v_ward_issue_counts
-- ---------------------------------------------------------------------------
-- Used by: heatmap data endpoint, ward-level analytics.
-- Returns centroid lat/lng per ward with open issue count for heatmap weight.
-- ---------------------------------------------------------------------------

CREATE VIEW v_ward_issue_counts AS
SELECT
    w.id            AS ward_id,
    w.municipality_id,
    w.name          AS ward_name,
    w.code          AS ward_code,
    ST_Y(ST_Centroid(w.boundary))   AS centroid_lat,
    ST_X(ST_Centroid(w.boundary))   AS centroid_lng,
    COUNT(i.id)     FILTER (WHERE i.status NOT IN ('CLOSED', 'REJECTED', 'VERIFIED'))
                    AS open_issue_count,
    COUNT(i.id)     AS total_issue_count
FROM wards w
LEFT JOIN issues i ON i.ward_id = w.id
    AND i.deleted_at IS NULL
    AND i.is_merged = FALSE
WHERE w.is_active = TRUE
GROUP BY w.id, w.municipality_id, w.name, w.code, w.boundary;

COMMENT ON VIEW v_ward_issue_counts IS
    'Ward-level issue counts with centroid coordinates. Drives heatmap overlay.';

-- ---------------------------------------------------------------------------
-- View: v_field_worker_workload
-- ---------------------------------------------------------------------------
-- Used by: supervisor team workload screen.
-- ---------------------------------------------------------------------------

CREATE VIEW v_field_worker_workload AS
SELECT
    u.id            AS worker_id,
    u.full_name     AS worker_name,
    u.department_id,
    u.is_active,
    -- Active (non-closed) assignments
    COUNT(i.id)     FILTER (WHERE i.status NOT IN ('CLOSED', 'VERIFIED', 'REJECTED'))
                    AS active_tasks,
    -- Overdue tasks
    COUNT(i.id)     FILTER (WHERE i.is_overdue = TRUE)
                    AS overdue_tasks,
    -- Completed today
    COUNT(i.id)     FILTER (
                        WHERE i.status IN ('RESOLVED', 'VERIFIED', 'CLOSED')
                        AND   i.resolved_at >= CURRENT_DATE
                    )
                    AS completed_today,
    -- Most urgent SLA deadline across active tasks
    MIN(i.sla_deadline) FILTER (
        WHERE i.status NOT IN ('CLOSED', 'VERIFIED', 'REJECTED')
        AND   i.sla_deadline IS NOT NULL
    )               AS next_sla_deadline
FROM users u
LEFT JOIN issues i ON i.assigned_to = u.id
    AND i.deleted_at IS NULL
WHERE u.is_active   = TRUE
  AND u.deleted_at  IS NULL
  AND EXISTS (
      SELECT 1 FROM roles r WHERE r.id = u.role_id AND r.name = 'FIELD_WORKER'
  )
GROUP BY u.id, u.full_name, u.department_id, u.is_active;

COMMENT ON VIEW v_field_worker_workload IS
    'Per-field-worker task counts and SLA urgency. Used by supervisor team screen.';

-- ---------------------------------------------------------------------------
-- View: v_citizen_issue_feed
-- ---------------------------------------------------------------------------
-- Used by: citizen public issue feed + My Issues list.
-- Excludes internal notes, masks anonymous reporter details.
-- ---------------------------------------------------------------------------

CREATE VIEW v_citizen_issue_feed AS
SELECT
    i.id,
    i.tracking_id,
    i.title,
    i.status,
    i.priority,
    i.upvote_count,
    i.comment_count,
    i.address_text,
    ST_Y(i.location::geometry) AS latitude,
    ST_X(i.location::geometry) AS longitude,
    i.created_at,
    i.sla_deadline,
    i.is_overdue,
    c.name          AS category_name,
    c.icon_name     AS category_icon,
    c.color_hex     AS category_color,
    d.name          AS department_name,
    w.name          AS ward_name,
    -- Reporter masked
    CASE WHEN i.is_anonymous THEN 'Anonymous' ELSE r.full_name END AS reporter_name,
    -- Lead image for card preview (first EVIDENCE image)
    (
        SELECT cdn_url FROM issue_images img
        WHERE  img.issue_id  = i.id
          AND  img.image_type = 'EVIDENCE'
          AND  img.is_active  = TRUE
          AND  img.deleted_at IS NULL
        ORDER BY img.sort_order ASC
        LIMIT 1
    )               AS preview_image_url
FROM issues i
JOIN  issue_categories c ON i.category_id   = c.id
LEFT JOIN departments  d ON i.department_id = d.id
LEFT JOIN wards        w ON i.ward_id       = w.id
LEFT JOIN users        r ON i.reported_by   = r.id AND i.is_anonymous = FALSE
WHERE i.deleted_at  IS NULL
  AND i.is_merged   = FALSE
  AND i.status     != 'DRAFT';

COMMENT ON VIEW v_citizen_issue_feed IS
    'Public issue feed for citizen app. Masks anonymous reporter details.
     Includes preview_image_url subquery for card display.';

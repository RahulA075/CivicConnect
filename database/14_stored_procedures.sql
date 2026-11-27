-- =============================================================================
-- CivicConnect Database
-- Script 14: Stored Procedures & Utility Queries
-- =============================================================================
-- Key reusable procedures for application operations and scheduled jobs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Function: get_nearest_ward(lat, lng, municipality_id)
-- ---------------------------------------------------------------------------
-- Returns the ward_id whose boundary polygon contains the given GPS point.
-- Falls back to the nearest ward centroid if no polygon contains the point.
-- Used by issue submission to auto-assign ward.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_nearest_ward(
    p_lat           DOUBLE PRECISION,
    p_lng           DOUBLE PRECISION,
    p_municipality  UUID
)
RETURNS UUID AS $$
DECLARE
    v_point     GEOMETRY;
    v_ward_id   UUID;
BEGIN
    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);

    -- Exact containment first (point inside polygon)
    SELECT id INTO v_ward_id
    FROM   wards
    WHERE  municipality_id = p_municipality
      AND  is_active        = TRUE
      AND  ST_Contains(boundary, v_point)
    LIMIT 1;

    -- Fallback: nearest ward centroid within 5km
    IF v_ward_id IS NULL THEN
        SELECT id INTO v_ward_id
        FROM   wards
        WHERE  municipality_id = p_municipality
          AND  is_active        = TRUE
          AND  boundary IS NOT NULL
          AND  ST_DWithin(
                   ST_Centroid(boundary)::geography,
                   v_point::geography,
                   5000   -- 5 km radius
               )
        ORDER BY ST_Distance(ST_Centroid(boundary)::geography, v_point::geography)
        LIMIT 1;
    END IF;

    RETURN v_ward_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------------------------------------
-- Function: get_nearby_issues(lat, lng, radius_m, municipality_id)
-- ---------------------------------------------------------------------------
-- Returns open issues within radius_m metres of a GPS point.
-- Used for duplicate detection on the report submission screen.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_nearby_issues(
    p_lat           DOUBLE PRECISION,
    p_lng           DOUBLE PRECISION,
    p_radius_m      INTEGER         DEFAULT 200,
    p_municipality  UUID            DEFAULT NULL
)
RETURNS TABLE (
    issue_id        UUID,
    tracking_id     VARCHAR(20),
    title           VARCHAR(300),
    status          issue_status,
    category_name   VARCHAR(200),
    distance_m      DOUBLE PRECISION,
    upvote_count    INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        i.id,
        i.tracking_id,
        i.title,
        i.status,
        c.name,
        ROUND(ST_Distance(
            i.location::geography,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        )::NUMERIC, 1)  AS distance_m,
        i.upvote_count
    FROM   issues i
    JOIN   issue_categories c ON c.id = i.category_id
    WHERE  i.deleted_at     IS NULL
      AND  i.is_merged       = FALSE
      AND  i.status         NOT IN ('CLOSED', 'VERIFIED', 'REJECTED')
      AND  (p_municipality   IS NULL OR i.municipality_id = p_municipality)
      AND  ST_DWithin(
               i.location::geography,
               ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
               p_radius_m
           )
    ORDER BY distance_m ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------------------------------------
-- Function: calculate_sla_deadline(category_id, priority, submitted_at)
-- ---------------------------------------------------------------------------
-- Looks up the applicable SLA policy (category-specific first, then
-- municipality default) and returns the sla_deadline timestamp.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION calculate_sla_deadline(
    p_category_id   UUID,
    p_priority      issue_priority,
    p_municipality  UUID,
    p_submitted_at  TIMESTAMPTZ     DEFAULT NOW()
)
RETURNS TIMESTAMPTZ AS $$
DECLARE
    v_hours INTEGER;
BEGIN
    -- Category-specific SLA first
    SELECT resolution_hours INTO v_hours
    FROM   sla_policies
    WHERE  municipality_id = p_municipality
      AND  category_id     = p_category_id
      AND  priority        = p_priority
      AND  is_active       = TRUE
    LIMIT 1;

    -- Fall back to municipality default (category_id IS NULL)
    IF v_hours IS NULL THEN
        SELECT resolution_hours INTO v_hours
        FROM   sla_policies
        WHERE  municipality_id = p_municipality
          AND  category_id     IS NULL
          AND  priority        = p_priority
          AND  is_active       = TRUE
        LIMIT 1;
    END IF;

    -- If no SLA configured, default to 72 hours
    IF v_hours IS NULL THEN
        v_hours := 72;
    END IF;

    RETURN p_submitted_at + (v_hours || ' hours')::INTERVAL;
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------------------------------------
-- Procedure: mark_overdue_issues()
-- ---------------------------------------------------------------------------
-- Run by a scheduled job every 15 minutes.
-- Sets is_overdue = TRUE for all issues past their sla_deadline.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE mark_overdue_issues()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE issues
    SET    is_overdue  = TRUE,
           updated_at  = NOW()
    WHERE  is_overdue   = FALSE
      AND  sla_deadline IS NOT NULL
      AND  sla_deadline < NOW()
      AND  status       NOT IN ('CLOSED', 'VERIFIED', 'REJECTED')
      AND  deleted_at   IS NULL;
END;
$$;

COMMENT ON PROCEDURE mark_overdue_issues IS
    'Called every 15 minutes by the SLA monitoring job. Flags issues past SLA deadline.';

-- ---------------------------------------------------------------------------
-- Function: get_heatmap_data(municipality_id, status_filter, date_from, date_to)
-- ---------------------------------------------------------------------------
-- Returns issue location points for Google Maps heatmap layer.
-- Aggregates to cluster_radius resolution to reduce payload size.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_heatmap_data(
    p_municipality  UUID,
    p_status        issue_status[]  DEFAULT NULL,   -- NULL = all statuses
    p_date_from     DATE            DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_date_to       DATE            DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    weight      INTEGER             -- count of issues at this coordinate cluster
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(ST_Y(location::geometry)::NUMERIC, 4)::DOUBLE PRECISION AS latitude,
        ROUND(ST_X(location::geometry)::NUMERIC, 4)::DOUBLE PRECISION AS longitude,
        COUNT(*)::INTEGER AS weight
    FROM issues
    WHERE municipality_id = p_municipality
      AND deleted_at      IS NULL
      AND is_merged       = FALSE
      AND created_at::DATE BETWEEN p_date_from AND p_date_to
      AND (p_status IS NULL OR status = ANY(p_status))
    GROUP BY
        ROUND(ST_Y(location::geometry)::NUMERIC, 4),
        ROUND(ST_X(location::geometry)::NUMERIC, 4)
    ORDER BY weight DESC;
END;
$$ LANGUAGE plpgsql STABLE;

-- ---------------------------------------------------------------------------
-- Function: get_issue_trend(municipality_id, days, group_by)
-- ---------------------------------------------------------------------------
-- Returns daily issue submission and resolution counts for trend charts.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_issue_trend(
    p_municipality  UUID,
    p_days          INTEGER         DEFAULT 30,
    p_department_id UUID            DEFAULT NULL
)
RETURNS TABLE (
    day             DATE,
    submitted       BIGINT,
    resolved        BIGINT,
    overdue_count   BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        gs.day::DATE,
        COUNT(i.id)     FILTER (WHERE i.created_at::DATE = gs.day::DATE),
        COUNT(i.id)     FILTER (WHERE i.resolved_at::DATE = gs.day::DATE),
        COUNT(i.id)     FILTER (WHERE i.is_overdue = TRUE AND i.created_at::DATE = gs.day::DATE)
    FROM   generate_series(
               CURRENT_DATE - (p_days - 1),
               CURRENT_DATE,
               '1 day'::INTERVAL
           ) AS gs(day)
    LEFT JOIN issues i
           ON i.municipality_id = p_municipality
          AND i.deleted_at       IS NULL
          AND i.is_merged        = FALSE
          AND (p_department_id   IS NULL OR i.department_id = p_department_id)
          AND i.created_at::DATE = gs.day::DATE
    GROUP BY gs.day
    ORDER BY gs.day ASC;
END;
$$ LANGUAGE plpgsql STABLE;

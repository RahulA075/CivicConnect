-- =============================================================================
-- CivicConnect Database
-- Script 02: Municipalities & Wards
-- =============================================================================
-- Platform-level geography. municipalities is the top-level tenant.
-- All data rows carry a municipality_id for logical tenant isolation.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: municipalities
-- ---------------------------------------------------------------------------
-- One row per city / municipal corporation onboarded onto the platform.
-- SYSTEM_ADMIN creates and manages municipalities.
-- ---------------------------------------------------------------------------

CREATE TABLE municipalities (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(20)     NOT NULL,           -- short code: e.g. "MUM", "DEL"
    state           VARCHAR(100)    NOT NULL,
    country         VARCHAR(100)    NOT NULL DEFAULT 'India',
    timezone        VARCHAR(60)     NOT NULL DEFAULT 'Asia/Kolkata',

    -- Contact
    contact_email   VARCHAR(255),
    contact_phone   VARCHAR(20),
    website_url     VARCHAR(500),

    -- Geospatial: outer boundary of the municipality
    -- SRID 4326 = WGS 84 (GPS standard)
    boundary        GEOMETRY(MULTIPOLYGON, 4326),

    -- Platform settings
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    logo_url        VARCHAR(500),

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT municipalities_code_unique UNIQUE (code),
    CONSTRAINT municipalities_name_state_unique UNIQUE (name, state)
);

COMMENT ON TABLE municipalities IS
    'Top-level tenant. Every data row in the system is scoped to one municipality.';

CREATE TRIGGER municipalities_set_updated_at
    BEFORE UPDATE ON municipalities
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: wards
-- ---------------------------------------------------------------------------
-- Administrative sub-divisions of a municipality.
-- Issues are tagged to a ward for routing and analytics.
-- ---------------------------------------------------------------------------

CREATE TABLE wards (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,

    -- Identity
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(20)     NOT NULL,           -- e.g. "W-001"
    description     TEXT,

    -- Geospatial: ward boundary polygon
    boundary        GEOMETRY(POLYGON, 4326),

    -- Status
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT wards_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    -- Constraints
    CONSTRAINT wards_code_municipality_unique UNIQUE (municipality_id, code)
);

COMMENT ON TABLE wards IS
    'Administrative sub-divisions of a municipality used for issue routing and analytics.';

CREATE INDEX idx_wards_municipality_id ON wards (municipality_id);
CREATE INDEX idx_wards_boundary ON wards USING GIST (boundary);

CREATE TRIGGER wards_set_updated_at
    BEFORE UPDATE ON wards
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- V2: Municipalities and Wards

CREATE TABLE municipalities (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(20)     NOT NULL,
    state           VARCHAR(100)    NOT NULL,
    country         VARCHAR(100)    NOT NULL DEFAULT 'India',
    timezone        VARCHAR(60)     NOT NULL DEFAULT 'Asia/Kolkata',
    contact_email   VARCHAR(255),
    contact_phone   VARCHAR(20),
    website_url     VARCHAR(500),
    boundary        GEOMETRY(MULTIPOLYGON, 4326),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    logo_url        VARCHAR(500),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT municipalities_code_unique UNIQUE (code),
    CONSTRAINT municipalities_name_state_unique UNIQUE (name, state)
);

CREATE TRIGGER municipalities_set_updated_at
    BEFORE UPDATE ON municipalities
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE wards (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    code            VARCHAR(20)     NOT NULL,
    description     TEXT,
    boundary        GEOMETRY(POLYGON, 4326),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT wards_municipality_fk
        FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE RESTRICT,
    CONSTRAINT wards_code_municipality_unique UNIQUE (municipality_id, code)
);

CREATE INDEX idx_wards_municipality_id ON wards (municipality_id);
CREATE INDEX idx_wards_boundary        ON wards USING GIST (boundary);

CREATE TRIGGER wards_set_updated_at
    BEFORE UPDATE ON wards
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

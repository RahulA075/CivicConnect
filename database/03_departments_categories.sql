-- =============================================================================
-- CivicConnect Database
-- Script 03: Departments & Issue Categories
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Table: departments
-- ---------------------------------------------------------------------------
-- Government departments within a municipality.
-- Each department owns a set of issue categories and handles their resolution.
-- ---------------------------------------------------------------------------

CREATE TABLE departments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,

    -- Identity
    name            VARCHAR(200)    NOT NULL,
    description     TEXT,
    icon_name       VARCHAR(100),               -- Material Symbol icon name
    color_hex       CHAR(7),                    -- e.g. '#1565C0'

    -- Contact
    contact_email   VARCHAR(255),
    contact_phone   VARCHAR(20),
    head_user_id    UUID,                       -- FK to users (dept head/supervisor), set later

    -- Status
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by      UUID,                       -- FK to users
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT departments_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    -- Constraints
    CONSTRAINT departments_name_municipality_unique UNIQUE (municipality_id, name)
);

COMMENT ON TABLE departments IS
    'Government departments within a municipality. Each department handles one or more issue categories.';

CREATE INDEX idx_departments_municipality_id ON departments (municipality_id);
CREATE INDEX idx_departments_is_active ON departments (municipality_id, is_active);

CREATE TRIGGER departments_set_updated_at
    BEFORE UPDATE ON departments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: issue_categories
-- ---------------------------------------------------------------------------
-- Issue categories (and subcategories via self-referencing parent_id).
-- Each category maps to a department and carries its own SLA defaults.
-- Examples: Roads > Pothole, Roads > Road Collapse, Water > Leakage
-- ---------------------------------------------------------------------------

CREATE TABLE issue_categories (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID            NOT NULL,
    department_id   UUID            NOT NULL,

    -- Hierarchy: parent_id NULL = top-level category
    parent_id       UUID,                       -- self-referencing FK

    -- Identity
    name            VARCHAR(200)    NOT NULL,
    description     TEXT,
    icon_name       VARCHAR(100)    NOT NULL,   -- Material Symbol icon name
    color_hex       CHAR(7)         NOT NULL DEFAULT '#1565C0',

    -- Display
    sort_order      SMALLINT        NOT NULL DEFAULT 0,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by      UUID,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT issue_categories_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    CONSTRAINT issue_categories_department_fk
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
        ON DELETE RESTRICT,

    CONSTRAINT issue_categories_parent_fk
        FOREIGN KEY (parent_id)
        REFERENCES issue_categories (id)
        ON DELETE SET NULL,

    -- Constraints
    CONSTRAINT issue_categories_name_dept_unique UNIQUE (department_id, name),

    -- Prevent a category from being its own parent
    CONSTRAINT issue_categories_no_self_parent CHECK (id != parent_id)
);

COMMENT ON TABLE issue_categories IS
    'Issue categories and subcategories. Self-referencing parent_id supports a 2-level hierarchy.';

CREATE INDEX idx_issue_categories_municipality ON issue_categories (municipality_id);
CREATE INDEX idx_issue_categories_department   ON issue_categories (department_id);
CREATE INDEX idx_issue_categories_parent       ON issue_categories (parent_id);
CREATE INDEX idx_issue_categories_active       ON issue_categories (municipality_id, is_active, sort_order);

CREATE TRIGGER issue_categories_set_updated_at
    BEFORE UPDATE ON issue_categories
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: sla_policies
-- ---------------------------------------------------------------------------
-- SLA resolution targets per category + priority combination.
-- Drives sla_deadline calculation on issue submission.
-- ---------------------------------------------------------------------------

CREATE TABLE sla_policies (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id     UUID            NOT NULL,
    category_id         UUID,                       -- NULL = applies to all categories in municipality
    priority            issue_priority  NOT NULL,

    -- Thresholds (in hours)
    resolution_hours    INTEGER         NOT NULL CHECK (resolution_hours > 0),
    warning_hours       INTEGER         NOT NULL CHECK (warning_hours > 0),   -- alert before breach
    escalation_hours    INTEGER         NOT NULL CHECK (escalation_hours > 0),-- auto-escalate after

    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by          UUID,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT sla_policies_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    CONSTRAINT sla_policies_category_fk
        FOREIGN KEY (category_id)
        REFERENCES issue_categories (id)
        ON DELETE CASCADE,

    -- Constraints
    CONSTRAINT sla_warning_before_resolution CHECK (warning_hours < resolution_hours),
    CONSTRAINT sla_escalation_after_resolution CHECK (escalation_hours >= resolution_hours),

    -- One SLA rule per municipality + category + priority combination
    CONSTRAINT sla_policies_unique UNIQUE (municipality_id, category_id, priority)
);

COMMENT ON TABLE sla_policies IS
    'SLA thresholds per municipality/category/priority. category_id NULL = municipality-wide default.';

CREATE INDEX idx_sla_policies_municipality ON sla_policies (municipality_id);
CREATE INDEX idx_sla_policies_category     ON sla_policies (category_id);

CREATE TRIGGER sla_policies_set_updated_at
    BEFORE UPDATE ON sla_policies
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------------
-- Table: escalation_rules
-- ---------------------------------------------------------------------------
-- Auto-escalation rules triggered when SLA is breached past threshold.
-- ---------------------------------------------------------------------------

CREATE TABLE escalation_rules (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id     UUID            NOT NULL,
    department_id       UUID,                       -- NULL = applies to all departments

    trigger_after_hours INTEGER         NOT NULL CHECK (trigger_after_hours > 0),
    escalate_to_role    user_role       NOT NULL,   -- which role receives the escalation alert
    notification_message TEXT,

    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by          UUID,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Foreign Keys
    CONSTRAINT escalation_rules_municipality_fk
        FOREIGN KEY (municipality_id)
        REFERENCES municipalities (id)
        ON DELETE RESTRICT,

    CONSTRAINT escalation_rules_department_fk
        FOREIGN KEY (department_id)
        REFERENCES departments (id)
        ON DELETE CASCADE
);

COMMENT ON TABLE escalation_rules IS
    'Auto-escalation rules. Triggers when an issue exceeds SLA by the configured hours.';

CREATE INDEX idx_escalation_rules_municipality ON escalation_rules (municipality_id);
CREATE INDEX idx_escalation_rules_department   ON escalation_rules (department_id);

CREATE TRIGGER escalation_rules_set_updated_at
    BEFORE UPDATE ON escalation_rules
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

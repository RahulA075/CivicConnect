-- V3: Departments, Issue Categories, SLA Policies, Escalation Rules

CREATE TABLE departments (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID         NOT NULL,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    icon_name       VARCHAR(100),
    color_hex       CHAR(7),
    contact_email   VARCHAR(255),
    contact_phone   VARCHAR(20),
    head_user_id    UUID,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_by      UUID,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT departments_municipality_fk
        FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE RESTRICT,
    CONSTRAINT departments_name_municipality_unique UNIQUE (municipality_id, name)
);

CREATE INDEX idx_departments_municipality_id ON departments (municipality_id);
CREATE TRIGGER departments_set_updated_at
    BEFORE UPDATE ON departments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE issue_categories (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID         NOT NULL,
    department_id   UUID         NOT NULL,
    parent_id       UUID,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    icon_name       VARCHAR(100) NOT NULL,
    color_hex       CHAR(7)      NOT NULL DEFAULT '#1565C0',
    sort_order      SMALLINT     NOT NULL DEFAULT 0,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_by      UUID,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT issue_categories_municipality_fk
        FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE RESTRICT,
    CONSTRAINT issue_categories_department_fk
        FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE RESTRICT,
    CONSTRAINT issue_categories_parent_fk
        FOREIGN KEY (parent_id) REFERENCES issue_categories (id) ON DELETE SET NULL,
    CONSTRAINT issue_categories_name_dept_unique UNIQUE (department_id, name),
    CONSTRAINT issue_categories_no_self_parent CHECK (id != parent_id)
);

CREATE INDEX idx_issue_categories_municipality ON issue_categories (municipality_id);
CREATE INDEX idx_issue_categories_department   ON issue_categories (department_id);
CREATE INDEX idx_issue_categories_parent       ON issue_categories (parent_id);
CREATE TRIGGER issue_categories_set_updated_at
    BEFORE UPDATE ON issue_categories FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE sla_policies (
    id                UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id   UUID            NOT NULL,
    category_id       UUID,
    priority          issue_priority  NOT NULL,
    resolution_hours  INTEGER         NOT NULL CHECK (resolution_hours > 0),
    warning_hours     INTEGER         NOT NULL CHECK (warning_hours > 0),
    escalation_hours  INTEGER         NOT NULL CHECK (escalation_hours > 0),
    is_active         BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by        UUID,
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT sla_policies_municipality_fk
        FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE RESTRICT,
    CONSTRAINT sla_policies_category_fk
        FOREIGN KEY (category_id) REFERENCES issue_categories (id) ON DELETE CASCADE,
    CONSTRAINT sla_warning_before_resolution CHECK (warning_hours < resolution_hours),
    CONSTRAINT sla_escalation_after_resolution CHECK (escalation_hours >= resolution_hours),
    CONSTRAINT sla_policies_unique UNIQUE (municipality_id, category_id, priority)
);

CREATE INDEX idx_sla_policies_municipality ON sla_policies (municipality_id);
CREATE TRIGGER sla_policies_set_updated_at
    BEFORE UPDATE ON sla_policies FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE escalation_rules (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id     UUID        NOT NULL,
    department_id       UUID,
    trigger_after_hours INTEGER     NOT NULL CHECK (trigger_after_hours > 0),
    escalate_to_role    user_role   NOT NULL,
    notification_message TEXT,
    is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
    created_by          UUID,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT escalation_rules_municipality_fk
        FOREIGN KEY (municipality_id) REFERENCES municipalities (id) ON DELETE RESTRICT,
    CONSTRAINT escalation_rules_department_fk
        FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE CASCADE
);

CREATE INDEX idx_escalation_rules_municipality ON escalation_rules (municipality_id);
CREATE TRIGGER escalation_rules_set_updated_at
    BEFORE UPDATE ON escalation_rules FOR EACH ROW EXECUTE FUNCTION set_updated_at();

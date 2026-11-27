-- =============================================================================
-- CivicConnect Database
-- Script 13: Seed Data
-- =============================================================================
-- Reference data for development and staging environments.
-- DO NOT run in production as-is. Production seeding should use
-- the admin onboarding flow.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Roles (already seeded in 04_users_roles.sql, skip if exists)
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Sample Municipality: Mumbai Municipal Corporation
-- ---------------------------------------------------------------------------

INSERT INTO municipalities (id, name, code, state, country, timezone, contact_email)
VALUES (
    'a1b2c3d4-0000-0000-0000-000000000001',
    'Mumbai Municipal Corporation',
    'MUM',
    'Maharashtra',
    'India',
    'Asia/Kolkata',
    'admin@mcgm.gov.in'
);

-- ---------------------------------------------------------------------------
-- Sample Departments
-- ---------------------------------------------------------------------------

INSERT INTO departments (id, municipality_id, name, icon_name, color_hex) VALUES
    ('d0000001-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'Roads Department',        'directions_car_rounded',  '#1565C0'),
    ('d0000002-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'Water Supply Department', 'water_drop_rounded',       '#0277BD'),
    ('d0000003-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'Electricity Department',  'bolt_rounded',             '#F57F17'),
    ('d0000004-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'Sanitation Department',   'delete_rounded',           '#2E7D32'),
    ('d0000005-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'Parks Department',        'park_rounded',             '#558B2F');

-- ---------------------------------------------------------------------------
-- Sample Issue Categories
-- ---------------------------------------------------------------------------

INSERT INTO issue_categories (id, municipality_id, department_id, parent_id, name, icon_name, color_hex, sort_order) VALUES
-- Roads (top-level)
('c0000001-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', NULL, 'Roads',          'directions_car_rounded', '#1565C0', 1),
-- Roads subcategories
('c0000002-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'Pothole',         'directions_car_rounded', '#1565C0', 1),
('c0000003-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'Road Collapse',   'directions_car_rounded', '#1565C0', 2),
('c0000004-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', 'c0000001-0000-0000-0000-000000000001', 'Road Divider',    'directions_car_rounded', '#1565C0', 3),

-- Water (top-level)
('c0000010-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', NULL, 'Water Supply',   'water_drop_rounded',     '#0277BD', 2),
('c0000011-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'c0000010-0000-0000-0000-000000000001', 'Water Leakage',   'water_drop_rounded',     '#0277BD', 1),
('c0000012-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'c0000010-0000-0000-0000-000000000001', 'No Water Supply', 'water_drop_rounded',     '#0277BD', 2),
('c0000013-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', 'c0000010-0000-0000-0000-000000000001', 'Water Main Break','water_drop_rounded',     '#0277BD', 3),

-- Electricity (top-level)
('c0000020-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000001', NULL, 'Electricity',    'bolt_rounded',           '#F57F17', 3),
('c0000021-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000001', 'c0000020-0000-0000-0000-000000000001', 'Street Light Out','lightbulb_rounded',      '#F57F17', 1),
('c0000022-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000001', 'c0000020-0000-0000-0000-000000000001', 'Power Outage',    'bolt_rounded',           '#F57F17', 2),

-- Sanitation (top-level)
('c0000030-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000004-0000-0000-0000-000000000001', NULL, 'Sanitation',     'delete_rounded',         '#2E7D32', 4),
('c0000031-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000004-0000-0000-0000-000000000001', 'c0000030-0000-0000-0000-000000000001', 'Garbage Not Collected','delete_rounded', '#2E7D32', 1),
('c0000032-0000-0000-0000-000000000001', 'a1b2c3d4-0000-0000-0000-000000000001', 'd0000004-0000-0000-0000-000000000001', 'c0000030-0000-0000-0000-000000000001', 'Blocked Drain',   'water_rounded',          '#2E7D32', 2);

-- ---------------------------------------------------------------------------
-- SLA Policies: Mumbai defaults per priority
-- ---------------------------------------------------------------------------
-- category_id = NULL means municipality-wide default for that priority

INSERT INTO sla_policies (municipality_id, category_id, priority, resolution_hours, warning_hours, escalation_hours) VALUES
-- Municipality-wide defaults
('a1b2c3d4-0000-0000-0000-000000000001', NULL, 'LOW',      120, 96,  144),  -- 5d resolve, warn at 4d, escalate at 6d
('a1b2c3d4-0000-0000-0000-000000000001', NULL, 'MEDIUM',    72, 48,   96),  -- 3d resolve, warn at 2d, escalate at 4d
('a1b2c3d4-0000-0000-0000-000000000001', NULL, 'HIGH',      48, 24,   72),  -- 2d resolve, warn at 1d, escalate at 3d
('a1b2c3d4-0000-0000-0000-000000000001', NULL, 'CRITICAL',   8,  4,   24),  -- 8h resolve, warn at 4h, escalate at 24h
-- Road Collapse override (always CRITICAL treatment)
('a1b2c3d4-0000-0000-0000-000000000001', 'c0000003-0000-0000-0000-000000000001', 'CRITICAL', 4, 2, 8),
-- Water Main Break override
('a1b2c3d4-0000-0000-0000-000000000001', 'c0000013-0000-0000-0000-000000000001', 'CRITICAL', 6, 3, 12);

-- ---------------------------------------------------------------------------
-- Escalation Rules
-- ---------------------------------------------------------------------------

INSERT INTO escalation_rules (municipality_id, department_id, trigger_after_hours, escalate_to_role, notification_message) VALUES
('a1b2c3d4-0000-0000-0000-000000000001', NULL,                                    48,  'MUNICIPAL_ADMIN', 'Issue overdue >48h. Requires admin attention.'),
('a1b2c3d4-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001',  24,  'DEPT_SUPERVISOR', 'Roads issue unresolved >24h past SLA.'),
('a1b2c3d4-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001',  12,  'DEPT_SUPERVISOR', 'Water issue unresolved >12h past SLA.');

-- ---------------------------------------------------------------------------
-- Sample Notification Templates (platform defaults)
-- ---------------------------------------------------------------------------

INSERT INTO notification_templates (municipality_id, event_type, channel, language_code, subject_template, body_template) VALUES
-- PUSH templates (no subject)
(NULL, 'ISSUE_SUBMITTED',   'PUSH', 'en', NULL,
 'Your report {{tracking_id}} has been submitted. We''ll keep you updated!'),

(NULL, 'ISSUE_ASSIGNED',    'PUSH', 'en', NULL,
 'Good news! Report {{tracking_id}} has been assigned to {{department_name}}.'),

(NULL, 'ISSUE_IN_PROGRESS', 'PUSH', 'en', NULL,
 'Work has started on your report {{tracking_id}}. Stay tuned!'),

(NULL, 'ISSUE_RESOLVED',    'PUSH', 'en', NULL,
 'Your report {{tracking_id}} has been resolved. Please verify and rate.'),

(NULL, 'ASSIGNMENT_RECEIVED', 'PUSH', 'en', NULL,
 'New task assigned: {{issue_title}} at {{address}}. SLA: {{sla_deadline}}.'),

-- EMAIL templates
(NULL, 'ISSUE_SUBMITTED',   'EMAIL', 'en',
 'CivicConnect: Report {{tracking_id}} received',
 'Dear {{citizen_name}},\n\nYour civic issue report has been submitted successfully.\n\nTracking ID: {{tracking_id}}\nCategory: {{category_name}}\nLocation: {{address}}\nExpected resolution: {{sla_deadline}}\n\nTrack your issue at: {{tracking_url}}\n\nThank you,\nCivicConnect Team'),

(NULL, 'SLA_BREACHED',      'EMAIL', 'en',
 '[URGENT] SLA Breach: Issue {{tracking_id}}',
 'Dear {{supervisor_name}},\n\nIssue {{tracking_id}} has breached its SLA deadline.\n\nIssue: {{issue_title}}\nDepartment: {{department_name}}\nOverdue by: {{overdue_duration}}\n\nPlease take immediate action.\n\nCivicConnect Operations');

-- V10: Add missing updated_by column to all AuditableEntity tables
-- AuditableEntity declares updated_by but several V2/V3 migrations did not include it.

ALTER TABLE municipalities    ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE wards             ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE departments       ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE issue_categories  ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE emergency_alerts  ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE escalation_rules  ADD COLUMN IF NOT EXISTS updated_by UUID;
ALTER TABLE sla_policies      ADD COLUMN IF NOT EXISTS updated_by UUID;

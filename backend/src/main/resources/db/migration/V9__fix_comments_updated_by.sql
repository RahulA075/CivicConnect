-- V9: Add missing updated_by column to comments table
-- AuditableEntity declares updated_by but V5 did not include it.

ALTER TABLE comments
    ADD COLUMN IF NOT EXISTS updated_by UUID;

-- =============================================================================
-- CivicConnect Database
-- Script 16: Consolidated Index Reference & Missing Index Analysis
-- =============================================================================
-- This script is DOCUMENTATION ONLY — indexes are created in their
-- respective table scripts. This file lists all indexes in one place
-- for review, along with the query patterns they serve.
-- =============================================================================

/*
═══════════════════════════════════════════════════════════════════════════════
 TABLE: municipalities
═══════════════════════════════════════════════════════════════════════════════
 INDEX                              TYPE    COLUMNS                     SERVES
 ─────────────────────────────────────────────────────────────────────────────
 municipalities_code_unique         UNIQUE  code                        Code lookup
 municipalities_name_state_unique   UNIQUE  (name, state)               Dup prevention

═══════════════════════════════════════════════════════════════════════════════
 TABLE: wards
═══════════════════════════════════════════════════════════════════════════════
 idx_wards_municipality_id          BTREE   municipality_id             Ward list per city
 idx_wards_boundary                 GIST    boundary                    Point-in-polygon (ward detection)

═══════════════════════════════════════════════════════════════════════════════
 TABLE: departments
═══════════════════════════════════════════════════════════════════════════════
 departments_name_municipality_unique UNIQUE (municipality_id, name)   Dup prevention
 idx_departments_municipality_id    BTREE   municipality_id             Dept list per city
 idx_departments_is_active          BTREE   (municipality_id, is_active) Active depts only

═══════════════════════════════════════════════════════════════════════════════
 TABLE: issue_categories
═══════════════════════════════════════════════════════════════════════════════
 idx_issue_categories_municipality  BTREE   municipality_id             Category list per city
 idx_issue_categories_department    BTREE   department_id               Categories per dept
 idx_issue_categories_parent        BTREE   parent_id                   Subcategory lookup
 idx_issue_categories_active        BTREE   (municipality_id, is_active, sort_order) Sorted active categories

═══════════════════════════════════════════════════════════════════════════════
 TABLE: users
═══════════════════════════════════════════════════════════════════════════════
 idx_users_email_unique             UNIQUE  LOWER(email) WHERE not null  Login by email
 idx_users_phone_unique             UNIQUE  phone WHERE not null         Login by phone
 idx_users_provider_id_unique       UNIQUE  (auth_provider, provider_id) OAuth login
 idx_users_role_id                  BTREE   role_id                     Users by role
 idx_users_municipality             BTREE   municipality_id             Authority users per city
 idx_users_department               BTREE   department_id               Workers per dept
 idx_users_is_active                BTREE   is_active                   Active user filter
 idx_users_deleted_at               BTREE   deleted_at                  Soft delete cleanup

═══════════════════════════════════════════════════════════════════════════════
 TABLE: refresh_tokens
═══════════════════════════════════════════════════════════════════════════════
 refresh_tokens_token_hash_unique   UNIQUE  token_hash                  Token validation lookup
 idx_refresh_tokens_user_id         BTREE   user_id                     Tokens per user
 idx_refresh_tokens_expires_at      BTREE   expires_at WHERE not revoked Expiry cleanup job

═══════════════════════════════════════════════════════════════════════════════
 TABLE: issues  ← most important, most indexed
═══════════════════════════════════════════════════════════════════════════════
 issues_tracking_id_unique          UNIQUE  tracking_id                 Tracking ID lookup
 idx_issues_location_gist           GIST    location                    Proximity search (ST_DWithin)
 idx_issues_location_municipality   GIST    location WHERE not deleted  Heatmap generation
 idx_issues_dept_status_created     BTREE   (dept_id, status, created_at) Authority queue
 idx_issues_reported_by             BTREE   (reported_by, created_at)   Citizen "My Issues"
 idx_issues_assigned_to             BTREE   (assigned_to, status)       Field worker task list
 idx_issues_municipality_status     BTREE   (municipality_id, status, created_at) Admin overview
 idx_issues_overdue                 BTREE   (municipality_id, is_overdue, dept_id) Overdue filter
 idx_issues_sla_deadline            BTREE   sla_deadline                SLA monitoring job
 idx_issues_ward_id                 BTREE   (ward_id, status)           Ward analytics
 idx_issues_category_id             BTREE   (category_id, municipality_id, status) Category analytics
 idx_issues_tracking_id             BTREE   tracking_id                 ID lookup (also unique)
 idx_issues_fts                     GIN     tsvector(title+description) Full-text search
 idx_issues_deleted_at              BTREE   deleted_at                  Soft delete cleanup

═══════════════════════════════════════════════════════════════════════════════
 TABLE: issue_images
═══════════════════════════════════════════════════════════════════════════════
 issue_images_storage_key_unique    UNIQUE  storage_key                 S3 key uniqueness
 idx_issue_images_issue_id          BTREE   (issue_id, image_type, sort_order) Image list per issue
 idx_issue_images_deleted           BTREE   deleted_at                  Orphan cleanup

═══════════════════════════════════════════════════════════════════════════════
 TABLE: comments
═══════════════════════════════════════════════════════════════════════════════
 idx_comments_issue_public          BTREE   (issue_id, created_at) WHERE public+active  Public thread
 idx_comments_issue_internal        BTREE   (issue_id, created_at) WHERE internal+active Internal notes
 idx_comments_user_id               BTREE   (user_id, created_at)       User comment history

═══════════════════════════════════════════════════════════════════════════════
 TABLE: votes
═══════════════════════════════════════════════════════════════════════════════
 votes_user_issue_unique            UNIQUE  (issue_id, user_id)         Prevent double voting
 idx_votes_issue_id                 BTREE   issue_id                    Vote count (unused — see counter)
 idx_votes_user_id                  BTREE   user_id                     User vote history

═══════════════════════════════════════════════════════════════════════════════
 TABLE: issue_status_history
═══════════════════════════════════════════════════════════════════════════════
 idx_issue_history_issue_id         BTREE   (issue_id, created_at ASC)  Issue timeline
 idx_issue_history_municipality     BTREE   (department_id, new_status, created_at) Analytics

═══════════════════════════════════════════════════════════════════════════════
 TABLE: issue_assignments
═══════════════════════════════════════════════════════════════════════════════
 idx_assignments_issue_active       UNIQUE  issue_id WHERE is_active    Enforce single active assignment
 idx_assignments_worker_active      BTREE   (assigned_to, is_active, created_at) Worker task list
 idx_assignments_assigned_by        BTREE   (assigned_by, created_at)   Supervisor activity

═══════════════════════════════════════════════════════════════════════════════
 TABLE: notifications
═══════════════════════════════════════════════════════════════════════════════
 idx_notifications_user_inbox       BTREE   (user_id, is_read, created_at) Notification inbox
 idx_notifications_issue_id         BTREE   issue_id                    Issue notifications
 idx_notifications_retry            BTREE   next_retry_at               Retry job
 idx_notifications_created_at       BTREE   created_at                  Archival cleanup

═══════════════════════════════════════════════════════════════════════════════
 TABLE: audit_logs (partitioned)
═══════════════════════════════════════════════════════════════════════════════
 idx_audit_logs_user_id             BTREE   (user_id, created_at)       User audit trail
 idx_audit_logs_municipality        BTREE   (municipality_id, created_at) City audit view
 idx_audit_logs_entity              BTREE   (entity_type, entity_id, created_at) Entity history
 idx_audit_logs_action              BTREE   (action, created_at)        Action filter
*/

-- ---------------------------------------------------------------------------
-- Index health check query (run periodically to find unused indexes)
-- ---------------------------------------------------------------------------

-- Uncomment to run:
-- SELECT
--     schemaname,
--     tablename,
--     indexname,
--     idx_scan        AS times_used,
--     idx_tup_read    AS tuples_read,
--     pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
-- FROM pg_stat_user_indexes
-- ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;

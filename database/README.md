# CivicConnect — Database Design

**Engine:** PostgreSQL 16 + PostGIS 3.4
**Schema:** Single schema (`public`), multi-tenant via `municipality_id`
**Normalization:** 3NF with deliberate, documented denormalizations

---

## Execution Order

Run scripts in strict numerical order. Each script depends on the previous.

| Script | Description | Key Dependencies |
|---|---|---|
| `01_extensions_and_types.sql` | Extensions (PostGIS, pgcrypto, pg_trgm), all ENUMs, utility functions | None — run first |
| `02_municipalities_wards.sql` | `municipalities`, `wards` | Script 01 |
| `03_departments_categories.sql` | `departments`, `issue_categories`, `sla_policies`, `escalation_rules` | Script 02 |
| `04_users_roles.sql` | `roles`, `users`, `otp_verifications`, `refresh_tokens`, `notification_preferences`, `device_tokens` | Scripts 02, 03 |
| `05_issues.sql` | `issues` (core domain table, PostGIS geometry, state machine trigger) | Scripts 02, 03, 04 |
| `06_issue_images.sql` | `issue_images` | Script 05 |
| `07_comments_votes.sql` | `comments`, `votes`, counter triggers | Script 05 |
| `08_issue_status_history.sql` | `issue_status_history`, `issue_assignments`, auto-history trigger | Scripts 04, 05 |
| `09_notifications.sql` | `notification_templates`, `notifications` | Scripts 04, 05 |
| `10_audit_logs.sql` | `audit_logs` (partitioned table + 36 monthly partitions) | Script 01 |
| `11_platform_config.sql` | `feature_flags`, `webhook_configs`, `scheduled_reports` | Scripts 02, 04 |
| `12_views.sql` | 5 read-optimized views | Scripts 02–11 |
| `13_seed_data.sql` | Dev/staging reference data (Mumbai sample data) | Scripts 02–11 |
| `14_stored_procedures.sql` | Geospatial functions, SLA procedures, analytics queries | Scripts 02–11 |
| `15_row_level_security.sql` | RLS policies, DB roles, grant statements | All tables |
| `16_indexes_summary.sql` | Index documentation reference (no DDL) | — |

---

## Quick Start (Local Development)

```bash
# Create database
psql -U postgres -c "CREATE DATABASE civicconnect;"

# Run all scripts in order
for script in database/0*.sql database/1*.sql; do
    echo "Running $script..."
    psql -U postgres -d civicconnect -f "$script"
done
```

Or using Docker Compose (see `infrastructure/docker/docker-compose.yml`):
```bash
docker compose up -d postgres
# Scripts auto-run via /docker-entrypoint-initdb.d/ mount
```

---

## Table Inventory (15 tables + 1 partitioned)

| Table | Rows (est. at 1 year, 1 city) | Purpose |
|---|---|---|
| `municipalities` | < 100 | Platform tenants |
| `wards` | ~200 per city | Geographic sub-divisions |
| `departments` | ~10 per city | Government departments |
| `issue_categories` | ~30 per city | Issue taxonomy |
| `sla_policies` | ~20 per city | SLA configuration |
| `escalation_rules` | ~5 per city | Auto-escalation rules |
| `roles` | 5 (fixed) | RBAC roles |
| `users` | ~50,000 per city | All users (all roles) |
| `otp_verifications` | ~100K/day (short-lived) | OTP codes |
| `refresh_tokens` | ~150K | Active JWT sessions |
| `notification_preferences` | = users count | Per-user prefs |
| `device_tokens` | ~60K | FCM/APNs tokens |
| `issues` | ~500K/year | Core civic reports |
| `issue_images` | ~1.5M/year | Issue photos (metadata only) |
| `comments` | ~300K/year | Public + internal notes |
| `votes` | ~1M/year | Citizen upvotes |
| `issue_status_history` | ~2M/year | Immutable state log |
| `issue_assignments` | ~600K/year | Assignment history |
| `notifications` | ~5M/year | Notification inbox |
| `notification_templates` | ~50 | Message templates |
| `audit_logs` | ~10M/year | Partitioned audit trail |
| `feature_flags` | ~10 per city | Feature toggles |
| `webhook_configs` | ~5 per city | Third-party webhooks |
| `scheduled_reports` | ~5 per city | Email report schedules |

---

## Key Design Decisions

### Multi-tenancy
Every business data row carries `municipality_id`. No separate schemas per tenant — simpler joins, single migration path. RLS adds a DB-level enforcement layer on top of application RBAC.

### PostGIS Geometry
`issues.location` is stored as `GEOMETRY(POINT, 4326)` using WGS 84 (GPS standard). This enables:
- `ST_DWithin` for proximity/duplicate detection (200m radius)
- `ST_Contains` for ward boundary detection
- Heatmap coordinate extraction via `ST_X / ST_Y`
- GIST indexes for sub-millisecond spatial queries

### Immutable Tables
`issue_status_history` and `audit_logs` are append-only. Application-level REVOKE prevents UPDATE/DELETE from the app role. Partitioned monthly for retention management.

### Denormalization
`issues.upvote_count` and `issues.comment_count` are denormalized and maintained by database triggers, avoiding `COUNT(*)` subqueries on every list render.

`issues.assigned_to` is denormalized from `issue_assignments` for O(1) field worker task list queries.

### State Machine
Issue status transitions are enforced by a `BEFORE UPDATE` trigger (`validate_status_transition()`). Invalid transitions raise a PostgreSQL exception which bubbles up as a 422 from the API.

### Partitioning
`audit_logs` is range-partitioned by `created_at` (monthly). Pre-created partitions from 2024 through 2026. Use `pg_partman` in production for automated partition management.

---

## Normalization Analysis

| Entity | Normal Form | Violations / Notes |
|---|---|---|
| `municipalities` | 3NF | Clean |
| `wards` | 3NF | Clean |
| `departments` | 3NF | Clean |
| `issue_categories` | 3NF | Self-ref FK is intentional design, not a violation |
| `users` | 3NF | Clean — auth_provider + provider_id is not a transitive dependency |
| `issues` | 3NF* | `upvote_count`, `comment_count`, `assigned_to` intentionally denormalized; documented |
| `issue_status_history` | 3NF | Snapshot data — redundancy is intentional for immutable log |
| `comments` | 3NF | Clean |
| `votes` | 3NF | Clean — minimal table |
| `notifications` | 3NF | Clean |
| `audit_logs` | 3NF | Snapshot/log table — intentional redundancy |

---

## Foreign Key Map

```
municipalities
  ├── wards.municipality_id
  ├── departments.municipality_id
  ├── issue_categories.municipality_id
  ├── sla_policies.municipality_id
  ├── escalation_rules.municipality_id
  ├── users.municipality_id
  ├── feature_flags.municipality_id
  ├── webhook_configs.municipality_id
  ├── notification_templates.municipality_id
  └── scheduled_reports.municipality_id

departments
  ├── issue_categories.department_id
  ├── issues.department_id
  ├── users.department_id
  ├── escalation_rules.department_id
  └── issue_status_history.department_id

issue_categories
  ├── issue_categories.parent_id (self)
  ├── issues.category_id
  └── sla_policies.category_id

roles
  └── users.role_id

users
  ├── refresh_tokens.user_id
  ├── notification_preferences.user_id
  ├── device_tokens.user_id
  ├── issues.reported_by
  ├── issues.assigned_to
  ├── comments.user_id
  ├── votes.user_id
  ├── notifications.user_id
  ├── issue_assignments.assigned_by
  ├── issue_assignments.assigned_to
  ├── issue_status_history.changed_by
  └── audit_logs.user_id

issues
  ├── issue_images.issue_id
  ├── comments.issue_id
  ├── votes.issue_id
  ├── issue_status_history.issue_id
  ├── issue_assignments.issue_id
  ├── notifications.issue_id
  └── issues.merged_into_id (self)
```

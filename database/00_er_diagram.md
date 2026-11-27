# CivicConnect — Entity Relationship Diagram

## Complete ER Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              CIVICCONNECT DATABASE — ER DIAGRAM                              │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 1 — PLATFORM & GEOGRAPHY
═══════════════════════════════════════════════════════════

  ┌─────────────────────────┐
  │       municipalities    │
  ├─────────────────────────┤
  │ PK id (uuid)            │
  │    name                 │
  │    state                │
  │    country              │
  │    boundary (geometry)  │
  │    contact_email        │
  │    is_active            │
  │    created_at           │
  └────────────┬────────────┘
               │ 1
               │ has many
               ├─────────────────────────────────┐
               │                                 │
               │ n                               │ n
  ┌────────────▼────────────┐       ┌────────────▼────────────┐
  │         wards           │       │       departments        │
  ├─────────────────────────┤       ├─────────────────────────┤
  │ PK id (uuid)            │       │ PK id (uuid)            │
  │ FK municipality_id      │       │ FK municipality_id      │
  │    name                 │       │    name                 │
  │    code                 │       │    description          │
  │    boundary (geometry)  │       │    contact_email        │
  │    is_active            │       │    is_active            │
  │    created_at           │       │    created_at           │
  └────────────┬────────────┘       └────────────┬────────────┘
               │ 1                               │ 1
               │                                │
               │ n                              │ n
               └──── issues.ward_id             └──── issues.department_id
                                                │
                                      ┌─────────▼──────────────┐
                                      │    issue_categories     │
                                      ├─────────────────────────┤
                                      │ PK id (uuid)            │
                                      │ FK municipality_id      │
                                      │ FK department_id        │
                                      │ FK parent_id (self-ref) │
                                      │    name                 │
                                      │    icon_name            │
                                      │    color_hex            │
                                      │    is_active            │
                                      │    sort_order           │
                                      └─────────────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 2 — IDENTITY & ACCESS
═══════════════════════════════════════════════════════════

  ┌─────────────────────────┐        ┌─────────────────────────┐
  │         roles           │        │     otp_verifications   │
  ├─────────────────────────┤        ├─────────────────────────┤
  │ PK id (uuid)            │        │ PK id (uuid)            │
  │    name (enum)          │        │    identifier           │
  │    description          │        │    otp_code (hashed)    │
  └────────────┬────────────┘        │    purpose (enum)       │
               │ 1                   │    is_used              │
               │                     │    attempts             │
               │ n                   │    expires_at           │
  ┌────────────▼────────────┐        │    created_at           │
  │          users          │        └─────────────────────────┘
  ├─────────────────────────┤
  │ PK id (uuid)            │        ┌─────────────────────────┐
  │ FK role_id              │        │     refresh_tokens      │
  │ FK municipality_id (opt)│        ├─────────────────────────┤
  │ FK department_id (opt)  │        │ PK id (uuid)            │
  │    full_name            │        │ FK user_id              │
  │    email (unique)       │◄───────│    token_hash           │
  │    phone (unique)       │  1:n   │    device_info          │
  │    password_hash        │        │    ip_address           │
  │    avatar_url           │        │    expires_at           │
  │    auth_provider (enum) │        │    is_revoked           │
  │    provider_id          │        │    created_at           │
  │    is_verified          │        └─────────────────────────┘
  │    is_active            │
  │    last_login_at        │        ┌─────────────────────────┐
  │    created_at           │        │   notification_prefs    │
  │    updated_at           │        ├─────────────────────────┤
  │    deleted_at           │◄───────│ PK id (uuid)            │
  └─────────────────────────┘  1:1   │ FK user_id (unique)     │
                                     │    push_enabled         │
                                     │    email_enabled        │
                                     │    sms_enabled          │
                                     │    updated_at           │
                                     └─────────────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 3 — ISSUE CORE (Central Domain)
═══════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────┐
  │                            issues                               │
  ├─────────────────────────────────────────────────────────────────┤
  │ PK  id (uuid)                                                   │
  │ FK  municipality_id ──────────────────► municipalities          │
  │ FK  category_id ──────────────────────► issue_categories        │
  │ FK  ward_id (nullable) ───────────────► wards                   │
  │ FK  department_id (nullable) ─────────► departments             │
  │ FK  reported_by (nullable) ───────────► users                   │
  │ FK  assigned_to (nullable) ───────────► users                   │
  │ FK  merged_into_id (nullable, self) ──► issues                  │
  │     tracking_id (unique, generated)                             │
  │     title                                                       │
  │     description                                                 │
  │     status (enum)                                               │
  │     priority (enum)                                             │
  │     location (geometry POINT 4326) ◄── PostGIS                  │
  │     address_text                                                │
  │     is_anonymous                                                │
  │     upvote_count (denormalized)                                 │
  │     sla_deadline (nullable)                                     │
  │     is_overdue                                                  │
  │     resolved_at (nullable)                                      │
  │     closed_at (nullable)                                        │
  │     citizen_rating (1-5, nullable)                              │
  │     citizen_rating_comment (nullable)                           │
  │     rejection_reason (nullable)                                 │
  │     resolution_note (nullable)                                  │
  │     created_at                                                  │
  │     updated_at                                                  │
  │     deleted_at (nullable)                                       │
  └─────────────────────────────────────────────────────────────────┘
         │ 1            │ 1           │ 1           │ 1
         │              │             │             │
         │ n            │ n           │ n           │ n
  ┌──────▼──────┐ ┌─────▼──────┐ ┌───▼──────┐ ┌───▼─────────────┐
  │issue_images │ │  comments  │ │  votes   │ │ issue_status_   │
  │             │ │            │ │          │ │    history      │
  ├─────────────┤ ├────────────┤ ├──────────┤ ├─────────────────┤
  │PK id (uuid) │ │PK id (uuid)│ │PK id     │ │PK id (uuid)     │
  │FK issue_id  │ │FK issue_id │ │FK issue_id│ │FK issue_id      │
  │   storage_  │ │FK user_id  │ │FK user_id │ │FK changed_by    │
  │   key       │ │   body     │ │  created_at│ │   old_status    │
  │   cdn_url   │ │   is_      │ └──────────┘ │   new_status    │
  │   image_    │ │   internal │              │   old_priority  │
  │   type(enum)│ │   created_at│             │   new_priority  │
  │   sort_order│ │   updated_at│             │   changed_by_   │
  │   is_active │ │   deleted_at│             │   role          │
  │   created_at│ └────────────┘             │   note          │
  └─────────────┘                            │   created_at    │
                                             └─────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 4 — OPERATIONS
═══════════════════════════════════════════════════════════

  ┌─────────────────────────┐        ┌─────────────────────────┐
  │    issue_assignments    │        │     sla_policies        │
  ├─────────────────────────┤        ├─────────────────────────┤
  │ PK id (uuid)            │        │ PK id (uuid)            │
  │ FK issue_id             │        │ FK municipality_id      │
  │ FK assigned_by          │        │ FK category_id (opt)    │
  │ FK assigned_to          │        │    priority (enum)      │
  │    assignment_note      │        │    resolution_hours     │
  │    is_active            │        │    escalation_hours     │
  │    created_at           │        │    is_active            │
  └─────────────────────────┘        │    created_at           │
                                     └─────────────────────────┘

  ┌─────────────────────────┐        ┌─────────────────────────┐
  │   escalation_rules      │        │    webhook_configs      │
  ├─────────────────────────┤        ├─────────────────────────┤
  │ PK id (uuid)            │        │ PK id (uuid)            │
  │ FK municipality_id      │        │ FK municipality_id      │
  │ FK department_id (opt)  │        │    url                  │
  │    trigger_after_hours  │        │    secret_hash          │
  │    escalate_to_role     │        │    events (jsonb)       │
  │    is_active            │        │    is_active            │
  │    created_at           │        │    created_at           │
  └─────────────────────────┘        └─────────────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 5 — NOTIFICATIONS
═══════════════════════════════════════════════════════════

  ┌─────────────────────────┐        ┌──────────────────────────┐
  │  notification_templates │        │     notifications        │
  ├─────────────────────────┤        ├──────────────────────────┤
  │ PK id (uuid)            │        │ PK id (uuid)             │
  │ FK municipality_id (opt)│        │ FK user_id               │
  │    event_type (enum)    │        │ FK issue_id (nullable)   │
  │    channel (enum)       │        │    type (enum)           │
  │    subject_template     │        │    channel (enum)        │
  │    body_template        │        │    title                 │
  │    is_active            │        │    body                  │
  │    created_at           │        │    is_read               │
  └─────────────────────────┘        │    delivered_at          │
                                     │    read_at               │
                                     │    created_at            │
                                     └──────────────────────────┘

  ┌─────────────────────────┐
  │    device_tokens        │
  ├─────────────────────────┤
  │ PK id (uuid)            │
  │ FK user_id              │
  │    token                │
  │    platform (enum)      │
  │    is_active            │
  │    created_at           │
  └─────────────────────────┘

═══════════════════════════════════════════════════════════
 ZONE 6 — AUDIT & PLATFORM ADMIN
═══════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────┐
  │                          audit_logs                             │
  ├─────────────────────────────────────────────────────────────────┤
  │ PK  id (uuid)                                                   │
  │ FK  user_id (nullable) ───────────────────────► users           │
  │     entity_type (enum)                                          │
  │     entity_id (uuid)                                            │
  │     action (enum)                                               │
  │     old_value (jsonb)                                           │
  │     new_value (jsonb)                                           │
  │     ip_address                                                  │
  │     user_agent                                                  │
  │     municipality_id (nullable)                                  │
  │     created_at                                                  │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────┐        ┌─────────────────────────┐
  │      feature_flags      │        │   scheduled_reports     │
  ├─────────────────────────┤        ├─────────────────────────┤
  │ PK id (uuid)            │        │ PK id (uuid)            │
  │ FK municipality_id (opt)│        │ FK municipality_id      │
  │    flag_key             │        │ FK created_by           │
  │    flag_value (boolean) │        │    report_type          │
  │    description          │        │    frequency (enum)     │
  │    created_at           │        │    recipient_emails     │
  │    updated_at           │        │    is_active            │
  └─────────────────────────┘        │    last_run_at          │
                                     │    next_run_at          │
                                     │    created_at           │
                                     └─────────────────────────┘
```

---

## Relationship Summary

| Relationship | Cardinality | FK Location |
|---|---|---|
| municipalities → wards | 1:N | wards.municipality_id |
| municipalities → departments | 1:N | departments.municipality_id |
| municipalities → issue_categories | 1:N | issue_categories.municipality_id |
| departments → issue_categories | 1:N | issue_categories.department_id |
| issue_categories → issue_categories | 1:N (self) | issue_categories.parent_id |
| roles → users | 1:N | users.role_id |
| municipalities → users | 1:N (nullable) | users.municipality_id |
| departments → users | 1:N (nullable) | users.department_id |
| users → refresh_tokens | 1:N | refresh_tokens.user_id |
| users → notification_prefs | 1:1 | notification_prefs.user_id |
| users → device_tokens | 1:N | device_tokens.user_id |
| issues → issue_images | 1:N | issue_images.issue_id |
| issues → comments | 1:N | comments.issue_id |
| issues → votes | 1:N | votes.issue_id |
| issues → issue_status_history | 1:N | issue_status_history.issue_id |
| issues → issue_assignments | 1:N | issue_assignments.issue_id |
| issues → issues (merge) | 1:N (self) | issues.merged_into_id |
| users → issues (reporter) | 1:N | issues.reported_by |
| users → issues (assignee) | 1:N | issues.assigned_to |
| users → comments | 1:N | comments.user_id |
| users → votes | 1:N | votes.user_id |
| users → notifications | 1:N | notifications.user_id |
| municipalities → sla_policies | 1:N | sla_policies.municipality_id |
| municipalities → escalation_rules | 1:N | escalation_rules.municipality_id |
| municipalities → webhook_configs | 1:N | webhook_configs.municipality_id |
| municipalities → feature_flags | 1:N (nullable) | feature_flags.municipality_id |
| municipalities → notification_templates | 1:N (nullable) | notification_templates.municipality_id |
| municipalities → scheduled_reports | 1:N | scheduled_reports.municipality_id |

---

## Normalization Notes

The schema is in **3rd Normal Form (3NF)** with the following deliberate denormalizations:

| Denormalization | Column | Justification |
|---|---|---|
| Upvote count cached | issues.upvote_count | Avoids COUNT(*) on votes table for every list render |
| Assignment cached | issues.assigned_to | Avoids join to issue_assignments for every issue fetch |
| Status cached | issues.status | Core field, not computed; source of truth |
| SLA overdue flag | issues.is_overdue | Batch-updated by scheduler; avoids real-time computation |

All denormalized columns are maintained by application logic and scheduled jobs, not triggers (to preserve portability).

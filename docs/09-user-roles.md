# CivicConnect — User Roles

## Role Hierarchy

```
                        ┌──────────────────────┐
                        │   SYSTEM_ADMIN        │
                        │ (Platform-level)      │
                        └──────────┬───────────┘
                                   │
                        ┌──────────▼───────────┐
                        │  MUNICIPAL_ADMIN      │
                        │ (City-level)          │
                        └──────────┬───────────┘
                                   │
                     ┌─────────────▼────────────┐
                     │   DEPT_SUPERVISOR         │
                     │ (Department-level)        │
                     └─────────────┬────────────┘
                                   │
                     ┌─────────────▼────────────┐
                     │    FIELD_WORKER           │
                     │ (Ground operations)       │
                     └──────────────────────────┘

                     ┌──────────────────────────┐
                     │       CITIZEN             │
                     │ (Independent / Public)    │
                     └──────────────────────────┘
```

---

## Role Definitions

### ROLE: CITIZEN

**Scope:** Platform-wide (all municipalities)
**Created by:** Self-registration
**Access level:** Public + authenticated personal data

| Permission | Access |
|---|---|
| Submit issue report | ✅ Full |
| Submit anonymous report | ✅ Full |
| View own submitted reports | ✅ Full |
| Track report status | ✅ Full |
| Upvote existing reports | ✅ Full |
| View public issue feed (own area) | ✅ Full |
| Verify or reject resolution | ✅ Own reports only |
| Rate resolved issues | ✅ Own reports only |
| View other citizens' personal data | ❌ No |
| Access authority dashboard | ❌ No |
| Manage users | ❌ No |

---

### ROLE: FIELD_WORKER

**Scope:** Assigned department within a municipality
**Created by:** Dept Supervisor or Municipal Admin
**Access level:** Task management within assigned workload

| Permission | Access |
|---|---|
| View assigned issues | ✅ Full |
| Update issue status (Accepted → In Progress → Completed) | ✅ Assigned only |
| Upload resolution photos | ✅ Assigned only |
| Add notes to assigned issues | ✅ Assigned only |
| Request escalation | ✅ Assigned only |
| View other field workers' assignments | ❌ No |
| Assign or reassign issues | ❌ No |
| Access analytics dashboard | ❌ No |
| Access citizen personal data | ❌ No |

---

### ROLE: DEPT_SUPERVISOR

**Scope:** Own department within a municipality
**Created by:** Municipal Admin
**Access level:** Department-wide issue management and team oversight

| Permission | Access |
|---|---|
| View all issues in own department | ✅ Full |
| Assign issues to field workers | ✅ Full |
| Reassign, escalate, or reject issues | ✅ Full |
| Change issue priority | ✅ Full |
| Add internal notes to issues | ✅ Full |
| Merge duplicate reports | ✅ Full |
| View field worker workload | ✅ Own team only |
| View department analytics | ✅ Own department only |
| Configure SLA policies | ❌ No (read-only view) |
| Create or deactivate user accounts | ❌ No |
| Access other departments' data | ❌ No |

---

### ROLE: MUNICIPAL_ADMIN

**Scope:** All departments within own municipality
**Created by:** System Admin
**Access level:** Full municipality management

| Permission | Access |
|---|---|
| View issues across all departments | ✅ Full |
| View cross-department analytics | ✅ Full |
| Configure departments and categories | ✅ Full |
| Configure SLA policies | ✅ Full |
| Configure escalation rules | ✅ Full |
| Create and manage authority user accounts | ✅ Own municipality only |
| Export reports | ✅ Full |
| Schedule automated reports | ✅ Full |
| Manage municipality settings | ✅ Full |
| Access other municipalities' data | ❌ No |
| Manage platform-level settings | ❌ No |

---

### ROLE: SYSTEM_ADMIN

**Scope:** All municipalities on the platform
**Created by:** Platform operators (manual provisioning)
**Access level:** Full platform access

| Permission | Access |
|---|---|
| Onboard new municipalities | ✅ Full |
| Manage all users across all municipalities | ✅ Full |
| Access all municipality data | ✅ Full |
| View platform-wide audit logs | ✅ Full |
| Manage feature flags | ✅ Full |
| Manage webhook configurations | ✅ Full |
| View system health dashboard | ✅ Full |
| Override any role permission temporarily | ✅ With audit trail |

---

## Permission Matrix Summary

| Permission | CITIZEN | FIELD_WORKER | DEPT_SUPERVISOR | MUNICIPAL_ADMIN | SYSTEM_ADMIN |
|---|:---:|:---:|:---:|:---:|:---:|
| Submit report | ✅ | — | — | — | — |
| View own reports | ✅ | — | — | — | — |
| Verify resolution | ✅ | — | — | — | — |
| View assigned tasks | — | ✅ | — | — | — |
| Update task status | — | ✅ | — | — | — |
| Manage dept issues | — | — | ✅ | — | — |
| Assign field workers | — | — | ✅ | — | — |
| Dept analytics | — | — | ✅ | — | — |
| Municipality config | — | — | — | ✅ | — |
| Manage auth users | — | — | — | ✅ | — |
| Cross-dept analytics | — | — | — | ✅ | — |
| Onboard municipality | — | — | — | — | ✅ |
| Platform audit logs | — | — | — | — | ✅ |
| Feature flags | — | — | — | — | ✅ |

---

## Role Assignment Rules

1. **CITIZEN** roles are self-assigned at registration — no approval required
2. **FIELD_WORKER** accounts are created by DEPT_SUPERVISOR or MUNICIPAL_ADMIN
3. **DEPT_SUPERVISOR** accounts are created by MUNICIPAL_ADMIN only
4. **MUNICIPAL_ADMIN** accounts are created by SYSTEM_ADMIN only
5. **SYSTEM_ADMIN** accounts are provisioned directly in the system — not via the UI
6. A user can hold only one role at any time (roles are mutually exclusive)
7. Role changes require admin confirmation and generate an audit log entry

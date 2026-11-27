# CivicConnect — Application Modules

## Module Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CivicConnect Platform                         │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│   Identity   │    Issue     │  Operations  │      Intelligence      │
│   & Access   │  Lifecycle   │   Control    │      & Analytics       │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Notification │    Media     │  Geospatial  │  Platform Admin &      │
│   Engine     │  Management  │   Services   │  Configuration         │
└──────────────┴──────────────┴──────────────┴────────────────────────┘
```

---

## Module 1: Identity & Access Management (IAM)

**Purpose:** Handles all aspects of user identity, authentication, authorization, and session management.

**Responsibilities:**
- Citizen registration via mobile OTP and email
- OAuth 2.0 social login (Google)
- Government authority account management (admin-created only)
- JWT issuance, refresh, and revocation
- Role-Based Access Control (RBAC) enforcement
- Multi-Factor Authentication for admin accounts
- Password management (reset, change)
- Authentication event logging
- Account suspension and reactivation

**Key Entities:** User, Role, Permission, Session, OTPRecord

**Interfaces:** REST API, Spring Security filter chain

---

## Module 2: Issue Lifecycle Management

**Purpose:** Core module. Manages the entire lifecycle of a civic issue from submission to closure and citizen verification.

**Sub-modules:**

### 2a. Issue Submission
- Accept new issue reports from citizens
- Validate inputs (category, location, description, attachments)
- Detect and surface nearby duplicate reports
- Assign unique tracking ID
- Trigger auto-routing to correct department

### 2b. Issue Routing Engine
- Map issue category + municipality to responsible department
- Apply routing rules configured per municipality
- Support manual override by supervisors

### 2c. Issue Workflow Engine
- Manage state machine: `Draft → Submitted → Assigned → In Progress → Resolved → Verified / Reopened → Closed`
- Enforce valid state transitions
- Maintain complete history log of all transitions

### 2d. Issue Assignment
- Supervisor assigns/reassigns issues to field workers
- Auto-assignment rules (round-robin, workload-based) — configurable
- Escalation management

### 2e. Issue Resolution & Verification
- Field worker marks issue resolved with evidence photos
- Citizen receives notification to verify
- Citizen confirms or reopens
- Issue closed after verification or after auto-close timeout

**Key Entities:** Issue, IssueCategory, IssueHistory, IssueAssignment, IssueComment, IssueMedia

**Interfaces:** REST API, internal event bus (status change events)

---

## Module 3: Operations Control Center (Authority Dashboard)

**Purpose:** Provides government supervisors and field workers with the tools to manage their workload and track performance.

**Responsibilities:**
- Real-time issue queue for supervisors (filtered by department, ward, status, priority)
- Field worker task list and daily workload view
- Issue detail view with full history and internal notes
- Bulk operations (assign, escalate, close)
- SLA countdown indicators per issue
- Overdue issue alerts and escalation triggers
- Internal communication thread per issue
- Workload distribution view across field workers

**Key Entities:** Assignment, WorkOrder, EscalationRule, SLAPolicy, InternalNote

**Interfaces:** REST API, WebSocket for real-time updates

---

## Module 4: Intelligence & Analytics

**Purpose:** Transforms raw issue data into actionable insights for administrators, supervisors, and city planners.

**Responsibilities:**
- Executive dashboard (total open/resolved/overdue, by department)
- Interactive heatmap of issue locations
- Trend analysis over time (by category, ward, department)
- SLA compliance rate by department
- Average resolution time by category and department
- Top recurring issue types and locations
- Citizen satisfaction score aggregation
- Public statistics page
- Scheduled report generation and email delivery
- Data export (CSV, PDF)

**Key Entities:** ReportSnapshot, DepartmentMetric, SatisfactionScore, AnalyticsFilter

**Interfaces:** REST API (read-heavy), scheduled job runner

---

## Module 5: Notification Engine

**Purpose:** Centralized, multi-channel notification dispatch system.

**Responsibilities:**
- Push notifications (FCM for Android, APNs for iOS)
- Email notifications (transactional and scheduled)
- SMS notifications (via third-party gateway)
- Notification template management per municipality
- User notification preference management (opt-in/opt-out per channel)
- Delivery status tracking and retry logic
- Authority alert system (SLA breaches, escalations, new assignments)

**Key Entities:** NotificationTemplate, NotificationLog, UserNotificationPreference, NotificationChannel

**Interfaces:** Internal event consumer, REST API (preference management), external gateway APIs

---

## Module 6: Media Management

**Purpose:** Handles all file uploads, storage, processing, and delivery for issue evidence photos.

**Responsibilities:**
- Secure presigned URL generation for direct client-to-storage upload
- Image format validation and size enforcement
- Server-side EXIF metadata stripping
- Cloud object storage management (S3-compatible)
- CDN integration for fast global delivery
- Media linkage to issues (evidence, resolution proof)
- Media deletion on issue or account deletion

**Key Entities:** MediaAsset, MediaReference

**Interfaces:** REST API, Cloud Storage API, CDN

---

## Module 7: Geospatial Services

**Purpose:** Provides location intelligence across the platform — for report submission, duplicate detection, heatmaps, and ward routing.

**Responsibilities:**
- Reverse geocoding (GPS coordinates to human-readable address)
- Ward/jurisdiction boundary detection (point-in-polygon)
- Proximity search (issues within N meters of a point)
- Heatmap data generation for analytics
- Map tile serving integration (OpenStreetMap / Google Maps)
- Address validation and enrichment

**Key Entities:** Location, Ward, Municipality, BoundaryPolygon

**Interfaces:** REST API, PostGIS spatial queries, external geocoding API

---

## Module 8: Platform Administration & Configuration

**Purpose:** Enables system administrators to configure, onboard, and manage municipalities, users, and platform settings.

**Responsibilities:**
- Municipality onboarding (name, boundaries, departments, categories)
- Department management (CRUD)
- Issue category and subcategory management
- SLA policy configuration per category and severity
- Escalation rule configuration
- User account management (authority roles)
- System health and audit log viewer
- Webhook management for third-party integrations
- Feature flag management per municipality

**Key Entities:** Municipality, Department, CategoryConfig, SLAPolicy, EscalationRule, AdminAuditLog, FeatureFlag, WebhookConfig

**Interfaces:** Admin REST API, Admin Web UI

---

## Module Dependency Map

```
                    ┌──────────────────┐
                    │       IAM        │◄──── All Modules (Auth)
                    └──────────────────┘
                             │
              ┌──────────────▼────────────────┐
              │     Issue Lifecycle Mgmt      │
              │  (Core Domain — Orchestrator) │
              └──┬──────┬──────┬──────────────┘
                 │      │      │
       ┌─────────┘  ┌───┘  ┌───┘
       ▼            ▼      ▼
  Operations   Analytics  Notifications
  Control Ctr  Module     Engine
       │                      │
       │                      ▼
       └───────────► Media Management
                         │
                         ▼
                   Geospatial Services
                         │
                         ▼
               Platform Admin & Config
```

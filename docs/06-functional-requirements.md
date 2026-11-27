# CivicConnect — Functional Requirements

## FR-01: Authentication & Authorization

| ID | Requirement |
|---|---|
| FR-01.1 | The system shall allow citizens to register using mobile number with OTP verification |
| FR-01.2 | The system shall allow citizens to register and login using email and password |
| FR-01.3 | The system shall support OAuth 2.0 login via Google |
| FR-01.4 | Government authority users shall be created by system administrators only — no self-registration |
| FR-01.5 | The system shall issue JWT tokens with configurable expiry for all authenticated sessions |
| FR-01.6 | The system shall enforce Role-Based Access Control (RBAC) across all API endpoints |
| FR-01.7 | The system shall support account deactivation without data deletion |
| FR-01.8 | The system shall allow password reset via email or OTP |
| FR-01.9 | The system shall log all authentication events (login, logout, failed attempts) |

---

## FR-02: Issue Reporting (Citizen)

| ID | Requirement |
|---|---|
| FR-02.1 | Citizens shall be able to submit a civic issue report with a title, description, category, and location |
| FR-02.2 | Citizens shall be able to attach up to 5 photos per report |
| FR-02.3 | The system shall auto-capture GPS coordinates when a report is submitted |
| FR-02.4 | Citizens shall be able to manually pin the location on a map if GPS is unavailable or inaccurate |
| FR-02.5 | The system shall present matching open reports within a 200m radius before submission to reduce duplicates |
| FR-02.6 | Citizens shall be able to upvote an existing report instead of creating a duplicate |
| FR-02.7 | Every submitted report shall receive a unique alphanumeric tracking ID instantly |
| FR-02.8 | Citizens shall be able to submit a report anonymously (without login) |
| FR-02.9 | The system shall allow report drafts to be saved locally and submitted later |
| FR-02.10 | Citizens shall be able to add a report via a QR code scanned at a physical issue location (future-ready endpoint) |

---

## FR-03: Issue Tracking (Citizen)

| ID | Requirement |
|---|---|
| FR-03.1 | Citizens shall be able to view all reports they have submitted with current status |
| FR-03.2 | The system shall send push notifications to citizens at every status change of their report |
| FR-03.3 | Citizens shall be able to view a public feed of recent reports in their area |
| FR-03.4 | Citizens shall be able to filter the public feed by category, area, and status |
| FR-03.5 | Citizens shall receive an estimated resolution time based on issue category SLA at the time of submission |
| FR-03.6 | The system shall send a reminder notification if a report is unresolved past its SLA deadline |

---

## FR-04: Issue Resolution Feedback (Citizen)

| ID | Requirement |
|---|---|
| FR-04.1 | When a report is marked resolved by an authority, the reporting citizen shall receive a notification with photos of the resolution |
| FR-04.2 | Citizens shall be able to confirm resolution (mark as verified) or reject it (mark as unresolved) |
| FR-04.3 | If a citizen rejects a resolution, they shall be required to provide a reason and the issue shall be automatically reopened |
| FR-04.4 | Citizens shall be able to rate the quality of resolution on a 1–5 star scale |
| FR-04.5 | Citizens shall be able to leave a text comment on a resolved issue |

---

## FR-05: Issue Management (Department Staff)

| ID | Requirement |
|---|---|
| FR-05.1 | The system shall automatically route incoming issues to the correct department based on category and municipality configuration |
| FR-05.2 | Department supervisors shall be able to view all issues assigned to their department |
| FR-05.3 | Supervisors shall be able to assign issues to specific field workers |
| FR-05.4 | Supervisors shall be able to reassign, escalate, or reject issues with a mandatory reason |
| FR-05.5 | Supervisors shall be able to change issue priority (Low / Medium / High / Critical) |
| FR-05.6 | The system shall flag issues as overdue when the SLA deadline passes without resolution |
| FR-05.7 | Supervisors shall receive in-app and email alerts for SLA breaches |
| FR-05.8 | The system shall maintain a complete audit log of all status changes and assignments for every issue |
| FR-05.9 | Supervisors shall be able to add internal notes to an issue (not visible to citizens) |
| FR-05.10 | Supervisors shall be able to merge duplicate reports into a single primary report |

---

## FR-06: Field Worker Operations

| ID | Requirement |
|---|---|
| FR-06.1 | Field workers shall receive a task list of issues assigned to them |
| FR-06.2 | Field workers shall be able to navigate to the issue location via integrated map |
| FR-06.3 | Field workers shall be able to update issue status (Accepted, In Progress, Completed) |
| FR-06.4 | Field workers shall be able to upload before and after photos when marking an issue as resolved |
| FR-06.5 | Field workers shall be able to add notes and request additional resources |
| FR-06.6 | Field workers shall be able to mark an issue as requiring escalation if it is beyond their scope |

---

## FR-07: Administration & Configuration

| ID | Requirement |
|---|---|
| FR-07.1 | System administrators shall be able to onboard new municipalities with jurisdiction boundaries, departments, and categories |
| FR-07.2 | Administrators shall be able to create, update, and deactivate user accounts for authority roles |
| FR-07.3 | Administrators shall be able to configure SLA thresholds per issue category and severity level |
| FR-07.4 | Administrators shall be able to define and edit issue categories and subcategories |
| FR-07.5 | Administrators shall be able to map issue categories to responsible departments |
| FR-07.6 | Administrators shall be able to configure escalation rules (e.g., auto-escalate after 48 hours overdue) |
| FR-07.7 | Administrators shall be able to export all reports for a given date range as CSV or PDF |
| FR-07.8 | The system shall provide an audit trail for all administrative configuration changes |

---

## FR-08: Analytics & Reporting

| ID | Requirement |
|---|---|
| FR-08.1 | The system shall provide a real-time dashboard showing total open, in-progress, resolved, and overdue issues |
| FR-08.2 | The system shall display an interactive heatmap of issue locations across the municipality |
| FR-08.3 | The system shall provide trend charts showing issue volume over time by category |
| FR-08.4 | The system shall provide department-level performance metrics (average resolution time, SLA compliance rate) |
| FR-08.5 | The system shall allow filtering of all analytics by date range, department, category, ward, and status |
| FR-08.6 | The system shall provide a public-facing summary page showing aggregated city statistics |
| FR-08.7 | Authorized administrators shall be able to schedule and receive automated email reports |

---

## FR-09: Notifications

| ID | Requirement |
|---|---|
| FR-09.1 | The system shall send push notifications to citizens for all report status changes |
| FR-09.2 | The system shall send email notifications to authority users for SLA breaches and escalations |
| FR-09.3 | The system shall support SMS notifications for citizens without smartphones (via gateway integration) |
| FR-09.4 | Citizens shall be able to manage their notification preferences (push, email, SMS) |
| FR-09.5 | The system shall support notification templates configurable per municipality |

---

## FR-10: Media Management

| ID | Requirement |
|---|---|
| FR-10.1 | The system shall accept image uploads in JPG, PNG, and HEIC formats |
| FR-10.2 | The system shall compress images on the client side before upload to reduce bandwidth usage |
| FR-10.3 | Uploaded images shall be stored in cloud object storage with CDN delivery |
| FR-10.4 | The system shall strip EXIF metadata from uploaded images before storage for privacy |
| FR-10.5 | The system shall enforce a maximum file size of 10MB per image after compression |

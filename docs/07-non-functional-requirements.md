# CivicConnect — Non-Functional Requirements

## NFR-01: Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01.1 | API response time for standard read operations | < 300ms (p95) |
| NFR-01.2 | API response time for write operations (report submission) | < 500ms (p95) |
| NFR-01.3 | Dashboard data refresh latency | < 30 seconds |
| NFR-01.4 | Mobile app cold start time | < 3 seconds on mid-range Android device |
| NFR-01.5 | Image upload to CDN availability | < 5 seconds for a 5MB image on 4G |
| NFR-01.6 | Push notification delivery time after trigger | < 10 seconds |
| NFR-01.7 | Search and filter results for authority dashboards | < 1 second |

---

## NFR-02: Scalability

| ID | Requirement |
|---|---|
| NFR-02.1 | The system shall support horizontal scaling of all backend services without downtime |
| NFR-02.2 | The database layer shall support read replicas for analytics workloads without impacting transactional performance |
| NFR-02.3 | The system shall handle 10,000 concurrent users at launch with a clear path to 100,000 concurrent users |
| NFR-02.4 | The system shall process up to 50,000 issue submissions per day per municipality |
| NFR-02.5 | The platform shall support multi-tenant deployment — multiple municipalities on shared infrastructure with tenant isolation |
| NFR-02.6 | The image storage and CDN layer shall scale independently from the application tier |

---

## NFR-03: Availability & Reliability

| ID | Requirement | Target |
|---|---|---|
| NFR-03.1 | Platform uptime SLA | 99.9% (< 8.7 hours downtime per year) |
| NFR-03.2 | Citizen-facing report submission endpoint availability | 99.95% |
| NFR-03.3 | Recovery Time Objective (RTO) | < 1 hour |
| NFR-03.4 | Recovery Point Objective (RPO) | < 15 minutes |
| NFR-03.5 | The system shall support zero-downtime deployments via rolling updates or blue-green deployment |
| NFR-03.6 | The mobile app shall support offline report drafting when connectivity is unavailable |

---

## NFR-04: Security

| ID | Requirement |
|---|---|
| NFR-04.1 | All data in transit shall be encrypted using TLS 1.2 or higher |
| NFR-04.2 | All data at rest shall be encrypted using AES-256 |
| NFR-04.3 | JWT tokens shall have a maximum lifetime of 24 hours with refresh token rotation |
| NFR-04.4 | All API endpoints shall enforce authentication and RBAC except explicitly public endpoints |
| NFR-04.5 | The system shall rate-limit all public endpoints to prevent abuse (max 100 requests/minute per IP) |
| NFR-04.6 | All user inputs shall be validated and sanitized server-side to prevent SQL injection and XSS attacks |
| NFR-04.7 | Sensitive data fields (e.g., mobile numbers, email addresses) shall be masked in logs |
| NFR-04.8 | The system shall perform dependency vulnerability scanning in the CI/CD pipeline |
| NFR-04.9 | Admin panel access shall require Multi-Factor Authentication (MFA) |
| NFR-04.10 | The system shall maintain a complete security audit log of privilege operations |
| NFR-04.11 | Anonymous reports shall not store any PII linkable to the citizen |

---

## NFR-05: Maintainability

| ID | Requirement |
|---|---|
| NFR-05.1 | Backend services shall be structured as independently deployable modules (domain-based packaging) |
| NFR-05.2 | All public API contracts shall be documented via OpenAPI 3.0 (Swagger) |
| NFR-05.3 | Code coverage for unit tests shall be maintained at a minimum of 80% across backend services |
| NFR-05.4 | All configuration (database URLs, secrets, SLAs) shall be externalized via environment variables or a secrets manager |
| NFR-05.5 | The CI/CD pipeline shall enforce automated lint, test, and build checks on every pull request |
| NFR-05.6 | Infrastructure shall be defined as code (IaC) to enable reproducible environment provisioning |

---

## NFR-06: Usability

| ID | Requirement |
|---|---|
| NFR-06.1 | The mobile app shall achieve a System Usability Scale (SUS) score of 80+ in user testing |
| NFR-06.2 | The report submission flow shall be completable in 5 taps or fewer (happy path) |
| NFR-06.3 | The app shall support a minimum of 3 languages at launch, with an extensible localization framework |
| NFR-06.4 | The mobile app shall comply with WCAG 2.1 AA accessibility standards |
| NFR-06.5 | The authority web dashboard shall be responsive and usable on tablets in addition to desktops |
| NFR-06.6 | All error messages shall be human-readable and actionable |

---

## NFR-07: Data Integrity & Compliance

| ID | Requirement |
|---|---|
| NFR-07.1 | The system shall enforce optimistic locking on concurrent issue updates to prevent data corruption |
| NFR-07.2 | The system shall retain all issue records and their history for a minimum of 7 years |
| NFR-07.3 | Citizens shall have the right to request deletion of their account and personally identifiable information |
| NFR-07.4 | The system shall comply with applicable data protection regulations (e.g., PDPB in India, GDPR in EU jurisdictions) |
| NFR-07.5 | The system shall provide a data export mechanism for citizens to download their own data |

---

## NFR-08: Observability

| ID | Requirement |
|---|---|
| NFR-08.1 | All services shall emit structured logs (JSON format) to a centralized log aggregation system |
| NFR-08.2 | The system shall expose health check endpoints for all services |
| NFR-08.3 | Distributed tracing shall be implemented across all service calls |
| NFR-08.4 | Key business metrics (reports submitted, resolution rate, SLA breaches) shall be exposed as application metrics |
| NFR-08.5 | Alerting shall be configured for P1/P2 incidents with defined on-call escalation paths |

---

## NFR-09: Portability & Interoperability

| ID | Requirement |
|---|---|
| NFR-09.1 | The backend shall be deployable on any major cloud provider (AWS, GCP, Azure) or on-premise |
| NFR-09.2 | The system shall expose a versioned REST API (v1, v2) to enable third-party integrations |
| NFR-09.3 | The system shall support webhook notifications for third-party smart city platform integrations |
| NFR-09.4 | The mobile app shall support Android 8.0+ and iOS 14+ |

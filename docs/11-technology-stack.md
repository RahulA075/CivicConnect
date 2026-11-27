# CivicConnect — Technology Stack

## Stack Overview

| Layer | Technology | Rationale |
|---|---|---|
| Mobile App | Flutter 3.x (Dart) | Single codebase for Android + iOS, excellent performance, rich widget ecosystem |
| Web Dashboard | Flutter Web | Reuses Flutter components from mobile, avoids maintaining a separate React/Angular codebase |
| Backend Framework | Spring Boot 3.x (Java 21) | Mature, production-proven, strong ecosystem, excellent Spring Security and Spring Data support |
| Primary Database | PostgreSQL 16 + PostGIS | Robust relational DB with best-in-class geospatial extension for location features |
| Caching | Redis 7 | Industry-standard in-memory store for session, rate limiting, and reference data caching |
| Message Broker | RabbitMQ | Reliable async event delivery for notifications and decoupled module communication |
| Object Storage | AWS S3 (or GCS) | Scalable, cheap, CDN-integrable object storage for media assets |
| CDN | AWS CloudFront (or Cloudflare) | Global low-latency delivery for media files |
| Push Notifications | Firebase Cloud Messaging (FCM) | Supports both Android and iOS; reliable, free at scale |
| Email | AWS SES / SendGrid | Transactional email delivery with delivery rate monitoring |
| SMS | Twilio / local SMS gateway | SMS notifications for citizens; easily swappable per region |
| Maps | Google Maps SDK / OpenStreetMap (Leaflet) | Mobile uses Google Maps SDK; web dashboard can use Leaflet for cost flexibility |
| Geocoding | Google Maps Geocoding API / Nominatim | Reverse geocoding for address resolution from GPS coordinates |
| Auth (Social) | Google OAuth 2.0 | Widely used social login, well-supported by Spring Security OAuth2 |
| Container Runtime | Docker | Containerized deployments for consistency across environments |
| Orchestration | Kubernetes (K8s) | Production orchestration with HPA, rolling updates, and self-healing |
| CI/CD | GitHub Actions | Automated build, test, security scan, and deploy pipeline |
| IaC | Terraform | Reproducible, cloud-agnostic infrastructure provisioning |
| API Documentation | OpenAPI 3.0 (Springdoc) | Auto-generated API docs from Spring annotations |
| Monitoring | Prometheus + Grafana | Industry-standard metrics collection and visualization |
| Logging | ELK Stack (Elasticsearch, Logstash, Kibana) | Centralized structured log aggregation and search |
| Distributed Tracing | OpenTelemetry + Jaeger | Request tracing across service boundaries |
| Secret Management | HashiCorp Vault / AWS Secrets Manager | Externalized secret storage, no secrets in code or config files |

---

## Mobile Stack Detail (Flutter)

| Concern | Library / Package |
|---|---|
| State Management | Riverpod 2.x |
| Navigation | go_router |
| HTTP Client | Dio (with interceptors for auth) |
| Local Storage | Hive / flutter_secure_storage |
| Push Notifications | firebase_messaging |
| Maps | google_maps_flutter |
| Camera / Image Picker | image_picker |
| Image Compression | flutter_image_compress |
| Offline Support | drift (SQLite ORM) |
| Localization | flutter_localizations + intl |
| Dependency Injection | Riverpod providers |
| Form Validation | reactive_forms |
| Accessibility | Flutter built-in semantics |
| Analytics | Firebase Analytics |
| Crash Reporting | Firebase Crashlytics |
| Testing | flutter_test, mocktail, integration_test |

---

## Backend Stack Detail (Spring Boot)

| Concern | Library / Framework |
|---|---|
| Framework | Spring Boot 3.x |
| Language | Java 21 (LTS) with virtual threads (Project Loom) |
| Security | Spring Security 6.x (JWT + OAuth2 Resource Server) |
| Data Access | Spring Data JPA + Hibernate |
| Geospatial | Hibernate Spatial + PostGIS |
| Database Migration | Flyway |
| Caching | Spring Cache + Lettuce (Redis client) |
| Messaging | Spring AMQP (RabbitMQ) |
| Validation | Jakarta Bean Validation (Hibernate Validator) |
| API Docs | Springdoc OpenAPI 3 |
| Email | Spring Mail |
| Object Mapping | MapStruct |
| Testing | JUnit 5, Mockito, Testcontainers |
| Build Tool | Gradle (Kotlin DSL) |
| Code Quality | Checkstyle, SpotBugs, SonarQube |
| Observability | Micrometer + OpenTelemetry |

---

## Database Schema Strategy

| Aspect | Decision |
|---|---|
| Schema per municipality | No — single schema with `municipality_id` column on all entities (simpler, easier joins) |
| Geospatial data type | PostGIS `GEOMETRY(Point, 4326)` for GPS coordinates |
| Soft deletes | Yes — `deleted_at` timestamp instead of hard delete for data retention compliance |
| Audit fields | All entities carry `created_at`, `updated_at`, `created_by`, `updated_by` |
| UUID vs sequential ID | UUID v7 as primary key (time-ordered, globally unique, safe for distributed systems) |
| Full-text search | PostgreSQL native `tsvector` for issue description search |
| Migrations | Flyway managed, sequential versioned scripts, applied on startup |

---

## Justification for Key Choices

### Flutter for both Mobile and Web
Eliminates the need for separate Android, iOS, and web teams. Dart is strongly typed, performant, and the Flutter ecosystem is mature enough for production apps at this scale. The component reuse between mobile and web dashboard significantly reduces total development effort.

### Spring Boot Modular Monolith over Microservices
Microservices add significant operational complexity (network calls, distributed transactions, service discovery, independent deployments) that is not justified at v1.0. A modular monolith with clean domain boundaries gives development velocity now while preserving the option to extract services later if needed.

### PostgreSQL + PostGIS over MongoDB or a separate GIS system
The domain is highly relational (users, departments, issues, assignments all have strict FK relationships). PostGIS adds first-class geospatial capabilities without a separate system. This eliminates a join between two different databases.

### RabbitMQ over Kafka
For v1.0, RabbitMQ's simpler operational model, excellent Spring AMQP integration, and message-per-event semantics are a better fit than Kafka's log-based approach. Kafka would be considered if event sourcing or replay is required in a future version.

### Redis for caching and rate limiting
Combining session storage, distributed rate limiting, and reference data caching in a single Redis instance reduces infrastructure overhead. Redis Cluster can be introduced when replication and higher availability are needed.

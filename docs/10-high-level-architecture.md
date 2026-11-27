# CivicConnect — High-Level Architecture

## Architecture Style

CivicConnect follows a **Modular Monolith** architecture for the backend at v1.0, organized into well-defined domain modules with clear internal boundaries. This approach provides the simplicity of a monolith for initial development velocity while establishing module boundaries that allow extraction into microservices if scale demands it in the future.

The mobile app is a single Flutter codebase targeting Android and iOS. The authority dashboard is a separate Flutter Web application.

---

## High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT TIER                                     │
├────────────────────┬────────────────────────┬───────────────────────────────┤
│   Flutter Mobile   │   Flutter Web (Auth     │   Third-Party Integrations   │
│   App              │   Dashboard / Admin)    │   (Smart City, Open Data)    │
│   Android / iOS    │   Browser               │                               │
└────────┬───────────┴──────────┬─────────────┴────────────────┬──────────────┘
         │                      │                               │
         │         HTTPS / TLS 1.3                              │
         │                      │                               │
┌────────▼──────────────────────▼───────────────────────────────▼──────────────┐
│                           API GATEWAY / LOAD BALANCER                         │
│                     (Rate Limiting · Auth Token Validation ·                  │
│                      Request Routing · SSL Termination)                       │
└──────────────────────────────────┬────────────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼────────────────────────────────────────────┐
│                        SPRING BOOT BACKEND (Modular Monolith)                  │
│                                                                                │
│  ┌───────────────┐  ┌──────────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │  IAM Module   │  │  Issue Lifecycle  │  │  Operations    │  │ Analytics  │ │
│  │               │  │  Module           │  │  Module        │  │ Module     │ │
│  └───────────────┘  └──────────────────┘  └────────────────┘  └────────────┘ │
│                                                                                │
│  ┌───────────────┐  ┌──────────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │  Notification │  │  Media Module     │  │  Geospatial    │  │  Platform  │ │
│  │  Module       │  │                   │  │  Module        │  │  Admin     │ │
│  └───────────────┘  └──────────────────┘  └────────────────┘  └────────────┘ │
│                                                                                │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                    Internal Event Bus (Spring ApplicationEvent)          │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└─────────┬─────────────────┬──────────────────────────────────────┬────────────┘
          │                 │                                        │
┌─────────▼──────┐  ┌───────▼───────┐                    ┌─────────▼──────────┐
│  PostgreSQL     │  │  Redis Cache  │                    │  Message Queue     │
│  + PostGIS      │  │  (Session,    │                    │  (RabbitMQ /       │
│  Primary DB     │  │   Rate Limit, │                    │   Kafka for async  │
│  Read Replicas  │  │   Geo Cache)  │                    │   notifications)   │
└────────────────┘  └───────────────┘                    └────────────────────┘
                                                                     │
┌──────────────────────────────────────────────────────────────────┐ │
│                       EXTERNAL SERVICES                           │◄┘
│                                                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │  Firebase  │  │  AWS SES / │  │  Twilio /  │  │  Google    │  │
│  │  FCM /     │  │  SendGrid  │  │  SMS GW    │  │  Maps API  │  │
│  │  APNs      │  │  (Email)   │  │            │  │  / OSM     │  │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘  │
│                                                                    │
│  ┌────────────┐  ┌────────────┐                                   │
│  │  AWS S3 /  │  │  OAuth 2.0 │                                   │
│  │  GCS       │  │  Google    │                                   │
│  │ (Media)    │  │  Auth      │                                   │
│  └────────────┘  └────────────┘                                   │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE TIER                           │
│                                                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │  Docker /  │  │  CI/CD     │  │  Prometheus │  │  ELK Stack │  │
│  │  Kubernetes│  │  Pipeline  │  │  + Grafana  │  │  Logging   │  │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

---

## Issue Lifecycle — Request Flow

```
Citizen (Mobile App)
        │
        │  POST /api/v1/issues  (JWT + report payload + GPS)
        ▼
   API Gateway  ──► Auth validation ──► Rate limit check
        │
        ▼
   Issue Lifecycle Module
        │
        ├──► Validate input
        ├──► Geospatial Module: detect ward + nearby duplicates
        ├──► Persist issue to PostgreSQL (status = SUBMITTED)
        ├──► Media Module: generate presigned upload URLs
        ├──► Routing Engine: determine responsible department
        ├──► Issue Assignment: notify department queue
        │
        └──► Publish IssueSubmittedEvent to internal event bus
                    │
                    ├──► Notification Module: push notification to citizen
                    └──► Analytics Module: update real-time metrics
```

---

## Data Flow — Status Update by Field Worker

```
Field Worker (Mobile App)
        │
        │  PATCH /api/v1/issues/{id}/status  (JWT + new status + photos)
        ▼
   API Gateway
        │
        ▼
   Issue Lifecycle Module
        │
        ├──► RBAC check: field worker owns this assignment
        ├──► State machine validation: valid transition?
        ├──► Media Module: store resolution photos
        ├──► Persist status change + history entry to PostgreSQL
        │
        └──► Publish IssueStatusChangedEvent
                    │
                    ├──► Notification Module: push to citizen (issue resolved)
                    └──► Analytics Module: update resolution metrics
```

---

## Multi-Tenancy Model

- Every data entity carries a `municipality_id` foreign key
- API gateway enforces that the JWT's `municipality_id` claim matches the resource's municipality
- Analytics and configuration are strictly scoped per municipality
- Shared infrastructure (compute, database cluster) with logical row-level isolation
- Each municipality has its own set of departments, categories, SLAs, and routing rules

---

## Caching Strategy

| Cache Type | What Is Cached | TTL |
|---|---|---|
| Redis — Session | JWT refresh token metadata | 24 hours |
| Redis — Rate Limit | Request counters per IP | 1 minute rolling |
| Redis — Reference Data | Categories, departments, SLA configs | 10 minutes |
| Redis — Geo Cache | Ward boundary lookups | 1 hour |
| Redis — Analytics | Dashboard summary counts | 30 seconds |
| CDN | Media assets (photos) | 7 days |

---

## Security Architecture

```
Internet
   │
   ▼
[WAF — Web Application Firewall]
   │
   ▼
[API Gateway — SSL Termination, Rate Limiting]
   │
   ▼
[Spring Security Filter Chain]
   │
   ├── JWT Validation Filter
   ├── RBAC Authorization Filter
   ├── Request Validation / Input Sanitization
   └── Audit Logging Filter
         │
         ▼
   [Application Modules]
         │
         ▼
   [Database — Encrypted at Rest, TLS in Transit]
```

---

## Deployment Architecture (Kubernetes)

```
┌─────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                   │
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │  Namespace: civicconnect-prod                 │   │
│  │                                               │   │
│  │  ┌────────────┐   ┌────────────┐              │   │
│  │  │ Backend    │   │ Backend    │   ...         │   │
│  │  │ Pod (r1)   │   │ Pod (r2)   │   (N replicas)│   │
│  │  └────────────┘   └────────────┘              │   │
│  │                                               │   │
│  │  ┌────────────────────────────────────────┐   │   │
│  │  │  Horizontal Pod Autoscaler (HPA)        │   │   │
│  │  └────────────────────────────────────────┘   │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
│  ┌──────────────┐  ┌───────────┐  ┌──────────────┐   │
│  │ PostgreSQL   │  │   Redis   │  │  RabbitMQ    │   │
│  │ StatefulSet  │  │ StatefulSet│  │  StatefulSet │   │
│  └──────────────┘  └───────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────┘
```

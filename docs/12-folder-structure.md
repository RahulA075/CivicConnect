# CivicConnect — Folder Structure

## Repository Layout

CivicConnect uses a monorepo structure with three top-level workspaces:

```
civicconnect/
├── mobile/          # Flutter mobile app (Android + iOS)
├── dashboard/       # Flutter web dashboard (Authorities + Admin)
├── backend/         # Spring Boot modular monolith
├── infrastructure/  # Terraform IaC, Kubernetes manifests, Docker configs
├── docs/            # Project documentation (this folder)
└── .github/         # GitHub Actions CI/CD workflows
```

---

## Mobile App — Flutter (`mobile/`)

```
mobile/
├── android/                         # Android platform project (auto-generated)
├── ios/                             # iOS platform project (auto-generated)
├── assets/
│   ├── images/                      # Static image assets
│   ├── icons/                       # Custom icon assets
│   └── l10n/                        # ARB localization files
│       ├── app_en.arb
│       ├── app_hi.arb
│       └── app_mr.arb
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp / routing root
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart      # Environment config (base URL, keys)
│   │   │   └── flavor_config.dart   # Dev / staging / prod flavors
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── storage_keys.dart
│   │   ├── error/
│   │   │   ├── app_exception.dart
│   │   │   ├── failure.dart
│   │   │   └── error_handler.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart      # Dio HTTP client setup
│   │   │   ├── auth_interceptor.dart
│   │   │   └── network_info.dart    # Connectivity checker
│   │   ├── storage/
│   │   │   ├── secure_storage.dart  # flutter_secure_storage wrapper
│   │   │   └── local_database.dart  # Drift (SQLite) setup
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_typography.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── location_utils.dart
│   │       ├── image_utils.dart
│   │       └── validators.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── user_model.dart
│   │   │   │   │   └── token_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── logout_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_provider.dart
│   │   │       ├── pages/
│   │   │       │   ├── login_page.dart
│   │   │       │   ├── register_page.dart
│   │   │       │   └── otp_verification_page.dart
│   │   │       └── widgets/
│   │   │           ├── login_form.dart
│   │   │           └── social_login_button.dart
│   │   ├── issues/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── issue_remote_datasource.dart
│   │   │   │   │   └── issue_local_datasource.dart  # Offline drafts
│   │   │   │   ├── models/
│   │   │   │   │   ├── issue_model.dart
│   │   │   │   │   ├── issue_category_model.dart
│   │   │   │   │   └── nearby_issue_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── issue_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── issue.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── issue_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── submit_issue_usecase.dart
│   │   │   │       ├── get_my_issues_usecase.dart
│   │   │   │       ├── get_nearby_issues_usecase.dart
│   │   │   │       └── verify_resolution_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── issue_submission_provider.dart
│   │   │       │   └── my_issues_provider.dart
│   │   │       ├── pages/
│   │   │       │   ├── report_issue_page.dart
│   │   │       │   ├── issue_detail_page.dart
│   │   │       │   ├── my_issues_page.dart
│   │   │       │   ├── nearby_issues_page.dart
│   │   │       │   └── verify_resolution_page.dart
│   │   │       └── widgets/
│   │   │           ├── issue_card.dart
│   │   │           ├── category_selector.dart
│   │   │           ├── location_picker_map.dart
│   │   │           ├── photo_picker.dart
│   │   │           └── status_timeline.dart
│   │   ├── feed/
│   │   │   └── ...                  # Public issue feed feature
│   │   ├── notifications/
│   │   │   └── ...                  # Notification list + preferences
│   │   └── profile/
│   │       └── ...                  # Citizen profile management
│   └── shared/
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── loading_indicator.dart
│       │   ├── error_view.dart
│       │   └── empty_state_view.dart
│       └── extensions/
│           ├── context_extensions.dart
│           └── string_extensions.dart
├── test/
│   ├── unit/
│   │   └── features/
│   │       ├── auth/
│   │       └── issues/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
└── pubspec.lock
```

---

## Web Dashboard — Flutter Web (`dashboard/`)

```
dashboard/
├── assets/
│   └── l10n/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                        # Shared with mobile (ideally a shared package)
│   │   └── ...
│   └── features/
│       ├── auth/
│       ├── operations/              # Supervisor issue queue and assignment
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │       └── pages/
│       │           ├── operations_dashboard_page.dart
│       │           ├── issue_queue_page.dart
│       │           └── issue_detail_page.dart
│       ├── analytics/               # Charts, heatmaps, export
│       │   └── presentation/
│       │       └── pages/
│       │           ├── analytics_overview_page.dart
│       │           ├── heatmap_page.dart
│       │           └── reports_page.dart
│       ├── field_tasks/             # Field worker task list (also on mobile)
│       └── admin/                   # Municipal admin config screens
│           └── presentation/
│               └── pages/
│                   ├── department_config_page.dart
│                   ├── category_config_page.dart
│                   ├── sla_config_page.dart
│                   └── user_management_page.dart
├── test/
├── pubspec.yaml
└── pubspec.lock
```

---

## Backend — Spring Boot (`backend/`)

```
backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/civicconnect/
│   │   │       ├── CivicConnectApplication.java    # Entry point
│   │   │       ├── config/
│   │   │       │   ├── SecurityConfig.java
│   │   │       │   ├── JwtConfig.java
│   │   │       │   ├── RedisConfig.java
│   │   │       │   ├── RabbitMQConfig.java
│   │   │       │   ├── OpenApiConfig.java
│   │   │       │   └── WebMvcConfig.java
│   │   │       ├── common/
│   │   │       │   ├── audit/
│   │   │       │   │   ├── AuditableEntity.java    # Base entity with audit fields
│   │   │       │   │   └── AuditLogService.java
│   │   │       │   ├── exception/
│   │   │       │   │   ├── GlobalExceptionHandler.java
│   │   │       │   │   ├── ResourceNotFoundException.java
│   │   │       │   │   ├── AccessDeniedException.java
│   │   │       │   │   └── ValidationException.java
│   │   │       │   ├── response/
│   │   │       │   │   ├── ApiResponse.java        # Standard response wrapper
│   │   │       │   │   └── PagedResponse.java
│   │   │       │   ├── security/
│   │   │       │   │   ├── JwtTokenProvider.java
│   │   │       │   │   ├── JwtAuthenticationFilter.java
│   │   │       │   │   └── CurrentUser.java        # @CurrentUser annotation
│   │   │       │   └── util/
│   │   │       │       ├── SlugGenerator.java
│   │   │       │       └── TrackingIdGenerator.java
│   │   │       ├── modules/
│   │   │       │   ├── iam/                        # Identity & Access Module
│   │   │       │   │   ├── controller/
│   │   │       │   │   │   ├── AuthController.java
│   │   │       │   │   │   └── UserController.java
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── AuthService.java
│   │   │       │   │   │   ├── UserService.java
│   │   │       │   │   │   └── OtpService.java
│   │   │       │   │   ├── repository/
│   │   │       │   │   │   ├── UserRepository.java
│   │   │       │   │   │   └── OtpRepository.java
│   │   │       │   │   ├── entity/
│   │   │       │   │   │   ├── User.java
│   │   │       │   │   │   ├── Role.java
│   │   │       │   │   │   └── OtpRecord.java
│   │   │       │   │   └── dto/
│   │   │       │   │       ├── RegisterRequest.java
│   │   │       │   │       ├── LoginRequest.java
│   │   │       │   │       └── AuthResponse.java
│   │   │       │   ├── issue/                      # Issue Lifecycle Module
│   │   │       │   │   ├── controller/
│   │   │       │   │   │   ├── IssueController.java
│   │   │       │   │   │   └── IssuePublicController.java
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── IssueService.java
│   │   │       │   │   │   ├── IssueRoutingService.java
│   │   │       │   │   │   ├── IssueWorkflowService.java
│   │   │       │   │   │   └── DuplicateDetectionService.java
│   │   │       │   │   ├── repository/
│   │   │       │   │   │   ├── IssueRepository.java
│   │   │       │   │   │   └── IssueHistoryRepository.java
│   │   │       │   │   ├── entity/
│   │   │       │   │   │   ├── Issue.java
│   │   │       │   │   │   ├── IssueHistory.java
│   │   │       │   │   │   ├── IssueCategory.java
│   │   │       │   │   │   └── IssueMedia.java
│   │   │       │   │   ├── dto/
│   │   │       │   │   │   ├── IssueSubmitRequest.java
│   │   │       │   │   │   ├── IssueResponse.java
│   │   │       │   │   │   └── IssueStatusUpdateRequest.java
│   │   │       │   │   └── event/
│   │   │       │   │       ├── IssueSubmittedEvent.java
│   │   │       │   │       └── IssueStatusChangedEvent.java
│   │   │       │   ├── operations/                 # Operations Module
│   │   │       │   │   ├── controller/
│   │   │       │   │   │   ├── OperationsController.java
│   │   │       │   │   │   └── FieldWorkerController.java
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── AssignmentService.java
│   │   │       │   │   │   └── SlaMonitoringService.java
│   │   │       │   │   ├── repository/
│   │   │       │   │   │   └── AssignmentRepository.java
│   │   │       │   │   └── entity/
│   │   │       │   │       └── Assignment.java
│   │   │       │   ├── analytics/                  # Analytics Module
│   │   │       │   │   ├── controller/
│   │   │       │   │   │   └── AnalyticsController.java
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── AnalyticsService.java
│   │   │       │   │   │   └── ReportGenerationService.java
│   │   │       │   │   └── dto/
│   │   │       │   │       ├── DashboardSummaryResponse.java
│   │   │       │   │       └── HeatmapDataResponse.java
│   │   │       │   ├── notification/               # Notification Module
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── NotificationService.java
│   │   │       │   │   │   ├── PushNotificationService.java
│   │   │       │   │   │   ├── EmailNotificationService.java
│   │   │       │   │   │   └── SmsNotificationService.java
│   │   │       │   │   ├── listener/
│   │   │       │   │   │   └── IssueEventListener.java
│   │   │       │   │   ├── repository/
│   │   │       │   │   │   └── NotificationLogRepository.java
│   │   │       │   │   └── entity/
│   │   │       │   │       ├── NotificationTemplate.java
│   │   │       │   │       └── NotificationLog.java
│   │   │       │   ├── media/                      # Media Module
│   │   │       │   │   ├── controller/
│   │   │       │   │   │   └── MediaController.java
│   │   │       │   │   ├── service/
│   │   │       │   │   │   └── MediaStorageService.java
│   │   │       │   │   └── entity/
│   │   │       │   │       └── MediaAsset.java
│   │   │       │   ├── geospatial/                 # Geospatial Module
│   │   │       │   │   ├── service/
│   │   │       │   │   │   ├── GeocodingService.java
│   │   │       │   │   │   └── WardDetectionService.java
│   │   │       │   │   └── entity/
│   │   │       │   │       ├── Ward.java
│   │   │       │   │       └── Municipality.java
│   │   │       │   └── admin/                      # Platform Admin Module
│   │   │       │       ├── controller/
│   │   │       │       │   ├── AdminController.java
│   │   │       │       │   └── MunicipalityController.java
│   │   │       │       ├── service/
│   │   │       │       │   ├── MunicipalityService.java
│   │   │       │       │   ├── DepartmentService.java
│   │   │       │       │   └── SLAPolicyService.java
│   │   │       │       ├── repository/
│   │   │       │       │   └── MunicipalityRepository.java
│   │   │       │       └── entity/
│   │   │       │           ├── Department.java
│   │   │       │           ├── SLAPolicy.java
│   │   │       │           └── EscalationRule.java
│   │   └── resources/
│   │       ├── application.yml                    # Base config
│   │       ├── application-dev.yml                # Dev overrides
│   │       ├── application-staging.yml
│   │       ├── application-prod.yml
│   │       └── db/
│   │           └── migration/                     # Flyway migrations
│   │               ├── V1__create_users.sql
│   │               ├── V2__create_issues.sql
│   │               ├── V3__create_municipalities.sql
│   │               └── V4__create_notifications.sql
│   └── test/
│       └── java/
│           └── com/civicconnect/
│               ├── modules/
│               │   ├── iam/
│               │   │   ├── AuthControllerTest.java
│               │   │   └── AuthServiceTest.java
│               │   └── issue/
│               │       ├── IssueServiceTest.java
│               │       └── IssueRoutingServiceTest.java
│               └── integration/
│                   ├── IssueSubmissionIntegrationTest.java
│                   └── AuthIntegrationTest.java
├── build.gradle.kts
├── settings.gradle.kts
├── Dockerfile
└── .env.example
```

---

## Infrastructure (`infrastructure/`)

```
infrastructure/
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   │   └── main.tf
│   │   ├── staging/
│   │   │   └── main.tf
│   │   └── prod/
│   │       └── main.tf
│   └── modules/
│       ├── kubernetes/
│       ├── database/
│       ├── redis/
│       ├── storage/
│       └── networking/
├── kubernetes/
│   ├── base/
│   │   ├── backend-deployment.yaml
│   │   ├── backend-service.yaml
│   │   ├── configmap.yaml
│   │   └── hpa.yaml
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── prod/
└── docker/
    ├── docker-compose.yml          # Local development stack
    └── docker-compose.test.yml     # CI test stack
```

---

## CI/CD (`.github/workflows/`)

```
.github/
├── workflows/
│   ├── mobile-ci.yml               # Flutter lint, test, build APK/IPA
│   ├── backend-ci.yml              # Java lint, test, build JAR, Docker image
│   ├── backend-cd-staging.yml      # Deploy to staging on main branch merge
│   └── backend-cd-prod.yml         # Deploy to prod on release tag
└── CODEOWNERS
```

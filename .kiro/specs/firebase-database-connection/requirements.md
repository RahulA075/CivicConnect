# Requirements Document

## Introduction

Phase 14 of CivicConnect completes the end-to-end connection between the Flutter mobile app (`com.civicconnect.app`), the Spring Boot backend, Firebase Cloud Messaging (FCM), and the PostgreSQL database. The prior phases established all the code skeletons (FirebaseConfig, FcmPushService, NotificationController, firebase_messaging_service.dart) with stub credentials and placeholder configuration. This phase wires everything together with real credentials and verifies that the full pipeline — user login → FCM token registration → push notification delivery — works correctly in the development environment (`civicconnect-dev` Firebase project).

The deliverables are:
1. Real Firebase credentials injected into `firebase_options.dart` (Flutter) and `firebase-service-account.json` (backend).
2. `GoogleService-Info.plist` placed in the iOS Runner folder.
3. A `.env` file created from `.env.example` with real PostgreSQL and Firebase values.
4. A passing backend build (`gradlew bootJar -x test`).
5. A passing `flutter analyze` with zero errors.
6. An automated end-to-end integration test that validates FCM token registration and push delivery through the backend API.

---

## Glossary

- **FCM**: Firebase Cloud Messaging — Google's cross-platform push notification service used by CivicConnect for issue updates and emergency alerts.
- **Firebase_Project**: The Firebase project named `civicconnect-dev` that hosts the Android app (`com.civicconnect.app`) and the iOS app (`com.civicconnect.app`).
- **firebase_options.dart**: The Flutter file that holds per-platform Firebase configuration values (API keys, App IDs, Sender IDs, etc.).
- **GoogleService-Info.plist**: The iOS-specific Firebase configuration file that must reside at `mobile/ios/Runner/GoogleService-Info.plist`.
- **google-services.json**: The Android-specific Firebase configuration file that must reside at `mobile/android/app/google-services.json`.
- **Service_Account_JSON**: The Firebase Admin SDK credential file (a JSON private key) used by the Spring Boot backend to send push notifications server-side.
- **FCM_Token**: A device-scoped registration token issued by Firebase to the Flutter app, stored in the `device_tokens` PostgreSQL table.
- **Backend**: The Spring Boot 3.x application running on port 8080, connecting to PostgreSQL via Docker Compose.
- **Flutter_App**: The Flutter 3.x mobile application targeting Android and iOS with package name `com.civicconnect.app`.
- **Device_Token_API**: The REST endpoint `POST /api/v1/notifications/device-token` that accepts an FCM token and platform string from the Flutter app.
- **NotificationService**: The Spring Boot service class `NotificationServiceImpl` responsible for registering tokens, subscribing to topics, and dispatching push notifications.
- **FcmPushService**: The Spring Boot service class that wraps the Firebase Admin SDK for single-token, multicast, and topic sends.
- **FirebaseConfig**: The Spring Boot `@Configuration` class that initialises the Firebase Admin SDK from credentials at startup.
- **Stub_Values**: Placeholder strings in `firebase_options.dart` of the form `STUB_*` and `000000000000` that must be replaced with real Firebase project values before the app can connect to Firebase.
- **End_to_End_Test**: An automated integration test (using Spring Boot's `@SpringBootTest` + Testcontainers or mocking) that covers the path from token registration API call through database persistence to FCM dispatch.
- **docker-compose.yml**: The Docker Compose file in `backend/` that starts PostgreSQL and Redis for local development.
- **DotEnv_File**: The `backend/.env` file (not committed to source control) that supplies environment variables to the backend at runtime.
- **flutterfire_cli**: The FlutterFire CLI tool (`flutterfire configure`) that generates `firebase_options.dart` from the Firebase project.
- **EARS**: Easy Approach to Requirements Syntax — the structured natural-language pattern used for all acceptance criteria below.

---

## Requirements

### Requirement 1: Firebase Credentials in flutter_options.dart

**User Story:** As a mobile developer, I want `firebase_options.dart` to contain the real Firebase project credentials for `civicconnect-dev`, so that the Flutter app can initialise Firebase and receive FCM push notifications on Android and iOS.

#### Acceptance Criteria

1. THE `firebase_options.dart` SHALL contain no `STUB_*` strings and no all-zero App IDs (`1:000000000000:android:0000000000000000` or `1:000000000000:ios:0000000000000000`) after the credentials update is applied.
2. WHEN `flutter analyze` is executed against the mobile project, THE Flutter_App SHALL produce zero errors and zero warnings related to `firebase_options.dart`.
3. THE `firebase_options.dart` SHALL declare a valid `messagingSenderId` (numeric string, non-zero) that matches the `civicconnect-dev` Firebase project's sender ID for each platform (`android`, `ios`, `web`).
4. THE `firebase_options.dart` SHALL declare a valid `projectId` equal to `civicconnect-dev` for all three platforms.
5. THE `firebase_options.dart` SHALL declare a valid `iosBundleId` equal to `com.civicconnect.app` in the `ios` `FirebaseOptions` block.
6. WHEN the Flutter_App initialises Firebase using `DefaultFirebaseOptions.currentPlatform`, THE Firebase_Project SHALL accept the initialisation without throwing a `FirebaseException`.

---

### Requirement 2: iOS GoogleService-Info.plist Placement

**User Story:** As an iOS developer, I want `GoogleService-Info.plist` to be present in `mobile/ios/Runner/`, so that the iOS build includes the Firebase configuration bundle required by the FCM SDK and APNs integration.

#### Acceptance Criteria

1. THE `GoogleService-Info.plist` file SHALL be present at the path `mobile/ios/Runner/GoogleService-Info.plist`.
2. THE `GoogleService-Info.plist` SHALL contain a `BUNDLE_ID` value equal to `com.civicconnect.app`.
3. THE `GoogleService-Info.plist` SHALL contain a `PROJECT_ID` value equal to `civicconnect-dev`.
4. THE `GoogleService-Info.plist` SHALL contain a non-empty `GOOGLE_APP_ID` value matching the iOS app registered in the `civicconnect-dev` Firebase project.
5. IF the `GoogleService-Info.plist` is absent from `mobile/ios/Runner/` at iOS build time, THEN THE iOS build SHALL fail with a descriptive error message indicating the missing file.
6. THE `GoogleService-Info.plist` SHALL NOT be committed to source control (it MUST appear in `mobile/.gitignore` or the root `.gitignore`).

---

### Requirement 3: Android google-services.json Placement

**User Story:** As an Android developer, I want `google-services.json` to be present in `mobile/android/app/`, so that the Android build includes the Firebase configuration required by the FCM SDK.

#### Acceptance Criteria

1. THE `google-services.json` file SHALL be present at the path `mobile/android/app/google-services.json`.
2. THE `google-services.json` SHALL contain a `project_id` value equal to `civicconnect-dev`.
3. THE `google-services.json` SHALL contain a `package_name` value equal to `com.civicconnect.app` inside the `client` array.
4. IF the `google-services.json` is absent from `mobile/android/app/` at Android build time, THEN THE Android build SHALL fail at the Gradle sync step with a descriptive error.
5. THE `google-services.json` SHALL NOT be committed to source control (it MUST appear in `mobile/android/app/.gitignore` or the root `.gitignore`).

---

### Requirement 4: Backend .env Configuration

**User Story:** As a backend developer, I want a fully populated `backend/.env` file, so that the Spring Boot application can connect to PostgreSQL and initialise the Firebase Admin SDK without manual property overrides.

#### Acceptance Criteria

1. THE `backend/.env` file SHALL exist at `backend/.env` before the backend is started.
2. THE `backend/.env` SHALL define `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` with values that allow the Backend to establish a JDBC connection to the PostgreSQL instance started by `docker-compose.yml`.
3. THE `backend/.env` SHALL define `FCM_CREDENTIALS_PATH` with a value that resolves to a readable `firebase-service-account.json` file on the developer's machine, OR the `firebase-service-account.json` file SHALL be placed at `backend/src/main/resources/firebase-service-account.json` so that the classpath fallback in `FirebaseConfig` activates.
4. THE Service_Account_JSON referenced by `FCM_CREDENTIALS_PATH` SHALL be a valid Firebase Admin SDK service account for the `civicconnect-dev` project, containing `"type": "service_account"` and a `"project_id"` equal to `civicconnect-dev`.
5. THE `backend/.env` SHALL NOT be committed to source control (it MUST appear in `backend/.gitignore` or the root `.gitignore`).
6. WHEN the Backend starts with the populated `backend/.env`, THE `FirebaseConfig` SHALL log `"FCM: Firebase Admin SDK initialised successfully"` and SHALL NOT log `"FCM: no credentials found"`.
7. WHEN the Backend starts with the populated `backend/.env`, THE Spring Boot application SHALL reach the `ApplicationStartedEvent` (i.e., full startup) without throwing a `BeanCreationException` related to database connectivity or Firebase initialisation.

---

### Requirement 5: Backend Build Verification

**User Story:** As a backend developer, I want the backend to produce a runnable JAR via `.\gradlew.bat bootJar -x test`, so that I can confirm the code compiles and all Spring Boot auto-configuration resolves correctly with no compilation errors.

#### Acceptance Criteria

1. WHEN `.\gradlew.bat bootJar -x test` is executed in `backend/`, THE Gradle build SHALL exit with code `0`.
2. WHEN `.\gradlew.bat bootJar -x test` completes, THE output JAR SHALL exist at `backend/build/libs/civicconnect-*.jar`.
3. IF any Java source file under `backend/src/main/` contains a compilation error, THEN THE Gradle build SHALL exit with a non-zero exit code and print the offending file and line number.
4. THE compiled JAR SHALL include `FirebaseConfig.class`, `FcmPushService.class`, and `NotificationController.class` in the `com/civicconnect/` package hierarchy, confirming these classes were compiled and packaged.

---

### Requirement 6: Flutter Static Analysis

**User Story:** As a mobile developer, I want `flutter analyze` to pass with zero errors, so that the Flutter codebase is free of type errors, unused imports, and linting violations before running on a device.

#### Acceptance Criteria

1. WHEN `flutter analyze` is executed in `mobile/`, THE Flutter_App SHALL produce zero analysis errors.
2. WHEN `flutter analyze` is executed in `mobile/`, THE Flutter_App SHALL produce zero analysis errors in `firebase_options.dart`, `main.dart`, `app.dart`, and `firebase_messaging_service.dart`.
3. THE `analysis_options.yaml` in `mobile/` SHALL enforce at minimum the rules from `package:flutter_lints/flutter.yaml`, and all source files SHALL comply with those rules.
4. IF any Dart source file contains an `undefined_identifier` or `invalid_assignment` error referencing Firebase types, THEN `flutter analyze` SHALL report that error with the file path and line number.

---

### Requirement 7: End-to-End FCM Token Registration Test

**User Story:** As a QA engineer, I want an automated integration test that registers an FCM token through the REST API and verifies it is persisted in PostgreSQL, so that I can confirm the token registration pipeline is fully operational.

#### Acceptance Criteria

1. THE End_to_End_Test SHALL send a valid JWT-authenticated `POST /api/v1/notifications/device-token` request with a well-formed FCM token string and platform `android`.
2. WHEN THE End_to_End_Test posts the token, THE Device_Token_API SHALL return HTTP 200 with body `{"status":"OK","message":"Device token registered"}`.
3. WHEN THE End_to_End_Test posts the token, THE `device_tokens` table in PostgreSQL SHALL contain exactly one active row (`is_active = TRUE`) for the submitted token value.
4. WHEN the same FCM token is posted a second time, THE Backend SHALL deactivate the previous row (`is_active = FALSE`) and insert a new active row, so that the `device_tokens` table contains exactly one active row for that token after the second registration.
5. WHEN a `DELETE /api/v1/notifications/device-token` request is sent with the registered token, THE Backend SHALL set `is_active = FALSE` on that row in `device_tokens`, and the Device_Token_API SHALL return HTTP 200.
6. THE End_to_End_Test SHALL be executable via `.\gradlew.bat test --tests "*FcmTokenRegistrationTest*"` and SHALL pass without requiring a live Firebase connection (FCM dispatch SHALL be mocked using a test double for `FcmPushService`).

---

### Requirement 8: End-to-End Push Notification Delivery Test

**User Story:** As a QA engineer, I want an automated test that verifies a push notification is dispatched via `FcmPushService` when `NotificationService.send()` is called for a user who has a registered FCM token, so that I can confirm the full notification dispatch pipeline works correctly.

#### Acceptance Criteria

1. THE End_to_End_Test SHALL create a test user with an active device token in the database, then call `NotificationService.send()` with event type `ISSUE_STATUS_CHANGED`, channel `PUSH`, and a valid `issueId`.
2. WHEN `NotificationService.send()` is invoked for a user with one active token, THE FcmPushService SHALL have its `sendToToken()` method called exactly once with the correct token, title, and body.
3. WHEN `NotificationService.send()` is invoked for a user with two or more active tokens, THE FcmPushService SHALL have its `sendMulticast()` method called exactly once with all active token values included in the list.
4. WHEN `NotificationService.send()` is invoked, THE `notifications` table in PostgreSQL SHALL contain a persisted `Notification` row with matching `event_type`, `user_id`, and `issue_id`.
5. WHEN a user has `push_enabled = FALSE` in `notification_preferences`, THE FcmPushService SHALL have neither `sendToToken()` nor `sendMulticast()` called, even when `NotificationService.send()` is invoked with channel `PUSH`.
6. THE test described in this requirement SHALL be runnable via `.\gradlew.bat test --tests "*FcmPushDispatchTest*"` and SHALL pass using a Mockito mock for `FcmPushService` so that no real Firebase connection is needed.

---

### Requirement 9: Stale Token Deactivation on FCM Error

**User Story:** As a backend developer, I want stale or invalid FCM tokens to be automatically deactivated in the database when Firebase returns an `UNREGISTERED` or `INVALID_ARGUMENT` error, so that the `device_tokens` table does not accumulate dead tokens that waste API calls.

#### Acceptance Criteria

1. WHEN `FcmPushService.sendToToken()` receives a `FirebaseMessagingException` with error code `UNREGISTERED`, THE FcmPushService SHALL log a warning message containing the abbreviated token and the phrase `"stale/invalid token"`.
2. WHEN `FcmPushService.sendToToken()` receives a `FirebaseMessagingException` with error code `INVALID_ARGUMENT`, THE FcmPushService SHALL log a warning message containing the abbreviated token and the phrase `"stale/invalid token"`.
3. THE NotificationService SHALL expose a method `deactivateStaleToken(String token)` that sets `is_active = FALSE` on the matching row in `device_tokens`.
4. WHEN `FcmPushService.sendToToken()` encounters an `UNREGISTERED` or `INVALID_ARGUMENT` error, THE NotificationService SHALL call `deactivateStaleToken()` with the offending token within the same execution context.
5. WHEN `FcmPushService.sendMulticast()` completes and the `BatchResponse` contains failed responses with error codes `UNREGISTERED` or `INVALID_ARGUMENT`, THE NotificationService SHALL call `deactivateStaleToken()` for each corresponding failed token.

---

### Requirement 10: Configuration Documentation

**User Story:** As a new developer joining the project, I want a `FIREBASE_SETUP.md` guide in the repository, so that I can set up real Firebase credentials for both the Flutter app and the backend in under 30 minutes without needing to ask a team member.

#### Acceptance Criteria

1. THE repository SHALL contain a `FIREBASE_SETUP.md` file at the path `docs/FIREBASE_SETUP.md`.
2. THE `FIREBASE_SETUP.md` SHALL describe the exact steps to generate and place `firebase-service-account.json` for the backend, including the Firebase Console navigation path (Project Settings → Service Accounts → Generate new private key).
3. THE `FIREBASE_SETUP.md` SHALL describe the exact steps to run `flutterfire configure` (or manually populate `firebase_options.dart`) and download `google-services.json` and `GoogleService-Info.plist`.
4. THE `FIREBASE_SETUP.md` SHALL list every environment variable in `.env.example` that is required for Phase 14 to function, with a description of where to obtain each value.
5. THE `FIREBASE_SETUP.md` SHALL include a verification checklist that a developer can run through to confirm the setup is complete before running the app or tests.

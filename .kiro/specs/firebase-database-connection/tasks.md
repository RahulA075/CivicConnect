# Implementation Tasks — Phase 14: Firebase + Database Connection

## Tasks

- [x] 1. Verify and update .gitignore entries for credential files
  - Root `.gitignore` created with all credential file exclusions
  - **Requirement:** 2.6, 3.5, 4.5
  - **Files:** `D:\CiviConnect\.gitignore`

- [x] 2. Update firebase_options.dart with real Firebase credentials
  - Replaced all `STUB_*` values with real `civicconnect-2026` credentials
  - Android appId: `1:1010727451423:android:84b2d8d119118e11f70e2a`
  - iOS appId: `1:1010727451423:ios:99430d33152fa0f0f70e2a`
  - messagingSenderId: `1010727451423` for all platforms
  - **Requirement:** 1.1, 1.3, 1.4, 1.5
  - **Files:** `mobile/lib/firebase_options.dart`

- [x] 3. Place Android google-services.json
  - File placed at `mobile/android/app/google-services.json`
  - project_id: `civicconnect-2026`, package_name: `com.civicconnect.app`
  - **Requirement:** 3.1, 3.2, 3.3
  - **Files:** `mobile/android/app/google-services.json`

- [x] 4. Place iOS GoogleService-Info.plist
  - File placed at `mobile/ios/Runner/GoogleService-Info.plist`
  - BUNDLE_ID: `com.civicconnect.app`, PROJECT_ID: `civicconnect-2026`
  - GOOGLE_APP_ID: `1:1010727451423:ios:99430d33152fa0f0f70e2a`
  - **Requirement:** 2.1, 2.2, 2.3, 2.4
  - **Files:** `mobile/ios/Runner/GoogleService-Info.plist`

- [x] 5. Create backend/.env from .env.example
  - Copied `.env.example` → `.env`
  - DB credentials match `docker-compose.yml` defaults
  - FCM credentials path commented out — classpath file used instead
  - **Requirement:** 4.1, 4.2, 4.3
  - **Files:** `backend/.env`

- [x] 6. Add stale token deactivation callback to FcmPushService
  - Added `@Setter Consumer<String> staleTokenCallback` (default no-op)
  - `handleFcmError()` now calls `staleTokenCallback.accept(token)` for UNREGISTERED/INVALID_ARGUMENT
  - `sendMulticast()` iterates `BatchResponse` and calls callback for each failed token
  - **Requirement:** 9.1, 9.2, 9.5
  - **Files:** `backend/src/main/java/com/civicconnect/modules/notification/service/FcmPushService.java`

- [x] 7. Add deactivateStaleToken to NotificationServiceImpl and wire callback
  - Added `deactivateStaleToken(String token)` — calls `deviceTokenRepository.deactivateByToken()`
  - Added `@PostConstruct wireStaleTokenCallback()` — wires `this::deactivateStaleToken` into `FcmPushService`
  - **Requirement:** 9.3, 9.4
  - **Files:** `backend/src/main/java/com/civicconnect/modules/notification/service/NotificationServiceImpl.java`

- [x] 8. Verify backend build passes
  - `.\gradlew.bat bootJar -x test` → **BUILD SUCCESSFUL in 25s**
  - JAR at `backend/build/libs/civicconnect.jar`
  - **Requirement:** 5.1, 5.2

- [x] 9. Run flutter analyze and fix any issues
  - `flutter analyze` → **zero errors** in Firebase files
  - 94 pre-existing info/warning notes (style: `withOpacity`, `const`, unused imports) — not errors
  - `firebase_options.dart`, `main.dart`, `app.dart`, `firebase_messaging_service.dart` — all clean
  - **Requirement:** 6.1, 6.2

- [ ] 10. Write FcmTokenRegistrationTest integration test
  - Create `backend/src/test/java/com/civicconnect/integration/FcmTokenRegistrationTest.java`
  - Annotate with `@SpringBootTest(webEnvironment = RANDOM_PORT)` and `@Tag("integration")`
  - Use `@MockBean FcmPushService` to avoid real Firebase calls
  - Use Testcontainers PostgreSQL (already in `build.gradle.kts`)
  - Test 1: `POST /api/v1/notifications/device-token` → HTTP 200, one `is_active=TRUE` row
  - Test 2: Same token posted twice → first row `is_active=FALSE`, one active row total
  - Test 3: `DELETE /api/v1/notifications/device-token` → HTTP 200, row `is_active=FALSE`
  - **Requirement:** 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
  - **Files:** `backend/src/test/java/com/civicconnect/integration/FcmTokenRegistrationTest.java`

- [ ] 11. Write FcmPushDispatchTest integration test
  - Create `backend/src/test/java/com/civicconnect/integration/FcmPushDispatchTest.java`
  - Annotate with `@SpringBootTest` and `@Tag("integration")`
  - Use `@MockBean FcmPushService`
  - Test 1: 1 active token → `sendToToken()` called exactly once, `Notification` row persisted
  - Test 2: 2 active tokens → `sendMulticast()` called once with both tokens
  - Test 3: `push_enabled=FALSE` preference → neither FCM method called
  - Test 4: `send()` invoked → `notifications` table row has correct `event_type`, `user_id`, `issue_id`
  - **Requirement:** 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
  - **Files:** `backend/src/test/java/com/civicconnect/integration/FcmPushDispatchTest.java`

- [x] 12. Create docs/FIREBASE_SETUP.md developer guide
  - Full setup guide with project details, step-by-step credential placement, env var table, verification checklist, and troubleshooting
  - **Requirement:** 10.1, 10.2, 10.3, 10.4, 10.5
  - **Files:** `docs/FIREBASE_SETUP.md`

- [ ] 13. End-to-end smoke test with real credentials (manual)
  - Start the dev stack: `docker compose up -d` then `.\gradlew.bat bootRun`
  - Confirm log line: `FCM: Firebase Admin SDK initialised successfully`
  - Run Flutter app on a real Android/iOS device or emulator
  - Confirm `[FCM] Token registered with backend` in Flutter logs
  - Confirm row in `device_tokens` table with `is_active = TRUE`
  - **Requirement:** 4.6, 4.7, 1.6

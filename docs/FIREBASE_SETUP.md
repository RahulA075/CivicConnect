# Firebase Setup Guide — CivicConnect

This guide gets the full Firebase + push notification pipeline running in under 30 minutes.

---

## Prerequisites

- Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)
- Flutter SDK installed
- Docker Desktop running (for the backend database stack)

---

## Project Details

| Field | Value |
|---|---|
| Firebase Project ID | `civicconnect-2026` |
| Project Number / Sender ID | `1010727451423` |
| Android Package Name | `com.civicconnect.app` |
| iOS Bundle ID | `com.civicconnect.app` |
| Storage Bucket | `civicconnect-2026.firebasestorage.app` |

---

## Step 1 — Backend: Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com) → **CivicConnect** project
2. Click the gear icon → **Project Settings** → **Service accounts** tab
3. Click **"Generate new private key"** → confirm → download the JSON file
4. Place the file at:
   ```
   backend/src/main/resources/firebase-service-account.json
   ```
   The `FirebaseConfig` class picks it up from the classpath automatically.
   No `.env` change needed when using the classpath location.

> ⚠️ **Never commit this file.** It is in `.gitignore`.

---

## Step 2 — Android: google-services.json

1. Firebase Console → **Project Settings** → **Your apps**
2. Select the Android app (`com.civicconnect.app`) or click **"+ Add app"** → Android
3. Download `google-services.json`
4. Place at:
   ```
   mobile/android/app/google-services.json
   ```

> ⚠️ **Never commit this file.** It is in `.gitignore`.

---

## Step 3 — iOS: GoogleService-Info.plist

1. Firebase Console → **Project Settings** → **Your apps**
2. Select the iOS app (`com.civicconnect.app`) or click **"+ Add app"** → iOS
3. Download `GoogleService-Info.plist`
4. Place at:
   ```
   mobile/ios/Runner/GoogleService-Info.plist
   ```

> ⚠️ **Never commit this file.** It is in `.gitignore`.

---

## Step 4 — Flutter: firebase_options.dart

`firebase_options.dart` is already populated with the real `civicconnect-2026` credentials.

If you ever need to regenerate it (e.g. after adding a new platform):

```bash
dart pub global activate flutterfire_cli
cd mobile
flutterfire configure --project=civicconnect-2026
```

---

## Step 5 — Backend: .env

Copy the example and fill in real values:

```bash
cp backend/.env.example backend/.env
```

Required variables for Phase 14:

| Variable | Description | Value |
|---|---|---|
| `DB_URL` | JDBC connection string | `jdbc:postgresql://localhost:5432/civicconnect` |
| `DB_USERNAME` | PostgreSQL user | `civicconnect_app` (matches `docker-compose.yml`) |
| `DB_PASSWORD` | PostgreSQL password | `changeme` (matches `docker-compose.yml` default) |
| `FCM_CREDENTIALS_PATH` | Path to service account JSON | Leave blank if file is at `src/main/resources/firebase-service-account.json` |
| `JWT_SECRET` | JWT signing secret (≥64 chars) | Generate a random 64+ char string |
| `AI_API_KEY` | OpenAI / Gemini API key | From your AI provider dashboard |

> `FCM_CREDENTIALS_PATH` is optional when the JSON is in the classpath location (Step 1).

---

## Verification Checklist

Run through these in order after placing all credential files:

- [ ] **Backend builds:** `cd backend && .\gradlew.bat bootJar -x test` → `BUILD SUCCESSFUL`
- [ ] **Backend starts:** `docker compose up -d && .\gradlew.bat bootRun`  
  Look for log line: `FCM: Firebase Admin SDK initialised successfully`  
  (If you see `FCM: no credentials found`, the JSON file path is wrong)
- [ ] **Flutter analyzes:** `cd mobile && flutter analyze` → zero errors  
  (infos and warnings about `withOpacity` / `const` are pre-existing style notes, not errors)
- [ ] **Token registered:** Run the Flutter app on a device/emulator, log in  
  Look for Flutter log: `[FCM] Token registered with backend`
- [ ] **Database row:** Query `SELECT * FROM device_tokens WHERE is_active = TRUE;`  
  You should see a row for your device with a real FCM token

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `FCM: no credentials found` | JSON not found at classpath or path | Check file is at `backend/src/main/resources/firebase-service-account.json` |
| `FCM: Failed to initialise` | Invalid JSON or wrong project | Regenerate key from Firebase Console |
| `[FCM] Could not get token` | App not connected to Firebase | Check `google-services.json` / `GoogleService-Info.plist` match the project |
| `[FCM] Failed to register token` | Backend not running or wrong base URL | Check backend is up on port 8080 and `DioClient` base URL is correct |
| Build error: `google-services.json not found` | File missing or in wrong location | Must be at `mobile/android/app/google-services.json` |

# MiningGuard — Developer Setup & Run Guide

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | 3.19+ | `flutter --version` to check |
| Dart | 3.3+ | Bundled with Flutter |
| Node.js | 18+ | Required for Firebase CLI |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| Java | 11 or 17 | **Do not use Java 21+** — Firestore emulator JAR crashes on Java 21+ |

> Check your Java version: `java -version`
> If you have Java 21+, install Java 17 from https://adoptium.net and point `JAVA_HOME` to it.

---

## Project Structure

```
miningguard/
├── mobile/      Flutter app (all Phase 2 code lives here)
├── firebase/    firebase.json, Firestore rules, indexes
├── backend/     FastAPI AI backend (Phase 6+)
└── docs/        This file and architecture docs
```

---

## Running the App (Phase 1 & 2)

You need **two terminals open at the same time**.

### Terminal 1 — Firebase Emulators

```bash
cd miningguard/firebase
firebase emulators:start --only auth,firestore --project mininggaurd
```

Leave this running. You should see:

```
│ Authentication │ 127.0.0.1:9099 │
│ Firestore      │ 127.0.0.1:8081 │
```

The Emulator UI opens at http://127.0.0.1:4000 — use it to inspect users and Firestore documents.

> If port 4000 is taken, the UI won't load but the emulators still work fine.
> If port 8080 is taken, make sure you're running from the `firebase/` folder so it picks up `firebase.json` (which sets Firestore to port 8081).

### Terminal 2 — Flutter App

```bash
cd miningguard/mobile
flutter pub get          # first time only
flutter run -d chrome    # runs in Chrome (web)
```

The app opens in Chrome at `http://localhost:PORT`.

---

## First-Time Login Flow

The emulators start empty — there are no users. You must **create an account first**.

1. Open the app in Chrome
2. On the login screen, tap **"Create Account"** (below the Sign In button)
3. Enter any email and password (minimum 6 characters)
4. You'll be redirected to the **Signup / Onboarding screen**
5. Fill in: Full Name, Mine ID, Department, Shift, Role
6. Choose your preferred language
7. You land on the **Worker Home** screen

On future runs, use **Sign In** with the same credentials.

---

## Role-Based Routing

After login, the app routes based on the `role` field in Firestore:

| Role | Destination |
|------|-------------|
| `worker` | `/worker/home` |
| `supervisor` | `/supervisor/dashboard` |
| `admin` | `/admin/panel` |

To test supervisor/admin routing, go to the Emulator UI → Firestore → `users` collection → find your document → change the `role` field → sign out and sign back in.

---

## Firebase Configuration

The app's Firebase config is in [mobile/lib/firebase_options.dart](../mobile/lib/firebase_options.dart).

It is already configured for the `mininggaurd` Firebase project. In debug mode, the app automatically connects to the local emulators (Auth on 9099, Firestore on 8081) instead of the real Firebase project.

To use **real Firebase** instead of emulators, remove or comment out this block in [mobile/lib/main.dart](../mobile/lib/main.dart):

```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8081);
}
```

Then ensure the real Firebase project has:
- Authentication → Sign-in method → **Email/Password** enabled
- **Firestore Database** created (start in test mode)

---

## Deploying Firestore Security Rules

```bash
cd miningguard/firebase
firebase login
firebase use mininggaurd
firebase deploy --only firestore:rules,firestore:indexes
```

---

## Integration Tests

Tests run against the emulators. Start the emulators first (Terminal 1 above), then:

```bash
cd miningguard/mobile
flutter test integration_test/auth_flow_test.dart
```

Five tests are included:
1. Email sign-in routes worker to `/worker/home`
2. Wrong password shows error and stays on login
3. New user goes through onboarding → language selection → home
4. Supervisor routes to `/supervisor/dashboard`
5. Sign out clears session and returns to `/login`

---

## Common Issues

**`firestore: Port 8080 is not open`**
You ran the emulator from the wrong folder. Always run from `miningguard/firebase/`, not from `mobile/`.

**`demo-no-project` in emulator output**
Always pass `--project mininggaurd` when starting emulators.

**`Authentication failed` / `Sign in failed`**
- Make sure emulators are running before the Flutter app
- Use **Create Account** on first run (emulators start empty)
- Make sure you ran from `miningguard/firebase/` with `--project mininggaurd`

**`No Directionality widget found`**
Hot restart the app (`R` in Flutter terminal). This clears stale widget tree state.

**`flutter_sound_web` compile error**
Run `flutter pub upgrade` — the `web` package version conflict is resolved by the current `pubspec.yaml`.

**Firestore emulator crashes immediately (exit code 3221225786)**
You are running Java 21+. Downgrade to Java 17.

---

## Phase Status

- [x] Phase 1 — Project Foundation & Setup
- [x] Phase 2 — Authentication & User Management
- [ ] Phase 3 — Daily Safety Checklist
- [ ] Phase 4 — Hazard Reporting System
- [ ] Phase 5 — Safety Education Module
- [ ] Phase 6 — AI Backend & Machine Learning
- [ ] Phase 7 — Dashboards & Analytics
- [ ] Phase 8 — Notifications & Real-Time Sync
- [ ] Phase 9 — Multi-Language, Offline & Security
- [ ] Phase 10 — Testing, Deployment & Launch

# MiningGuard — Developer Setup Guide

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | 3.19+ | https://flutter.dev/docs/get-started/install |
| Dart | 3.3+ | Bundled with Flutter |
| Python | 3.11+ | https://python.org |
| Node.js | 18+ | https://nodejs.org (for Firebase CLI) |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| FlutterFire CLI | Latest | `dart pub global activate flutterfire_cli` |

---

## 1. Clone the Repository

```bash
git clone https://github.com/YOUR_ORG/miningguard.git
cd miningguard
```

## 2. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Create a new project named `miningguard-dev`
3. Enable the following services:
   - **Authentication** → Sign-in methods: Email/Password and Phone
   - **Firestore** → Start in test mode (rules deployed below)
   - **Storage** → Start in test mode
   - **Cloud Messaging** → No setup needed, enabled by default

## 3. Configure Flutter with Firebase

```bash
cd mobile
flutterfire configure --project=miningguard-dev
```

This generates `lib/firebase_options.dart` with your real project values.

## 4. Set Up Flutter App

```bash
cd mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## 5. Set Up FastAPI Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

Download your Firebase service account key:
- Firebase Console → Project Settings → Service Accounts → Generate new private key
- Save as `backend/firebase-service-account.json`
- **Never commit this file to git**

```bash
cp .env.example .env
# Edit .env with your project values
uvicorn app.main:app --reload --port 8000
```

Confirm: Open http://localhost:8000/health — should return `{"status": "healthy"}`.

## 6. Deploy Firebase Rules

```bash
cd firebase
firebase login
firebase use miningguard-dev
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

## 7. Start Firebase Emulators (Optional — for local development)

```bash
cd firebase
firebase emulators:start
```

Emulator UI available at http://localhost:4000

---

## Troubleshooting

**`google-services.json` not found:** Run `flutterfire configure` again.

**Firebase Admin SDK error:** Ensure `firebase-service-account.json` is in `backend/` and `FIREBASE_CREDENTIALS_PATH` in `.env` points to it.

**Flutter build fails:** Run `flutter clean && flutter pub get` then retry.

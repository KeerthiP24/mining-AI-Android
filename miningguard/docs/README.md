# ⛏️ MiningGuard — Run Guide (VS Code)

Full setup and run commands for the Flutter app + FastAPI AI backend.

---

## Prerequisites — Install These First

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | ≥ 3.19 | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Python | ≥ 3.11 | https://python.org/downloads |
| Git | Any | https://git-scm.com |
| VS Code | Latest | https://code.visualstudio.com |

### VS Code Extensions to Install
Open VS Code → Extensions (`Ctrl+Shift+X`) → search and install:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)
- **Python** (by Microsoft)
- **REST Client** (by Huachao Mao) — optional, for testing API

---

## 1. Clone & Open the Project

```bash
git clone https://github.com/your-org/miningguard.git
cd miningguard
code .
```

---

## 2. Firebase Setup (required before anything runs)

### 2a. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `miningguard-dev`
3. Enable **Google Analytics** → Continue → Create project

### 2b. Enable Firebase Services
In Firebase Console, enable these one by one:
- **Authentication** → Sign-in method → enable Email/Password and Phone
- **Firestore Database** → Create database → Start in **test mode** → pick region
- **Storage** → Get started → Start in test mode
- **Cloud Messaging** → no setup needed, auto-enabled

### 2c. Add Android App to Firebase
1. In Firebase Console → Project Settings → Add app → Android
2. Android package name: `com.miningguard.app`
3. Download `google-services.json`
4. Place it at:
```
miningguard/android/app/google-services.json
```

### 2d. Install FlutterFire CLI & Configure
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# From the miningguard/ root folder:
flutterfire configure --project=miningguard-dev
```
This auto-generates `lib/firebase_options.dart`. Do not commit this file.

### 2e. Firebase Admin Credentials (for FastAPI backend)
1. Firebase Console → Project Settings → Service accounts
2. Click **Generate new private key** → Download JSON
3. Save it as:
```
miningguard/backend/firebase-credentials.json
```
⚠️ Never commit this file. It's already in `.gitignore`.

---

## 3. Flutter App Setup

Open a new terminal in VS Code (`Ctrl+`` `) and run from the project root:

```bash
# Install all Flutter packages
flutter pub get

# Verify Flutter is set up correctly
flutter doctor
```

Fix any issues `flutter doctor` reports before continuing.

---

## 4. FastAPI Backend Setup

Open a **second terminal** in VS Code (`Ctrl+Shift+`` `) and run:

```bash
# Navigate to backend folder
cd backend

# Create a Python virtual environment
python -m venv venv

# Activate it — Windows:
venv\Scripts\activate

# Activate it — Mac/Linux:
source venv/bin/activate

# Install all dependencies
pip install fastapi uvicorn python-multipart pillow numpy \
            scikit-learn joblib firebase-admin pydantic

# Optional: install TensorFlow for image detection
# (skip if you want the rule-based fallback only)
pip install tensorflow
```

### 4a. Create Backend `.env` File
Create `backend/.env`:
```
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
RISK_MODEL_PATH=ml/risk_model.pkl
ALLOWED_ORIGINS=http://localhost,http://10.0.2.2
```

> **10.0.2.2** is how the Android emulator reaches your localhost.

---

## 5. Run Everything

You need **3 terminals** open simultaneously in VS Code.

---

### Terminal 1 — FastAPI Backend

```bash
cd backend
source venv/bin/activate        # Mac/Linux
# OR: venv\Scripts\activate     # Windows

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

Verify it's working — open in browser or run:
```bash
curl http://localhost:8000/health
# → {"status":"ok"}

curl http://localhost:8000/docs
# → Opens Swagger UI in browser
```

---

### Terminal 2 — Flutter App (Emulator)

```bash
# List available devices
flutter devices

# Start Android emulator (if not already running)
# OR open Android Studio → Device Manager → Play button

# Run the app on the emulator
flutter run

# Run with verbose logging if something goes wrong
flutter run -v
```

**For a specific device:**
```bash
flutter run -d emulator-5554       # Android emulator
flutter run -d chrome              # Web browser (limited features)
```

**For release build testing:**
```bash
flutter run --release
```

---

### Terminal 3 — Run Tests

```bash
# Flutter unit tests
flutter test

# Backend tests (from backend/ folder)
cd backend
source venv/bin/activate
python -m pytest ../test/hazard_report/test_phase4.py -v

# Backend tests with coverage
python -m pytest ../test/ -v --cov=routes --cov-report=term-missing
```

---

## 6. VS Code Launch Config (run with F5)

Create `.vscode/launch.json` in the project root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter App",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    },
    {
      "name": "FastAPI Backend",
      "type": "debugpy",
      "request": "launch",
      "module": "uvicorn",
      "args": ["main:app", "--reload", "--port", "8000"],
      "cwd": "${workspaceFolder}/backend",
      "env": {
        "FIREBASE_CREDENTIALS_PATH": "firebase-credentials.json"
      },
      "console": "integratedTerminal"
    },
    {
      "name": "Run Phase 4 Tests",
      "type": "debugpy",
      "request": "launch",
      "module": "pytest",
      "args": ["../test/hazard_report/test_phase4.py", "-v"],
      "cwd": "${workspaceFolder}/backend",
      "console": "integratedTerminal"
    }
  ],
  "compounds": [
    {
      "name": "Full Stack (Flutter + API)",
      "configurations": ["Flutter App", "FastAPI Backend"]
    }
  ]
}
```

Now press **F5** and select **Full Stack** to launch both at once.

---

## 7. Connect Flutter to FastAPI

In `lib/core/services/api_service.dart`, set the base URL:

```dart
// For Android emulator → use 10.0.2.2 (not localhost)
const String kApiBaseUrl = 'http://10.0.2.2:8000';

// For physical device → use your machine's local IP
// Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
const String kApiBaseUrl = 'http://192.168.1.X:8000';

// For production
const String kApiBaseUrl = 'https://your-backend.onrender.com';
```

---

## 8. Environment Summary

```
miningguard/
├── android/app/google-services.json   ← Firebase config (don't commit)
├── lib/firebase_options.dart           ← Generated by flutterfire CLI
├── backend/
│   ├── .env                            ← Backend env vars (don't commit)
│   ├── firebase-credentials.json       ← Service account key (don't commit)
│   ├── venv/                           ← Python virtualenv (don't commit)
│   └── ml/
│       ├── risk_model.pkl              ← Trained risk model
│       └── hazard_detection_model.h5   ← TF image model
└── .gitignore                          ← Must include all of the above
```

---

## 9. Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `flutter: command not found` | Add Flutter SDK `bin/` to your PATH |
| `google-services.json not found` | Download from Firebase Console → place in `android/app/` |
| `No devices found` | Open Android Studio, start an emulator first |
| `Connection refused` on API call | Make sure `uvicorn` is running; use `10.0.2.2` not `localhost` on emulator |
| `Invalid Firebase token` | Token expired — log out and back in on the app |
| `Model not loaded` | Expected if no `.pkl`/`.h5` file — rule-based fallback activates automatically |
| `CERTIFICATE_VERIFY_FAILED` | Run `pip install certifi` and set `SSL_CERT_FILE` |
| `MissingPluginException` | Run `flutter clean && flutter pub get`, restart app |
| `Hive box not open` | Call `await Hive.openBox(...)` before any checklist/report read |

---

## 10. Firestore Indexes Required

Run these in Firebase Console → Firestore → Indexes → Add composite index:

| Collection | Fields | Order |
|-----------|--------|-------|
| `hazard_reports` | `uid` ASC, `submittedAt` DESC | Composite |
| `hazard_reports` | `mineId` ASC, `status` ASC, `submittedAt` DESC | Composite |
| `checklists` | `uid` ASC, `submittedAt` DESC | Composite |

Without these, Firestore will throw an error and print a direct link to create the missing index — click it.

---

## Quick-Start Cheat Sheet

```bash
# Terminal 1 — API
cd backend && source venv/bin/activate && uvicorn main:app --reload --port 8000

# Terminal 2 — App
flutter run

# Terminal 3 — Tests
cd backend && python -m pytest ../test/ -v
```

---

*MiningGuard · Flutter + FastAPI + Firebase · Stack: Dart / Python / Firestore*

///
backend:firebase emulators:start --only auth,firestore --project mininggaurd         
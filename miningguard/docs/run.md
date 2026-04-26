# MiningGuard — Complete Run Guide

---

## Your Machine — Fixed Reference

| Item | Value |
|---|---|
| Flutter SDK | `C:\flutter` |
| Flutter Version | 3.43.0 (beta channel) |
| Dart Version | 3.12.0 |
| Android SDK | `C:\Users\keert\AppData\Local\Android\Sdk` |
| Java Version | 23.0.2 |
| Project Folder | `D:\MiningProject[MCA]-v1\miningguard\mobile` |
| Firebase Folder | `D:\MiningProject[MCA]-v1\miningguard\firebase` |
| Firebase Project ID | `mininggaurd` |
| Android Package Name | `com.miningguard.miningguard` |
| Android Firebase App ID | `1:728205489401:android:7887ceaf6536e286869e28` |

---

## How the App Connects to Firebase

The app runs in two modes depending on your environment:

| Mode | Auth | Firestore | Storage |
|---|---|---|---|
| **Debug (emulators running)** | `127.0.0.1:9099` | `127.0.0.1:8081` | Real Firebase |
| **Release / real Firebase** | Real Firebase | Real Firebase | Real Firebase |

> `google-services.json` is already placed at `android/app/google-services.json` ✅  
> `firebase_options.dart` has the real Android appId ✅  
> Emulator + real Firebase Auth and Firestore are both enabled ✅

---

## Method 1 — Run on Chrome (Web) with Emulators

This is the easiest way to test during development. No phone or USB needed.

### You need 2 terminals open at the same time.

---

### Terminal 1 — Start Firebase Emulators

```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\firebase"
firebase emulators:start --only auth,firestore --project mininggaurd
```

Wait until you see:
```
✔  All emulators ready! It is now safe to connect your app.
   View Emulator UI at http://127.0.0.1:4000/
```

**Keep this terminal open the whole time.**

---

### Terminal 2 — Run Flutter on Chrome

```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\mobile"
flutter run -d chrome
```

The app opens in a Chrome browser tab automatically.

---

### Terminal 2 — If you already have the app running

If the app is already running in Chrome, just press **`R`** (capital R) in Terminal 2 to hot restart — no need to stop and re-run.

---

### Viewing emulator data while testing

Open in browser: **http://127.0.0.1:4000**

| Tab | What you see |
|---|---|
| **Authentication** | All registered users (email + uid) |
| **Firestore** | All collections: `users`, `hazard_reports`, `checklists` |

---

## Method 2 — Run on Android Emulator (AVD)

### Step 1 — Start Firebase Emulators (Terminal 1)

```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\firebase"
firebase emulators:start --only auth,firestore --project mininggaurd
```

### Step 2 — Update emulator host for Android AVD

> Android Emulator (AVD) cannot reach `127.0.0.1` — it uses `10.0.2.2` to reach your PC.
> Open `D:\MiningProject[MCA]-v1\miningguard\mobile\lib\main.dart` and change:

```dart
// Change this:
await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8081);

// To this (for Android AVD):
await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8081);
```

### Step 3 — Start an Android Virtual Device

1. Open **Android Studio**
2. Click **Device Manager** icon on the right panel
3. Click the **Play ▶** button next to any AVD
4. Wait for it to fully boot to the Android home screen

### Step 4 — Run the app (Terminal 2)

```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\mobile"
flutter devices
```

You will see something like:
```
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x86_64 • Android 14
```

Then run:
```powershell
flutter run -d emulator-5554
```

---

## Method 3 — Run on Physical Android Phone

> On a physical phone, emulators will NOT work (127.0.0.1 refers to the phone itself, not your PC).
> The app will use **real Firebase** automatically.

### Step 1 — Enable Developer Options on your phone

1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times quickly
3. You will see "You are now a developer!"

### Step 2 — Enable USB Debugging

1. Go to **Settings → Developer Options**
2. Turn ON **USB Debugging**

### Step 3 — Connect phone to PC

1. Plug in via USB cable (must be a data cable, not charge-only)
2. On the phone: tap **Allow** when "Allow USB debugging?" prompt appears

### Step 4 — Disable emulator code in main.dart

Since real Firebase is used, you must comment out the emulator block in
`D:\MiningProject[MCA]-v1\miningguard\mobile\lib\main.dart`:

```dart
// Comment these out for physical device:
// if (kDebugMode) {
//   await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
//   FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8081);
// }
```

### Step 5 — Enable Email/Password in Firebase Console

1. Go to https://console.firebase.google.com → **mininggaurd** project
2. Click **Authentication** → **Sign-in method**
3. Click **Email/Password** → toggle **Enable** → Save

### Step 6 — Run

```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\mobile"
flutter devices
```

Find your phone's device ID, then:
```powershell
flutter run -d <your-device-id>
```

Example:
```powershell
flutter run -d RF8M12345678
```

---

## First Time: Register an Account

When the app opens for the first time:

1. Tap **"Don't have an account? Sign Up"** on the login screen
2. Enter your **email** and **password** (on login screen)
3. After creating credentials, you land on the **Profile Setup** screen — fill in:

| Field | Example Value |
|---|---|
| Full Name | `John Worker` |
| Mine ID | `MINE001` |
| Department | `Underground Operations` |
| Shift | `morning` / `afternoon` / `night` |
| Role | `Worker` or `Supervisor` |

4. Tap **Save Profile** → you are taken to the **Worker Dashboard**

---

## App Screens & Navigation

| Screen | Route | How to reach |
|---|---|---|
| Login | `/login` | App start (not logged in) |
| Sign Up | `/signup` | Tap "Sign Up" on Login screen |
| Worker Dashboard | `/worker/home` | After login (Worker role) |
| Daily Checklist | `/worker/checklist` | Dashboard → Checklist button |
| Checklist History | `/worker/checklist/history` | Dashboard → History |
| Report Hazard | `/worker/report` | Dashboard → Report Hazard |
| My Reports | `/worker/reports` | Dashboard → My Reports |
| Profile | `/worker/profile` | Dashboard → Profile icon |
| Supervisor Dashboard | `/supervisor/dashboard` | After login (Supervisor role) |

---

## Quick Commands Reference

```powershell
# Navigate to project
cd "D:\MiningProject[MCA]-v1\miningguard\mobile"

# Install packages
flutter pub get

# Check Flutter health
flutter doctor

# List connected devices
flutter devices

# Run on Chrome
flutter run -d chrome

# Run on Android device/emulator
flutter run -d <device-id>

# Run release build
flutter run --release -d <device-id>

# Clear build cache (fixes most errors)
flutter clean
flutter pub get
flutter run

# Hot reload (while app is running in terminal)
r

# Hot restart (while app is running in terminal)
R

# Stop the app
q
```

---

## Troubleshooting

### "configuration not found" on login
- Make sure Firebase Emulators are running (Terminal 1)
- Make sure you started emulators BEFORE running the app
- Check emulator UI at http://127.0.0.1:4000 — both Auth and Firestore tabs should be active

### "Gradle build failed"
```powershell
flutter clean
flutter pub get
flutter run
```

### "No devices found"
- For Chrome: just run `flutter run -d chrome` directly
- For phone: check USB debugging is ON, try a different USB cable
- Run `adb devices` — if it shows `unauthorized`, check your phone screen for the "Allow USB debugging?" popup

### "sdk.dir not set" error
Create file `D:\MiningProject[MCA]-v1\miningguard\mobile\android\local.properties` with:
```
sdk.dir=C:\Users\keert\AppData\Local\Android\Sdk
flutter.sdk=C:\flutter
```

### App opens but stuck on loading spinner
- Emulators are not running or crashed
- Go to Terminal 1 and restart: `firebase emulators:start --only auth,firestore --project mininggaurd`

### "flutterfire not recognized"
Use the full path:
```powershell
& "C:\Users\keert\AppData\Local\Pub\Cache\bin\flutterfire.bat" configure --project=mininggaurd --platforms=android --android-package-name=com.miningguard.miningguard --yes
```

---

## Project File Reference

```
D:\MiningProject[MCA]-v1\
  miningguard\
    firebase\                          ← Run emulator commands here
      firestore.rules
      storage.rules
      firebase.json
    mobile\                            ← Run flutter commands here
      lib\
        main.dart                      ← Firebase init + emulator config
        firebase_options.dart          ← Auto-generated Firebase config
        features\
          auth\screens\
            login_screen.dart
            signup_screen.dart
          dashboard\                   ← Worker home screen
          checklist\                   ← Phase 3: Daily safety checklist
          hazard_report\               ← Phase 4: Hazard reporting
      android\
        app\
          google-services.json         ← Android Firebase config ✅
          build.gradle.kts
      pubspec.yaml                     ← All dependencies
    docs\
      run.md                           ← This file
```

---

## Summary — Fastest Way to Run Right Now

Open **two PowerShell windows**:

**Window 1:**
```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\firebase"
firebase emulators:start --only auth,firestore --project mininggaurd
```

**Window 2:**
```powershell
cd "D:\MiningProject[MCA]-v1\miningguard\mobile"
flutter run -d chrome
```

Register a new account → test the app.
View all data at **http://127.0.0.1:4000**

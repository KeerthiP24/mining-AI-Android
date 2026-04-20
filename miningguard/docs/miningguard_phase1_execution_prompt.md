# ⛏️ MiningGuard — Phase 1 Execution Prompt
### Project Foundation & Setup · Complete Agent Build Guide

> **This is a self-contained execution prompt for an AI coding agent.**
> Read every section fully before writing a single file. Every decision made here
> affects all 10 phases. Do not skip, abbreviate, or reorder any step.

---

## 🧭 Agent Instructions — Read First

You are building **Phase 1** of **MiningGuard**, an AI-powered mining safety companion app for Indian mine workers. Your job is to create the complete project skeleton — every folder, every config file, every boilerplate — so that Phases 2–10 can be built on top without restructuring anything.

**Guiding principles for this phase:**
- Correctness over speed. Every file must be syntactically valid and buildable.
- Separation of concerns. Features must never bleed into each other's folders.
- Zero assumptions. If a value is not specified below, use the exact default shown. Do not invent values.
- Verify before moving on. After creating each major section, confirm the project still builds.

**Stack you are working with:**

| Layer | Technology | Version |
|-------|-----------|---------|
| Mobile App | Flutter + Dart | Flutter 3.19+ / Dart 3.3+ |
| State Management | Riverpod | `flutter_riverpod: ^2.5.1` |
| Navigation | GoRouter | `go_router: ^13.2.0` |
| Database | Cloud Firestore | `cloud_firestore: ^4.15.4` |
| Auth | Firebase Auth | `firebase_auth: ^4.17.4` |
| Storage | Firebase Storage | `firebase_storage: ^11.6.5` |
| Notifications | Firebase FCM | `firebase_messaging: ^14.7.17` |
| Core Firebase | firebase_core | `firebase_core: ^2.27.0` |
| Local Storage | Hive | `hive_flutter: ^1.1.0` |
| HTTP Client | Dio | `dio: ^5.4.1` |
| AI Backend | FastAPI + Python | Python 3.11+ |
| ML — Risk | Scikit-learn | `scikit-learn==1.4.0` |
| ML — Image | TensorFlow | `tensorflow==2.15.0` |
| CI/CD | GitHub Actions | Latest |

---

## 📁 Complete Project Structure to Create

Before writing any code, create this exact directory tree. Every folder listed here must exist. The agent must not add folders not listed here.

```
miningguard/
│
├── .github/
│   └── workflows/
│       ├── flutter_ci.yml
│       └── fastapi_ci.yml
│
├── mobile/                          ← Flutter application root
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart     ← Placeholder (filled in by FlutterFire CLI)
│   │   │
│   │   ├── core/                    ← App-wide infrastructure
│   │   │   ├── router/
│   │   │   │   └── app_router.dart
│   │   │   ├── theme/
│   │   │   │   └── app_theme.dart
│   │   │   ├── constants/
│   │   │   │   └── app_constants.dart
│   │   │   ├── errors/
│   │   │   │   └── app_exception.dart
│   │   │   └── utils/
│   │   │       └── logger.dart
│   │   │
│   │   ├── shared/                  ← Reusable widgets and models
│   │   │   ├── widgets/
│   │   │   │   ├── loading_widget.dart
│   │   │   │   └── error_widget.dart
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── checklist_model.dart
│   │   │   │   ├── hazard_report_model.dart
│   │   │   │   ├── alert_model.dart
│   │   │   │   └── video_model.dart
│   │   │   └── providers/
│   │   │       └── firebase_providers.dart
│   │   │
│   │   └── features/                ← One folder per feature
│   │       ├── auth/
│   │       │   ├── screens/
│   │       │   ├── providers/
│   │       │   └── services/
│   │       ├── checklist/
│   │       │   ├── screens/
│   │       │   ├── providers/
│   │       │   └── services/
│   │       ├── hazard_report/
│   │       │   ├── screens/
│   │       │   ├── providers/
│   │       │   └── services/
│   │       ├── education/
│   │       │   ├── screens/
│   │       │   ├── providers/
│   │       │   └── services/
│   │       └── dashboard/
│   │           ├── screens/
│   │           ├── providers/
│   │           └── services/
│   │
│   ├── test/
│   │   ├── unit/
│   │   └── widget/
│   │
│   └── pubspec.yaml
│
├── backend/                         ← FastAPI AI backend root
│   ├── app/
│   │   ├── main.py
│   │   ├── config.py
│   │   │
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── deps.py              ← Shared dependencies (auth, db)
│   │   │   └── v1/
│   │   │       ├── __init__.py
│   │   │       ├── router.py        ← Registers all v1 routes
│   │   │       ├── risk.py
│   │   │       ├── behavior.py
│   │   │       ├── image_detect.py
│   │   │       └── recommendations.py
│   │   │
│   │   ├── ml/
│   │   │   ├── __init__.py
│   │   │   ├── risk_model.py
│   │   │   ├── image_model.py
│   │   │   ├── behavior_engine.py
│   │   │   └── recommendation_engine.py
│   │   │
│   │   ├── schemas/
│   │   │   ├── __init__.py
│   │   │   ├── risk_schema.py
│   │   │   ├── image_schema.py
│   │   │   ├── behavior_schema.py
│   │   │   └── recommendation_schema.py
│   │   │
│   │   └── core/
│   │       ├── __init__.py
│   │       ├── firebase_admin.py    ← Firebase Admin SDK init
│   │       ├── security.py          ← Token verification
│   │       └── logger.py
│   │
│   ├── models/                      ← Saved ML model files (.pkl, .h5)
│   │   └── .gitkeep
│   │
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_risk.py
│   │   └── test_image.py
│   │
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   ├── Dockerfile
│   └── .env.example
│
├── firebase/                        ← Firebase configuration files
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   ├── storage.rules
│   └── firebase.json
│
├── docs/
│   ├── setup.md
│   └── architecture.md
│
├── .gitignore
└── README.md
```

---

## STEP 1 — Flutter App Setup

### 1.1 Initialize the Flutter Project

Run the following command from the `miningguard/` root directory:

```bash
flutter create mobile --org com.miningguard --project-name miningguard --platforms android
```

This creates the Flutter project inside the `mobile/` directory targeting Android only (iOS can be added in a future phase).

After creation, confirm Flutter builds successfully:

```bash
cd mobile && flutter pub get && flutter analyze
```

There must be zero errors before proceeding.

---

### 1.2 Write `pubspec.yaml`

Replace the generated `pubspec.yaml` with the following exact content. Do not add or remove any dependency without explicit instruction.

```yaml
name: miningguard
description: AI-Powered Mining Safety Companion for Indian Mine Workers
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.4
  cloud_firestore: ^4.15.4
  firebase_storage: ^11.6.5
  firebase_messaging: ^14.7.17

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.4

  # Navigation
  go_router: ^13.2.0

  # Local Storage
  hive_flutter: ^1.1.0

  # HTTP
  dio: ^5.4.1

  # Utilities
  intl: ^0.19.0
  logger: ^2.0.2+1
  equatable: ^2.0.5
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # Media
  image_picker: ^1.0.7
  speech_to_text: ^6.6.0
  flutter_sound: ^9.2.13
  cached_network_image: ^3.3.1
  youtube_player_flutter: ^8.1.2

  # UI
  flutter_svg: ^2.0.9
  lottie: ^3.1.0
  fl_chart: ^0.67.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
  mockito: ^5.4.4
  fake_cloud_firestore: ^2.4.4
  firebase_auth_mocks: ^0.13.0

flutter:
  uses-material-design: true
  generate: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/lottie/

  fonts:
    - family: NotoSans
      fonts:
        - asset: assets/fonts/NotoSans-Regular.ttf
        - asset: assets/fonts/NotoSans-Bold.ttf
          weight: 700
```

After writing this file run:

```bash
flutter pub get
```

Confirm zero dependency resolution errors before proceeding.

---

### 1.3 Create Asset Directories

Create the following empty asset folders (place a `.gitkeep` file in each):

```
mobile/assets/images/.gitkeep
mobile/assets/icons/.gitkeep
mobile/assets/lottie/.gitkeep
mobile/assets/fonts/.gitkeep
```

---

### 1.4 Write `lib/main.dart`

This is the application entry point. Write it exactly as shown below.

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// Background FCM message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM Background] Message ID: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler before anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Hive for offline storage
  await Hive.initFlutter();

  runApp(
    // ProviderScope wraps the entire app — required for Riverpod
    const ProviderScope(
      child: MiningGuardApp(),
    ),
  );
}

class MiningGuardApp extends ConsumerWidget {
  const MiningGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MiningGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // Localization support — languages added in Phase 9
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('bn'),
        Locale('te'),
        Locale('mr'),
        Locale('or'),
      ],
    );
  }
}
```

---

### 1.5 Write `lib/firebase_options.dart` (Placeholder)

This file is normally generated by the FlutterFire CLI. Create a placeholder that compiles but will be replaced when Firebase is configured:

```dart
// PLACEHOLDER — Replace this file by running:
// flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// Prerequisites:
// 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. Install Firebase CLI: npm install -g firebase-tools
// 3. Login: firebase login
// 4. Run: flutterfire configure --project=YOUR_PROJECT_ID

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run: flutterfire configure --project=YOUR_PROJECT_ID',
        );
    }
  }

  // REPLACE ALL VALUES BELOW with output from: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'REPLACE_WITH_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_STORAGE_BUCKET',
  );
}
```

---

### 1.6 Write `lib/core/constants/app_constants.dart`

```dart
/// Central constants file. Import this wherever a magic value is needed.
/// Never hardcode strings, colors, or numbers directly in widget files.
class AppConstants {
  AppConstants._();

  // ── App Identity ──────────────────────────────────────────────────────────
  static const String appName = 'MiningGuard';
  static const String appVersion = '1.0.0';

  // ── Firestore Collection Names ────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String minesCollection = 'mines';
  static const String checklistsCollection = 'checklists';
  static const String hazardReportsCollection = 'hazard_reports';
  static const String safetyVideosCollection = 'safety_videos';
  static const String alertsCollection = 'alerts';

  // ── Hive Box Names (offline storage) ─────────────────────────────────────
  static const String checklistBox = 'checklist_box';
  static const String reportQueueBox = 'report_queue_box';
  static const String userCacheBox = 'user_cache_box';

  // ── FastAPI Backend Base URL ──────────────────────────────────────────────
  // Development: localhost for emulator, 10.0.2.2 for Android emulator
  // Production:  set via environment variable in release builds
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000/api/v1';
  static const String apiBaseUrlProd = 'https://YOUR_RENDER_URL.onrender.com/api/v1';

  // ── AI API Endpoint Paths ─────────────────────────────────────────────────
  static const String riskPredictEndpoint = '/risk/predict';
  static const String behaviorAnalyzeEndpoint = '/behavior/analyze';
  static const String imageDetectEndpoint = '/image/detect';
  static const String recommendationsEndpoint = '/recommendations';

  // ── Risk Levels ────────────────────────────────────────────────────────────
  static const String riskLow = 'low';
  static const String riskMedium = 'medium';
  static const String riskHigh = 'high';

  // ── User Roles ─────────────────────────────────────────────────────────────
  static const String roleWorker = 'worker';
  static const String roleSupervisor = 'supervisor';
  static const String roleAdmin = 'admin';

  // ── Checklist Status ───────────────────────────────────────────────────────
  static const String checklistPending = 'pending';
  static const String checklistInProgress = 'in_progress';
  static const String checklistCompleted = 'completed';
  static const String checklistMissed = 'missed';

  // ── Hazard Report Status ───────────────────────────────────────────────────
  static const String reportSubmitted = 'submitted';
  static const String reportAcknowledged = 'acknowledged';
  static const String reportInProgress = 'in_progress';
  static const String reportResolved = 'resolved';

  // ── Hazard Categories ──────────────────────────────────────────────────────
  static const List<String> hazardCategories = [
    'roof_fall',
    'gas_leak',
    'fire',
    'machinery',
    'electrical',
    'other',
  ];

  // ── Severity Levels ────────────────────────────────────────────────────────
  static const String severityLow = 'low';
  static const String severityMedium = 'medium';
  static const String severityHigh = 'high';
  static const String severityCritical = 'critical';

  // ── Supported Languages ────────────────────────────────────────────────────
  static const List<String> supportedLanguageCodes = [
    'en', 'hi', 'bn', 'te', 'mr', 'or',
  ];

  // ── Shift Types ────────────────────────────────────────────────────────────
  static const String shiftMorning = 'morning';
  static const String shiftAfternoon = 'afternoon';
  static const String shiftNight = 'night';

  // ── Compliance Scoring Weights ─────────────────────────────────────────────
  static const double mandatoryItemWeight = 0.70;
  static const double optionalItemWeight = 0.30;

  // ── Timeouts & Durations ───────────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration checklistReminderDelay = Duration(hours: 1);
  static const int behaviorAnalysisWindowDays = 30;
  static const int riskWindowDays = 7;

  // ── FCM Notification Channels ──────────────────────────────────────────────
  static const String fcmChannelStandard = 'miningguard_standard';
  static const String fcmChannelCritical = 'miningguard_critical';
}
```

---

### 1.7 Write `lib/core/errors/app_exception.dart`

```dart
/// Unified exception type for MiningGuard.
/// All service layers throw AppException; UI layers catch AppException.
/// Never let Firebase exceptions, Dio exceptions, or Dart exceptions
/// propagate into widget code — always wrap them here.
class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  final String code;
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  // ── Named constructors for common error types ────────────────────────────

  factory AppException.network(String message, {Object? originalError}) =>
      AppException(
        code: 'NETWORK_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.auth(String message, {Object? originalError}) =>
      AppException(
        code: 'AUTH_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.firestore(String message, {Object? originalError}) =>
      AppException(
        code: 'FIRESTORE_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.storage(String message, {Object? originalError}) =>
      AppException(
        code: 'STORAGE_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.ai(String message, {Object? originalError}) =>
      AppException(
        code: 'AI_BACKEND_ERROR',
        message: message,
        originalError: originalError,
      );

  factory AppException.unknown(Object error) =>
      AppException(
        code: 'UNKNOWN_ERROR',
        message: 'An unexpected error occurred.',
        originalError: error,
      );

  @override
  String toString() => 'AppException[$code]: $message';
}
```

---

### 1.8 Write `lib/core/utils/logger.dart`

```dart
import 'package:logger/logger.dart';

/// Singleton logger. Use this everywhere instead of print() or debugPrint().
///
/// Usage:
///   import 'package:miningguard/core/utils/logger.dart';
///   AppLogger.d('checklist loaded'); // debug
///   AppLogger.i('user logged in');   // info
///   AppLogger.w('low connectivity'); // warning
///   AppLogger.e('upload failed', error: e, stackTrace: st); // error
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
```

---

### 1.9 Write `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';

/// MiningGuard design system.
///
/// Color palette is chosen for high contrast in low-light mine environments
/// and for clear risk-level communication (green / amber / red).
class AppTheme {
  AppTheme._();

  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primaryYellow = Color(0xFFF5A623);    // Safety yellow
  static const Color primaryDark = Color(0xFF1A1A2E);      // Deep navy — backgrounds
  static const Color accentBlue = Color(0xFF0EA5E9);       // Sky blue — CTAs

  // ── Risk Level Colors ─────────────────────────────────────────────────────
  static const Color riskLow = Color(0xFF22C55E);          // Green
  static const Color riskMedium = Color(0xFFF59E0B);       // Amber
  static const Color riskHigh = Color(0xFFEF4444);         // Red

  // ── Severity Colors ───────────────────────────────────────────────────────
  static const Color severityLow = Color(0xFF6B7280);      // Grey
  static const Color severityMedium = Color(0xFFF59E0B);   // Amber
  static const Color severityHigh = Color(0xFFEF4444);     // Red
  static const Color severityCritical = Color(0xFF7F1D1D); // Deep red

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        brightness: Brightness.light,
      ),
      fontFamily: 'NotoSans',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryDark,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryYellow,
        brightness: Brightness.dark,
      ),
      fontFamily: 'NotoSans',
      scaffoldBackgroundColor: primaryDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F23),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
```

---

### 1.10 Write `lib/core/router/app_router.dart`

This is the central navigation file. All routes for every phase are declared here even if their screens are not built yet — they point to placeholder screens until each phase is implemented.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Route Name Constants ──────────────────────────────────────────────────────
// Use these constants everywhere instead of raw strings.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String languageSelect = '/language-select';

  // Worker routes
  static const String workerHome = '/worker/home';
  static const String checklist = '/worker/checklist';
  static const String checklistHistory = '/worker/checklist/history';
  static const String reportHazard = '/worker/report';
  static const String myReports = '/worker/reports';
  static const String education = '/worker/education';
  static const String workerProfile = '/worker/profile';

  // Supervisor routes
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String workersList = '/supervisor/workers';
  static const String workerDetail = '/supervisor/workers/:uid';
  static const String pendingReports = '/supervisor/reports';

  // Admin routes
  static const String adminPanel = '/admin/panel';
  static const String userManagement = '/admin/users';
  static const String contentManagement = '/admin/content';
  static const String analytics = '/admin/analytics';
}

// ── Placeholder Screen ────────────────────────────────────────────────────────
// Shown for routes whose feature screens have not been built yet.
// Replace each one as phases are completed.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Screen not yet built:\n$routeName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This placeholder will be replaced in a future phase.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Router Provider ────────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,  // Set to false in production
    routes: [
      // ── Splash / Root ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Splash Screen'),
      ),

      // ── Auth Flow ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Sign Up'),
      ),
      GoRoute(
        path: AppRoutes.languageSelect,
        name: 'language-select',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Language Selection'),
      ),

      // ── Worker Screens ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.workerHome,
        name: 'worker-home',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Worker Home Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.checklist,
        name: 'checklist',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Daily Checklist'),
      ),
      GoRoute(
        path: AppRoutes.checklistHistory,
        name: 'checklist-history',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Checklist History'),
      ),
      GoRoute(
        path: AppRoutes.reportHazard,
        name: 'report-hazard',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Report Hazard'),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        name: 'my-reports',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'My Hazard Reports'),
      ),
      GoRoute(
        path: AppRoutes.education,
        name: 'education',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Safety Education'),
      ),
      GoRoute(
        path: AppRoutes.workerProfile,
        name: 'worker-profile',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Worker Profile'),
      ),

      // ── Supervisor Screens ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.supervisorDashboard,
        name: 'supervisor-dashboard',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Supervisor Dashboard'),
      ),
      GoRoute(
        path: AppRoutes.workersList,
        name: 'workers-list',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Workers List'),
      ),
      GoRoute(
        path: AppRoutes.workerDetail,
        name: 'worker-detail',
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          return PlaceholderScreen(routeName: 'Worker Detail: $uid');
        },
      ),
      GoRoute(
        path: AppRoutes.pendingReports,
        name: 'pending-reports',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Pending Reports'),
      ),

      // ── Admin Screens ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminPanel,
        name: 'admin-panel',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Admin Panel'),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'User Management'),
      ),
      GoRoute(
        path: AppRoutes.contentManagement,
        name: 'content-management',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Content Management'),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        builder: (context, state) =>
            const PlaceholderScreen(routeName: 'Analytics'),
      ),
    ],

    // ── Error Page ──────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});
```

---

### 1.11 Write Shared Data Models

These models are the data contract for every feature and for Firestore documents. Write each model exactly as shown. Code generation (freezed + json_serializable) will be run after.

**`lib/shared/models/user_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.mineId,
    required this.department,
    required this.shift,
    required this.languageCode,
    this.riskScore = 0.0,
    this.riskLevel = 'low',
    this.complianceRate = 1.0,
    this.totalHazardReports = 0,
    this.consecutiveMissedDays = 0,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String role;         // worker | supervisor | admin
  final String mineId;
  final String department;
  final String shift;        // morning | afternoon | night
  final String languageCode; // en | hi | bn | te | mr | or
  final double riskScore;    // 0–100
  final String riskLevel;    // low | medium | high
  final double complianceRate; // 0.0–1.0
  final int totalHazardReports;
  final int consecutiveMissedDays;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      role: data['role'] as String? ?? 'worker',
      mineId: data['mineId'] as String? ?? '',
      department: data['department'] as String? ?? '',
      shift: data['shift'] as String? ?? 'morning',
      languageCode: data['languageCode'] as String? ?? 'en',
      riskScore: (data['riskScore'] as num?)?.toDouble() ?? 0.0,
      riskLevel: data['riskLevel'] as String? ?? 'low',
      complianceRate: (data['complianceRate'] as num?)?.toDouble() ?? 1.0,
      totalHazardReports: data['totalHazardReports'] as int? ?? 0,
      consecutiveMissedDays: data['consecutiveMissedDays'] as int? ?? 0,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      'mineId': mineId,
      'department': department,
      'shift': shift,
      'languageCode': languageCode,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'complianceRate': complianceRate,
      'totalHazardReports': totalHazardReports,
      'consecutiveMissedDays': consecutiveMissedDays,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? role,
    String? shift,
    String? languageCode,
    double? riskScore,
    String? riskLevel,
    double? complianceRate,
    int? totalHazardReports,
    int? consecutiveMissedDays,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone,
      role: role ?? this.role,
      mineId: mineId,
      department: department,
      shift: shift ?? this.shift,
      languageCode: languageCode ?? this.languageCode,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      complianceRate: complianceRate ?? this.complianceRate,
      totalHazardReports: totalHazardReports ?? this.totalHazardReports,
      consecutiveMissedDays: consecutiveMissedDays ?? this.consecutiveMissedDays,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

**`lib/shared/models/checklist_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItemModel {
  const ChecklistItemModel({
    required this.id,
    required this.label,
    required this.category,
    required this.isMandatory,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String label;
  final String category; // ppe | machinery | environment | emergency
  final bool isMandatory;
  final bool isCompleted;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'category': category,
    'isMandatory': isMandatory,
    'isCompleted': isCompleted,
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
  };

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) =>
      ChecklistItemModel(
        id: map['id'] as String,
        label: map['label'] as String,
        category: map['category'] as String,
        isMandatory: map['isMandatory'] as bool? ?? true,
        isCompleted: map['isCompleted'] as bool? ?? false,
        completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      );

  ChecklistItemModel copyWith({bool? isCompleted, DateTime? completedAt}) =>
      ChecklistItemModel(
        id: id,
        label: label,
        category: category,
        isMandatory: isMandatory,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
      );
}

class ChecklistModel {
  const ChecklistModel({
    required this.id,
    required this.uid,
    required this.mineId,
    required this.shift,
    required this.date,
    required this.items,
    this.status = 'pending',
    this.complianceScore = 0.0,
    this.submittedAt,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String mineId;
  final String shift;
  final String date;        // Format: 'YYYY-MM-DD'
  final List<ChecklistItemModel> items;
  final String status;      // pending | in_progress | completed | missed
  final double complianceScore; // 0.0–1.0
  final DateTime? submittedAt;
  final DateTime? createdAt;

  factory ChecklistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return ChecklistModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      shift: data['shift'] as String? ?? 'morning',
      date: data['date'] as String? ?? '',
      items: rawItems
          .map((e) => ChecklistItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: data['status'] as String? ?? 'pending',
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0.0,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'mineId': mineId,
    'shift': shift,
    'date': date,
    'items': items.map((e) => e.toMap()).toList(),
    'status': status,
    'complianceScore': complianceScore,
    if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
```

**`lib/shared/models/hazard_report_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AiAnalysisModel {
  const AiAnalysisModel({
    required this.hazardDetected,
    required this.confidence,
    required this.suggestedSeverity,
    required this.correctionRecommendation,
  });

  final String hazardDetected;
  final double confidence;
  final String suggestedSeverity;
  final String correctionRecommendation;

  factory AiAnalysisModel.fromMap(Map<String, dynamic> map) => AiAnalysisModel(
    hazardDetected: map['hazardDetected'] as String? ?? 'unknown',
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    suggestedSeverity: map['suggestedSeverity'] as String? ?? 'low',
    correctionRecommendation: map['correctionRecommendation'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'hazardDetected': hazardDetected,
    'confidence': confidence,
    'suggestedSeverity': suggestedSeverity,
    'correctionRecommendation': correctionRecommendation,
  };
}

class HazardReportModel {
  const HazardReportModel({
    required this.id,
    required this.reporterId,
    required this.mineId,
    required this.mineSection,
    required this.category,
    required this.severity,
    required this.description,
    this.mediaUrls = const [],
    this.voiceNoteUrl,
    this.aiAnalysis,
    this.status = 'submitted',
    this.supervisorNote,
    this.resolvedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reporterId;
  final String mineId;
  final String mineSection;
  final String category;   // roof_fall | gas_leak | fire | machinery | electrical | other
  final String severity;   // low | medium | high | critical
  final String description;
  final List<String> mediaUrls;
  final String? voiceNoteUrl;
  final AiAnalysisModel? aiAnalysis;
  final String status;     // submitted | acknowledged | in_progress | resolved
  final String? supervisorNote;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HazardReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final aiData = data['aiAnalysis'] as Map<String, dynamic>?;
    return HazardReportModel(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      mineSection: data['mineSection'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      severity: data['severity'] as String? ?? 'low',
      description: data['description'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      aiAnalysis: aiData != null ? AiAnalysisModel.fromMap(aiData) : null,
      status: data['status'] as String? ?? 'submitted',
      supervisorNote: data['supervisorNote'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'reporterId': reporterId,
    'mineId': mineId,
    'mineSection': mineSection,
    'category': category,
    'severity': severity,
    'description': description,
    'mediaUrls': mediaUrls,
    if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis!.toMap(),
    'status': status,
    if (supervisorNote != null) 'supervisorNote': supervisorNote,
    if (resolvedBy != null) 'resolvedBy': resolvedBy,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
```

**`lib/shared/models/alert_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;     // risk_level_change | missed_checklist | behavior_pattern | critical_hazard
  final String title;
  final String message;
  final String severity; // info | warning | critical
  final bool isRead;
  final String? relatedId;
  final DateTime? createdAt;

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      isRead: data['isRead'] as bool? ?? false,
      relatedId: data['relatedId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'title': title,
    'message': message,
    'severity': severity,
    'isRead': isRead,
    if (relatedId != null) 'relatedId': relatedId,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
```

**`lib/shared/models/video_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  const VideoModel({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.titleBn,
    required this.category,
    required this.source,
    required this.youtubeId,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.targetRoles = const ['worker', 'supervisor'],
    this.tags = const [],
    this.isActive = true,
  });

  final String id;
  final String titleEn;
  final String? titleHi;
  final String? titleBn;
  final String category;    // ppe | gas_ventilation | roof_support | emergency | machinery
  final String source;      // dgms | msha | hse | worksafe | custom
  final String youtubeId;
  final String? thumbnailUrl;
  final int durationSeconds;
  final List<String> targetRoles;
  final List<String> tags;
  final bool isActive;

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      titleEn: data['titleEn'] as String? ?? '',
      titleHi: data['titleHi'] as String?,
      titleBn: data['titleBn'] as String?,
      category: data['category'] as String? ?? '',
      source: data['source'] as String? ?? '',
      youtubeId: data['youtubeId'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      targetRoles: List<String>.from(data['targetRoles'] as List? ?? ['worker']),
      tags: List<String>.from(data['tags'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titleEn': titleEn,
    if (titleHi != null) 'titleHi': titleHi,
    if (titleBn != null) 'titleBn': titleBn,
    'category': category,
    'source': source,
    'youtubeId': youtubeId,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
    'targetRoles': targetRoles,
    'tags': tags,
    'isActive': isActive,
  };
}
```

---

### 1.12 Write `lib/shared/providers/firebase_providers.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase service providers.
/// These are the single source of truth for Firebase instances throughout the app.
/// Every feature that needs Firestore, Auth, Storage, or FCM must
/// access them via these providers — never instantiate directly.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Exposes the current auth state as a stream.
/// Use this to listen for login/logout events at the app level.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Convenience provider: current logged-in user.
/// Returns null if not authenticated.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});
```

---

### 1.13 Write Shared UI Widgets

**`lib/shared/widgets/loading_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryYellow,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

**`lib/shared/widgets/error_widget.dart`**

```dart
import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## STEP 2 — FastAPI Backend Setup

### 2.1 Create `backend/requirements.txt`

```
fastapi==0.110.0
uvicorn[standard]==0.27.1
pydantic==2.6.1
pydantic-settings==2.2.1
firebase-admin==6.4.0
scikit-learn==1.4.0
tensorflow==2.15.0
numpy==1.26.4
Pillow==10.2.0
python-multipart==0.0.9
httpx==0.27.0
python-jose[cryptography]==3.3.0
```

### 2.2 Create `backend/requirements-dev.txt`

```
pytest==8.0.2
pytest-asyncio==0.23.5
httpx==0.27.0
black==24.2.0
isort==5.13.2
mypy==1.8.0
```

### 2.3 Write `backend/app/config.py`

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.
    In development: create a .env file in backend/ with these values.
    In production: set these as environment variables on your hosting platform.
    Never commit .env to git.
    """

    # App
    app_name: str = "MiningGuard AI Backend"
    app_version: str = "1.0.0"
    debug: bool = False

    # Firebase Admin SDK
    # Path to your service account key JSON file
    firebase_credentials_path: str = "firebase-service-account.json"
    firebase_project_id: str = ""

    # CORS — Add your Flutter app's origin if using web, or keep * for mobile
    allowed_origins: list[str] = ["*"]

    # ML Model Paths
    risk_model_path: str = "models/risk_model.pkl"
    image_model_path: str = "models/image_model.h5"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
```

### 2.4 Write `backend/app/core/firebase_admin.py`

```python
import firebase_admin
from firebase_admin import credentials, firestore as fs, auth

from app.config import settings
from app.core.logger import logger

_app: firebase_admin.App | None = None


def initialize_firebase() -> firebase_admin.App:
    """
    Initialize the Firebase Admin SDK.
    Called once at application startup in main.py.
    Safe to call multiple times — returns existing app if already initialized.
    """
    global _app
    if _app is not None:
        return _app

    try:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        _app = firebase_admin.initialize_app(cred, {
            "projectId": settings.firebase_project_id,
        })
        logger.info("Firebase Admin SDK initialized successfully.")
        return _app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise


def get_firestore_client():
    """Return a Firestore client. Requires firebase to be initialized."""
    return fs.client()


def get_auth_client():
    """Return the Firebase Auth client."""
    return auth
```

### 2.5 Write `backend/app/core/security.py`

```python
from firebase_admin import auth
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.logger import logger

bearer_scheme = HTTPBearer()


async def verify_firebase_token(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
) -> dict:
    """
    FastAPI dependency that verifies a Firebase ID token.

    Usage in route:
        @router.get("/protected")
        async def protected(user: dict = Depends(verify_firebase_token)):
            return {"uid": user["uid"]}

    Raises HTTP 401 if token is missing, expired, or invalid.
    Returns the decoded token dict which includes 'uid', 'email', etc.
    """
    token = credentials.credentials
    try:
        decoded = auth.verify_id_token(token)
        return decoded
    except auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Firebase token has expired. Please re-authenticate.",
        )
    except auth.InvalidIdTokenError as e:
        logger.warning(f"Invalid Firebase token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Firebase token.",
        )
    except Exception as e:
        logger.error(f"Token verification error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed.",
        )
```

### 2.6 Write `backend/app/core/logger.py`

```python
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger("miningguard")
```

### 2.7 Write Pydantic Schemas

**`backend/app/schemas/risk_schema.py`**

```python
from pydantic import BaseModel, Field


class RiskPredictionRequest(BaseModel):
    """
    Input features for the risk prediction model.
    All features must be present; use 0 as default if a value is unavailable.
    """
    uid: str = Field(..., description="Worker's Firebase UID")
    missed_checklists_7d: int = Field(
        ..., ge=0, le=7,
        description="Number of checklists missed in the last 7 days"
    )
    consecutive_missed_days: int = Field(
        ..., ge=0,
        description="Current streak of consecutive missed days"
    )
    compliance_rate: float = Field(
        ..., ge=0.0, le=1.0,
        description="Overall compliance rate as a fraction (0.0 to 1.0)"
    )
    high_severity_reports_7d: int = Field(
        ..., ge=0,
        description="High or critical severity reports filed in last 7 days"
    )
    total_reports_7d: int = Field(
        ..., ge=0,
        description="Total hazard reports filed in last 7 days"
    )
    videos_watched_7d: int = Field(
        ..., ge=0,
        description="Safety videos watched in last 7 days (positive signal)"
    )
    role: str = Field(..., description="worker | supervisor | admin")
    shift: str = Field(..., description="morning | afternoon | night")


class RiskContributingFactor(BaseModel):
    factor: str
    impact: str  # "high" | "medium" | "low"
    description: str


class RiskPredictionResponse(BaseModel):
    uid: str
    risk_level: str          # "low" | "medium" | "high"
    risk_score: float        # 0–100
    contributing_factors: list[RiskContributingFactor]
    model_confidence: float  # 0.0–1.0
```

**`backend/app/schemas/image_schema.py`**

```python
from pydantic import BaseModel


class ImageDetectionResponse(BaseModel):
    hazard_detected: str         # "missing_helmet" | "missing_vest" | "unsafe_environment" | "machinery_hazard" | "safe"
    confidence: float            # 0.0–1.0
    suggested_severity: str      # "low" | "medium" | "high" | "critical"
    correction_recommendation: str
    processing_time_ms: int
```

**`backend/app/schemas/behavior_schema.py`**

```python
from pydantic import BaseModel


class BehaviorAnalysisRequest(BaseModel):
    uid: str


class DetectedPattern(BaseModel):
    pattern_type: str    # "weekly_skip" | "night_shift_gap" | "escalating_severity" | "repeated_ppe_miss" | "inactivity_spike"
    severity: str        # "low" | "medium" | "high"
    description: str
    recommended_action: str
    data_points: list[str]


class BehaviorAnalysisResponse(BaseModel):
    uid: str
    analysis_window_days: int
    patterns_found: list[DetectedPattern]
    overall_behavior_score: float  # 0.0–1.0 (higher is safer)
    last_analyzed_at: str          # ISO timestamp
```

**`backend/app/schemas/recommendation_schema.py`**

```python
from pydantic import BaseModel


class RecommendationRequest(BaseModel):
    uid: str
    recent_report_categories: list[str] = []
    missed_checklist_items: list[str] = []
    risk_level: str = "low"
    role: str = "worker"
    shift: str = "morning"


class VideoRecommendation(BaseModel):
    video_id: str
    reason: str
    priority_score: float


class RecommendationResponse(BaseModel):
    uid: str
    recommended_video_id: str
    recommendation_reason: str
    safety_tip: str
    fallback_category: str
```

### 2.8 Write ML Module Stubs

These files establish the module structure. Full ML implementation happens in Phase 6.

**`backend/app/ml/risk_model.py`**

```python
"""
Risk Prediction Engine — Stub for Phase 1.
Full Gradient Boosting implementation in Phase 6.
"""
from app.schemas.risk_schema import (
    RiskContributingFactor,
    RiskPredictionRequest,
    RiskPredictionResponse,
)
from app.core.logger import logger


class RiskPredictionModel:
    """
    Placeholder risk model that returns a deterministic result
    based on simple threshold logic. Replaced in Phase 6 with
    a trained scikit-learn GradientBoostingClassifier.
    """

    def predict(self, request: RiskPredictionRequest) -> RiskPredictionResponse:
        logger.info(f"[RiskModel STUB] Predicting risk for uid={request.uid}")

        # Simple heuristic until real model is trained
        score = (
            (request.missed_checklists_7d * 10)
            + (request.consecutive_missed_days * 8)
            + (request.high_severity_reports_7d * 12)
            - (request.videos_watched_7d * 3)
            + ((1.0 - request.compliance_rate) * 30)
        )
        score = max(0.0, min(100.0, float(score)))

        if score >= 65:
            risk_level = "high"
        elif score >= 35:
            risk_level = "medium"
        else:
            risk_level = "low"

        factors = []
        if request.missed_checklists_7d >= 3:
            factors.append(RiskContributingFactor(
                factor="missed_checklists",
                impact="high",
                description=f"Missed {request.missed_checklists_7d} checklists in the last 7 days.",
            ))
        if request.compliance_rate < 0.6:
            factors.append(RiskContributingFactor(
                factor="low_compliance",
                impact="high",
                description=f"Compliance rate is {request.compliance_rate:.0%} — below the 60% threshold.",
            ))
        if request.high_severity_reports_7d >= 2:
            factors.append(RiskContributingFactor(
                factor="high_severity_reports",
                impact="medium",
                description=f"Filed {request.high_severity_reports_7d} high-severity reports this week.",
            ))

        return RiskPredictionResponse(
            uid=request.uid,
            risk_level=risk_level,
            risk_score=score,
            contributing_factors=factors,
            model_confidence=0.60,  # stub confidence
        )


# Singleton instance loaded at startup
risk_model = RiskPredictionModel()
```

**`backend/app/ml/image_model.py`**

```python
"""
Image Hazard Detection Engine — Stub for Phase 1.
Full MobileNetV2 TensorFlow implementation in Phase 6.
"""
from app.schemas.image_schema import ImageDetectionResponse
from app.core.logger import logger


class ImageDetectionModel:
    """
    Placeholder that returns a safe result for all images.
    Replaced in Phase 6 with a fine-tuned MobileNetV2 classifier.
    """

    def predict(self, image_bytes: bytes) -> ImageDetectionResponse:
        logger.info(f"[ImageModel STUB] Analyzing image ({len(image_bytes)} bytes)")
        return ImageDetectionResponse(
            hazard_detected="safe",
            confidence=0.50,
            suggested_severity="low",
            correction_recommendation="No immediate action required. (Model stub — full analysis available in Phase 6.)",
            processing_time_ms=10,
        )


image_model = ImageDetectionModel()
```

**`backend/app/ml/behavior_engine.py`**

```python
"""
Behavior Analysis Engine — Stub for Phase 1.
Full pattern detection implementation in Phase 6.
"""
from datetime import datetime

from app.schemas.behavior_schema import BehaviorAnalysisRequest, BehaviorAnalysisResponse
from app.core.logger import logger


class BehaviorAnalysisEngine:
    """
    Placeholder that returns an empty pattern result.
    Full implementation in Phase 6.
    """

    def analyze(self, request: BehaviorAnalysisRequest) -> BehaviorAnalysisResponse:
        logger.info(f"[BehaviorEngine STUB] Analyzing uid={request.uid}")
        return BehaviorAnalysisResponse(
            uid=request.uid,
            analysis_window_days=30,
            patterns_found=[],
            overall_behavior_score=1.0,
            last_analyzed_at=datetime.utcnow().isoformat(),
        )


behavior_engine = BehaviorAnalysisEngine()
```

**`backend/app/ml/recommendation_engine.py`**

```python
"""
Personalized Recommendation Engine — Stub for Phase 1.
Full content-matching logic in Phase 6.
"""
from app.schemas.recommendation_schema import RecommendationRequest, RecommendationResponse
from app.core.logger import logger


class RecommendationEngine:
    """
    Placeholder that returns a default PPE video recommendation.
    Full personalization logic in Phase 6.
    """

    def recommend(self, request: RecommendationRequest) -> RecommendationResponse:
        logger.info(f"[RecommendationEngine STUB] Recommending for uid={request.uid}")
        return RecommendationResponse(
            uid=request.uid,
            recommended_video_id="default_ppe_intro",
            recommendation_reason="Default recommendation: PPE fundamentals apply to all workers.",
            safety_tip="Always wear your PPE before entering the mine. Your hard hat protects you from roof falls.",
            fallback_category="ppe",
        )


recommendation_engine = RecommendationEngine()
```

### 2.9 Write API Route Handlers

**`backend/app/api/v1/router.py`**

```python
from fastapi import APIRouter
from app.api.v1 import risk, behavior, image_detect, recommendations

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(risk.router, prefix="/risk", tags=["Risk Prediction"])
api_v1_router.include_router(behavior.router, prefix="/behavior", tags=["Behavior Analysis"])
api_v1_router.include_router(image_detect.router, prefix="/image", tags=["Image Detection"])
api_v1_router.include_router(recommendations.router, prefix="/recommendations", tags=["Recommendations"])
```

**`backend/app/api/v1/risk.py`**

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.risk_model import risk_model
from app.schemas.risk_schema import RiskPredictionRequest, RiskPredictionResponse

router = APIRouter()


@router.post("/predict", response_model=RiskPredictionResponse)
async def predict_risk(
    request: RiskPredictionRequest,
    current_user: dict = Depends(get_current_user),
) -> RiskPredictionResponse:
    """
    Predict a worker's current risk level based on their behavioral features.
    Requires a valid Firebase ID token in the Authorization header.
    """
    return risk_model.predict(request)
```

**`backend/app/api/v1/behavior.py`**

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.behavior_engine import behavior_engine
from app.schemas.behavior_schema import BehaviorAnalysisRequest, BehaviorAnalysisResponse

router = APIRouter()


@router.post("/analyze", response_model=BehaviorAnalysisResponse)
async def analyze_behavior(
    request: BehaviorAnalysisRequest,
    current_user: dict = Depends(get_current_user),
) -> BehaviorAnalysisResponse:
    """
    Analyze a worker's behavior patterns over the last 30 days.
    """
    return behavior_engine.analyze(request)
```

**`backend/app/api/v1/image_detect.py`**

```python
from fastapi import APIRouter, Depends, File, UploadFile
from app.api.deps import get_current_user
from app.ml.image_model import image_model
from app.schemas.image_schema import ImageDetectionResponse

router = APIRouter()


@router.post("/detect", response_model=ImageDetectionResponse)
async def detect_hazard(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
) -> ImageDetectionResponse:
    """
    Analyze an uploaded image for safety hazards.
    Accepts JPEG or PNG. Max size enforced at the nginx/reverse-proxy layer.
    """
    image_bytes = await file.read()
    return image_model.predict(image_bytes)
```

**`backend/app/api/v1/recommendations.py`**

```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.ml.recommendation_engine import recommendation_engine
from app.schemas.recommendation_schema import RecommendationRequest, RecommendationResponse

router = APIRouter()


@router.post("/", response_model=RecommendationResponse)
async def get_recommendations(
    request: RecommendationRequest,
    current_user: dict = Depends(get_current_user),
) -> RecommendationResponse:
    """
    Get a personalized video recommendation and safety tip for a worker.
    """
    return recommendation_engine.recommend(request)
```

**`backend/app/api/deps.py`**

```python
from fastapi import Depends
from app.core.security import verify_firebase_token


async def get_current_user(
    token_data: dict = Depends(verify_firebase_token),
) -> dict:
    """
    Dependency that returns the verified Firebase user data.
    Inject into any route that requires authentication.
    """
    return token_data
```

### 2.10 Write `backend/app/main.py`

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_v1_router
from app.config import settings
from app.core.firebase_admin import initialize_firebase
from app.core.logger import logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — runs setup on start, cleanup on shutdown."""
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    initialize_firebase()
    logger.info("All services initialized. Ready to serve requests.")
    yield
    logger.info("Shutting down MiningGuard AI Backend.")


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="AI-powered safety analysis backend for MiningGuard mobile app.",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,  # Disable Swagger in production
    redoc_url="/redoc" if settings.debug else None,
)

# CORS — allow Flutter app to call the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

# Register routes
app.include_router(api_v1_router)


@app.get("/health")
async def health_check():
    """Liveness probe endpoint for Render.com / Cloud Run health checks."""
    return {"status": "healthy", "version": settings.app_version}
```

### 2.11 Create `backend/.env.example`

```env
# Copy this file to .env and fill in your real values.
# NEVER commit the .env file to git.

APP_NAME=MiningGuard AI Backend
DEBUG=true

# Path to your Firebase service account key JSON
# Download from: Firebase Console → Project Settings → Service Accounts → Generate new private key
FIREBASE_CREDENTIALS_PATH=firebase-service-account.json
FIREBASE_PROJECT_ID=your-firebase-project-id

# CORS
ALLOWED_ORIGINS=["http://localhost:3000","http://10.0.2.2:3000"]

# ML Model Paths (relative to backend/ directory)
RISK_MODEL_PATH=models/risk_model.pkl
IMAGE_MODEL_PATH=models/image_model.h5
```

### 2.12 Write `backend/Dockerfile`

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for TensorFlow and image processing
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies first (layer cache optimization)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create models directory
RUN mkdir -p models

# Non-root user for security
RUN adduser --disabled-password --gecos '' appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## STEP 3 — Firebase Configuration Files

### 3.1 Write `firebase/firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper Functions ────────────────────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    function isWorker() {
      return isAuthenticated() && getUserRole() == 'worker';
    }

    function isSupervisor() {
      return isAuthenticated() && getUserRole() == 'supervisor';
    }

    function isAdmin() {
      return isAuthenticated() && getUserRole() == 'admin';
    }

    function isSupervisorOrAdmin() {
      return isAuthenticated() && (getUserRole() == 'supervisor' || getUserRole() == 'admin');
    }

    function getUserMineId() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.mineId;
    }

    // ── Users Collection ────────────────────────────────────────────────────
    // NOTE: Phase 1 uses permissive rules for development.
    // Phase 9 tightens these to enforce mine-level isolation.

    match /users/{uid} {
      allow read: if isAuthenticated() && (isOwner(uid) || isSupervisorOrAdmin());
      allow create: if isAuthenticated() && isOwner(uid);
      allow update: if isAuthenticated() && (isOwner(uid) || isAdmin());
      allow delete: if isAdmin();
    }

    // ── Mines Collection ─────────────────────────────────────────────────────
    match /mines/{mineId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // ── Checklists Collection ─────────────────────────────────────────────────
    match /checklists/{checklistId} {
      allow read: if isAuthenticated() && (
        resource.data.uid == request.auth.uid || isSupervisorOrAdmin()
      );
      allow create: if isAuthenticated() &&
        request.resource.data.uid == request.auth.uid;
      allow update: if isAuthenticated() &&
        resource.data.uid == request.auth.uid;
      allow delete: if isAdmin();
    }

    // ── Hazard Reports Collection ─────────────────────────────────────────────
    match /hazard_reports/{reportId} {
      allow read: if isAuthenticated() && (
        resource.data.reporterId == request.auth.uid || isSupervisorOrAdmin()
      );
      allow create: if isAuthenticated() &&
        request.resource.data.reporterId == request.auth.uid;
      allow update: if isAuthenticated() && (
        resource.data.reporterId == request.auth.uid || isSupervisorOrAdmin()
      );
      allow delete: if isAdmin();
    }

    // ── Safety Videos Collection ──────────────────────────────────────────────
    match /safety_videos/{videoId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // ── Alerts Collection ─────────────────────────────────────────────────────
    match /alerts/{alertId} {
      allow read: if isAuthenticated() && (
        resource.data.userId == request.auth.uid || isSupervisorOrAdmin()
      );
      allow create: if isSupervisorOrAdmin();  // Only supervisor/admin create alerts
      allow update: if isAuthenticated() &&
        resource.data.userId == request.auth.uid;  // Worker can mark as read
      allow delete: if isAdmin();
    }
  }
}
```

### 3.2 Write `firebase/firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "checklists",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "uid", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "checklists",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "mineId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "hazard_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "reporterId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "hazard_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "mineId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "alerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isRead", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "mineId", "order": "ASCENDING" },
        { "fieldPath": "riskLevel", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### 3.3 Write `firebase/storage.rules`

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // ── Helper Functions ─────────────────────────────────────────────────────

    function isAuthenticated() {
      return request.auth != null;
    }

    function isValidMediaFile() {
      return request.resource.contentType.matches('image/.*')
          || request.resource.contentType.matches('video/.*')
          || request.resource.contentType.matches('audio/.*');
    }

    function isUnderSizeLimit() {
      // 100 MB maximum per file
      return request.resource.size <= 100 * 1024 * 1024;
    }

    // ── Hazard Report Media ───────────────────────────────────────────────────
    match /reports/{mineId}/{reportId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated()
          && isValidMediaFile()
          && isUnderSizeLimit();
      allow delete: if isAuthenticated();
    }

    // ── Video Thumbnails ──────────────────────────────────────────────────────
    match /thumbnails/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // ── Default: deny all other paths ────────────────────────────────────────
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3.4 Write `firebase/firebase.json`

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

---

## STEP 4 — CI/CD Pipeline

### 4.1 Write `.github/workflows/flutter_ci.yml`

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'mobile/**'
      - '.github/workflows/flutter_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'mobile/**'

jobs:
  build-and-test:
    name: Build & Test Flutter App
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set Up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          channel: 'stable'

      - name: Get Dependencies
        working-directory: mobile
        run: flutter pub get

      - name: Verify Formatting
        working-directory: mobile
        run: dart format --output=none --set-exit-if-changed lib/

      - name: Run Dart Analyzer
        working-directory: mobile
        run: flutter analyze --fatal-infos

      - name: Run Unit Tests
        working-directory: mobile
        run: flutter test test/unit/ --coverage

      - name: Build APK (Debug)
        working-directory: mobile
        # Requires google-services.json; skip in CI with placeholder
        run: |
          if [ -f "android/app/google-services.json" ]; then
            flutter build apk --debug
          else
            echo "google-services.json not present — skipping APK build in CI."
          fi
```

### 4.2 Write `.github/workflows/fastapi_ci.yml`

```yaml
name: FastAPI CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/fastapi_ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

jobs:
  test:
    name: Test FastAPI Backend
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set Up Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Dependencies
        working-directory: backend
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Lint with Black
        working-directory: backend
        run: black --check app/

      - name: Sort Imports Check
        working-directory: backend
        run: isort --check-only app/

      - name: Run Tests
        working-directory: backend
        env:
          DEBUG: "true"
          FIREBASE_CREDENTIALS_PATH: "test-credentials.json"
          FIREBASE_PROJECT_ID: "test-project"
        run: pytest tests/ -v --tb=short
```

---

## STEP 5 — Documentation

### 5.1 Write `docs/setup.md`

```markdown
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
```

### 5.2 Write Root `.gitignore`

```gitignore
# ── Flutter ─────────────────────────────────────────────────────────────────
mobile/.dart_tool/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/build/
mobile/.packages
mobile/pubspec.lock  # Include this for reproducible builds on teams — remove this line

# Firebase generated files
mobile/lib/firebase_options.dart   # REMOVE THIS LINE once configured — track in git

# Android local config
mobile/android/local.properties
mobile/android/key.properties
mobile/android/*.jks

# ── Python / FastAPI ─────────────────────────────────────────────────────────
backend/__pycache__/
backend/**/__pycache__/
backend/*.pyc
backend/*.pyo
backend/venv/
backend/.venv/
backend/.env                       # Never commit real env values
backend/firebase-service-account.json  # Never commit service account key
backend/models/*.pkl               # Trained model files (too large for git)
backend/models/*.h5

# ── IDE ──────────────────────────────────────────────────────────────────────
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db

# ── CI artifacts ─────────────────────────────────────────────────────────────
coverage/
.coverage
htmlcov/
```

### 5.3 Write Root `README.md`

```markdown
# ⛏️ MiningGuard

**AI-Powered Mining Safety Companion for Indian Mine Workers**

> Built for India's 3.5 million mine workers · Aligned with DGMS, MSHA, HSE, WorkSafe

---

## What Is MiningGuard?

MiningGuard is a Flutter mobile application that uses machine learning to:
- Predict which workers are at risk of an accident before it happens
- Analyze hazard photos to identify safety violations
- Detect unsafe behavioral patterns over time
- Deliver personalized safety training every day, in the worker's own language

---

## Repository Structure

```
miningguard/
├── mobile/        Flutter Android app
├── backend/       FastAPI AI backend (Python)
├── firebase/      Firestore rules, Storage rules, Indexes
├── docs/          Setup guides and architecture docs
└── .github/       CI/CD pipelines (GitHub Actions)
```

## Quick Start

See [docs/setup.md](docs/setup.md) for the complete setup guide.

## Tech Stack

Flutter · Firebase · FastAPI · Scikit-learn · TensorFlow · Riverpod · GoRouter

## Phase Status

- [x] Phase 1 — Project Foundation & Setup
- [ ] Phase 2 — Authentication & User Management
- [ ] Phase 3 — Daily Safety Checklist
- [ ] Phase 4 — Hazard Reporting System
- [ ] Phase 5 — Safety Education Module
- [ ] Phase 6 — AI Backend & Machine Learning
- [ ] Phase 7 — Dashboards & Analytics
- [ ] Phase 8 — Notifications & Real-Time Sync
- [ ] Phase 9 — Multi-Language, Offline & Security
- [ ] Phase 10 — Testing, Deployment & Launch
```

---

## STEP 6 — Verification Checklist

After completing all steps above, the agent must verify every item below before declaring Phase 1 complete. A failed item must be fixed before moving on.

### Flutter Verification

```bash
cd mobile

# 1. Dependencies resolve without errors
flutter pub get

# 2. No analysis warnings or errors
flutter analyze

# 3. App builds in debug mode
# (Requires google-services.json — if not available, confirm Dart code compiles)
flutter build apk --debug

# 4. Tests pass (no tests yet — confirm test runner itself works)
flutter test
```

Expected: Zero errors, zero warnings. The app opens to the Splash placeholder screen.

### FastAPI Verification

```bash
cd backend
source venv/bin/activate

# 1. App starts without errors
uvicorn app.main:app --reload --port 8000

# 2. Health check responds
curl http://localhost:8000/health
# Expected: {"status":"healthy","version":"1.0.0"}

# 3. Swagger UI accessible (debug mode only)
# Open: http://localhost:8000/docs
# Expected: All 5 endpoints visible (health + 4 AI endpoints)

# 4. Tests pass
pytest tests/ -v
```

### File Structure Verification

Confirm that every file listed in the directory tree in the introduction exists. No file may be missing. Use the following command from the project root:

```bash
find . -type f -name "*.dart" | sort
find . -type f -name "*.py" | sort
find . -type f -name "*.yaml" -o -name "*.yml" | sort
```

### Security Verification

Confirm the following files are listed in `.gitignore` and do NOT appear in `git status`:

- `backend/.env`
- `backend/firebase-service-account.json`
- `mobile/lib/firebase_options.dart` (until real values are populated)
- `mobile/android/key.properties`

---

## STEP 7 — Handoff Notes for Phase 2

When Phase 1 is confirmed complete, record these handoff facts that Phase 2 will depend on:

1. **Auth Provider Location:** `lib/shared/providers/firebase_providers.dart` — Phase 2 must import `firebaseAuthProvider` and `authStateChangesProvider` from here. Never instantiate `FirebaseAuth.instance` directly in feature code.

2. **User Model Location:** `lib/shared/models/user_model.dart` — Phase 2 writes user profiles using `UserModel.toFirestore()` and reads them using `UserModel.fromFirestore()`. Do not create a parallel user model.

3. **Router Location:** `lib/core/router/app_router.dart` — Phase 2 replaces the placeholder screens at `AppRoutes.login`, `AppRoutes.signup`, and `AppRoutes.languageSelect` with real screens. The router itself must not be recreated.

4. **Firestore Collection Names:** Always use the constants in `AppConstants` — never hardcode collection name strings in service files.

5. **Backend Auth Pattern:** Every FastAPI route that handles real user data must use `Depends(get_current_user)` from `app/api/deps.py`. The security module in `app/core/security.py` handles token verification.

6. **Error Handling:** All service-layer exceptions must be wrapped in `AppException` before being surfaced to the UI layer.

---

*MiningGuard Phase 1 Execution Prompt · Version 1.0*
*Stack: Flutter 3.19 · Firebase · FastAPI · Python 3.11 · Scikit-learn · TensorFlow*
*Total files to create in Phase 1: ~45 files across Flutter, FastAPI, Firebase, and CI/CD*

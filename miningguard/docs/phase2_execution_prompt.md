# MiningGuard — Phase 2 Execution Prompt
## Authentication & User Management

> **How to use this prompt:** Copy the entire contents of each section below and give it to your AI coding assistant (Claude, Copilot, Cursor, etc.) as a task. Each section is a self-contained prompt that builds on the previous one. Complete them in order.

---

## Context Block (Prepend to Every Prompt)

```
You are building MiningGuard — an AI-powered mining safety companion app.

Tech stack:
- Flutter (Dart) — mobile app
- Firebase Auth — authentication (email/password + phone OTP)
- Cloud Firestore — database
- Riverpod — state management
- GoRouter — navigation

Project folder structure (already scaffolded in Phase 1):
lib/
├── core/
│   ├── router/
│   ├── services/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── checklist/
│   ├── hazard_report/
│   ├── education/
│   └── dashboard/
└── shared/
    ├── models/
    ├── widgets/
    └── constants/

Firebase project is already initialized. pubspec.yaml already includes:
- firebase_core, firebase_auth, cloud_firestore
- flutter_riverpod, riverpod_annotation
- go_router
- intl (for localization)

Do not re-scaffold the project. Write only the files relevant to the task.
Always use Riverpod for state. Never use setState or Provider.
Use GoRouter for all navigation. Never use Navigator.push directly.
```

---

## Prompt 1 — User Data Model

```
Task: Create the UserModel and UserRole enum for MiningGuard.

File to create: lib/shared/models/user_model.dart

Requirements:
1. Create an enum UserRole with values: worker, supervisor, admin

2. Create a UserModel class with these fields:
   - uid (String) — Firebase Auth UID
   - fullName (String)
   - mineId (String) — links worker to their mine
   - role (UserRole)
   - department (String)
   - shift (String) — values: "morning", "afternoon", "night"
   - preferredLanguage (String) — values: "en", "hi", "bn", "te", "mr", "or"
   - riskScore (double) — 0 to 100, default 0
   - riskLevel (String) — "low", "medium", "high", default "low"
   - complianceRate (double) — 0.0 to 1.0, default 1.0
   - totalHazardReports (int) — default 0
   - consecutiveMissedDays (int) — default 0
   - fcmToken (String?) — nullable, for push notifications
   - createdAt (DateTime)
   - lastActiveAt (DateTime)

3. Include:
   - fromFirestore(DocumentSnapshot doc) factory constructor
   - toFirestore() → Map<String, dynamic> method
   - copyWith() method
   - Immutable class using final fields

4. Add a computed getter isHighRisk that returns true when riskLevel == "high"

Keep the file clean, well-commented, and production-ready.
```

---

## Prompt 2 — Auth Service

```
Task: Create the AuthService class for MiningGuard.

File to create: lib/features/auth/data/auth_service.dart

Requirements:
1. Create a class AuthService that wraps Firebase Auth operations.

2. Implement these methods:

   Future<UserCredential> signInWithEmail(String email, String password)
   — signs in using email/password
   — throws AuthException with readable message on failure
   — handle: wrong-password, user-not-found, too-many-requests

   Future<void> sendOtp({
     required String phoneNumber,
     required Function(PhoneAuthCredential) onAutoVerified,
     required Function(String verificationId, int? resendToken) onCodeSent,
     required Function(FirebaseAuthException) onFailed,
   })
   — sends OTP to phone number
   — follows Firebase phone auth flow exactly

   Future<UserCredential> verifyOtp(String verificationId, String smsCode)
   — verifies the OTP entered by user
   — throws readable AuthException on wrong code

   Future<void> signOut()
   — signs out from Firebase Auth

   Stream<User?> get authStateChanges
   — wraps FirebaseAuth.instance.authStateChanges()

   Future<String?> getCurrentToken()
   — returns current user ID token for FastAPI calls
   — returns null if not signed in

3. Create a custom AuthException class with a message field.

4. The class should be instantiable (not static). It will be injected via Riverpod.
```

---

## Prompt 3 — User Repository

```
Task: Create the UserRepository class for MiningGuard.

File to create: lib/features/auth/data/user_repository.dart

Requirements:
1. Create a class UserRepository that handles all Firestore operations for user data.

2. Use the UserModel from lib/shared/models/user_model.dart.

3. Implement these methods:

   Future<void> createUser(UserModel user)
   — writes a new user document to Firestore at path: users/{uid}
   — throws if document already exists (do not silently overwrite)

   Future<UserModel?> getUser(String uid)
   — fetches user document from Firestore
   — returns null if document does not exist
   — maps Firestore data to UserModel via fromFirestore

   Stream<UserModel?> watchUser(String uid)
   — returns a real-time stream of the user document
   — maps DocumentSnapshot to UserModel?
   — emits null if document deleted

   Future<void> updateUser(String uid, Map<String, dynamic> fields)
   — partial update using Firestore .update()
   — only updates the fields passed in (does not overwrite entire document)

   Future<void> updateFcmToken(String uid, String token)
   — convenience method to update only the fcmToken field

   Future<void> updateLastActive(String uid)
   — updates lastActiveAt to DateTime.now()

4. The class takes a FirebaseFirestore instance in its constructor (for testability).
```

---

## Prompt 4 — Riverpod Providers

```
Task: Create all Riverpod providers needed for authentication in MiningGuard.

File to create: lib/features/auth/domain/auth_providers.dart

Requirements:
1. Provide the following providers:

   authServiceProvider
   — Provider<AuthService>
   — returns AuthService instance

   userRepositoryProvider
   — Provider<UserRepository>
   — returns UserRepository with FirebaseFirestore.instance

   authStateProvider
   — StreamProvider<User?>
   — watches AuthService.authStateChanges
   — used by GoRouter redirect to decide if user is logged in

   currentUserProvider
   — StreamProvider<UserModel?>
   — depends on authStateProvider
   — when auth state has a uid, watches UserRepository.watchUser(uid)
   — emits null when signed out

   currentUserRoleProvider
   — Provider<UserRole?>
   — reads currentUserProvider
   — returns null if loading or signed out
   — returns UserRole from UserModel otherwise

2. Use Riverpod's ref.watch and ref.read correctly.
3. Use AsyncValue for all stream-based providers.
4. Add brief doc comments on each provider explaining what it exposes.
```

---

## Prompt 5 — Login Screen

```
Task: Build the Login Screen UI for MiningGuard.

File to create: lib/features/auth/presentation/screens/login_screen.dart

Design requirements:
- App name "MiningGuard" at the top with a helmet icon (use Icons.engineering)
- Tab bar with two tabs: "Email" and "Phone"
- Large, accessible UI suitable for workers wearing gloves (minimum tap target 48x48dp)
- Use the color scheme: primary #F5A623 (amber/orange), background dark charcoal #1A1A2E
- All text large (minimum 16sp for body, 18sp for inputs)

Email tab:
- Email text field
- Password text field with show/hide toggle
- "Sign In" button (full width, amber background)
- Loading indicator replaces button while signing in
- Error message displayed below button on failure

Phone tab:
- Phone number field (with +91 prefix for India default)
- "Send OTP" button
- After OTP is sent: a 6-digit OTP input field appears
- "Verify OTP" button
- 60-second countdown "Resend OTP" button

State management:
- Use ConsumerStatefulWidget
- Use ref.read(authServiceProvider) for auth calls
- On successful login:
  - Fetch user from Firestore via ref.read(userRepositoryProvider)
  - If user document does not exist, navigate to /onboarding
  - If user document exists, navigate to /home
  - Use context.go() from GoRouter, never Navigator.push

Error handling:
- Show SnackBar for AuthException messages
- Never expose Firebase internal error codes to the user

Import path assumptions:
- AuthService: package:miningguard/features/auth/data/auth_service.dart
- Auth providers: package:miningguard/features/auth/domain/auth_providers.dart
```

---

## Prompt 6 — Signup & Onboarding Flow

```
Task: Build the Signup and Language Selection screens for MiningGuard.

Files to create:
- lib/features/auth/presentation/screens/signup_screen.dart
- lib/features/auth/presentation/screens/language_selection_screen.dart

--- SIGNUP SCREEN ---

This screen is shown when a user is authenticated (has a Firebase Auth account) but
has no Firestore user document yet.

Fields to collect (single scrollable form):
1. Full Name (text, required)
2. Mine ID (text, required — 6-character alphanumeric code)
3. Department (dropdown: Underground Operations, Surface Operations, Engineering, Safety, Administration)
4. Shift (segmented control or radio buttons: Morning 🌅, Afternoon 🌇, Night 🌙)
5. Role (dropdown, required: Worker, Supervisor — Admin accounts are created by existing admins only)

On submit:
- Validate all fields (show inline errors)
- Show loading state
- Create UserModel with these values + uid from Firebase Auth + defaults:
  riskScore=0, riskLevel="low", complianceRate=1.0, consecutiveMissedDays=0
  createdAt=now, lastActiveAt=now
- Call userRepository.createUser(userModel)
- Navigate to /language-selection using context.go()

--- LANGUAGE SELECTION SCREEN ---

Full-screen language picker. Shown only once after signup.
Title: "Choose your language / अपनी भाषा चुनें"

Display 6 large tappable cards in a grid (2 columns):
- English — "English"
- Hindi — "हिन्दी"
- Bengali — "বাংলা"
- Telugu — "తెలుగు"
- Marathi — "मराठी"
- Odia — "ଓଡ଼ିଆ"

Each card shows the language name in its own script (large, 22sp).
Selected card has an amber border and checkmark.

On "Continue" button tap:
- Call userRepository.updateUser(uid, {"preferredLanguage": selectedCode})
- Navigate to /home using context.go()

Both screens use ConsumerStatefulWidget and Riverpod providers.
```

---

## Prompt 7 — Role-Based GoRouter Configuration

```
Task: Configure GoRouter for MiningGuard with role-based redirects.

File to modify: lib/core/router/app_router.dart
(This file was created in Phase 1 as a skeleton. Replace its contents entirely.)

Requirements:
1. Define these routes:
   /splash         → SplashScreen (shows app logo for 2 seconds, then redirects)
   /login          → LoginScreen
   /signup         → SignupScreen
   /language       → LanguageSelectionScreen
   /home           → HomeScreen (placeholder widget for now)
   /supervisor     → SupervisorDashboardScreen (placeholder)
   /admin          → AdminPanelScreen (placeholder)

2. Implement a redirect function with this logic:

   Step 1 — If authStateProvider is loading: show /splash
   Step 2 — If user is NOT authenticated: redirect to /login
            (except if already on /login)
   Step 3 — If user IS authenticated but currentUserProvider has no Firestore doc:
            redirect to /signup
   Step 4 — If on /signup or /language but user already has a doc:
            redirect to role-appropriate home
   Step 5 — Role-based home routing:
            - admin → /admin
            - supervisor → /supervisor
            - worker → /home

3. Create a routerProvider using Provider<GoRouter> with Riverpod.
   Use ref.watch(authStateProvider) and ref.watch(currentUserProvider) inside it.
   Use router.refresh() to trigger re-evaluation when auth state changes.

4. Add placeholder screen widgets inline at the bottom of this file for:
   HomeScreen, SupervisorDashboardScreen, AdminPanelScreen
   (just a Scaffold with a centered Text showing the screen name)
   These will be replaced in later phases.

5. Wire the router in main.dart:
   MaterialApp.router(
     routerConfig: ref.watch(routerProvider),
   )
```

---

## Prompt 8 — User Profile Screen

```
Task: Build the User Profile Screen for MiningGuard.

File to create: lib/features/auth/presentation/screens/profile_screen.dart

Requirements:
Display the logged-in worker's profile with these sections:

--- SECTION 1: Identity ---
- Avatar circle with worker's initials (first letter of first + last name)
- Full name (large, bold)
- Role badge (color-coded chip: Worker=blue, Supervisor=orange, Admin=red)
- Mine ID
- Department and Shift

--- SECTION 2: Safety Stats ---
Display as a row of 3 metric cards:
- Risk Level (color-coded: green/amber/red with icon)
- Compliance Rate (shown as percentage, e.g. "84%")
- Total Reports (count)

--- SECTION 3: Settings ---
List tile: "Preferred Language" → shows current language name → taps to language selection
List tile: "Shift Schedule" → shows current shift → taps to a shift picker bottom sheet
List tile: "Notification Preferences" → placeholder screen for Phase 8
List tile: "Sign Out" (red text) → shows confirmation dialog → calls authService.signOut() → routes to /login

Constraints:
- Workers CANNOT change their role or mine ID (do not show edit for these fields)
- Only admins can change roles (enforced at Firestore security rules level in Phase 9)
- Use ref.watch(currentUserProvider) to get live user data
- Shift picker bottom sheet: show Morning/Afternoon/Night options, call userRepository.updateUser on confirm
- Use ConsumerWidget

Show a loading shimmer (use a Container with grey color as placeholder) while currentUserProvider is loading.
Show an error message if currentUserProvider has an error.
```

---

## Prompt 9 — Session Persistence & Auth Guard

```
Task: Implement session persistence and auth state handling for MiningGuard.

Files to create or modify:

1. lib/core/services/session_service.dart (NEW)

   Create a SessionService class that:
   - On app launch, checks if a Firebase Auth user is already signed in
     (Firebase persists sessions automatically; this service wraps that check)
   - Calls userRepository.updateLastActive(uid) when a session is found
   - Provides a Future<bool> isSessionValid() method that:
       Returns true if: Firebase has a current user AND their Firestore document exists
       Returns false otherwise (stale auth without Firestore record)
   - If session is not valid (Firebase user exists but no Firestore doc): calls signOut()
     so the user is sent back to login cleanly

2. lib/core/services/fcm_token_service.dart (NEW)

   Create an FcmTokenService class that:
   - Has a method registerToken(String uid) that:
       Gets the current FCM token from FirebaseMessaging.instance.getToken()
       Calls userRepository.updateFcmToken(uid, token)
   - Listens to FirebaseMessaging.instance.onTokenRefresh and updates Firestore
     when the token changes
   - This should be called once after a successful login or app resume

3. lib/features/auth/presentation/widgets/auth_gate.dart (NEW)

   Create an AuthGate widget that:
   - Watches authStateProvider
   - While loading: shows a centered CircularProgressIndicator on dark background
   - When signed out: GoRouter handles redirect (this widget just returns const SizedBox())
   - When signed in: calls FcmTokenService().registerToken(uid) once
     (use ref.listen to detect sign-in event, not ref.watch to avoid repeated calls)
   - This widget wraps the router shell, not individual screens

All three classes accept their dependencies via constructor injection for testability.
```

---

## Prompt 10 — Firestore Security Rules (Auth Scope)

```
Task: Write Firestore security rules for the user data created in Phase 2.

This is NOT a Dart file. Create: firestore.rules

Write Firestore security rules that enforce:

USERS COLLECTION (users/{uid}):

  READ:
  - A user can read their own document (request.auth.uid == uid)
  - A supervisor can read documents where the user's mineId matches the supervisor's mineId
    (requires reading the supervisor's own document — use get() to fetch it)
  - An admin can read any user document

  CREATE:
  - Only the authenticated user can create their own document (request.auth.uid == uid)
  - The document must contain all required fields:
    uid, fullName, mineId, role, department, shift, preferredLanguage
  - Role can only be "worker" or "supervisor" on self-registration
    (role == "admin" is not allowed in the create rule)

  UPDATE:
  - A user can update only these fields on their own document:
    preferredLanguage, shift, fcmToken, lastActiveAt
  - They CANNOT change: uid, role, mineId, riskScore, riskLevel, complianceRate
    (these are updated only by the AI backend via Admin SDK)
  - A supervisor can update report-related fields on workers in their mine
  - An admin can update any field on any document

  DELETE:
  - Only admins can delete user documents

Helper functions to write:
  function isSignedIn() — checks request.auth != null
  function isOwner(uid) — checks request.auth.uid == uid
  function isAdmin() — checks caller's role field in Firestore
  function isSupervisor() — checks caller's role field

Add a comment above each rule block explaining what it enforces and why.
Format the file cleanly with consistent indentation.
```

---

## Prompt 11 — Phase 2 Integration Test

```
Task: Write integration tests for Phase 2 authentication flow.

File to create: integration_test/auth_flow_test.dart

Use flutter_test and integration_test packages.
Use Firebase Auth Emulator (configured in Phase 1).

Write tests for these scenarios:

TEST 1 — Email Sign In Success
  Given: A pre-seeded user in Firebase Auth emulator (email: test@miningguard.com, password: Test@1234)
  And: A corresponding user document in Firestore emulator
  When: User enters credentials and taps Sign In
  Then: User is navigated to /home (worker dashboard)

TEST 2 — Email Sign In Failure
  Given: Wrong password is entered
  When: User taps Sign In
  Then: An error SnackBar is shown
  And: User remains on /login

TEST 3 — New User Onboarding Flow
  Given: A Firebase Auth account exists (just auth, no Firestore doc)
  When: App launches with that user signed in
  Then: User is redirected to /signup
  When: User fills in all required fields and submits
  Then: Firestore user document is created
  And: User is navigated to /language
  When: User selects a language and taps Continue
  Then: preferredLanguage is updated in Firestore
  And: User is navigated to /home

TEST 4 — Role-Based Redirect
  Given: A supervisor user with a Firestore document (role: supervisor)
  When: They sign in
  Then: They are redirected to /supervisor, not /home

TEST 5 — Sign Out
  Given: A logged-in worker on /home
  When: They navigate to Profile and tap Sign Out and confirm
  Then: Firebase Auth session is cleared
  And: They are redirected to /login

Use emulator-safe test setup:
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  });
```

---

## Phase 2 Completion Checklist

Before moving to Phase 3, verify all of the following are working:

- [ ] Worker can sign in with email and password
- [ ] Worker can sign in with phone OTP
- [ ] New users are redirected to /signup after first auth
- [ ] Signup form validates all fields and creates Firestore document
- [ ] Language selection screen saves preference to Firestore
- [ ] Workers are routed to /home after onboarding
- [ ] Supervisors are routed to /supervisor after login
- [ ] Admins are routed to /admin after login
- [ ] Profile screen shows live user data from Firestore
- [ ] Language can be changed from Profile screen
- [ ] Shift can be changed from Profile screen
- [ ] Sign out clears session and routes to /login
- [ ] Reopening the app while logged in skips login screen
- [ ] FCM token is registered to Firestore after login
- [ ] All 5 integration tests pass against Firebase emulators
- [ ] Firestore security rules prevent workers from reading other workers' documents

---

## Notes for the Developer

**Execution order matters.** Run the prompts in sequence — later prompts import from files created by earlier ones.

**Firebase Emulator** must be running for Prompt 10 and 11 tests:
```bash
firebase emulators:start --only auth,firestore
```

**Admin SDK access** — riskScore, riskLevel, complianceRate, and complianceRate fields are intentionally write-protected from the Flutter app. They will only be updated by the FastAPI backend (Phase 6) using Firebase Admin SDK, which bypasses security rules.

**Language strings** — All hardcoded strings in the auth screens are temporary English placeholders. Full localization of these strings is done in Phase 9. For now, use the key names as placeholders (e.g., `Text('login.title')`).

---

*MiningGuard · Phase 2 Execution Guide · v1.0*
*Next: Phase 3 — Daily Safety Checklist System*

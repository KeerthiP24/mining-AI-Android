// Integration tests for Phase 2 authentication flow.
// Run against Firebase emulators:
//   firebase emulators:start --only auth,firestore
//   flutter test integration_test/auth_flow_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miningguard/core/router/app_router.dart';
import 'package:miningguard/firebase_options.dart';
import 'package:miningguard/shared/models/user_model.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

Future<void> _seedWorkerAuthAndDoc({
  String email = 'test@miningguard.com',
  String password = 'Test@1234',
  String uid = 'test-worker-uid',
}) async {
  await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
  final now = DateTime.now();
  await FirebaseFirestore.instance.collection('users').doc(uid).set(
        UserModel(
          uid: uid,
          fullName: 'Test Worker',
          mineId: 'MN0001',
          role: UserRole.worker,
          department: 'Safety',
          shift: 'morning',
          preferredLanguage: 'en',
          createdAt: now,
          lastActiveAt: now,
        ).toFirestore(),
      );
}

Future<void> _seedSupervisorAuthAndDoc() async {
  const email = 'supervisor@miningguard.com';
  const password = 'Test@1234';
  final cred = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
  final uid = cred.user!.uid;
  final now = DateTime.now();
  await FirebaseFirestore.instance.collection('users').doc(uid).set(
        UserModel(
          uid: uid,
          fullName: 'Test Supervisor',
          mineId: 'MN0001',
          role: UserRole.supervisor,
          department: 'Safety',
          shift: 'morning',
          preferredLanguage: 'en',
          createdAt: now,
          lastActiveAt: now,
        ).toFirestore(),
      );
}

Widget _app() => ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(appRouterProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );

// ── Setup ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8081);
  });

  tearDown(() async {
    // Sign out and clear emulator data between tests
    await FirebaseAuth.instance.signOut();
  });

  // ── TEST 1: Email sign-in success ─────────────────────────────────────────

  testWidgets('TEST 1 — email sign-in routes worker to /worker/home',
      (tester) async {
    await _seedWorkerAuthAndDoc();
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Should land on login screen
    expect(find.text('MiningGuard'), findsOneWidget);

    await tester.enterText(
        find.byType(TextField).at(0), 'test@miningguard.com');
    await tester.enterText(find.byType(TextField).at(1), 'Test@1234');
    await tester.tap(find.text('login.signIn'));
    await tester.pumpAndSettle();

    // Should navigate to worker home
    expect(find.text('Worker Home — Phase 3 coming soon'), findsOneWidget);
  });

  // ── TEST 2: Email sign-in failure ─────────────────────────────────────────

  testWidgets('TEST 2 — wrong password shows error and stays on login',
      (tester) async {
    await _seedWorkerAuthAndDoc();
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).at(0), 'test@miningguard.com');
    await tester.enterText(find.byType(TextField).at(1), 'WrongPassword!');
    await tester.tap(find.text('login.signIn'));
    await tester.pumpAndSettle();

    // Error message visible and still on login
    expect(find.text('MiningGuard'), findsOneWidget);
    expect(
      find.textContaining('Incorrect password'),
      findsOneWidget,
    );
  });

  // ── TEST 3: New user onboarding flow ──────────────────────────────────────

  testWidgets('TEST 3 — auth-only user is redirected through onboarding',
      (tester) async {
    // Create Firebase Auth account but NO Firestore doc
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'newuser@miningguard.com',
      password: 'Test@1234',
    );
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Sign in
    await tester.enterText(
        find.byType(TextField).at(0), 'newuser@miningguard.com');
    await tester.enterText(find.byType(TextField).at(1), 'Test@1234');
    await tester.tap(find.text('login.signIn'));
    await tester.pumpAndSettle();

    // Should land on signup screen
    expect(find.text('signup.title'), findsOneWidget);

    // Fill signup form
    await tester.enterText(find.byType(TextFormField).at(0), 'New Worker');
    await tester.enterText(find.byType(TextFormField).at(1), 'MN0002');

    // Select department
    await tester.tap(find.text('signup.department'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Safety').last);
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('signup.submit'));
    await tester.pumpAndSettle();

    // Should go to language selection
    expect(
      find.text('Choose your language\nअपनी भाषा चुनें'),
      findsOneWidget,
    );

    // Select Hindi
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('language.continue'));
    await tester.pumpAndSettle();

    // Should land on worker home
    expect(find.text('Worker Home — Phase 3 coming soon'), findsOneWidget);

    // Verify Firestore doc has preferredLanguage = 'hi'
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    expect(doc.data()?['preferredLanguage'], equals('hi'));
  });

  // ── TEST 4: Role-based redirect ───────────────────────────────────────────

  testWidgets('TEST 4 — supervisor is redirected to /supervisor/dashboard',
      (tester) async {
    await _seedSupervisorAuthAndDoc();
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).at(0), 'supervisor@miningguard.com');
    await tester.enterText(find.byType(TextField).at(1), 'Test@1234');
    await tester.tap(find.text('login.signIn'));
    await tester.pumpAndSettle();

    expect(
      find.text('Supervisor Dashboard — Phase 3 coming soon'),
      findsOneWidget,
    );
  });

  // ── TEST 5: Sign out ──────────────────────────────────────────────────────

  testWidgets('TEST 5 — sign out clears session and routes to /login',
      (tester) async {
    await _seedWorkerAuthAndDoc();
    await FirebaseAuth.instance.signOut();

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Sign in first
    await tester.enterText(
        find.byType(TextField).at(0), 'test@miningguard.com');
    await tester.enterText(find.byType(TextField).at(1), 'Test@1234');
    await tester.tap(find.text('login.signIn'));
    await tester.pumpAndSettle();

    // Navigate to profile
    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();

    // Tap sign out
    await tester.tap(find.text('profile.signOut').last);
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('profile.signOut').last);
    await tester.pumpAndSettle();

    // Should be back on login
    expect(find.text('MiningGuard'), findsOneWidget);
    expect(FirebaseAuth.instance.currentUser, isNull);
  });
}

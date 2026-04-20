import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/widgets/auth_gate.dart';
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

    return AuthGate(
      child: MaterialApp.router(
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
      ),
    );
  }
}

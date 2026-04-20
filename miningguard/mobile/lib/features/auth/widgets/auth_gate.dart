import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miningguard/core/services/fcm_token_service.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';
import 'package:miningguard/features/auth/services/user_repository.dart';

/// Wraps the router shell to handle:
/// - Loading state while Firebase resolves auth
/// - One-time FCM token registration on sign-in
///
/// GoRouter handles actual route redirects; this widget handles side-effects.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    // Show a splash-style loader while Firebase resolves the session
    if (authAsync.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF5A623)),
        ),
      );
    }

    // Register FCM token once when the user signs in (not on every rebuild)
    ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      final prevUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;

      if (nextUid != null && nextUid != prevUid) {
        FcmTokenService(
          messaging: FirebaseMessaging.instance,
          userRepository: ref.read(userRepositoryProvider),
        ).registerToken(nextUid);
      }
    });

    return child;
  }
}

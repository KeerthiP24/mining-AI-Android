import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miningguard/core/services/fcm_token_service.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';

/// Wraps the router shell to handle:
/// - Loading state while Firebase resolves auth
/// - FCM token registration on sign-in AND on every cold start while
///   already signed in (so users who installed before the FCM-permission
///   fix still get their token saved on the next launch).
///
/// GoRouter handles actual route redirects; this widget handles side-effects.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _registeredUid;

  void _registerIfNeeded(String? uid) {
    if (uid == null || uid == _registeredUid) return;
    _registeredUid = uid;
    FcmTokenService(
      messaging: FirebaseMessaging.instance,
      userRepository: ref.read(userRepositoryProvider),
    ).registerToken(uid);
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    // Show a bare splash while Firebase resolves the session.
    // Cannot use Scaffold here — MaterialApp hasn't mounted yet.
    if (authAsync.isLoading) {
      return const ColoredBox(
        color: Color(0xFF1A1A2E),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFF5A623)),
        ),
      );
    }

    // Cover the case where the user was already signed in when the app
    // started — `ref.listen` only fires on transitions, but we also want
    // to (re)register on cold start so previously-skipped users finally
    // save their token.
    _registerIfNeeded(authAsync.valueOrNull?.uid);

    // Catch later sign-ins after launch.
    ref.listen<AsyncValue>(authStateProvider, (previous, next) {
      _registerIfNeeded(next.valueOrNull?.uid);
    });

    return widget.child;
  }
}

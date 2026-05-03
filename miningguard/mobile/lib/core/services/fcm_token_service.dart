import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:miningguard/features/auth/services/user_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class FcmTokenService {
  FcmTokenService({
    required FirebaseMessaging messaging,
    required UserRepository userRepository,
  })  : _messaging = messaging,
        _userRepository = userRepository;

  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;

  Future<void> registerToken(String uid) async {
    // Step 1 — Android 13+ runtime POST_NOTIFICATIONS permission. The
    // OS-level system dialog only fires the first time; if the user has
    // ever dismissed it the prompt won't reappear, so on a denial we open
    // the app's notification settings page directly.
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    if (status.isPermanentlyDenied || status.isDenied) {
      await openAppSettings();
    }

    // Step 2 — Firebase / iOS-side permission (no-op on Android once
    // POST_NOTIFICATIONS is granted).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _userRepository.updateFcmToken(uid, token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _userRepository.updateFcmToken(uid, newToken);
    });
  }
}

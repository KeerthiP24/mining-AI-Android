import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:miningguard/features/auth/services/user_repository.dart';

/// Registers and keeps the FCM token for the current user up to date in
/// Firestore.  Accepts dependencies via constructor for testability.
class FcmTokenService {
  FcmTokenService({
    required FirebaseMessaging messaging,
    required UserRepository userRepository,
  })  : _messaging = messaging,
        _userRepository = userRepository;

  final FirebaseMessaging _messaging;
  final UserRepository _userRepository;

  /// Fetches the current FCM token and writes it to Firestore.
  /// Also subscribes to token refreshes so the record stays current.
  Future<void> registerToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _userRepository.updateFcmToken(uid, token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _userRepository.updateFcmToken(uid, newToken);
    });
  }
}

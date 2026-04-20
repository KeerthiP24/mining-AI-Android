import 'package:firebase_auth/firebase_auth.dart';
import 'package:miningguard/features/auth/services/auth_service.dart';
import 'package:miningguard/features/auth/services/user_repository.dart';

/// Validates and manages Firebase Auth sessions on app launch.
/// Accepts dependencies via constructor for testability.
class SessionService {
  SessionService({
    required FirebaseAuth auth,
    required UserRepository userRepository,
    required AuthService authService,
  })  : _auth = auth,
        _userRepository = userRepository,
        _authService = authService;

  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final AuthService _authService;

  /// Returns true when a Firebase user is signed in AND their Firestore
  /// document exists.  Returns false for stale auth (Firebase token exists
  /// but no Firestore record) — in that case the user is signed out so they
  /// land cleanly on the login screen.
  Future<bool> isSessionValid() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _userRepository.getUser(user.uid);
    if (doc == null) {
      // Stale auth — clean it up
      await _authService.signOut();
      return false;
    }

    await _userRepository.updateLastActive(user.uid);
    return true;
  }
}

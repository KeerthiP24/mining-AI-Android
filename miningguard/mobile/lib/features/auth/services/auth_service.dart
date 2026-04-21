import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by AuthService when a Firebase Auth operation fails with a
/// user-readable message (no Firebase error codes exposed to widgets).
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Wraps Firebase Auth operations for MiningGuard.
/// Inject via Riverpod; never instantiate directly in widget code.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException) onFailed,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: resendToken,
    );
  }

  Future<UserCredential> verifyOtp(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns the current user's ID token for FastAPI calls, or null when
  /// no user is signed in.
  Future<String?> getCurrentToken() async {
    return _auth.currentUser?.getIdToken();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check the code and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      default:
        return 'Sign in failed [$code]. Please try again.';
    }
  }
}

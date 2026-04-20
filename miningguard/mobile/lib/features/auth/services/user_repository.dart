import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miningguard/shared/models/user_model.dart';

/// Handles all Firestore operations for the users collection.
/// Accepts [FirebaseFirestore] via constructor for testability.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Creates a new user document at users/{uid}.
  /// Throws [StateError] if the document already exists.
  Future<void> createUser(UserModel user) async {
    final ref = _users.doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) {
      throw StateError('User document for ${user.uid} already exists.');
    }
    await ref.set(user.toFirestore());
  }

  /// Fetches the user document. Returns null if it does not exist.
  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserModel.fromFirestore(snapshot);
  }

  /// Real-time stream of the user document. Emits null if the document is
  /// deleted or does not exist.
  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  /// Partially updates the user document — only the supplied [fields] are
  /// written; all other fields are left unchanged.
  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await _users.doc(uid).update(fields);
  }

  /// Convenience method to update only the FCM token.
  Future<void> updateFcmToken(String uid, String token) async {
    await _users.doc(uid).update({'fcmToken': token});
  }

  /// Updates lastActiveAt to now.
  Future<void> updateLastActive(String uid) async {
    await _users.doc(uid).update({
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}

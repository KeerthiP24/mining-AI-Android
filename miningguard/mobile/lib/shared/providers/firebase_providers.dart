import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase service providers.
/// These are the single source of truth for Firebase instances throughout the app.
/// Every feature that needs Firestore, Auth, Storage, or FCM must
/// access them via these providers — never instantiate directly.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// Exposes the raw Firebase Auth state as a stream.
/// Prefer authStateProvider from auth_providers.dart for auth-gated features.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Convenience provider: current Firebase Auth user (not the Firestore model).
/// Returns null if not authenticated.
/// For the full UserModel use currentUserModelProvider in auth_providers.dart.
final firebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).value;
});

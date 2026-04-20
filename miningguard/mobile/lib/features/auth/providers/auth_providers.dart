import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miningguard/features/auth/services/auth_service.dart';
import 'package:miningguard/features/auth/services/user_repository.dart';
import 'package:miningguard/shared/models/user_model.dart';

/// Singleton [AuthService] instance backed by [FirebaseAuth.instance].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Singleton [UserRepository] instance backed by [FirebaseFirestore.instance].
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

/// Stream of the Firebase Auth state. Used by GoRouter's redirect to decide
/// whether a user is signed in.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Stream of the Firestore [UserModel] for the currently signed-in user.
/// Emits null when signed out or when no Firestore document exists yet
/// (i.e. user is authenticated but hasn't completed onboarding).
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

/// Convenience provider that exposes the [UserRole] of the current user.
/// Returns null while loading or when signed out.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserModelProvider).valueOrNull?.role;
});

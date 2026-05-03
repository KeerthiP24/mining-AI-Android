import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../data/education_repository.dart';
import '../data/video_of_day_service.dart';
import '../domain/safety_video.dart';
import '../domain/video_watch.dart';

// ── Repository / service singletons ──────────────────────────────────────────

final educationRepositoryProvider = Provider<EducationRepository>((ref) {
  return EducationRepository(ref.watch(firestoreProvider));
});

final videoOfDayServiceProvider = Provider<VideoOfDayService>((ref) {
  return VideoOfDayService(ref.watch(educationRepositoryProvider));
});

// ── Library streams ──────────────────────────────────────────────────────────

/// Full active video library scoped to the current user's role.
final videoLibraryProvider =
    StreamProvider.autoDispose<List<SafetyVideo>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(educationRepositoryProvider)
      .watchLibraryForRole(user.role.name);
});

/// Library filtered to a single category. `family` arg is the category key
/// from [VideoCategory], or `'all'` to get the full library.
final videosByCategoryProvider = StreamProvider.autoDispose
    .family<List<SafetyVideo>, String>((ref, category) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final repo = ref.watch(educationRepositoryProvider);
  if (category == 'all') {
    return repo.watchLibraryForRole(user.role.name);
  }
  return repo.watchByCategory(user.role.name, category);
});

// ── Video of the Day ─────────────────────────────────────────────────────────

/// Resolves today's recommended video. Cached on the user document — calls
/// within the same calendar day return the cached selection without rerunning
/// selection logic (handled inside [VideoOfDayService]).
final videoOfDayProvider = FutureProvider.autoDispose<SafetyVideo?>((ref) async {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return null;
  final library = await ref.watch(videoLibraryProvider.future);
  if (library.isEmpty) return null;
  return ref.watch(videoOfDayServiceProvider).getVideoForUser(
        user: user,
        allVideos: library,
      );
});

// ── Continue Watching ────────────────────────────────────────────────────────

final continueWatchingProvider =
    StreamProvider.autoDispose<List<VideoWatch>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref
      .watch(educationRepositoryProvider)
      .watchInProgressForUser(user.uid);
});

// ── UI state — currently selected category chip ──────────────────────────────

final selectedCategoryProvider = StateProvider.autoDispose<String>((_) => 'all');

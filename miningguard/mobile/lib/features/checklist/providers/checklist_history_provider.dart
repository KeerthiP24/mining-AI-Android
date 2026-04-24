import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../models/checklist.dart';
import 'checklist_provider.dart';

/// Streams the last [limit] checklist entries for the current user.
/// Default is 7 days; the UI can request more via the family overload.
final checklistHistoryProvider =
    StreamProvider.family<List<Checklist>, int>((ref, limit) {
  final userAsync = ref.watch(currentUserModelProvider);
  final uid = userAsync.valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(checklistRepositoryProvider)
      .watchHistory(uid, limit: limit);
});

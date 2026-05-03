import '../../../shared/models/user_model.dart';
import '../domain/safety_video.dart';
import 'education_repository.dart';

/// Maps a [HazardCategory] firestoreValue (Phase 4) to one or more video tags
/// the recommendation can match against.
const Map<String, List<String>> _hazardCategoryToTags = {
  'roof_fall': ['roof_support', 'roof', 'roof_fall'],
  'gas_leak': ['gas_ventilation', 'gas', 'methane', 'ventilation'],
  'fire': ['fire', 'emergency'],
  'machinery': ['machinery'],
  'electrical': ['electrical', 'machinery'],
  'other': [],
};

/// Selects today's "Video of the Day" for a user.
///
/// This service runs entirely client-side for Phase 5. Phase 6 will replace
/// the body of [getVideoForUser] with a FastAPI call; the public signature
/// is intentionally narrow so the swap is transparent.
class VideoOfDayService {
  VideoOfDayService(this._repo);

  final EducationRepository _repo;

  /// Returns the recommended video for [user] today, or null if the library
  /// is empty.
  ///
  /// [allVideos] is the full library accessible to the user's role. Pass it
  /// in rather than re-querying so the caller can stream it once.
  /// [now] is overridable for tests; defaults to [DateTime.now].
  Future<SafetyVideo?> getVideoForUser({
    required UserModel user,
    required List<SafetyVideo> allVideos,
    DateTime? now,
  }) async {
    if (allVideos.isEmpty) return null;
    final today = now ?? DateTime.now();
    final todayKey = _isoDate(today);

    // Step 1 — same-day cache: return immediately if already chosen today.
    final cached = await _repo.readCachedVideoOfDay(user.uid);
    if (cached.date == todayKey && cached.videoId != null) {
      final hit = allVideos.where((v) => v.videoId == cached.videoId);
      if (hit.isNotEmpty) return hit.first;
      // Cached pointer no longer exists in the library — fall through.
    }

    final recentlyWatched =
        await _repo.getRecentlyCompletedVideoIds(user.uid, days: 7);
    final lastWatchedAt = await _repo.getLastWatchedAtByVideo(user.uid);

    bool notRecentlyWatched(SafetyVideo v) =>
        !recentlyWatched.contains(v.videoId);

    SafetyVideo? selected;

    // Priority 1 — match a recent hazard report's category to video tags.
    final recentCategories =
        await _repo.getRecentHazardCategories(user.uid, days: 7);
    if (recentCategories.isNotEmpty) {
      final wantedTags = <String>{};
      for (final cat in recentCategories) {
        wantedTags.addAll(_hazardCategoryToTags[cat] ?? const []);
      }
      if (wantedTags.isNotEmpty) {
        selected = _firstMatching(
          allVideos,
          where: (v) =>
              notRecentlyWatched(v) &&
              v.tags.any(wantedTags.contains),
        );
      }
    }

    // Priority 2 — high-risk users get an emergency or PPE refresher.
    selected ??= user.isHighRisk
        ? _firstMatching(
            allVideos,
            where: (v) =>
                notRecentlyWatched(v) &&
                (v.category == VideoCategory.emergency ||
                    v.category == VideoCategory.ppe),
          )
        : null;

    // Priority 3 — Phase 6 hint, if the risk engine has stored one.
    if (selected == null) {
      final recommendedCategory =
          await _repo.readRecommendedCategory(user.uid);
      if (recommendedCategory != null && recommendedCategory.isNotEmpty) {
        selected = _firstMatching(
          allVideos,
          where: (v) =>
              notRecentlyWatched(v) && v.category == recommendedCategory,
        );
      }
    }

    // Priority 4 — rotating schedule keyed by day-of-year.
    if (selected == null) {
      final categoryIndex = _dayOfYear(today) % VideoCategory.values.length;
      final rotatingCategory = VideoCategory.values[categoryIndex];
      selected = _leastRecentlyWatched(
        allVideos.where(
          (v) => v.category == rotatingCategory && notRecentlyWatched(v),
        ),
        lastWatchedAt,
      );
    }

    // Priority 5 — anything not watched recently.
    selected ??= _leastRecentlyWatched(
      allVideos.where(notRecentlyWatched),
      lastWatchedAt,
    );

    // Last resort — pick least-recently-watched across the whole library so
    // we never return null when at least one video exists.
    selected ??= _leastRecentlyWatched(allVideos, lastWatchedAt);

    if (selected != null) {
      await _repo.cacheVideoOfDay(
        uid: user.uid,
        videoId: selected.videoId,
        date: todayKey,
      );
    }
    return selected;
  }

  SafetyVideo? _firstMatching(
    Iterable<SafetyVideo> videos, {
    required bool Function(SafetyVideo) where,
  }) {
    for (final v in videos) {
      if (where(v)) return v;
    }
    return null;
  }

  /// Returns the video with the oldest `lastWatchedAt` (or never-watched if
  /// any are present, which sort first because they have no timestamp).
  SafetyVideo? _leastRecentlyWatched(
    Iterable<SafetyVideo> videos,
    Map<String, DateTime> lastWatchedAt,
  ) {
    SafetyVideo? best;
    DateTime? bestStamp;
    for (final v in videos) {
      final stamp = lastWatchedAt[v.videoId];
      if (best == null) {
        best = v;
        bestStamp = stamp;
        continue;
      }
      // Never-watched (null stamp) wins outright.
      if (stamp == null && bestStamp != null) {
        best = v;
        bestStamp = null;
      } else if (stamp != null &&
          bestStamp != null &&
          stamp.isBefore(bestStamp)) {
        best = v;
        bestStamp = stamp;
      }
    }
    return best;
  }

  static String _isoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static int _dayOfYear(DateTime d) {
    final start = DateTime(d.year);
    return d.difference(start).inDays + 1;
  }
}

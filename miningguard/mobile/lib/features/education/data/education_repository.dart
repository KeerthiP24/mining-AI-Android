import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/safety_video.dart';
import '../domain/video_watch.dart';

class EducationException implements Exception {
  const EducationException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'EducationException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Sole gateway between the education feature and Firestore.
///
/// Widgets and providers must go through this class — never call
/// [FirebaseFirestore] directly. This makes the feature testable with
/// `fake_cloud_firestore` and centralises field-name knowledge.
class EducationRepository {
  EducationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _videos =>
      _firestore.collection('safety_videos');

  CollectionReference<Map<String, dynamic>> get _watches =>
      _firestore.collection('video_watches');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // ── Video library reads ─────────────────────────────────────────────────────

  /// Streams all active videos targeted at [role]. Sorted by upload date,
  /// newest first.
  Stream<List<SafetyVideo>> watchLibraryForRole(String role) {
    return _videos
        .where('isActive', isEqualTo: true)
        .where('targetRoles', arrayContains: role)
        .snapshots()
        .map((snap) {
      final videos = snap.docs.map(SafetyVideo.fromFirestore).toList();
      videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return videos;
    });
  }

  /// Streams videos for [role] filtered to a single [category].
  Stream<List<SafetyVideo>> watchByCategory(String role, String category) {
    return _videos
        .where('isActive', isEqualTo: true)
        .where('targetRoles', arrayContains: role)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) {
      final videos = snap.docs.map(SafetyVideo.fromFirestore).toList();
      videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      return videos;
    });
  }

  /// One-shot fetch of a single video. Returns null if missing.
  Future<SafetyVideo?> getVideo(String videoId) async {
    try {
      final snap = await _videos.doc(videoId).get();
      if (!snap.exists) return null;
      return SafetyVideo.fromFirestore(snap);
    } catch (e) {
      throw EducationException('Failed to fetch video', cause: e);
    }
  }

  // ── Watch session reads ─────────────────────────────────────────────────────

  /// Returns the watch document for this user+video+today, or null.
  Future<VideoWatch?> getTodaysWatch(
    String uid,
    String videoId,
    DateTime today,
  ) async {
    final id = VideoWatch.buildWatchId(uid, videoId, today);
    final snap = await _watches.doc(id).get();
    if (!snap.exists) return null;
    return VideoWatch.fromFirestore(snap);
  }

  /// Streams all in-progress watches (started but not yet completed) for the
  /// user. Used by the Continue Watching section.
  Stream<List<VideoWatch>> watchInProgressForUser(String uid) {
    return _watches
        .where('userId', isEqualTo: uid)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(VideoWatch.fromFirestore)
          .where((w) => w.completionPercent > 0)
          .toList();
      list.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      return list;
    });
  }

  /// Returns video IDs the user has completed in the last [days] days.
  Future<Set<String>> getRecentlyCompletedVideoIds(
    String uid, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _watches
        .where('userId', isEqualTo: uid)
        .where('isCompleted', isEqualTo: true)
        .where('watchedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs
        .map((d) => (d.data()['videoId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Returns the most recent watch timestamp per video for the user.
  /// Used by Video of the Day to pick the least-recently-watched video.
  Future<Map<String, DateTime>> getLastWatchedAtByVideo(String uid) async {
    final snap = await _watches.where('userId', isEqualTo: uid).get();
    final result = <String, DateTime>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final vid = data['videoId'] as String?;
      final ts = (data['watchedAt'] as Timestamp?)?.toDate();
      if (vid == null || ts == null) continue;
      final existing = result[vid];
      if (existing == null || ts.isAfter(existing)) {
        result[vid] = ts;
      }
    }
    return result;
  }

  // ── Watch session writes ────────────────────────────────────────────────────

  /// Creates or returns the watch session for this user+video+today.
  ///
  /// If a session already exists for today, it is returned unchanged so
  /// progress accumulates across re-entries to the player screen.
  Future<VideoWatch> initWatchSession({
    required String uid,
    required String videoId,
    required String mineId,
  }) async {
    final today = DateTime.now();
    final id = VideoWatch.buildWatchId(uid, videoId, today);
    final ref = _watches.doc(id);
    final snap = await ref.get();
    if (snap.exists) return VideoWatch.fromFirestore(snap);

    final watch = VideoWatch(
      watchId: id,
      userId: uid,
      videoId: videoId,
      mineId: mineId,
      watchedAt: today,
    );
    await ref.set(watch.toFirestore());
    return watch;
  }

  /// Persists the current playback completion percent. The Cloud Function
  /// `onVideoWatched` reacts when [isCompleted] flips to true.
  Future<void> updateWatchProgress(
    String watchId,
    int completionPercent,
  ) async {
    final clamped = completionPercent.clamp(0, 100);
    await _watches.doc(watchId).update({
      'completionPercent': clamped,
      'isCompleted': clamped >= 90,
    });
  }

  /// Records the result of a quiz attempt.
  Future<void> saveQuizResult({
    required String watchId,
    required bool passed,
    required int score,
    required int pointsAwarded,
  }) async {
    await _watches.doc(watchId).update({
      'quizAttempted': true,
      'quizPassed': passed,
      'quizScore': score,
      'compliancePointsAwarded': pointsAwarded,
    });
  }

  /// Increments the worker's lifetime compliance points. Atomic.
  Future<void> awardCompliancePoints(String uid, int points) async {
    if (points <= 0) return;
    await _users.doc(uid).set(
      {'compliancePoints': FieldValue.increment(points)},
      SetOptions(merge: true),
    );
  }

  /// Caches the Video of the Day selection on the user document.
  Future<void> cacheVideoOfDay({
    required String uid,
    required String videoId,
    required String date,
  }) async {
    await _users.doc(uid).set(
      {
        'videoOfDayVideoId': videoId,
        'videoOfDayDate': date,
      },
      SetOptions(merge: true),
    );
  }

  /// Reads the cached Video of the Day fields off the user document.
  /// Returns `(videoId, date)` or `(null, null)` if absent.
  Future<({String? videoId, String? date})> readCachedVideoOfDay(
    String uid,
  ) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return (videoId: null, date: null);
    final data = snap.data() ?? {};
    return (
      videoId: data['videoOfDayVideoId'] as String?,
      date: data['videoOfDayDate'] as String?,
    );
  }

  /// Reads the recommendedCategory hint set by the Phase 6 risk engine, if any.
  Future<String?> readRecommendedCategory(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return (snap.data() ?? const {})['recommendedCategory'] as String?;
  }

  // ── Recent hazard reports (used by Video of the Day) ────────────────────────

  /// Returns the categories the user has reported in the last [days] days.
  Future<Set<String>> getRecentHazardCategories(
    String uid, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _firestore
        .collection('hazard_reports')
        .where('uid', isEqualTo: uid)
        .where('submittedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs
        .map((d) => (d.data()['category'] as String?) ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
  }
}

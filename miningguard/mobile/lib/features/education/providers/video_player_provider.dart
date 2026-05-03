import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../data/education_repository.dart';
import '../domain/video_watch.dart';
import 'education_providers.dart';

/// Mutable watch-session state for the player screen.
///
/// Handles three responsibilities:
/// 1. Initialise (or restore) the day's [VideoWatch] document.
/// 2. Throttle Firestore writes from frequent player progress updates to
///    one write every 5 seconds.
/// 3. Track whether the quiz has been triggered this session, so we don't
///    re-pop the bottom sheet on every position update past 90%.
class VideoWatchNotifier extends StateNotifier<VideoWatch?> {
  VideoWatchNotifier(this._repo, this._uid, this._mineId, this._videoId)
      : super(null);

  final EducationRepository _repo;
  final String _uid;
  final String _mineId;
  final String _videoId;

  Timer? _flushTimer;
  int? _pendingPercent;
  bool _quizTriggeredThisSession = false;

  /// True once the 90% threshold has been crossed during this session.
  /// Player screen reads this to know whether to show the quiz overlay.
  bool get quizTriggered => _quizTriggeredThisSession;

  /// True if today's watch document already records a passed quiz, so we
  /// must not award points twice or re-trigger the quiz.
  bool get alreadyCompletedToday =>
      state?.isCompleted == true && state?.quizAttempted == true;

  Future<void> init() async {
    final watch = await _repo.initWatchSession(
      uid: _uid,
      videoId: _videoId,
      mineId: _mineId,
    );
    state = watch;
    if (watch.completionPercent >= 90 && watch.quizAttempted) {
      _quizTriggeredThisSession = true;
    }
  }

  /// Records a new completion percent, throttled to one Firestore write
  /// every ~5s. Returns true if this update is the first to cross 90 (the
  /// player screen uses that signal to launch the quiz).
  bool reportProgress(int percent) {
    final clamped = percent.clamp(0, 100);
    final current = state;
    if (current == null) return false;

    final crossedThreshold = clamped >= 90 &&
        current.completionPercent < 90 &&
        !_quizTriggeredThisSession &&
        !current.quizAttempted;
    if (crossedThreshold) _quizTriggeredThisSession = true;

    state = current.copyWith(
      completionPercent: clamped,
      isCompleted: clamped >= 90 || current.isCompleted,
    );

    _pendingPercent = clamped;
    _flushTimer ??= Timer(const Duration(seconds: 5), _flush);

    return crossedThreshold;
  }

  Future<void> _flush() async {
    final percent = _pendingPercent;
    _flushTimer = null;
    _pendingPercent = null;
    final current = state;
    if (percent == null || current == null) return;
    await _repo.updateWatchProgress(current.watchId, percent);
  }

  /// Forces an immediate write of any pending progress. Call this when the
  /// user leaves the player screen so we don't lose the last few seconds.
  Future<void> flushNow() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flush();
  }

  /// Persists a quiz attempt and (if passed) credits the user 5 compliance
  /// points. [score] is the number of correct answers (0–3).
  Future<void> submitQuiz({required int score, required int totalQuestions}) async {
    final current = state;
    if (current == null) return;

    final passed = score >= 2;
    final points = passed ? 5 : 0;

    await _repo.saveQuizResult(
      watchId: current.watchId,
      passed: passed,
      score: score,
      pointsAwarded: points,
    );
    if (passed) {
      await _repo.awardCompliancePoints(_uid, points);
    }

    state = current.copyWith(
      quizAttempted: true,
      quizPassed: passed,
      quizScore: score,
      compliancePointsAwarded: points,
    );
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}

/// Family-keyed by video id so each player screen gets its own notifier.
///
/// **Important:** we deliberately use `ref.read` (not `ref.watch`) for the
/// user model. The user-model provider is a Firestore *stream* and emits at
/// least once after the player mounts — `ref.watch` would dispose this
/// notifier and recreate it mid-playback, which resets the watch state and
/// restarts `init()`, causing playback/progress glitches.
final videoWatchStateProvider = StateNotifierProvider.autoDispose
    .family<VideoWatchNotifier, VideoWatch?, String>((ref, videoId) {
  final user = ref.read(currentUserModelProvider).valueOrNull;
  final repo = ref.read(educationRepositoryProvider);
  final notifier = VideoWatchNotifier(
    repo,
    user?.uid ?? '',
    user?.mineId ?? '',
    videoId,
  );
  if (user != null) {
    notifier.init();
  }
  return notifier;
});

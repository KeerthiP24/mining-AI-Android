import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a single worker's interaction with one video for one calendar day.
///
/// Document path: `video_watches/{watchId}` where
/// `watchId = "{uid}_{videoId}_{YYYY-MM-DD}"`. Using a deterministic ID
/// allows the player screen to upsert progress without re-querying.
class VideoWatch {
  const VideoWatch({
    required this.watchId,
    required this.userId,
    required this.videoId,
    required this.mineId,
    required this.watchedAt,
    this.completionPercent = 0,
    this.isCompleted = false,
    this.quizAttempted = false,
    this.quizPassed = false,
    this.quizScore = 0,
    this.compliancePointsAwarded = 0,
  });

  final String watchId;
  final String userId;
  final String videoId;
  final String mineId;
  final DateTime watchedAt;
  final int completionPercent;
  final bool isCompleted;
  final bool quizAttempted;
  final bool quizPassed;
  final int quizScore;
  final int compliancePointsAwarded;

  /// Builds the deterministic watch ID for this user+video+date.
  static String buildWatchId(String uid, String videoId, DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${uid}_${videoId}_$y-$m-$d';
  }

  factory VideoWatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return VideoWatch(
      watchId: doc.id,
      userId: data['userId'] as String? ?? '',
      videoId: data['videoId'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      watchedAt:
          (data['watchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completionPercent: (data['completionPercent'] as num?)?.toInt() ?? 0,
      isCompleted: data['isCompleted'] as bool? ?? false,
      quizAttempted: data['quizAttempted'] as bool? ?? false,
      quizPassed: data['quizPassed'] as bool? ?? false,
      quizScore: (data['quizScore'] as num?)?.toInt() ?? 0,
      compliancePointsAwarded:
          (data['compliancePointsAwarded'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'videoId': videoId,
        'mineId': mineId,
        'watchedAt': Timestamp.fromDate(watchedAt),
        'completionPercent': completionPercent,
        'isCompleted': isCompleted,
        'quizAttempted': quizAttempted,
        'quizPassed': quizPassed,
        'quizScore': quizScore,
        'compliancePointsAwarded': compliancePointsAwarded,
      };

  VideoWatch copyWith({
    int? completionPercent,
    bool? isCompleted,
    bool? quizAttempted,
    bool? quizPassed,
    int? quizScore,
    int? compliancePointsAwarded,
  }) {
    return VideoWatch(
      watchId: watchId,
      userId: userId,
      videoId: videoId,
      mineId: mineId,
      watchedAt: watchedAt,
      completionPercent: completionPercent ?? this.completionPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      quizAttempted: quizAttempted ?? this.quizAttempted,
      quizPassed: quizPassed ?? this.quizPassed,
      quizScore: quizScore ?? this.quizScore,
      compliancePointsAwarded:
          compliancePointsAwarded ?? this.compliancePointsAwarded,
    );
  }
}

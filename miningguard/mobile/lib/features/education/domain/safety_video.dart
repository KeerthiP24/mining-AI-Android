import 'package:cloud_firestore/cloud_firestore.dart';

import 'quiz_question.dart';

/// Categories used for browsing and the rotating Video of the Day fallback.
class VideoCategory {
  VideoCategory._();

  static const String ppe = 'ppe';
  static const String gasVentilation = 'gas_ventilation';
  static const String roofSupport = 'roof_support';
  static const String emergency = 'emergency';
  static const String machinery = 'machinery';

  /// Order matters: used by the rotating-schedule fallback in
  /// [VideoOfDayService] (`dayOfYear % values.length`).
  static const List<String> values = [
    ppe,
    gasVentilation,
    roofSupport,
    emergency,
    machinery,
  ];
}

/// Sources of video content. Rendered as colored pills on the hero card.
class VideoSource {
  VideoSource._();
  static const String dgms = 'DGMS';
  static const String msha = 'MSHA';
  static const String hse = 'HSE';
  static const String workSafe = 'WorkSafe';
  static const String custom = 'Custom';
}

/// Firestore-backed model for a single safety education video.
///
/// Document path: `safety_videos/{videoId}`.
class SafetyVideo {
  const SafetyVideo({
    required this.videoId,
    required this.title,
    required this.description,
    required this.category,
    required this.source,
    required this.youtubeId,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.targetRoles,
    required this.tags,
    required this.quizQuestions,
    required this.uploadedAt,
    this.isActive = true,
  });

  final String videoId;
  final Map<String, String> title;
  final Map<String, String> description;
  final String category;
  final String source;
  final String youtubeId;
  final String thumbnailUrl;
  final int durationSeconds;
  final List<String> targetRoles;
  final List<String> tags;
  final List<QuizQuestion> quizQuestions;
  final DateTime uploadedAt;
  final bool isActive;

  factory SafetyVideo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final youtubeId = data['youtubeId'] as String? ?? '';
    final providedThumb = data['thumbnailUrl'] as String?;
    return SafetyVideo(
      videoId: doc.id,
      title: _stringMap(data['title']),
      description: _stringMap(data['description']),
      category: data['category'] as String? ?? '',
      source: data['source'] as String? ?? VideoSource.custom,
      youtubeId: youtubeId,
      thumbnailUrl: providedThumb?.isNotEmpty == true
          ? providedThumb!
          : 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      targetRoles:
          (data['targetRoles'] as List<dynamic>?)?.cast<String>() ?? const [],
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      quizQuestions: (data['quizQuestions'] as List<dynamic>? ?? const [])
          .map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
          .toList(),
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'category': category,
        'source': source,
        'youtubeId': youtubeId,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'targetRoles': targetRoles,
        'tags': tags,
        'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'isActive': isActive,
      };

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }
    return const {};
  }
}

/// Resolves a localized string map with a deterministic fallback chain:
/// requested language → English → first available value → empty string.
String localizeMap(Map<String, String> map, String langCode) {
  if (map.isEmpty) return '';
  return map[langCode] ?? map['en'] ?? map.values.first;
}

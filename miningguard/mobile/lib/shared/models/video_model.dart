import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  const VideoModel({
    required this.id,
    required this.titleEn,
    this.titleHi,
    this.titleBn,
    required this.category,
    required this.source,
    required this.youtubeId,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.targetRoles = const ['worker', 'supervisor'],
    this.tags = const [],
    this.isActive = true,
  });

  final String id;
  final String titleEn;
  final String? titleHi;
  final String? titleBn;
  final String category;    // ppe | gas_ventilation | roof_support | emergency | machinery
  final String source;      // dgms | msha | hse | worksafe | custom
  final String youtubeId;
  final String? thumbnailUrl;
  final int durationSeconds;
  final List<String> targetRoles;
  final List<String> tags;
  final bool isActive;

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      titleEn: data['titleEn'] as String? ?? '',
      titleHi: data['titleHi'] as String?,
      titleBn: data['titleBn'] as String?,
      category: data['category'] as String? ?? '',
      source: data['source'] as String? ?? '',
      youtubeId: data['youtubeId'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      targetRoles: List<String>.from(data['targetRoles'] as List? ?? ['worker']),
      tags: List<String>.from(data['tags'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titleEn': titleEn,
    if (titleHi != null) 'titleHi': titleHi,
    if (titleBn != null) 'titleBn': titleBn,
    'category': category,
    'source': source,
    'youtubeId': youtubeId,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    'durationSeconds': durationSeconds,
    'targetRoles': targetRoles,
    'tags': tags,
    'isActive': isActive,
  };
}

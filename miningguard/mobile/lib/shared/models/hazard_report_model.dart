import 'package:cloud_firestore/cloud_firestore.dart';

class AiAnalysisModel {
  const AiAnalysisModel({
    required this.hazardDetected,
    required this.confidence,
    required this.suggestedSeverity,
    required this.correctionRecommendation,
  });

  final String hazardDetected;
  final double confidence;
  final String suggestedSeverity;
  final String correctionRecommendation;

  factory AiAnalysisModel.fromMap(Map<String, dynamic> map) => AiAnalysisModel(
    hazardDetected: map['hazardDetected'] as String? ?? 'unknown',
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    suggestedSeverity: map['suggestedSeverity'] as String? ?? 'low',
    correctionRecommendation: map['correctionRecommendation'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'hazardDetected': hazardDetected,
    'confidence': confidence,
    'suggestedSeverity': suggestedSeverity,
    'correctionRecommendation': correctionRecommendation,
  };
}

class HazardReportModel {
  const HazardReportModel({
    required this.id,
    required this.reporterId,
    required this.mineId,
    required this.mineSection,
    required this.category,
    required this.severity,
    required this.description,
    this.mediaUrls = const [],
    this.voiceNoteUrl,
    this.aiAnalysis,
    this.status = 'submitted',
    this.supervisorNote,
    this.resolvedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String reporterId;
  final String mineId;
  final String mineSection;
  final String category;   // roof_fall | gas_leak | fire | machinery | electrical | other
  final String severity;   // low | medium | high | critical
  final String description;
  final List<String> mediaUrls;
  final String? voiceNoteUrl;
  final AiAnalysisModel? aiAnalysis;
  final String status;     // submitted | acknowledged | in_progress | resolved
  final String? supervisorNote;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HazardReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final aiData = data['aiAnalysis'] as Map<String, dynamic>?;
    return HazardReportModel(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      mineSection: data['mineSection'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      severity: data['severity'] as String? ?? 'low',
      description: data['description'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] as List? ?? []),
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      aiAnalysis: aiData != null ? AiAnalysisModel.fromMap(aiData) : null,
      status: data['status'] as String? ?? 'submitted',
      supervisorNote: data['supervisorNote'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'reporterId': reporterId,
    'mineId': mineId,
    'mineSection': mineSection,
    'category': category,
    'severity': severity,
    'description': description,
    'mediaUrls': mediaUrls,
    if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis!.toMap(),
    'status': status,
    if (supervisorNote != null) 'supervisorNote': supervisorNote,
    if (resolvedBy != null) 'resolvedBy': resolvedBy,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

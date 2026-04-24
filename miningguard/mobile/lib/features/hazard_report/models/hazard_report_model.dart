import 'package:cloud_firestore/cloud_firestore.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum HazardCategory {
  roofFall,
  gasLeak,
  fire,
  machinery,
  electrical,
  other;

  String get label {
    switch (this) {
      case HazardCategory.roofFall: return 'Roof Fall';
      case HazardCategory.gasLeak: return 'Gas Leak';
      case HazardCategory.fire: return 'Fire';
      case HazardCategory.machinery: return 'Machinery';
      case HazardCategory.electrical: return 'Electrical';
      case HazardCategory.other: return 'Other';
    }
  }

  String get firestoreValue {
    switch (this) {
      case HazardCategory.roofFall: return 'roof_fall';
      case HazardCategory.gasLeak: return 'gas_leak';
      case HazardCategory.fire: return 'fire';
      case HazardCategory.machinery: return 'machinery';
      case HazardCategory.electrical: return 'electrical';
      case HazardCategory.other: return 'other';
    }
  }

  static HazardCategory fromString(String value) {
    switch (value) {
      case 'roof_fall': return HazardCategory.roofFall;
      case 'gas_leak': return HazardCategory.gasLeak;
      case 'fire': return HazardCategory.fire;
      case 'machinery': return HazardCategory.machinery;
      case 'electrical': return HazardCategory.electrical;
      default: return HazardCategory.other;
    }
  }
}

enum HazardSeverity {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case HazardSeverity.low: return 'Low';
      case HazardSeverity.medium: return 'Medium';
      case HazardSeverity.high: return 'High';
      case HazardSeverity.critical: return 'Critical';
    }
  }

  String get firestoreValue => name;

  static HazardSeverity fromString(String value) {
    switch (value) {
      case 'medium': return HazardSeverity.medium;
      case 'high': return HazardSeverity.high;
      case 'critical': return HazardSeverity.critical;
      default: return HazardSeverity.low;
    }
  }
}

enum ReportStatus {
  pending,
  acknowledged,
  inProgress,
  resolved;

  String get label {
    switch (this) {
      case ReportStatus.pending: return 'Pending';
      case ReportStatus.acknowledged: return 'Acknowledged';
      case ReportStatus.inProgress: return 'In Progress';
      case ReportStatus.resolved: return 'Resolved';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ReportStatus.pending: return 'pending';
      case ReportStatus.acknowledged: return 'acknowledged';
      case ReportStatus.inProgress: return 'in_progress';
      case ReportStatus.resolved: return 'resolved';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'acknowledged': return ReportStatus.acknowledged;
      case 'in_progress': return ReportStatus.inProgress;
      case 'resolved': return ReportStatus.resolved;
      default: return ReportStatus.pending;
    }
  }
}

enum InputMode {
  photo,
  voice,
  text;

  String get label {
    switch (this) {
      case InputMode.photo: return 'Photo / Video';
      case InputMode.voice: return 'Voice';
      case InputMode.text: return 'Text';
    }
  }

  String get firestoreValue => name;

  static InputMode fromString(String value) {
    switch (value) {
      case 'voice': return InputMode.voice;
      case 'text': return InputMode.text;
      default: return InputMode.photo;
    }
  }
}

// ── Embedded AI analysis data ─────────────────────────────────────────────────

class AiAnalysisData {
  const AiAnalysisData({
    required this.hazardDetected,
    required this.confidence,
    required this.suggestedSeverity,
    required this.recommendedAction,
  });

  final String hazardDetected;
  final double confidence;
  final String suggestedSeverity;
  final String recommendedAction;

  factory AiAnalysisData.fromMap(Map<String, dynamic> map) {
    return AiAnalysisData(
      hazardDetected: map['hazardDetected'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      suggestedSeverity: map['suggestedSeverity'] as String? ?? 'low',
      recommendedAction: map['recommendedAction'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'hazardDetected': hazardDetected,
    'confidence': confidence,
    'suggestedSeverity': suggestedSeverity,
    'recommendedAction': recommendedAction,
  };
}

// ── HazardReportModel ─────────────────────────────────────────────────────────

class HazardReportModel {
  const HazardReportModel({
    required this.reportId,
    required this.uid,
    required this.mineId,
    this.supervisorId = '',
    this.mineSection = '',
    required this.inputMode,
    this.description = '',
    this.voiceTranscription = '',
    required this.category,
    required this.severity,
    this.mediaUrls = const [],
    this.voiceNoteUrl,
    this.aiAnalysis,
    required this.status,
    this.supervisorNote,
    required this.submittedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.isOfflineCreated = false,
    this.syncedAt,
  });

  final String reportId;
  final String uid;
  final String mineId;
  final String supervisorId;
  final String mineSection;
  final InputMode inputMode;
  final String description;
  final String voiceTranscription;
  final HazardCategory category;
  final HazardSeverity severity;
  final List<String> mediaUrls;
  final String? voiceNoteUrl;
  final AiAnalysisData? aiAnalysis;
  final ReportStatus status;
  final String? supervisorNote;
  final DateTime submittedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final bool isOfflineCreated;
  final DateTime? syncedAt;

  factory HazardReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAi = data['aiAnalysis'] as Map<String, dynamic>?;
    final rawMedia = data['mediaUrls'] as List<dynamic>?;
    return HazardReportModel(
      reportId: doc.id,
      uid: data['uid'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      supervisorId: data['supervisorId'] as String? ?? '',
      mineSection: data['mineSection'] as String? ?? '',
      inputMode: InputMode.fromString(data['inputMode'] as String? ?? 'text'),
      description: data['description'] as String? ?? '',
      voiceTranscription: data['voiceTranscription'] as String? ?? '',
      category: HazardCategory.fromString(data['category'] as String? ?? 'other'),
      severity: HazardSeverity.fromString(data['severity'] as String? ?? 'low'),
      mediaUrls: rawMedia?.cast<String>() ?? [],
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      aiAnalysis: rawAi != null ? AiAnalysisData.fromMap(rawAi) : null,
      status: ReportStatus.fromString(data['status'] as String? ?? 'pending'),
      supervisorNote: data['supervisorNote'] as String?,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      isOfflineCreated: data['isOfflineCreated'] as bool? ?? false,
      syncedAt: (data['syncedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'mineId': mineId,
    'supervisorId': supervisorId,
    'mineSection': mineSection,
    'inputMode': inputMode.firestoreValue,
    'description': description,
    'voiceTranscription': voiceTranscription,
    'category': category.firestoreValue,
    'severity': severity.firestoreValue,
    'mediaUrls': mediaUrls,
    if (voiceNoteUrl != null) 'voiceNoteUrl': voiceNoteUrl,
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis!.toMap(),
    'status': status.firestoreValue,
    if (supervisorNote != null) 'supervisorNote': supervisorNote,
    'submittedAt': FieldValue.serverTimestamp(),
    'acknowledgedAt': null,
    'resolvedAt': null,
    'isOfflineCreated': isOfflineCreated,
    'syncedAt': null,
  };

  // JSON serialization for Hive offline storage
  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'uid': uid,
    'mineId': mineId,
    'supervisorId': supervisorId,
    'mineSection': mineSection,
    'inputMode': inputMode.firestoreValue,
    'description': description,
    'voiceTranscription': voiceTranscription,
    'category': category.firestoreValue,
    'severity': severity.firestoreValue,
    'mediaUrls': mediaUrls,
    'voiceNoteUrl': voiceNoteUrl,
    'aiAnalysis': aiAnalysis?.toMap(),
    'status': status.firestoreValue,
    'supervisorNote': supervisorNote,
    'submittedAt': submittedAt.toIso8601String(),
    'isOfflineCreated': isOfflineCreated,
  };

  factory HazardReportModel.fromJson(Map<String, dynamic> json) {
    final rawAi = json['aiAnalysis'] as Map<String, dynamic>?;
    final rawMedia = json['mediaUrls'] as List<dynamic>?;
    return HazardReportModel(
      reportId: json['reportId'] as String,
      uid: json['uid'] as String? ?? '',
      mineId: json['mineId'] as String? ?? '',
      supervisorId: json['supervisorId'] as String? ?? '',
      mineSection: json['mineSection'] as String? ?? '',
      inputMode: InputMode.fromString(json['inputMode'] as String? ?? 'text'),
      description: json['description'] as String? ?? '',
      voiceTranscription: json['voiceTranscription'] as String? ?? '',
      category: HazardCategory.fromString(json['category'] as String? ?? 'other'),
      severity: HazardSeverity.fromString(json['severity'] as String? ?? 'low'),
      mediaUrls: rawMedia?.cast<String>() ?? [],
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      aiAnalysis: rawAi != null ? AiAnalysisData.fromMap(rawAi) : null,
      status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
      supervisorNote: json['supervisorNote'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      isOfflineCreated: json['isOfflineCreated'] as bool? ?? false,
    );
  }

  HazardReportModel copyWith({
    String? reportId,
    String? uid,
    String? mineId,
    String? supervisorId,
    String? mineSection,
    InputMode? inputMode,
    String? description,
    String? voiceTranscription,
    HazardCategory? category,
    HazardSeverity? severity,
    List<String>? mediaUrls,
    String? voiceNoteUrl,
    AiAnalysisData? aiAnalysis,
    ReportStatus? status,
    String? supervisorNote,
    DateTime? submittedAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    bool? isOfflineCreated,
    DateTime? syncedAt,
  }) {
    return HazardReportModel(
      reportId: reportId ?? this.reportId,
      uid: uid ?? this.uid,
      mineId: mineId ?? this.mineId,
      supervisorId: supervisorId ?? this.supervisorId,
      mineSection: mineSection ?? this.mineSection,
      inputMode: inputMode ?? this.inputMode,
      description: description ?? this.description,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      status: status ?? this.status,
      supervisorNote: supervisorNote ?? this.supervisorNote,
      submittedAt: submittedAt ?? this.submittedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isOfflineCreated: isOfflineCreated ?? this.isOfflineCreated,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'checklist_item.dart';

/// One checklist document per worker per shift-day.
/// checklistId = "{uid}_{mineId}_{date}" e.g. "uid123_mine001_2025-07-14"
class Checklist {
  const Checklist({
    required this.checklistId,
    required this.uid,
    required this.mineId,
    required this.shift,
    required this.date,
    required this.templateVersion,
    required this.status,
    required this.items,
    required this.createdAt,
    this.submittedAt,
    this.complianceScore = 0.0,
    this.mandatoryScore = 0.0,
  });

  final String checklistId;
  final String uid;
  final String mineId;
  final String shift;  // morning | afternoon | night
  final String date;   // YYYY-MM-DD (mine local timezone)
  final int templateVersion;
  final String status;  // in_progress | submitted | missed
  final Map<String, ChecklistItemData> items;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final double complianceScore;
  final double mandatoryScore;

  bool get isSubmitted => status == 'submitted';
  bool get isMissed => status == 'missed';

  /// True when all mandatory items are checked.
  bool get allMandatoryComplete {
    return items.values
        .where((item) => item.mandatory)
        .every((item) => item.completed);
  }

  int get totalCompleted => items.values.where((i) => i.completed).length;
  int get totalItems => items.length;

  int get optionalUnchecked => items.values
      .where((i) => !i.mandatory && !i.completed)
      .length;

  /// Calculates compliance score from current item state.
  /// mandatory_score * 0.70 + optional_score * 0.30
  ({double complianceScore, double mandatoryScore}) calculateScores() {
    final mandatoryItems = items.values.where((i) => i.mandatory).toList();
    final optionalItems = items.values.where((i) => !i.mandatory).toList();

    if (mandatoryItems.isEmpty && optionalItems.isEmpty) {
      return (complianceScore: 0.70, mandatoryScore: 1.0);
    }

    final mandatoryTotal = mandatoryItems.length;
    final mandatoryCompleted =
        mandatoryItems.where((i) => i.completed).length;
    final mScore =
        mandatoryTotal > 0 ? mandatoryCompleted / mandatoryTotal : 1.0;

    final optionalTotal = optionalItems.length;
    final optionalCompleted =
        optionalItems.where((i) => i.completed).length;
    final oScore =
        optionalTotal > 0 ? optionalCompleted / optionalTotal : 1.0;

    final compliance = (mScore * 0.70) + (oScore * 0.30);
    return (complianceScore: compliance, mandatoryScore: mScore);
  }

  factory Checklist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as Map<String, dynamic>? ?? {};

    final parsedItems = <String, ChecklistItemData>{};
    for (final entry in rawItems.entries) {
      parsedItems[entry.key] =
          ChecklistItemData.fromMap(entry.value as Map<String, dynamic>);
    }

    return Checklist(
      checklistId: doc.id,
      uid: data['uid'] as String,
      mineId: data['mineId'] as String,
      shift: data['shift'] as String? ?? 'morning',
      date: data['date'] as String,
      templateVersion: data['templateVersion'] as int? ?? 1,
      status: data['status'] as String? ?? 'in_progress',
      items: parsedItems,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0.0,
      mandatoryScore: (data['mandatoryScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'mineId': mineId,
      'shift': shift,
      'date': date,
      'templateVersion': templateVersion,
      'status': status,
      'items': items.map((k, v) => MapEntry(k, v.toMap())),
      'createdAt': Timestamp.fromDate(createdAt),
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      'complianceScore': complianceScore,
      'mandatoryScore': mandatoryScore,
    };
  }

  Checklist copyWith({
    String? status,
    Map<String, ChecklistItemData>? items,
    DateTime? submittedAt,
    double? complianceScore,
    double? mandatoryScore,
  }) {
    return Checklist(
      checklistId: checklistId,
      uid: uid,
      mineId: mineId,
      shift: shift,
      date: date,
      templateVersion: templateVersion,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      complianceScore: complianceScore ?? this.complianceScore,
      mandatoryScore: mandatoryScore ?? this.mandatoryScore,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;     // risk_level_change | missed_checklist | behavior_pattern | critical_hazard
  final String title;
  final String message;
  final String severity; // info | warning | critical
  final bool isRead;
  final String? relatedId;
  final DateTime? createdAt;

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Phase 6 backend writes `uid`; older Phase 4 docs used `userId`.
    final ownerId =
        data['userId'] as String? ?? data['uid'] as String? ?? '';
    return AlertModel(
      id: doc.id,
      userId: ownerId,
      type: data['type'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      isRead: data['isRead'] as bool? ?? false,
      relatedId: data['relatedId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'title': title,
    'message': message,
    'severity': severity,
    'isRead': isRead,
    if (relatedId != null) 'relatedId': relatedId,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

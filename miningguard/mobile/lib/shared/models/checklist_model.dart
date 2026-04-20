import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItemModel {
  const ChecklistItemModel({
    required this.id,
    required this.label,
    required this.category,
    required this.isMandatory,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String label;
  final String category; // ppe | machinery | environment | emergency
  final bool isMandatory;
  final bool isCompleted;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'category': category,
    'isMandatory': isMandatory,
    'isCompleted': isCompleted,
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
  };

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) =>
      ChecklistItemModel(
        id: map['id'] as String,
        label: map['label'] as String,
        category: map['category'] as String,
        isMandatory: map['isMandatory'] as bool? ?? true,
        isCompleted: map['isCompleted'] as bool? ?? false,
        completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      );

  ChecklistItemModel copyWith({bool? isCompleted, DateTime? completedAt}) =>
      ChecklistItemModel(
        id: id,
        label: label,
        category: category,
        isMandatory: isMandatory,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
      );
}

class ChecklistModel {
  const ChecklistModel({
    required this.id,
    required this.uid,
    required this.mineId,
    required this.shift,
    required this.date,
    required this.items,
    this.status = 'pending',
    this.complianceScore = 0.0,
    this.submittedAt,
    this.createdAt,
  });

  final String id;
  final String uid;
  final String mineId;
  final String shift;
  final String date;        // Format: 'YYYY-MM-DD'
  final List<ChecklistItemModel> items;
  final String status;      // pending | in_progress | completed | missed
  final double complianceScore; // 0.0–1.0
  final DateTime? submittedAt;
  final DateTime? createdAt;

  factory ChecklistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return ChecklistModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      shift: data['shift'] as String? ?? 'morning',
      date: data['date'] as String? ?? '',
      items: rawItems
          .map((e) => ChecklistItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: data['status'] as String? ?? 'pending',
      complianceScore: (data['complianceScore'] as num?)?.toDouble() ?? 0.0,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'mineId': mineId,
    'shift': shift,
    'date': date,
    'items': items.map((e) => e.toMap()).toList(),
    'status': status,
    'complianceScore': complianceScore,
    if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

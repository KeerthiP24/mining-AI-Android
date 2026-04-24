import 'package:cloud_firestore/cloud_firestore.dart';

/// Completion state for a single checklist item stored in Firestore.
/// Keyed by itemId in the parent Checklist.items Map.
class ChecklistItemData {
  const ChecklistItemData({
    required this.mandatory,
    required this.completed,
    this.completedAt,
  });

  final bool mandatory;
  final bool completed;
  final DateTime? completedAt;

  factory ChecklistItemData.fromMap(Map<String, dynamic> map) {
    return ChecklistItemData(
      mandatory: map['mandatory'] as bool? ?? false,
      completed: map['completed'] as bool? ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mandatory': mandatory,
      'completed': completed,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  ChecklistItemData copyWith({
    bool? mandatory,
    bool? completed,
    DateTime? completedAt,
  }) {
    return ChecklistItemData(
      mandatory: mandatory ?? this.mandatory,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

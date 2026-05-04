import 'package:cloud_firestore/cloud_firestore.dart';

/// A mine site. The collection is `mines/` keyed by mineId. Workers and
/// supervisors reference this via [UserModel.mineId].
class MineModel {
  const MineModel({
    required this.id,
    required this.name,
    this.location = '',
    this.workerCount = 0,
    this.supervisorIds = const <String>[],
    this.sections = const <String>[],
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String location;
  final int workerCount;
  final List<String> supervisorIds;
  final List<String> sections;
  final bool isActive;
  final DateTime? createdAt;

  factory MineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return MineModel(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      location: data['location'] as String? ?? '',
      workerCount: (data['workerCount'] as num?)?.toInt() ?? 0,
      supervisorIds:
          (data['supervisorIds'] as List?)?.whereType<String>().toList()
              ?? const <String>[],
      sections:
          (data['sections'] as List?)?.whereType<String>().toList()
              ?? const <String>[],
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'location': location,
        'workerCount': workerCount,
        'supervisorIds': supervisorIds,
        'sections': sections,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles available in MiningGuard. Admin accounts are created by existing admins
/// only — self-registration allows worker and supervisor only.
enum UserRole { worker, supervisor, admin }

/// Immutable model representing a MiningGuard user document in Firestore.
class UserModel {
  const UserModel({
    required this.uid,
    required this.fullName,
    required this.mineId,
    required this.role,
    required this.department,
    required this.shift,
    required this.preferredLanguage,
    this.riskScore = 0.0,
    this.riskLevel = 'low',
    this.complianceRate = 1.0,
    this.totalHazardReports = 0,
    this.consecutiveMissedDays = 0,
    this.fcmToken,
    required this.createdAt,
    required this.lastActiveAt,
  });

  final String uid;
  final String fullName;
  final String mineId;
  final UserRole role;
  final String department;
  final String shift;             // morning | afternoon | night
  final String preferredLanguage; // en | hi | bn | te | mr | or
  final double riskScore;         // 0–100
  final String riskLevel;         // low | medium | high
  final double complianceRate;    // 0.0–1.0
  final int totalHazardReports;
  final int consecutiveMissedDays;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  bool get isHighRisk => riskLevel == 'high';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      mineId: data['mineId'] as String? ?? '',
      role: _roleFromString(data['role'] as String? ?? 'worker'),
      department: data['department'] as String? ?? '',
      shift: data['shift'] as String? ?? 'morning',
      preferredLanguage: data['preferredLanguage'] as String? ?? 'en',
      riskScore: (data['riskScore'] as num?)?.toDouble() ?? 0.0,
      riskLevel: data['riskLevel'] as String? ?? 'low',
      complianceRate: (data['complianceRate'] as num?)?.toDouble() ?? 1.0,
      totalHazardReports: data['totalHazardReports'] as int? ?? 0,
      consecutiveMissedDays: data['consecutiveMissedDays'] as int? ?? 0,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'mineId': mineId,
      'role': role.name,
      'department': department,
      'shift': shift,
      'preferredLanguage': preferredLanguage,
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'complianceRate': complianceRate,
      'totalHazardReports': totalHazardReports,
      'consecutiveMissedDays': consecutiveMissedDays,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? mineId,
    UserRole? role,
    String? department,
    String? shift,
    String? preferredLanguage,
    double? riskScore,
    String? riskLevel,
    double? complianceRate,
    int? totalHazardReports,
    int? consecutiveMissedDays,
    String? fcmToken,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      mineId: mineId ?? this.mineId,
      role: role ?? this.role,
      department: department ?? this.department,
      shift: shift ?? this.shift,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      complianceRate: complianceRate ?? this.complianceRate,
      totalHazardReports: totalHazardReports ?? this.totalHazardReports,
      consecutiveMissedDays:
          consecutiveMissedDays ?? this.consecutiveMissedDays,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  static UserRole _roleFromString(String value) {
    switch (value) {
      case 'supervisor':
        return UserRole.supervisor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.worker;
    }
  }
}

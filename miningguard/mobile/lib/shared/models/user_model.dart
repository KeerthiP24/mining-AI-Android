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
    this.lastChecklistDate,
    this.fcmToken,
    required this.createdAt,
    required this.lastActiveAt,
    // Phase 7 — denormalised dashboard fields
    this.email,
    this.mineName,
    this.todayChecklistDone = false,
    this.pendingReportCount = 0,
    this.riskFactors = const <String>[],
    this.isActive = true,
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
  final String? lastChecklistDate;  // "YYYY-MM-DD"
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  // Phase 7 — dashboard support fields. The first three are denormalised by
  // Cloud Functions: when those CFs aren't deployed yet they default to safe
  // empty values so the UI keeps rendering rather than crashing.
  final String? email;
  final String? mineName;
  final bool todayChecklistDone;
  final int pendingReportCount;
  final List<String> riskFactors;
  final bool isActive;

  bool get isHighRisk => riskLevel == 'high';

  /// Spec-spelling alias used by Phase 7 widgets.
  String get name => fullName;

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
      lastChecklistDate: data['lastChecklistDate'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt:
          (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      email: data['email'] as String?,
      mineName: data['mineName'] as String?,
      todayChecklistDone: data['todayChecklistDone'] as bool? ?? false,
      pendingReportCount: (data['pendingReportCount'] as num?)?.toInt() ?? 0,
      riskFactors: (data['riskFactors'] as List?)?.whereType<String>().toList()
          ?? const <String>[],
      isActive: data['isActive'] as bool? ?? true,
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
      if (lastChecklistDate != null) 'lastChecklistDate': lastChecklistDate,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      if (email != null) 'email': email,
      if (mineName != null) 'mineName': mineName,
      'todayChecklistDone': todayChecklistDone,
      'pendingReportCount': pendingReportCount,
      'riskFactors': riskFactors,
      'isActive': isActive,
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
    String? lastChecklistDate,
    String? fcmToken,
    DateTime? lastActiveAt,
    String? email,
    String? mineName,
    bool? todayChecklistDone,
    int? pendingReportCount,
    List<String>? riskFactors,
    bool? isActive,
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
      lastChecklistDate: lastChecklistDate ?? this.lastChecklistDate,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      email: email ?? this.email,
      mineName: mineName ?? this.mineName,
      todayChecklistDone: todayChecklistDone ?? this.todayChecklistDone,
      pendingReportCount: pendingReportCount ?? this.pendingReportCount,
      riskFactors: riskFactors ?? this.riskFactors,
      isActive: isActive ?? this.isActive,
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

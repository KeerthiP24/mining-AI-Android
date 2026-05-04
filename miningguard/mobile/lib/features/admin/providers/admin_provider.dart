import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/education/domain/safety_video.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/models/mine_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/firebase_providers.dart';

// ── User search filter (admin user-management tab) ───────────────────────────

final adminUserSearchProvider = StateProvider<String>((_) => '');

/// All users — admin-only collection read. Firestore security rules must
/// enforce that only `role == admin` can run this query.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .orderBy('fullName')
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
});

/// Filtered users — applies the admin search box client-side.
final filteredAdminUsersProvider = Provider<List<UserModel>>((ref) {
  final all = ref.watch(allUsersProvider).valueOrNull ?? const <UserModel>[];
  final query = ref.watch(adminUserSearchProvider).trim().toLowerCase();
  if (query.isEmpty) return all;
  return all.where((u) =>
      u.fullName.toLowerCase().contains(query) ||
      u.mineId.toLowerCase().contains(query) ||
      (u.email ?? '').toLowerCase().contains(query)).toList();
});

// ── Mines & videos ───────────────────────────────────────────────────────────

final allMinesProvider = StreamProvider<List<MineModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('mines')
      .snapshots()
      .map((s) => s.docs.map(MineModel.fromFirestore).toList());
});

final allVideosProvider = StreamProvider<List<SafetyVideo>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('safety_videos')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SafetyVideo.fromFirestore).toList());
});

// ── Analytics aggregations ───────────────────────────────────────────────────

class MonthlyIncidentData {
  const MonthlyIncidentData({
    required this.month,
    required this.totalReports,
    required this.criticalReports,
  });
  final DateTime month;
  final int totalReports;
  final int criticalReports;
}

/// Last 6 months of incident counts. Reads from the existing
/// `hazard_reports` collection and groups client-side.
final monthlyIncidentTrendProvider =
    FutureProvider<List<MonthlyIncidentData>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final since = DateTime(DateTime.now().year, DateTime.now().month - 5, 1);

  final snap = await firestore
      .collection('hazard_reports')
      .where('submittedAt', isGreaterThan: Timestamp.fromDate(since))
      .get();

  // Pre-seed buckets so months with zero reports still appear on the chart.
  final buckets = <String, MonthlyIncidentData>{};
  for (var i = 0; i < 6; i++) {
    final m = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
    buckets['${m.year}-${m.month.toString().padLeft(2, '0')}'] =
        MonthlyIncidentData(month: m, totalReports: 0, criticalReports: 0);
  }

  for (final doc in snap.docs) {
    final report = HazardReportModel.fromFirestore(doc);
    final m = DateTime(report.submittedAt.year, report.submittedAt.month, 1);
    final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    final current = buckets[key];
    if (current == null) continue;
    final isCritical = report.severity == HazardSeverity.critical;
    buckets[key] = MonthlyIncidentData(
      month: current.month,
      totalReports: current.totalReports + 1,
      criticalReports: current.criticalReports + (isCritical ? 1 : 0),
    );
  }

  final list = buckets.values.toList()
    ..sort((a, b) => a.month.compareTo(b.month));
  return list;
});

/// Risk-heatmap row used by the admin analytics tab.
class HeatmapRow {
  const HeatmapRow({
    required this.section,
    required this.avgRiskScore,
    required this.workerCount,
    required this.reportCount,
  });
  final String section;
  final double avgRiskScore;
  final int workerCount;
  final int reportCount;
}

/// Average risk score per mine section + report counts. Sorted desc.
final riskHeatmapProvider = FutureProvider<List<HeatmapRow>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final usersSnap = await firestore
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .get();
  final reportsSnap = await firestore
      .collection('hazard_reports')
      .where('status', whereIn: ['pending', 'acknowledged', 'in_progress'])
      .get();

  final scoreByDept = <String, List<double>>{};
  for (final doc in usersSnap.docs) {
    final u = UserModel.fromFirestore(doc);
    final key = u.department.isEmpty ? 'Unspecified' : u.department;
    scoreByDept.putIfAbsent(key, () => []).add(u.riskScore);
  }
  final reportsByDept = <String, int>{};
  for (final doc in reportsSnap.docs) {
    final r = HazardReportModel.fromFirestore(doc);
    final key = r.mineSection.isEmpty ? 'Unspecified' : r.mineSection;
    reportsByDept[key] = (reportsByDept[key] ?? 0) + 1;
  }

  final keys = {...scoreByDept.keys, ...reportsByDept.keys};
  final rows = keys.map((k) {
    final scores = scoreByDept[k] ?? const <double>[];
    final avg = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    return HeatmapRow(
      section: k,
      avgRiskScore: avg,
      workerCount: scores.length,
      reportCount: reportsByDept[k] ?? 0,
    );
  }).toList();
  rows.sort((a, b) => b.avgRiskScore.compareTo(a.avgRiskScore));
  return rows;
});

// ── Mutations (user management) ──────────────────────────────────────────────

class UserManagementService {
  UserManagementService(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> setActive(String uid, bool active) =>
      _firestore.collection('users').doc(uid).update({'isActive': active});

  Future<void> updateRole(String uid, String newRole) =>
      _firestore.collection('users').doc(uid).update({'role': newRole});

  Future<void> reassignMine(String uid, String mineId) =>
      _firestore.collection('users').doc(uid).update({'mineId': mineId});

  /// Bulk-import workers via CSV rows. Each row must contain at minimum
  /// `name`, `email`, `mineId`, `role`. Performs a single batched write
  /// (Firestore batch limit = 500 documents). Returns the number of rows
  /// that were skipped because they were missing required columns.
  Future<int> bulkImportWorkers(List<Map<String, String>> rows) async {
    var skipped = 0;
    final batch = _firestore.batch();
    for (final row in rows) {
      final name = row['name']?.trim();
      final mineId = row['mineId']?.trim();
      if (name == null || name.isEmpty || mineId == null || mineId.isEmpty) {
        skipped++;
        continue;
      }
      // The doc id is the email, which keeps duplicates from being created
      // when a CSV is re-imported. Real auth account creation lives in the
      // Firebase admin SDK / Cloud Functions — this only seeds Firestore.
      final email = row['email']?.trim() ?? '';
      final docId = email.isEmpty ? _firestore.collection('users').doc().id : email;
      batch.set(_firestore.collection('users').doc(docId), {
        'fullName': name,
        'email': email,
        'mineId': mineId,
        'role': row['role']?.trim().toLowerCase() ?? 'worker',
        'shift': row['shift']?.trim().toLowerCase() ?? 'morning',
        'preferredLanguage': row['language']?.trim() ?? 'en',
        'department': row['department']?.trim() ?? '',
        'isActive': true,
        'riskLevel': 'low',
        'riskScore': 0,
        'complianceRate': 1.0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    return skipped;
  }
}

final userManagementServiceProvider =
    Provider<UserManagementService>((ref) =>
        UserManagementService(ref.watch(firestoreProvider)));

// ── Mutations (announcements) ────────────────────────────────────────────────

/// Sends an announcement (writes one alert per worker in the selected mine).
/// Returns the number of alerts written.
Future<int> sendMineAnnouncement({
  required FirebaseFirestore firestore,
  required String mineId,
  required String message,
  String severity = 'info',
}) async {
  Query<Map<String, dynamic>> q = firestore
      .collection('users')
      .where('role', isEqualTo: 'worker');
  if (mineId.isNotEmpty && mineId != '*') {
    q = q.where('mineId', isEqualTo: mineId);
  }
  final users = await q.get();
  if (users.docs.isEmpty) return 0;

  // Firestore batch limit is 500 writes — chunk if necessary.
  var written = 0;
  for (var i = 0; i < users.docs.length; i += 400) {
    final batch = firestore.batch();
    final chunk = users.docs.skip(i).take(400);
    for (final doc in chunk) {
      final ref = firestore.collection('alerts').doc();
      batch.set(ref, {
        'alertId': ref.id,
        'uid': doc.id,
        'userId': doc.id,
        'type': 'announcement',
        'title': 'Announcement',
        'message': message,
        'severity': severity,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      written++;
    }
    await batch.commit();
  }
  return written;
}

// ── Mutations (videos) ───────────────────────────────────────────────────────

Future<void> addSafetyVideo({
  required FirebaseFirestore firestore,
  required String title,
  required String description,
  required String youtubeId,
  required String category,
  required List<String> targetRoles,
  required List<String> tags,
  int durationSeconds = 0,
  String source = 'Custom',
}) async {
  await firestore.collection('safety_videos').add({
    'title': {'en': title},
    'description': {'en': description},
    'category': category,
    'youtubeId': youtubeId,
    'thumbnailUrl': 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
    'durationSeconds': durationSeconds,
    'targetRoles': targetRoles,
    'tags': tags,
    'source': source,
    'quizQuestions': <Map<String, dynamic>>[],
    'uploadedAt': FieldValue.serverTimestamp(),
    'isActive': true,
  });
}

Future<void> deleteSafetyVideo(
    FirebaseFirestore firestore, String videoId) async {
  await firestore.collection('safety_videos').doc(videoId).delete();
}

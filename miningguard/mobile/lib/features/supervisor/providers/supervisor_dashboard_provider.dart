import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/checklist/models/checklist.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/widgets/dashboard/compliance_trend_chart.dart';

/// Filter options for the supervisor's worker list.
enum WorkerFilter { all, highRisk, pendingReports, checklistIncomplete }

/// All workers in the same mine as the current supervisor.
final mineWorkersProvider = StreamProvider<List<UserModel>>((ref) {
  final supervisor = ref.watch(currentUserModelProvider).valueOrNull;
  if (supervisor == null || supervisor.mineId.isEmpty) {
    return const Stream.empty();
  }
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('role', isEqualTo: 'worker')
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromFirestore).toList());
});

/// Currently-selected worker filter chip.
final workerFilterProvider =
    StateProvider<WorkerFilter>((ref) => WorkerFilter.all);

/// Filtered + sorted worker list. Sort order: high → medium → low.
final filteredWorkersProvider = Provider<List<UserModel>>((ref) {
  final all = ref.watch(mineWorkersProvider).valueOrNull ?? const <UserModel>[];
  final filter = ref.watch(workerFilterProvider);
  List<UserModel> filtered;
  switch (filter) {
    case WorkerFilter.highRisk:
      filtered = all.where((w) => w.riskLevel.toLowerCase() == 'high').toList();
      break;
    case WorkerFilter.pendingReports:
      filtered = all.where((w) => w.pendingReportCount > 0).toList();
      break;
    case WorkerFilter.checklistIncomplete:
      filtered = all.where((w) => !w.todayChecklistDone).toList();
      break;
    case WorkerFilter.all:
      filtered = List<UserModel>.from(all);
  }
  const order = {'high': 0, 'medium': 1, 'low': 2};
  filtered.sort((a, b) => (order[a.riskLevel.toLowerCase()] ?? 3)
      .compareTo(order[b.riskLevel.toLowerCase()] ?? 3));
  return filtered;
});

/// Pending hazard reports across the supervisor's mine.
final pendingReportsProvider = StreamProvider<List<HazardReportModel>>((ref) {
  final supervisor = ref.watch(currentUserModelProvider).valueOrNull;
  if (supervisor == null || supervisor.mineId.isEmpty) {
    return const Stream.empty();
  }
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('hazard_reports')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('status', whereIn: ['pending', 'acknowledged', 'in_progress'])
      .orderBy('submittedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) {
    final reports = s.docs.map(HazardReportModel.fromFirestore).toList();
    // Sort severity desc client-side — Firestore would need a composite index
    // on severity+submittedAt, and we already pull a small page.
    const severityRank = {
      'critical': 0,
      'high': 1,
      'medium': 2,
      'low': 3,
    };
    reports.sort((a, b) {
      final cmp = (severityRank[a.severity.firestoreValue] ?? 9)
          .compareTo(severityRank[b.severity.firestoreValue] ?? 9);
      if (cmp != 0) return cmp;
      return b.submittedAt.compareTo(a.submittedAt);
    });
    return reports;
  });
});

/// 30-day compliance trend averaged across the mine.
final mineComplianceTrendProvider =
    FutureProvider<List<ComplianceDataPoint>>((ref) async {
  final supervisor = ref.watch(currentUserModelProvider).valueOrNull;
  if (supervisor == null || supervisor.mineId.isEmpty) return const [];
  final firestore = ref.watch(firestoreProvider);
  final since = DateTime.now().subtract(const Duration(days: 30));
  final snap = await firestore
      .collection('checklists')
      .where('mineId', isEqualTo: supervisor.mineId)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt')
      .get();

  // Bucket by date string for averaging.
  final grouped = <String, List<double>>{};
  for (final doc in snap.docs) {
    final c = Checklist.fromFirestore(doc);
    grouped.putIfAbsent(c.date, () => []).add(c.complianceScore);
  }
  final points = grouped.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return ComplianceDataPoint(date: DateTime.parse(e.key), rate: avg);
  }).toList();
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
});

/// Read-only summary derived from the live streams. No additional Firestore
/// reads — counts are purely client-side aggregations.
class MineSummary {
  const MineSummary({
    required this.totalWorkers,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.checklistCompletedCount,
    required this.pendingReportsCount,
  });
  final int totalWorkers;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final int checklistCompletedCount;
  final int pendingReportsCount;

  double get checklistCompletionRate =>
      totalWorkers == 0 ? 0 : checklistCompletedCount / totalWorkers;
}

final mineSummaryProvider = Provider<MineSummary>((ref) {
  final workers = ref.watch(mineWorkersProvider).valueOrNull ?? const [];
  final reports = ref.watch(pendingReportsProvider).valueOrNull ?? const [];
  return MineSummary(
    totalWorkers: workers.length,
    highRiskCount:
        workers.where((w) => w.riskLevel.toLowerCase() == 'high').length,
    mediumRiskCount:
        workers.where((w) => w.riskLevel.toLowerCase() == 'medium').length,
    lowRiskCount:
        workers.where((w) => w.riskLevel.toLowerCase() == 'low').length,
    checklistCompletedCount: workers.where((w) => w.todayChecklistDone).length,
    pendingReportsCount: reports.length,
  );
});

/// One worker's profile (for the worker-detail screen, read by uid).
final workerByUidProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('users').doc(uid).snapshots().map(
        (snap) => snap.exists ? UserModel.fromFirestore(snap) : null,
      );
});

/// Last 10 hazard reports filed by a specific worker.
final workerReportsProvider =
    StreamProvider.family<List<HazardReportModel>, String>((ref, uid) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('hazard_reports')
      .where('uid', isEqualTo: uid)
      .orderBy('submittedAt', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(HazardReportModel.fromFirestore).toList());
});

/// One worker's last 14 days of checklists.
final workerChecklistHistoryProvider =
    FutureProvider.family<List<Checklist>, String>((ref, uid) async {
  final firestore = ref.watch(firestoreProvider);
  final since = DateTime.now().subtract(const Duration(days: 14));
  final snap = await firestore
      .collection('checklists')
      .where('uid', isEqualTo: uid)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt', descending: true)
      .get();
  return snap.docs.map(Checklist.fromFirestore).toList();
});

/// One worker's 30-day compliance trend.
final workerComplianceTrendProvider =
    FutureProvider.family<List<ComplianceDataPoint>, String>((ref, uid) async {
  final firestore = ref.watch(firestoreProvider);
  final since = DateTime.now().subtract(const Duration(days: 30));
  final snap = await firestore
      .collection('checklists')
      .where('uid', isEqualTo: uid)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt')
      .get();
  return snap.docs.map((d) {
    final c = Checklist.fromFirestore(d);
    return ComplianceDataPoint(
      date: c.submittedAt ?? c.createdAt,
      rate: c.complianceScore,
    );
  }).toList();
});

// ── Mutations ────────────────────────────────────────────────────────────────

Future<void> updateReportStatus({
  required FirebaseFirestore firestore,
  required String reportId,
  required String newStatus,
  String? supervisorNote,
}) async {
  final updates = <String, dynamic>{
    'status': newStatus,
    if (supervisorNote != null && supervisorNote.isNotEmpty)
      'supervisorNote': supervisorNote,
    if (newStatus == 'acknowledged')
      'acknowledgedAt': FieldValue.serverTimestamp(),
    if (newStatus == 'resolved')
      'resolvedAt': FieldValue.serverTimestamp(),
  };
  await firestore
      .collection('hazard_reports')
      .doc(reportId)
      .update(updates);
}

Future<void> sendCustomAlert({
  required FirebaseFirestore firestore,
  required String workerUid,
  required String title,
  required String message,
  String severity = 'info',
}) async {
  await firestore.collection('alerts').add({
    'uid': workerUid,
    'userId': workerUid, // both fields for backward compat
    'type': 'custom',
    'title': title,
    'message': message,
    'severity': severity,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/checklist/models/checklist.dart';
import '../../../features/hazard_report/models/hazard_report_model.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../../../shared/widgets/dashboard/compliance_trend_chart.dart';

/// Today's date as a YYYY-MM-DD string in local time. The Phase 3
/// checklist generation service uses the same format.
String _todayKey() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

/// Today's checklist for the current worker, streamed from Firestore.
/// Returns null while the worker hasn't started one yet today.
final todayChecklistProvider = StreamProvider<Checklist?>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('checklists')
      .where('uid', isEqualTo: user.uid)
      .where('date', isEqualTo: _todayKey())
      .limit(1)
      .snapshots()
      .map((snap) =>
          snap.docs.isEmpty ? null : Checklist.fromFirestore(snap.docs.first));
});

/// Last 5 hazard reports filed by this worker.
final workerRecentReportsProvider =
    StreamProvider<List<HazardReportModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('hazard_reports')
      .where('uid', isEqualTo: user.uid)
      .orderBy('submittedAt', descending: true)
      .limit(5)
      .snapshots()
      .map((s) => s.docs.map(HazardReportModel.fromFirestore).toList());
});

/// Unread alerts for this worker. Phase 6 backend writes the `uid` field;
/// older docs may use `userId`. We use `uid` because that's what the live
/// pipeline writes today.
final workerAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('alerts')
      .where('uid', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map(AlertModel.fromFirestore).toList());
});

/// 30-day compliance history. Builds a [ComplianceDataPoint] from each
/// submitted checklist using its `complianceScore` (0.0–1.0).
final workerComplianceHistoryProvider =
    FutureProvider<List<ComplianceDataPoint>>((ref) async {
  final user = ref.watch(currentUserModelProvider).valueOrNull;
  if (user == null) return const [];
  final firestore = ref.watch(firestoreProvider);
  final since = DateTime.now().subtract(const Duration(days: 30));
  final snap = await firestore
      .collection('checklists')
      .where('uid', isEqualTo: user.uid)
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

/// Marks a single alert as read. Used when the worker taps an alert row.
Future<void> markAlertRead(WidgetRef ref, String alertId) async {
  await ref
      .read(firestoreProvider)
      .collection('alerts')
      .doc(alertId)
      .update({'isRead': true});
}

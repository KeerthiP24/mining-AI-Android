import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hazard_report_model.dart';

class ReportException implements Exception {
  const ReportException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => 'ReportException: $message${cause != null ? ' ($cause)' : ''}';
}

class HazardReportRepository {
  HazardReportRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('hazard_reports');

  Future<String> submitReport(HazardReportModel report) async {
    try {
      final doc = await _reports.add(report.toFirestore());
      return doc.id;
    } catch (e) {
      throw ReportException('Failed to submit report', cause: e);
    }
  }

  Future<void> updateStatus(
    String reportId,
    ReportStatus status, {
    String? supervisorNote,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status.firestoreValue,
        if (status == ReportStatus.acknowledged)
          'acknowledgedAt': FieldValue.serverTimestamp(),
        if (status == ReportStatus.resolved)
          'resolvedAt': FieldValue.serverTimestamp(),
        if (supervisorNote != null) 'supervisorNote': supervisorNote,
      };
      await _reports.doc(reportId).update(data);
    } catch (e) {
      throw ReportException('Failed to update report status', cause: e);
    }
  }

  Future<HazardReportModel?> getReport(String reportId) async {
    try {
      final doc = await _reports.doc(reportId).get();
      if (!doc.exists) return null;
      return HazardReportModel.fromFirestore(doc);
    } catch (e) {
      throw ReportException('Failed to fetch report', cause: e);
    }
  }

  Stream<List<HazardReportModel>> watchWorkerReports(String uid) {
    return _reports
        .where('uid', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(HazardReportModel.fromFirestore).toList());
  }

  Stream<List<HazardReportModel>> watchMineReports(
    String mineId, {
    ReportStatus? statusFilter,
  }) {
    Query<Map<String, dynamic>> query =
        _reports.where('mineId', isEqualTo: mineId);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.firestoreValue);
    }
    return query
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(HazardReportModel.fromFirestore).toList());
  }
}

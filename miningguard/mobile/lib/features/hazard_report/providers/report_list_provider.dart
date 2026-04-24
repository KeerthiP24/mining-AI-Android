import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hazard_report_model.dart';
import 'hazard_report_provider.dart';

final workerReportsProvider =
    StreamProvider.family<List<HazardReportModel>, String>((ref, uid) {
  final repo = ref.watch(hazardReportRepositoryProvider);
  return repo.watchWorkerReports(uid);
});

final mineReportsProvider =
    StreamProvider.family<List<HazardReportModel>, String>((ref, mineId) {
  final repo = ref.watch(hazardReportRepositoryProvider);
  return repo.watchMineReports(mineId);
});

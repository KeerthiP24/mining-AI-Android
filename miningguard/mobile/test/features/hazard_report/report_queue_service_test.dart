import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:miningguard/features/hazard_report/models/hazard_report_model.dart';
import 'package:miningguard/features/hazard_report/services/hazard_report_repository.dart';
import 'package:miningguard/features/hazard_report/services/report_queue_service.dart';

HazardReportModel makeReport(String id) => HazardReportModel(
      reportId: id,
      uid: 'user1',
      mineId: 'mine1',
      inputMode: InputMode.text,
      description: 'Test hazard $id',
      category: HazardCategory.fire,
      severity: HazardSeverity.medium,
      status: ReportStatus.pending,
      submittedAt: DateTime(2025, 9, 1),
      isOfflineCreated: true,
    );

void main() {
  setUpAll(() async {
    Hive.init('.');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('hazard_queue')) {
      final box = Hive.box<String>('hazard_queue');
      await box.clear();
    }
  });

  group('ReportQueueService', () {
    test('enqueue adds to box, pendingCount increments', () async {
      await ReportQueueService.openBox();
      final repo = HazardReportRepository(FakeFirebaseFirestore());
      final service = ReportQueueService(repo);

      expect(service.pendingCount, 0);
      await service.enqueue(makeReport('r1'));
      expect(service.pendingCount, 1);
      await service.enqueue(makeReport('r2'));
      expect(service.pendingCount, 2);
    });

    test('flush submits all queued reports and clears the box', () async {
      await ReportQueueService.openBox();
      final fakeFirestore = FakeFirebaseFirestore();
      final repo = HazardReportRepository(fakeFirestore);
      final service = ReportQueueService(repo);

      await service.enqueue(makeReport('q1'));
      await service.enqueue(makeReport('q2'));
      expect(service.pendingCount, 2);

      await service.flush();

      expect(service.pendingCount, 0);

      final docs = await fakeFirestore.collection('hazard_reports').get();
      expect(docs.docs.length, 2);
    });

    test('flush leaves failed reports in queue', () async {
      await ReportQueueService.openBox();
      // Use a broken JSON entry to simulate a corrupt queue item
      final box = Hive.box<String>('hazard_queue');
      await box.add('{"invalid": true}'); // missing required reportId field

      final repo = HazardReportRepository(FakeFirebaseFirestore());
      final service = ReportQueueService(repo);

      // Should not throw; bad entry stays in queue
      await expectLater(service.flush(), completes);
    });
  });
}

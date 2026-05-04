import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/supervisor/providers/supervisor_dashboard_provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  group('updateReportStatus', () {
    test('writes new status with acknowledgedAt for "acknowledged"', () async {
      await firestore
          .collection('hazard_reports')
          .doc('r1')
          .set({'status': 'pending'});

      await updateReportStatus(
        firestore: firestore,
        reportId: 'r1',
        newStatus: 'acknowledged',
      );

      final doc = await firestore.collection('hazard_reports').doc('r1').get();
      final data = doc.data()!;
      expect(data['status'], 'acknowledged');
      expect(data['acknowledgedAt'], isA<Timestamp>());
    });

    test('writes resolvedAt + supervisorNote for "resolved"', () async {
      await firestore
          .collection('hazard_reports')
          .doc('r2')
          .set({'status': 'in_progress'});

      await updateReportStatus(
        firestore: firestore,
        reportId: 'r2',
        newStatus: 'resolved',
        supervisorNote: 'Issue handled',
      );

      final data = (await firestore
              .collection('hazard_reports')
              .doc('r2')
              .get())
          .data()!;
      expect(data['status'], 'resolved');
      expect(data['resolvedAt'], isA<Timestamp>());
      expect(data['supervisorNote'], 'Issue handled');
    });
  });

  group('sendCustomAlert', () {
    test('writes both uid and userId for backward compat', () async {
      await sendCustomAlert(
        firestore: firestore,
        workerUid: 'worker-1',
        title: 'Hi',
        message: 'Test',
        severity: 'warning',
      );

      final docs = (await firestore.collection('alerts').get()).docs;
      expect(docs, hasLength(1));
      final data = docs.first.data();
      expect(data['uid'], 'worker-1');
      expect(data['userId'], 'worker-1');
      expect(data['title'], 'Hi');
      expect(data['message'], 'Test');
      expect(data['severity'], 'warning');
      expect(data['isRead'], isFalse);
    });
  });
}

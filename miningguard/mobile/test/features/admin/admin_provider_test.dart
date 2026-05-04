import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/admin/providers/admin_provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  test('bulkImportWorkers writes one user per row, skipping incomplete ones',
      () async {
    final svc = UserManagementService(firestore);
    final skipped = await svc.bulkImportWorkers([
      {
        'name': 'Alice',
        'email': 'alice@m.test',
        'mineId': 'M1',
        'role': 'worker',
        'shift': 'morning',
      },
      // Missing mineId -> skipped
      {'name': 'Bob', 'email': 'bob@m.test', 'role': 'worker'},
      {
        'name': 'Carol',
        'email': 'carol@m.test',
        'mineId': 'M1',
        'role': 'supervisor',
      },
    ]);

    expect(skipped, 1);
    final docs = (await firestore.collection('users').get()).docs;
    expect(docs, hasLength(2));
    final names = docs.map((d) => d.data()['fullName']).toSet();
    expect(names, containsAll(<String>{'Alice', 'Carol'}));
  });

  test('addSafetyVideo writes localised title + derived thumbnail', () async {
    await addSafetyVideo(
      firestore: firestore,
      title: 'Helmet basics',
      description: 'How to wear a helmet',
      youtubeId: 'YT123',
      category: 'ppe',
      targetRoles: const ['worker'],
      tags: const ['helmet', 'ppe'],
      durationSeconds: 180,
    );

    final docs = (await firestore.collection('safety_videos').get()).docs;
    expect(docs, hasLength(1));
    final data = docs.first.data();
    expect(data['title'], {'en': 'Helmet basics'});
    expect(data['youtubeId'], 'YT123');
    expect(data['thumbnailUrl'],
        'https://img.youtube.com/vi/YT123/hqdefault.jpg');
    expect(data['isActive'], isTrue);
    expect(data['targetRoles'], ['worker']);
  });

  test('sendMineAnnouncement writes one alert per worker in the mine',
      () async {
    // Seed 3 workers, 1 supervisor
    await firestore.collection('users').doc('w1').set({
      'role': 'worker', 'mineId': 'M1', 'fullName': 'A',
    });
    await firestore.collection('users').doc('w2').set({
      'role': 'worker', 'mineId': 'M1', 'fullName': 'B',
    });
    await firestore.collection('users').doc('w3').set({
      'role': 'worker', 'mineId': 'M2', 'fullName': 'C',
    });
    await firestore.collection('users').doc('s1').set({
      'role': 'supervisor', 'mineId': 'M1', 'fullName': 'S',
    });

    final n = await sendMineAnnouncement(
      firestore: firestore,
      mineId: 'M1',
      message: 'Stay safe',
    );

    expect(n, 2);
    final alerts = (await firestore.collection('alerts').get()).docs;
    expect(alerts, hasLength(2));
    final uids = alerts.map((a) => a.data()['uid']).toSet();
    expect(uids, {'w1', 'w2'});
  });

  test('sendMineAnnouncement with mineId="*" addresses every worker',
      () async {
    await firestore.collection('users').doc('w1').set({
      'role': 'worker', 'mineId': 'M1', 'fullName': 'A',
    });
    await firestore.collection('users').doc('w2').set({
      'role': 'worker', 'mineId': 'M2', 'fullName': 'B',
    });

    final n = await sendMineAnnouncement(
      firestore: firestore,
      mineId: '*',
      message: 'Mine-wide notice',
    );
    expect(n, 2);
  });
}

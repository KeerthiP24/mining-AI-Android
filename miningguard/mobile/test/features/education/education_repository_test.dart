import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/education/data/education_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EducationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = EducationRepository(firestore);
  });

  test('initWatchSession creates a deterministic id and persists', () async {
    final watch = await repo.initWatchSession(
      uid: 'u1',
      videoId: 'v1',
      mineId: 'm1',
    );

    expect(watch.userId, 'u1');
    expect(watch.videoId, 'v1');
    expect(watch.completionPercent, 0);
    expect(watch.isCompleted, isFalse);

    final fetched = await firestore
        .collection('video_watches')
        .doc(watch.watchId)
        .get();
    expect(fetched.exists, isTrue);
  });

  test('initWatchSession is idempotent for same user/video/day', () async {
    final first = await repo.initWatchSession(
      uid: 'u1', videoId: 'v1', mineId: 'm1',
    );
    final second = await repo.initWatchSession(
      uid: 'u1', videoId: 'v1', mineId: 'm1',
    );
    expect(second.watchId, first.watchId);
  });

  test('updateWatchProgress sets isCompleted=true at >=90%', () async {
    final watch = await repo.initWatchSession(
      uid: 'u1', videoId: 'v1', mineId: 'm1',
    );

    await repo.updateWatchProgress(watch.watchId, 89);
    var snap = await firestore
        .collection('video_watches')
        .doc(watch.watchId)
        .get();
    expect(snap.data()?['isCompleted'], isFalse);

    await repo.updateWatchProgress(watch.watchId, 95);
    snap = await firestore
        .collection('video_watches')
        .doc(watch.watchId)
        .get();
    expect(snap.data()?['isCompleted'], isTrue);
    expect(snap.data()?['completionPercent'], 95);
  });

  test('awardCompliancePoints increments the user document', () async {
    await firestore.collection('users').doc('u1').set({'compliancePoints': 3});

    await repo.awardCompliancePoints('u1', 5);

    final snap = await firestore.collection('users').doc('u1').get();
    expect(snap.data()?['compliancePoints'], 8);
  });

  test('saveQuizResult records all quiz fields', () async {
    final watch = await repo.initWatchSession(
      uid: 'u1', videoId: 'v1', mineId: 'm1',
    );

    await repo.saveQuizResult(
      watchId: watch.watchId,
      passed: true,
      score: 3,
      pointsAwarded: 5,
    );

    final snap = await firestore
        .collection('video_watches')
        .doc(watch.watchId)
        .get();
    expect(snap.data()?['quizAttempted'], isTrue);
    expect(snap.data()?['quizPassed'], isTrue);
    expect(snap.data()?['quizScore'], 3);
    expect(snap.data()?['compliancePointsAwarded'], 5);
  });

  test('cacheVideoOfDay merges into the user doc', () async {
    await repo.cacheVideoOfDay(
      uid: 'u1',
      videoId: 'vid_xyz',
      date: '2026-05-02',
    );
    final snap = await firestore.collection('users').doc('u1').get();
    expect(snap.data()?['videoOfDayVideoId'], 'vid_xyz');
    expect(snap.data()?['videoOfDayDate'], '2026-05-02');
  });
}

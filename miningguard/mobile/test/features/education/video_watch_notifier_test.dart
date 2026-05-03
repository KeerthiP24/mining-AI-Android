import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/education/data/education_repository.dart';
import 'package:miningguard/features/education/providers/video_player_provider.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EducationRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = EducationRepository(firestore);
  });

  test('reportProgress fires the quiz exactly once when crossing 90%',
      () async {
    final notifier = VideoWatchNotifier(repo, 'u1', 'm1', 'v1');
    await notifier.init();

    final firstCross = notifier.reportProgress(85);
    expect(firstCross, isFalse);

    final crossed = notifier.reportProgress(91);
    expect(crossed, isTrue, reason: 'first 90+ report should signal');

    // Subsequent updates above 90 must not re-trigger.
    expect(notifier.reportProgress(92), isFalse);
    expect(notifier.reportProgress(99), isFalse);
  });

  test('does not re-trigger the quiz on a session that already completed it',
      () async {
    // Simulate the situation where today's watch already has quizAttempted=true.
    final notifier = VideoWatchNotifier(repo, 'u1', 'm1', 'v1');
    await notifier.init();
    await repo.saveQuizResult(
      watchId: notifier.state!.watchId,
      passed: true,
      score: 3,
      pointsAwarded: 5,
    );
    // Mutate state directly (re-init would normally do this on a fresh load).
    final restored = VideoWatchNotifier(repo, 'u1', 'm1', 'v1');
    await restored.init();

    final crossed = restored.reportProgress(95);
    expect(crossed, isFalse,
        reason: 'already-completed watch must never re-fire the quiz');
  });

  test('submitQuiz awards 5 points when score >= 2', () async {
    final notifier = VideoWatchNotifier(repo, 'u1', 'm1', 'v1');
    await notifier.init();

    await notifier.submitQuiz(score: 2, totalQuestions: 3);

    final user = await firestore.collection('users').doc('u1').get();
    expect(user.data()?['compliancePoints'], 5);

    final watch = await firestore
        .collection('video_watches')
        .doc(notifier.state!.watchId)
        .get();
    expect(watch.data()?['quizPassed'], isTrue);
    expect(watch.data()?['compliancePointsAwarded'], 5);
  });

  test('submitQuiz awards 0 points when score <= 1', () async {
    final notifier = VideoWatchNotifier(repo, 'u1', 'm1', 'v1');
    await notifier.init();

    await notifier.submitQuiz(score: 1, totalQuestions: 3);

    final user = await firestore.collection('users').doc('u1').get();
    // Document may not exist if no compliancePoints field was created.
    expect(user.data()?['compliancePoints'], anyOf(isNull, equals(0)));

    final watch = await firestore
        .collection('video_watches')
        .doc(notifier.state!.watchId)
        .get();
    expect(watch.data()?['quizPassed'], isFalse);
    expect(watch.data()?['compliancePointsAwarded'], 0);
  });
}

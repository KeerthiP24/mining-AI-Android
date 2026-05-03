import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/education/data/education_repository.dart';
import 'package:miningguard/features/education/data/video_of_day_service.dart';
import 'package:miningguard/features/education/domain/safety_video.dart';
import 'package:miningguard/shared/models/user_model.dart';

UserModel _user({String riskLevel = 'low', String uid = 'uid1'}) => UserModel(
      uid: uid,
      fullName: 'Test',
      mineId: 'mine1',
      role: UserRole.worker,
      department: 'A',
      shift: 'morning',
      preferredLanguage: 'en',
      riskLevel: riskLevel,
      createdAt: DateTime(2026),
      lastActiveAt: DateTime(2026),
    );

SafetyVideo _video({
  required String id,
  required String category,
  List<String> tags = const [],
}) {
  return SafetyVideo(
    videoId: id,
    title: {'en': 'Title $id'},
    description: {'en': ''},
    category: category,
    source: VideoSource.dgms,
    youtubeId: id,
    thumbnailUrl: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
    durationSeconds: 60,
    targetRoles: const ['worker'],
    tags: tags,
    quizQuestions: const [],
    uploadedAt: DateTime(2026),
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late EducationRepository repo;
  late VideoOfDayService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = EducationRepository(firestore);
    service = VideoOfDayService(repo);
  });

  test('selects a hazard-tagged video when a recent report matches', () async {
    // Recent gas_leak report → service should prefer videos tagged gas/methane.
    await firestore.collection('hazard_reports').add({
      'uid': 'uid1',
      'category': 'gas_leak',
      'submittedAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 1)),
      ),
    });

    final library = [
      _video(id: 'ppe1', category: VideoCategory.ppe, tags: ['ppe']),
      _video(
        id: 'gas1',
        category: VideoCategory.gasVentilation,
        tags: ['gas', 'methane'],
      ),
    ];

    final pick = await service.getVideoForUser(
      user: _user(),
      allVideos: library,
      now: DateTime(2026, 1, 15),
    );

    expect(pick?.videoId, 'gas1');
  });

  test(
    'high-risk users receive an emergency or PPE video when no hazard match',
    () async {
      final library = [
        _video(id: 'mach1', category: VideoCategory.machinery),
        _video(id: 'em1', category: VideoCategory.emergency),
      ];
      final pick = await service.getVideoForUser(
        user: _user(riskLevel: 'high'),
        allVideos: library,
        now: DateTime(2026, 1, 15),
      );
      expect(pick?.videoId, 'em1');
    },
  );

  test(
    'rotating-schedule fallback picks by dayOfYear % values.length',
    () async {
      final library = [
        _video(id: 'ppe1', category: VideoCategory.ppe),
        _video(id: 'gas1', category: VideoCategory.gasVentilation),
        _video(id: 'roof1', category: VideoCategory.roofSupport),
        _video(id: 'em1', category: VideoCategory.emergency),
        _video(id: 'mach1', category: VideoCategory.machinery),
      ];
      // Day 1 of year → index 1 → gasVentilation
      final pick = await service.getVideoForUser(
        user: _user(),
        allVideos: library,
        now: DateTime(2026, 1, 1),
      );
      expect(pick?.videoId, 'gas1');
    },
  );

  test('returns the cached selection when called again the same day',
      () async {
    final library = [
      _video(id: 'ppe1', category: VideoCategory.ppe),
      _video(id: 'gas1', category: VideoCategory.gasVentilation),
    ];

    final today = DateTime(2026, 3, 10);
    final firstPick = await service.getVideoForUser(
      user: _user(),
      allVideos: library,
      now: today,
    );

    // Even if we mutate the library order, the cached pick should be returned.
    final mutatedLibrary = List<SafetyVideo>.from(library.reversed);
    final secondPick = await service.getVideoForUser(
      user: _user(),
      allVideos: mutatedLibrary,
      now: today,
    );

    expect(secondPick?.videoId, firstPick?.videoId);
  });

  test('writes videoOfDayDate / videoOfDayVideoId on the user doc', () async {
    final library = [_video(id: 'ppe1', category: VideoCategory.ppe)];
    final today = DateTime(2026, 4, 1);

    await service.getVideoForUser(
      user: _user(),
      allVideos: library,
      now: today,
    );

    final userSnap = await firestore.collection('users').doc('uid1').get();
    expect(userSnap.data()?['videoOfDayVideoId'], 'ppe1');
    expect(userSnap.data()?['videoOfDayDate'], '2026-04-01');
  });
}

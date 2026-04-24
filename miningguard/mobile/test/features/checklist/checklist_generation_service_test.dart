import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/checklist/services/checklist_generation_service.dart';
import 'package:miningguard/features/checklist/services/checklist_repository.dart';
import 'package:miningguard/shared/models/user_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ChecklistRepository repo;
  late ChecklistGenerationService service;

  final testUser = UserModel(
    uid: 'uid123',
    fullName: 'Test Worker',
    mineId: 'mine001',
    role: UserRole.worker,
    department: 'Section A',
    shift: 'morning',
    preferredLanguage: 'en',
    createdAt: DateTime(2025),
    lastActiveAt: DateTime(2025),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ChecklistRepository(fakeFirestore);
    service = ChecklistGenerationService(repo, fakeFirestore);
  });

  Future<void> seedTemplate() async {
    await fakeFirestore
        .collection('checklist_templates')
        .doc('mine001_worker')
        .set({
      'templateId': 'mine001_worker',
      'mineId': 'mine001',
      'role': 'worker',
      'version': 1,
      'items': [
        {
          'itemId': 'ppe_helmet',
          'category': 'ppe',
          'labelKey': 'checklist_ppe_helmet',
          'mandatory': true,
          'order': 1,
        },
        {
          'itemId': 'env_walkways_clear',
          'category': 'environment',
          'labelKey': 'checklist_env_walkways_clear',
          'mandatory': false,
          'order': 2,
        },
      ],
    });
  }

  group('getOrCreateChecklist', () {
    test('creates new checklist with correct checklistId format', () async {
      await seedTemplate();

      final checklist = await service.getOrCreateChecklist(testUser);

      // ID format: {uid}_{mineId}_{date}
      expect(checklist.checklistId, startsWith('uid123_mine001_'));
      expect(checklist.status, equals('in_progress'));
      expect(checklist.uid, equals('uid123'));
      expect(checklist.mineId, equals('mine001'));
    });

    test('new checklist has all items set to completed=false', () async {
      await seedTemplate();

      final checklist = await service.getOrCreateChecklist(testUser);

      expect(checklist.items, isNotEmpty);
      for (final item in checklist.items.values) {
        expect(item.completed, isFalse);
        expect(item.completedAt, isNull);
      }
    });

    test('returns existing checklist unchanged on second call', () async {
      await seedTemplate();

      final first = await service.getOrCreateChecklist(testUser);

      // Simulate worker tapping an item
      await repo.updateItemCompleted(first.checklistId, 'ppe_helmet', true);

      final second = await service.getOrCreateChecklist(testUser);

      expect(second.checklistId, equals(first.checklistId));
      // The update should be reflected
      expect(second.items['ppe_helmet']?.completed, isTrue);
    });

    test('selects correct template by role — supervisor gets supervisor template',
        () async {
      // Seed supervisor template
      await fakeFirestore
          .collection('checklist_templates')
          .doc('mine001_supervisor')
          .set({
        'templateId': 'mine001_supervisor',
        'mineId': 'mine001',
        'role': 'supervisor',
        'version': 2,
        'items': [
          {
            'itemId': 'sup_attendance_confirmed',
            'category': 'supervisor',
            'labelKey': 'checklist_sup_attendance_confirmed',
            'mandatory': true,
            'order': 1,
          },
        ],
      });

      final supervisorUser = UserModel(
        uid: 'sup001',
        fullName: 'Supervisor',
        mineId: 'mine001',
        role: UserRole.supervisor,
        department: 'Management',
        shift: 'morning',
        preferredLanguage: 'en',
        createdAt: DateTime(2025),
        lastActiveAt: DateTime(2025),
      );

      final checklist = await service.getOrCreateChecklist(supervisorUser);

      expect(checklist.templateVersion, equals(2));
      expect(checklist.items.containsKey('sup_attendance_confirmed'), isTrue);
    });

    test('auto-seeds default templates when none exist and creates checklist',
        () async {
      // No template pre-seeded — service should seed defaults and succeed
      final checklist = await service.getOrCreateChecklist(testUser);

      expect(checklist.checklistId, startsWith('uid123_mine001_'));
      expect(checklist.status, equals('in_progress'));
      expect(checklist.items, isNotEmpty);

      // Verify both worker and supervisor templates were created in Firestore
      final workerTpl = await fakeFirestore
          .collection('checklist_templates')
          .doc('mine001_worker')
          .get();
      final supTpl = await fakeFirestore
          .collection('checklist_templates')
          .doc('mine001_supervisor')
          .get();
      expect(workerTpl.exists, isTrue);
      expect(supTpl.exists, isTrue);
    });
  });
}

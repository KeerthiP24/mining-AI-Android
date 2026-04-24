import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/checklist/services/checklist_generation_service.dart';
import 'package:miningguard/features/checklist/services/checklist_repository.dart';
import 'package:miningguard/shared/models/user_model.dart';

/// Integration-style test that exercises the full checklist flow:
/// generate → mark mandatory items → submit → verify Firestore state.
///
/// Uses FakeFirebaseFirestore to avoid a running emulator during CI.
/// For against-emulator tests, see the integration_test/ flutter drive suite.
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ChecklistRepository repo;
  late ChecklistGenerationService service;

  final worker = UserModel(
    uid: 'worker001',
    fullName: 'Ravi Kumar',
    mineId: 'mine001',
    role: UserRole.worker,
    department: 'Section B',
    shift: 'morning',
    preferredLanguage: 'hi',
    createdAt: DateTime(2025),
    lastActiveAt: DateTime(2025),
  );

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repo = ChecklistRepository(fakeFirestore);
    service = ChecklistGenerationService(repo, fakeFirestore);

    // Seed template
    await fakeFirestore
        .collection('checklist_templates')
        .doc('mine001_worker')
        .set({
      'templateId': 'mine001_worker',
      'mineId': 'mine001',
      'role': 'worker',
      'version': 1,
      'items': [
        {'itemId': 'ppe_helmet', 'category': 'ppe', 'labelKey': 'checklist_ppe_helmet', 'mandatory': true, 'order': 1},
        {'itemId': 'ppe_boots', 'category': 'ppe', 'labelKey': 'checklist_ppe_boots', 'mandatory': true, 'order': 2},
        {'itemId': 'env_walkways_clear', 'category': 'environment', 'labelKey': 'checklist_env_walkways_clear', 'mandatory': false, 'order': 3},
      ],
    });

    // Seed user document
    await fakeFirestore.collection('users').doc('worker001').set({
      'uid': 'worker001',
      'fullName': 'Ravi Kumar',
      'mineId': 'mine001',
      'role': 'worker',
      'department': 'Section B',
      'shift': 'morning',
      'preferredLanguage': 'hi',
      'complianceRate': 1.0,
      'consecutiveMissedDays': 0,
      'riskScore': 0.0,
      'riskLevel': 'low',
      'totalHazardReports': 0,
    });
  });

  test('full checklist flow: generate → mark mandatory → submit', () async {
    // 1. Generate checklist
    final checklist = await service.getOrCreateChecklist(worker);
    expect(checklist.status, equals('in_progress'));
    expect(checklist.items.isNotEmpty, isTrue);

    // 2. Verify all items start as incomplete
    for (final item in checklist.items.values) {
      expect(item.completed, isFalse);
    }

    // 3. Mark each mandatory item complete
    final mandatoryIds = checklist.items.entries
        .where((e) => e.value.mandatory)
        .map((e) => e.key)
        .toList();

    for (final itemId in mandatoryIds) {
      await repo.updateItemCompleted(checklist.checklistId, itemId, true);
    }

    // 4. Re-fetch and verify items are marked
    final updated = await repo.getChecklist(checklist.checklistId);
    expect(updated, isNotNull);
    for (final id in mandatoryIds) {
      expect(updated!.items[id]?.completed, isTrue);
    }
    expect(updated!.allMandatoryComplete, isTrue);

    // 5. Submit the checklist
    final scores = updated.calculateScores();
    expect(scores.complianceScore, greaterThan(0.0));

    await repo.submitChecklist(
      updated.checklistId,
      worker.uid,
      updated.date,
      scores.complianceScore,
      scores.mandatoryScore,
    );

    // 6. Verify Firestore state
    final submitted = await repo.getChecklist(checklist.checklistId);
    expect(submitted!.status, equals('submitted'));
    expect(submitted.complianceScore, greaterThan(0.0));

    // 7. Verify user's consecutiveMissedDays reset to 0
    final userDoc = await fakeFirestore
        .collection('users')
        .doc('worker001')
        .get();
    expect(userDoc.data()?['consecutiveMissedDays'], equals(0));
  });

  test('re-opening submitted checklist returns same document (no duplicate created)', () async {
    // Generate and submit
    final first = await service.getOrCreateChecklist(worker);
    final scores = first.calculateScores();
    await repo.submitChecklist(
      first.checklistId,
      worker.uid,
      first.date,
      scores.complianceScore,
      scores.mandatoryScore,
    );

    // Call getOrCreate again — should return the submitted doc, not create new
    final second = await service.getOrCreateChecklist(worker);
    expect(second.checklistId, equals(first.checklistId));
    expect(second.status, equals('submitted'));
  });
}

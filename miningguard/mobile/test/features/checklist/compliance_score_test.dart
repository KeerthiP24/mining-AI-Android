import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/checklist/models/checklist.dart';
import 'package:miningguard/features/checklist/models/checklist_item.dart';

void main() {
  group('Checklist.calculateScores', () {
    Checklist makeChecklist(Map<String, ChecklistItemData> items) {
      return Checklist(
        checklistId: 'test_mine001_2025-07-14',
        uid: 'test',
        mineId: 'mine001',
        shift: 'morning',
        date: '2025-07-14',
        templateVersion: 1,
        status: 'in_progress',
        items: items,
        createdAt: DateTime(2025, 7, 14),
      );
    }

    test('all mandatory + all optional complete → 1.0', () {
      final checklist = makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: true),
        'item2': const ChecklistItemData(mandatory: true, completed: true),
        'item3': const ChecklistItemData(mandatory: false, completed: true),
      });
      final scores = checklist.calculateScores();
      expect(scores.complianceScore, closeTo(1.0, 0.001));
      expect(scores.mandatoryScore, closeTo(1.0, 0.001));
    });

    test('all mandatory complete + no optional complete → 0.70', () {
      final checklist = makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: true),
        'item2': const ChecklistItemData(mandatory: true, completed: true),
        'item3': const ChecklistItemData(mandatory: false, completed: false),
      });
      final scores = checklist.calculateScores();
      // mandatory_score=1.0, optional_score=0.0 → 1.0*0.70 + 0.0*0.30 = 0.70
      expect(scores.complianceScore, closeTo(0.70, 0.001));
      expect(scores.mandatoryScore, closeTo(1.0, 0.001));
    });

    test('no mandatory complete + all optional complete → 0.30', () {
      final checklist = makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: false),
        'item2': const ChecklistItemData(mandatory: true, completed: false),
        'item3': const ChecklistItemData(mandatory: false, completed: true),
      });
      final scores = checklist.calculateScores();
      // mandatory_score=0.0, optional_score=1.0 → 0.0*0.70 + 1.0*0.30 = 0.30
      expect(scores.complianceScore, closeTo(0.30, 0.001));
      expect(scores.mandatoryScore, closeTo(0.0, 0.001));
    });

    test('no optional items → optional score treated as 1.0', () {
      final checklist = makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: true),
        'item2': const ChecklistItemData(mandatory: true, completed: true),
      });
      final scores = checklist.calculateScores();
      // mandatory_score=1.0, optional_score=1.0 (no optional items) → 1.0
      expect(scores.complianceScore, closeTo(1.0, 0.001));
    });

    test('50% mandatory + 50% optional → 0.50', () {
      final checklist = makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: true),
        'item2': const ChecklistItemData(mandatory: true, completed: false),
        'item3': const ChecklistItemData(mandatory: false, completed: true),
        'item4': const ChecklistItemData(mandatory: false, completed: false),
      });
      final scores = checklist.calculateScores();
      // mandatory_score=0.5, optional_score=0.5 → 0.5*0.70 + 0.5*0.30 = 0.50
      expect(scores.complianceScore, closeTo(0.50, 0.001));
    });

    test('zero items total → graceful result, no division by zero', () {
      final checklist = makeChecklist({});
      final scores = checklist.calculateScores();
      expect(scores.complianceScore, isA<double>());
      expect(scores.mandatoryScore, isA<double>());
      expect(scores.complianceScore, isNot(isNaN));
      expect(scores.mandatoryScore, isNot(isNaN));
    });
  });

  group('Checklist.allMandatoryComplete', () {
    test('returns true when all mandatory items are checked', () {
      final checklist = Checklist(
        checklistId: 'x',
        uid: 'u',
        mineId: 'm',
        shift: 'morning',
        date: '2025-07-14',
        templateVersion: 1,
        status: 'in_progress',
        items: {
          'a': const ChecklistItemData(mandatory: true, completed: true),
          'b': const ChecklistItemData(mandatory: false, completed: false),
        },
        createdAt: DateTime.now(),
      );
      expect(checklist.allMandatoryComplete, isTrue);
    });

    test('returns false when a mandatory item is unchecked', () {
      final checklist = Checklist(
        checklistId: 'x',
        uid: 'u',
        mineId: 'm',
        shift: 'morning',
        date: '2025-07-14',
        templateVersion: 1,
        status: 'in_progress',
        items: {
          'a': const ChecklistItemData(mandatory: true, completed: false),
          'b': const ChecklistItemData(mandatory: false, completed: true),
        },
        createdAt: DateTime.now(),
      );
      expect(checklist.allMandatoryComplete, isFalse);
    });
  });
}

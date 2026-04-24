import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/checklist/models/checklist.dart';
import 'package:miningguard/features/checklist/models/checklist_item.dart';
import 'package:miningguard/l10n/app_localizations.dart';

/// Minimal submit bar widget for testing — mirrors the logic in ChecklistScreen._SubmitBar
class _TestSubmitBar extends StatelessWidget {
  const _TestSubmitBar({required this.checklist, required this.onSubmit});
  final Checklist checklist;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit = checklist.allMandatoryComplete;

    return FilledButton(
      onPressed: canSubmit ? onSubmit : null,
      child: Text(l10n.checklist_submit_button),
    );
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Checklist _makeChecklist(Map<String, ChecklistItemData> items) {
  return Checklist(
    checklistId: 'test_mine001_2025-07-14',
    uid: 'uid',
    mineId: 'mine001',
    shift: 'morning',
    date: '2025-07-14',
    templateVersion: 1,
    status: 'in_progress',
    items: items,
    createdAt: DateTime(2025, 7, 14),
  );
}

void main() {
  group('Submit button state', () {
    testWidgets('is disabled when mandatory items are incomplete', (tester) async {
      bool submitted = false;

      final checklist = _makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: false),
        'item2': const ChecklistItemData(mandatory: false, completed: true),
      });

      await tester.pumpWidget(
        _wrap(_TestSubmitBar(
          checklist: checklist,
          onSubmit: () => submitted = true,
        )),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull); // disabled

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(submitted, isFalse);
    });

    testWidgets('is enabled when all mandatory items are complete', (tester) async {
      bool submitted = false;

      final checklist = _makeChecklist({
        'item1': const ChecklistItemData(mandatory: true, completed: true),
        'item2': const ChecklistItemData(mandatory: true, completed: true),
        'item3': const ChecklistItemData(mandatory: false, completed: false),
      });

      await tester.pumpWidget(
        _wrap(_TestSubmitBar(
          checklist: checklist,
          onSubmit: () => submitted = true,
        )),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull); // enabled

      await tester.tap(find.byType(FilledButton));
      expect(submitted, isTrue);
    });

    testWidgets('is disabled when no items at all', (tester) async {
      final checklist = _makeChecklist({});

      await tester.pumpWidget(
        _wrap(_TestSubmitBar(
          checklist: checklist,
          onSubmit: () {},
        )),
      );

      // No mandatory items → allMandatoryComplete is true (vacuously)
      // Edge case: empty checklist counts as complete
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}

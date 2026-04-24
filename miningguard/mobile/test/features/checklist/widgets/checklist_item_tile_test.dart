import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miningguard/features/checklist/widgets/checklist_item_tile.dart';
import 'package:miningguard/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('ChecklistItemTile', () {
    testWidgets('calls onTap when tapped and not submitted', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrap(
          ChecklistItemTile(
            itemId: 'ppe_helmet',
            label: 'Hard hat fitted',
            mandatory: true,
            completed: false,
            isSubmitted: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('does NOT call onTap when isSubmitted=true', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrap(
          ChecklistItemTile(
            itemId: 'ppe_helmet',
            label: 'Hard hat fitted',
            mandatory: true,
            completed: false,
            isSubmitted: true,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('shows strikethrough text when completed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistItemTile(
            itemId: 'ppe_helmet',
            label: 'Hard hat fitted',
            mandatory: false,
            completed: true,
            isSubmitted: false,
            onTap: () {},
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Hard hat fitted'));
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('shows "Required" badge for mandatory incomplete items',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistItemTile(
            itemId: 'ppe_helmet',
            label: 'Hard hat fitted',
            mandatory: true,
            completed: false,
            isSubmitted: false,
            onTap: () {},
          ),
        ),
      );

      // Badge should show "Required"
      expect(find.textContaining('Required'), findsOneWidget);
    });

    testWidgets('does NOT show "Required" badge when item is completed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          ChecklistItemTile(
            itemId: 'ppe_helmet',
            label: 'Hard hat fitted',
            mandatory: true,
            completed: true,
            isSubmitted: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.textContaining('Required'), findsNothing);
    });
  });
}

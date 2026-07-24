import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuerfelblock/screens/regicide_counter_screen.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: ThemeData(useMaterial3: true), home: child);

Future<void> _pumpCounter(
  WidgetTester tester, {
  Size size = const Size(800, 1000),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: _wrap(const RegicideCounterScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RegicideCounterScreen', () {
    testWidgets('Enemy card shows Jack with default values', (tester) async {
      await _pumpCounter(tester);

      expect(find.byKey(const Key('regicide-enemy-card')), findsOneWidget);
      // Corner index shows rank letter B + suit ♥
      expect(find.text('B'), findsWidgets);
      // Center stats: HP 20, ATK 10
      expect(find.text('20'), findsWidgets);
      expect(find.text('10'), findsWidgets);
    });

    testWidgets('Suit selector changes the corner index', (tester) async {
      await _pumpCounter(tester);

      expect(find.text('♥'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('suit-3')));
      await tester.tap(find.byKey(const Key('suit-3')));
      await tester.pumpAndSettle();
      // Now spade suit shown in corners
      expect(find.text('♠'), findsWidgets);
    });

    testWidgets('Attack dialog adds damage to health', (tester) async {
      await _pumpCounter(tester);

      // Tap attack button
      await tester.ensureVisible(find.byKey(const Key('regicide-attack-btn')));
      await tester.tap(find.byKey(const Key('regicide-attack-btn')));
      await tester.pumpAndSettle();

      // Type 5 in the dialog
      expect(find.text('Angriff eingeben'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Health should show 15
      expect(find.text('15'), findsWidgets);
    });

    testWidgets('Shield dialog reduces attack', (tester) async {
      await _pumpCounter(tester);

      // Tap shield button
      await tester.ensureVisible(find.byKey(const Key('regicide-shield-btn')));
      await tester.tap(find.byKey(const Key('regicide-shield-btn')));
      await tester.pumpAndSettle();

      // Type 3 in the dialog
      expect(find.text('Schild eingeben'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Attack should show 7 (10-3), badge shows ♠−3
      expect(find.text('7'), findsWidgets);
      expect(find.text('♠−3'), findsOneWidget);
    });

    testWidgets('Defeated button advances to next enemy', (tester) async {
      await _pumpCounter(tester);

      await tester.ensureVisible(
        find.byKey(const Key('regicide-defeated-btn')),
      );
      await tester.tap(find.byKey(const Key('regicide-defeated-btn')));
      await tester.pumpAndSettle();

      // Still Jack (1 of 4 defeated), castle shows 1 check
      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.check),
        findsOneWidget,
      );
    });

    testWidgets('Castle overview shows defeated enemies', (tester) async {
      await _pumpCounter(tester);

      expect(find.byKey(const Key('regicide-castle-overview')), findsOneWidget);
      expect(find.text('König'), findsOneWidget);
      expect(find.text('Dame'), findsOneWidget);
      expect(find.text('Bube'), findsOneWidget);
    });

    testWidgets('Layout does not overflow at 360×800 and 200% text scale', (
      tester,
    ) async {
      await _pumpCounter(tester, size: const Size(360, 800), textScale: 2.0);
      expect(tester.takeException(), isNull);
    });
  });
}

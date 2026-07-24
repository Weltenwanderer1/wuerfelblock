import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wuerfelblock/screens/regicide_counter_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

/// Pump with a tall viewport so all controls are visible without scrolling.
Future<void> _pump(WidgetTester tester, {Widget? child}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(child ?? const RegicideCounterScreen()));
  await tester.pumpAndSettle();
}

void main() {
  group('RegicideCounterScreen', () {
    testWidgets('Shows initial Jack enemy with correct stats', (tester) async {
      await _pump(tester);

      expect(find.text('Bube'), findsWidgets);
      expect(find.textContaining('20 / 20'), findsOneWidget);
    });

    testWidgets('Damage chips reduce health', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(find.text('+5'));
      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(find.textContaining('15 / 20'), findsOneWidget);

      await tester.tap(find.text('+5'));
      await tester.pumpAndSettle();
      expect(find.textContaining('10 / 20'), findsOneWidget);
    });

    testWidgets('Damage -1 button works', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(find.text('+3'));
      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();
      expect(find.textContaining('17 / 20'), findsOneWidget);

      await tester.ensureVisible(find.text('−1'));
      await tester.tap(find.text('−1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('18 / 20'), findsOneWidget);
    });

    testWidgets('Reset damage restores full health', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(find.text('+10'));
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      expect(find.textContaining('10 / 20'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.textContaining('20 / 20'), findsOneWidget);
    });

    testWidgets('Spade shield reduces attack', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(find.text('♠ −3'));
      await tester.tap(find.text('♠ −3'));
      await tester.pumpAndSettle();
      // Badge shows on the card AND chip label — both expected
      expect(find.textContaining('♠ −3'), findsWidgets);
    });

    testWidgets('Suit selector changes display', (tester) async {
      await _pump(tester);

      expect(find.textContaining('Herz'), findsWidgets);

      await tester.tap(find.byKey(const Key('suit-3')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pik'), findsWidgets);
    });

    testWidgets('Defeated button advances to next enemy', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(
        find.byKey(const Key('regicide-defeated-btn')),
      );
      await tester.tap(find.byKey(const Key('regicide-defeated-btn')));
      await tester.pumpAndSettle();

      // Still Jack rank, health reset
      expect(find.textContaining('20 / 20'), findsOneWidget);
    });

    testWidgets('Defeating 4 Jacks advances to Queens', (tester) async {
      await _pump(tester);

      final defeatedBtn = find.byKey(const Key('regicide-defeated-btn'));
      for (var i = 0; i < 4; i++) {
        await tester.ensureVisible(defeatedBtn);
        await tester.tap(defeatedBtn);
        await tester.pumpAndSettle();
      }

      expect(find.text('Dame'), findsWidgets);
      expect(find.textContaining('30 / 30'), findsOneWidget);
    });

    testWidgets('Castle overview tracks progress', (tester) async {
      await _pump(tester);

      expect(find.byKey(const Key('castle-jack-0')), findsOneWidget);
      expect(find.byKey(const Key('castle-jack-3')), findsOneWidget);
      expect(find.byKey(const Key('castle-queen-0')), findsOneWidget);
      expect(find.byKey(const Key('castle-king-0')), findsOneWidget);
    });

    testWidgets('Full reset dialog works', (tester) async {
      await _pump(tester);

      await tester.ensureVisible(find.text('+10'));
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      expect(find.textContaining('10 / 20'), findsOneWidget);

      // Open reset dialog via AppBar
      await tester.tap(find.byKey(const Key('regicide-reset')));
      await tester.pumpAndSettle();
      expect(find.text('Zurücksetzen?'), findsOneWidget);

      // Confirm — the dialog button text is 'Zurücksetzen' (no '?')
      await tester.tap(find.text('Zurücksetzen').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('20 / 20'), findsOneWidget);
    });

    testWidgets('Winning shows victory banner', (tester) async {
      await _pump(tester);

      final defeatedBtn = find.byKey(const Key('regicide-defeated-btn'));
      for (var i = 0; i < 12; i++) {
        await tester.ensureVisible(defeatedBtn);
        await tester.tap(defeatedBtn);
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('regicide-victory')), findsOneWidget);
      expect(find.text('Schloss erobert!'), findsOneWidget);
    });

    testWidgets('New game from victory resets everything', (tester) async {
      await _pump(tester);

      final defeatedBtn = find.byKey(const Key('regicide-defeated-btn'));
      for (var i = 0; i < 12; i++) {
        await tester.ensureVisible(defeatedBtn);
        await tester.tap(defeatedBtn);
        await tester.pumpAndSettle();
      }

      // Victory banner visible
      expect(find.byKey(const Key('regicide-victory')), findsOneWidget);

      await tester.ensureVisible(find.text('Neues Spiel'));
      await tester.tap(find.text('Neues Spiel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('20 / 20'), findsOneWidget);
      expect(find.byKey(const Key('regicide-victory')), findsNothing);
    });

    testWidgets('Enemy card has playing card style', (tester) async {
      await _pump(tester);

      final enemyCard = find.byKey(const Key('regicide-enemy-card'));
      expect(enemyCard, findsOneWidget);

      final cardWidget = tester.widget<Card>(enemyCard);
      expect(cardWidget.elevation, 4);
    });

    testWidgets('Layout renders at 360x800 with 200% text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const RegicideCounterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegicideCounterScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

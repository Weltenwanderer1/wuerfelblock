import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/controllers/game_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/rules_content.dart';
import 'package:wuerfelblock/screens/block_game_screen.dart';
import 'package:wuerfelblock/screens/digital_game_screen.dart';
import 'package:wuerfelblock/screens/escalero_rules_screen.dart';
import 'package:wuerfelblock/screens/rules_screen.dart';
import 'package:wuerfelblock/screens/rules_selection_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_rules_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  test('Kniffel rules describe permissive behavior in both game modes', () {
    final strike = RulesContent.forRuleSet(
      RuleSet.kniffel,
    ).sections.singleWhere((section) => section.title == 'Streichen');

    expect(
      strike.body,
      contains('Die App bleibt in beiden Spielarten bewusst permissiv'),
    );
    expect(strike.body, isNot(contains('Der Scoreblock bleibt')));
  });

  testWidgets('home offers one Spielregeln action', (tester) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spielregeln'), findsOneWidget);
    expect(find.text('Yatzy-Regeln'), findsNothing);
    expect(find.text('Kniffel-Regeln'), findsNothing);
    expect(find.byKey(const Key('rules-action')), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.text('Regelhilfe'), findsNothing);

    await tester.tap(find.byKey(const Key('rules-action')));
    await tester.pumpAndSettle();
    expect(find.byType(RulesSelectionScreen), findsOneWidget);
    expect(find.byKey(const Key('rules-link-ten-thousand')), findsOneWidget);
    expect(find.byKey(const Key('rules-link-escalero')), findsOneWidget);

    await tester.tap(find.byKey(const Key('rules-link-ten-thousand')));
    await tester.pumpAndSettle();
    expect(find.byType(TenThousandRulesScreen), findsOneWidget);
  });

  testWidgets('rules selection opens Escalero separately', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RulesSelectionScreen()));
    final link = find.byKey(const Key('rules-link-escalero'));
    await tester.scrollUntilVisible(link, 250);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.byType(EscaleroRulesScreen), findsOneWidget);
  });

  testWidgets('rules selection opens Schuppenschatz rules', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MaterialApp(home: RulesSelectionScreen()));
    final link = find.byKey(const Key('rules-link-schuppenschatz'));
    await tester.scrollUntilVisible(link, 250);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('Schuppenschatz · Regeln'), findsOneWidget);
    for (final heading in [
      'Spielidee',
      'Die Felder auf der Karte',
      'Dein Zug',
      'Die drei Drachenarten',
      'Spielende & Sieg',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(heading), findsOneWidget);
    }
  });

  testWidgets('rules page is structured and ruleset-specific', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RulesScreen(ruleSet: RuleSet.kniffel)),
    );

    for (final heading in <String>[
      'Ziel',
      'Material',
      'Spielzug',
      'Wertung',
      'Bonus im oberen Block',
      'Streichen',
      'Spielende und Gewinner',
      'Zusatz-Kniffel',
    ]) {
      await tester.scrollUntilVisible(
        find.text(heading),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.text('Yatzy klassisch'), findsNothing);
  });

  testWidgets('block game has active rules and category help', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    expect(find.byTooltip('Yatzy (klassisch)-Regeln öffnen'), findsOneWidget);
    expect(find.byKey(const Key('classic-score-sheet')), findsOneWidget);
    expect(find.text('⚀'), findsOneWidget);
    expect(find.text('OBERER BLOCK'), findsOneWidget);
    expect(find.text('UNTERER BLOCK'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-info-ones')));
    await tester.pumpAndSettle();
    expect(find.text('Einser'), findsWidgets);
    expect(find.textContaining('Beispiel:'), findsOneWidget);
  });

  testWidgets('digital game has active rules and info for every category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.digital,
        players: [Player(name: 'Ada')],
        rollCount: 1,
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: DigitalGameScreen(game: game)));

    expect(find.byTooltip('Yahtzee/Kniffel-Regeln öffnen'), findsOneWidget);
    for (final category in RuleSet.kniffel.categories) {
      expect(find.byKey(Key('category-info-${category.name}')), findsOneWidget);
    }

    final fullHouse = find.byKey(const Key('category-info-fullHouse'));
    await tester.tap(fullHouse);
    await tester.pumpAndSettle();
    expect(find.text('Full House'), findsWidgets);
    expect(find.textContaining('25 Punkte'), findsOneWidget);
  });
}

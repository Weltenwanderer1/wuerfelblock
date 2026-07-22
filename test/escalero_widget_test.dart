import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/escalero_controller.dart';
import 'package:wuerfelblock/models/escalero_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/escalero_game_screen.dart';
import 'package:wuerfelblock/screens/escalero_result_screen.dart';
import 'package:wuerfelblock/screens/escalero_rules_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/widgets/poker_die_widget.dart';

class _ClearFailRepository extends MemoryGameRepository {
  @override
  Future<void> clear() async => throw StateError('clear failed');
}

void main() {
  testWidgets('Pokerwürfel hat Bild- und Haltesemantik', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PokerDieWidget(value: 6, held: true)),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    final node = tester.getSemantics(find.byType(PokerDieWidget));
    expect(node.label, 'Ass, festgehalten');
    expect(node.flagsCollection.isSelected.toString(), contains('isTrue'));
    semantics.dispose();
  });

  testWidgets('Blockmodus passt auf 360 × 800', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final game = EscaleroController.newGame(
      names: const ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: EscaleroGameScreen(game: game)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('escalero-sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Blockwertung bietet regelkonforme Schnellwahl', (tester) async {
    final game = EscaleroController.newGame(
      names: const ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: EscaleroGameScreen(game: game)));
    await tester.pumpAndSettle();

    final straight = find.byKey(const Key('escalero-edit-straight-0'));
    await tester.ensureVisible(straight);
    await tester.pumpAndSettle();
    await tester.tap(straight);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('escalero-quick-score-20')), findsOneWidget);
    expect(find.byKey(const Key('escalero-quick-score-25')), findsOneWidget);
    await tester.tap(find.byKey(const Key('escalero-quick-score-25')));
    await tester.pumpAndSettle();

    expect(game.state.players[0].entries[EscaleroCategory.straight]![0], 25);
    expect(game.state.activePlayerIndex, 1);
  });

  testWidgets('Fremdes Blatt ist im Blockmodus schreibgeschützt', (
    tester,
  ) async {
    final game = EscaleroController.newGame(
      names: const ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: EscaleroGameScreen(game: game)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('escalero-player-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bea').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('escalero-readonly-sheet')), findsOneWidget);
    final cell = find.byKey(const Key('escalero-edit-nine-0'));
    final inkWell = find.descendant(of: cell, matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(inkWell).onTap, isNull);
    expect(game.state.filledEntryCount, 0);
  });

  testWidgets('Digitaler Scorepfad ist über Zelle und Bestätigung erreichbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final values = <int>[6, 6, 6, 6, 6];
    final game = EscaleroController.newGame(
      names: const ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(MaterialApp(home: EscaleroGameScreen(game: game)));
    final scoreCell = find.byKey(const Key('escalero-score-ace-0'));
    final scoreInk = find.descendant(
      of: scoreCell,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(scoreInk).onTap, isNull);

    await tester.tap(find.byKey(const Key('escalero-roll')));
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(scoreInk).onTap, isNotNull);
    await tester.tap(scoreCell);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('escalero-confirm-score')), findsOneWidget);
    await tester.tap(find.byKey(const Key('escalero-confirm-score')));
    await tester.pumpAndSettle();
    expect(game.state.activePlayerIndex, 1);
  });

  testWidgets('fehlgeschlagener Abbruch lässt die Partie geöffnet', (
    tester,
  ) async {
    final game = EscaleroController.newGame(
      names: const ['Ada', 'Bea'],
      repository: _ClearFailRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const Key('open-escalero'),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => EscaleroGameScreen(game: game),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-escalero')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Partie beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Beenden'));
    await tester.pumpAndSettle();

    expect(find.byType(EscaleroGameScreen), findsOneWidget);
    expect(
      find.text('Die Partie konnte nicht gelöscht werden.'),
      findsOneWidget,
    );
  });

  testWidgets('Ergebnis öffnet die Escalero-Regeln', (tester) async {
    EscaleroPlayer complete(String name) {
      var player = EscaleroPlayer(name);
      for (final category in EscaleroCategory.values) {
        for (var column = 0; column < 3; column++) {
          player = player.withEntry(category, column, 0);
        }
      }
      return player;
    }

    final game = EscaleroController(
      state: EscaleroGameState(players: [complete('Ada'), complete('Bea')]),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: EscaleroResultScreen(game: game)),
    );
    final rankLabels = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .map((avatar) => (avatar.child! as Text).data);
    expect(rankLabels, ['1', '1']);
    expect(
      find.text('Abrechnung ausschließlich nach den Spielpunkten.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('kassiert die Person mit der höchsten Summe'),
      findsOneWidget,
    );
    expect(find.textContaining('danach Rohpunkten'), findsNothing);
    await tester.tap(find.byKey(const Key('escalero-result-rules')));
    await tester.pumpAndSettle();
    expect(find.byType(EscaleroRulesScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('escalero-rule-5')),
      300,
    );
    expect(
      find.textContaining('Person mit der höchsten Kolonnensumme'),
      findsOneWidget,
    );
    expect(find.textContaining('von jedem der beiden Gegner'), findsOneWidget);
    expect(find.textContaining('Paarvergleich'), findsNothing);
  });

  testWidgets('Regeln bleiben bei 200 % Text zugänglich', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: EscaleroRulesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('escalero-rules-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

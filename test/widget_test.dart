import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/controllers/game_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/block_game_screen.dart';
import 'package:wuerfelblock/screens/digital_game_screen.dart';
import 'package:wuerfelblock/screens/result_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _FailingRepository extends MemoryGameRepository {
  @override
  Future<void> save(GameState state) =>
      Future.error(Exception('Speicher voll'));
}

void main() {
  testWidgets('Start zeigt Branding und Hauptaktionen', (tester) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Würfelblock'), findsWidgets);
    expect(find.text('Neue Partie'), findsOneWidget);
    expect(find.text('Regelhilfe'), findsOneWidget);
  });

  testWidgets('Setup verlangt eindeutige, nicht leere Namen', (tester) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    expect(find.text('Partie starten'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-player')));
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Spieler 1');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('start-game')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Namen müssen eindeutig sein.'), findsOneWidget);
  });

  testWidgets('Blockzelle öffnet Eingabe und übernimmt Punkte', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    await tester.tap(find.byKey(const Key('score-ones-0')));
    await tester.pumpAndSettle();
    expect(find.text('Punkte eintragen'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('score-input')), '3');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(game.state.players.first.scores[ScoreCategory.ones], 3);
  });

  testWidgets('Digitalwürfel können geworfen und gehalten werden', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.digital,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: DigitalGameScreen(game: game)));
    await tester.tap(find.text('Würfeln'));
    await tester.pump();
    expect(find.text('Wurf 1 von 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('die-0')));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp(r'^Würfel [1-6] gehalten$')),
      findsOneWidget,
    );
  });

  testWidgets('Kniffel kleine Straße lehnt 17 Punkte ab', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    final cell = find.byKey(const Key('score-smallStraight-0'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('score-input')), '17');
    await tester.tap(find.text('Speichern'));
    await tester.pump();
    expect(find.textContaining('Ungültige Punktzahl'), findsOneWidget);
    expect(game.state.players.first.scores, isEmpty);
  });

  testWidgets('Setup wartet Save ab, sperrt Mehrfachstart und zeigt Fehler', (
    tester,
  ) async {
    var starts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          repository: _FailingRepository(),
          onStarted: (_) => starts++,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(starts, 0);
    expect(find.textContaining('nicht gespeichert'), findsOneWidget);
  });

  testWidgets('abgeschlossene gespeicherte Partie wird als Ergebnis geöffnet', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    final state = GameState(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      players: [
        Player(
          name: 'Ada',
          scores: {
            for (final category in RuleSet.kniffel.categories) category: 0,
          },
        ),
      ],
      isComplete: true,
    );
    await repository.save(state);
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partie fortsetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('Gewonnen!'), findsOneWidget);
  });

  testWidgets('Neue Partie behält Save bis zum tatsächlichen Start', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    final oldState = GameState(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.block,
      players: [Player(name: 'Alt')],
    );
    await repository.save(oldState);
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verwerfen'));
    await tester.pumpAndSettle();
    expect(find.byType(SetupScreen), findsOneWidget);
    expect((await repository.load())!.players.first.name, 'Alt');
  });

  testWidgets('Resultat kann letzten Eintrag rückgängig machen', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    for (final category in RuleSet.kniffel.categories) {
      await game.enterScore(category, 0);
    }
    await tester.pumpWidget(MaterialApp(home: ResultScreen(game: game)));
    await tester.tap(find.text('Letzten Eintrag rückgängig'));
    await tester.pumpAndSettle();
    expect(find.byType(BlockGameScreen), findsOneWidget);
    expect(game.state.isComplete, isFalse);
  });

  testWidgets('gespeicherte Blockzelle hat vollständige Semantik', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    await game.enterScore(ScoreCategory.ones, 3);
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Einser für Ada: 3 Punkte',
      ),
      findsOneWidget,
    );
  });
}

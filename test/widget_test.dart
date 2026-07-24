import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/controllers/escalero_controller.dart';
import 'package:wuerfelblock/controllers/game_controller.dart';
import 'package:wuerfelblock/l10n/localized_text.dart';

import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/escalero_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/screens/balut_game_screen.dart';
import 'package:wuerfelblock/screens/block_game_screen.dart';
import 'package:wuerfelblock/screens/digital_game_screen.dart';
import 'package:wuerfelblock/screens/escalero_game_screen.dart';
import 'package:wuerfelblock/screens/result_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_digital_game_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_game_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_result_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _FailingRepository extends MemoryGameRepository {
  @override
  Future<void> save(SavedGameState state) =>
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
    expect(find.byKey(const Key('rules-action')), findsOneWidget);
    expect(find.text('Spielregeln'), findsOneWidget);
    expect(find.text('Yatzy-Regeln'), findsNothing);
  });

  testWidgets('Setup verlangt eindeutige, nicht leere Namen', (tester) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    expect(find.text('Partie starten'), findsOneWidget);
    final addPlayer = find.byKey(const Key('add-player'), skipOffstage: false);
    await tester.ensureVisible(addPlayer);
    await tester.pumpAndSettle();
    await tester.tap(addPlayer);
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Spieler 1');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('start-game'), skipOffstage: false),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Namen müssen eindeutig sein.'), findsOneWidget);
  });

  testWidgets('Blockzelle öffnet Eingabe und übernimmt Punkte', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
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

  testWidgets('Yahtzee/Kniffel-Dialog zeigt keinen alten Yatzy-Namen', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    final cell = find.byKey(const Key('score-yatzy-0'));
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.text('Kniffel · Ada'), findsOneWidget);
    expect(find.textContaining('Yatzy / Kniffel'), findsNothing);
  });

  testWidgets('gefüllte Blockzelle ist bearbeitbar und vorausgefüllt', (
    tester,
  ) async {
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada', scores: {ScoreCategory.ones: 1}),
          Player(name: 'Berta'),
        ],
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('score-ones-0')));
    await tester.pumpAndSettle();

    expect(find.text('Punkte ändern'), findsOneWidget);
    final input = tester.widget<TextField>(
      find.byKey(const Key('score-input')),
    );
    expect(input.controller!.text, '1');
    expect(find.text('Eintrag löschen'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('score-input')), '3');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(game.state.players.first.scores[ScoreCategory.ones], 3);
  });

  testWidgets('gefüllte Blockzelle kann gelöscht werden', (tester) async {
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada', scores: {ScoreCategory.ones: 1}),
          Player(name: 'Berta'),
        ],
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('score-ones-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eintrag löschen'));
    await tester.pumpAndSettle();

    expect(
      game.state.players.first.scores.containsKey(ScoreCategory.ones),
      isFalse,
    );
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('Scoreblock-Kopf bleibt beim vertikalen Scrollen stehen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    final header = find.byKey(const Key('score-sheet-header'));
    final scroll = find.byKey(const Key('score-sheet-scroll'));
    expect(header, findsOneWidget);
    expect(scroll, findsOneWidget);
    final initialY = tester.getTopLeft(header).dy;
    expect(
      tester.getTopLeft(find.text('OBERER BLOCK')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(header).dy),
    );

    await tester.drag(scroll, const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, closeTo(initialY, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kniffel-Block für zwei Personen passt auf 360 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    final horizontal = find.byKey(const Key('score-sheet-horizontal-scroll'));
    expect(horizontal, findsOneWidget);
    final scrollables = tester
        .stateList<ScrollableState>(
          find.descendant(of: horizontal, matching: find.byType(Scrollable)),
        )
        .where((item) => item.position.axisDirection == AxisDirection.right)
        .toList();
    expect(scrollables, hasLength(1));
    expect(scrollables.single.position.maxScrollExtent, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Digitalwürfel können geworfen und gehalten werden', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: DigitalGameScreen(game: game)));
    await tester.tap(find.text('Würfeln'));
    await tester.pump();
    expect(find.text('Wurf 1 von 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('die-0')));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp(r'^Würfel [1-6], gehalten$')),
      findsOneWidget,
    );
  });

  testWidgets('Kniffel kleine Straße lehnt 17 Punkte ab', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    final cell = find.byKey(const Key('score-smallStraight-0'));
    await tester.drag(
      find.byKey(const Key('score-sheet-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
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
    expect(((await repository.load()).state)!.players.first.name, 'Alt');
  });

  testWidgets('Resultat kann letzten Eintrag rückgängig machen', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    for (final category in RuleSet.kniffel.categories) {
      await game.enterScore(category, 0, playerIndex: 0);
      await game.enterScore(category, 0, playerIndex: 1);
    }
    await tester.pumpWidget(MaterialApp(home: ResultScreen(game: game)));
    await tester.tap(find.text('Letzten Eintrag rückgängig'));
    await tester.pumpAndSettle();
    expect(find.byType(BlockGameScreen), findsOneWidget);
    expect(game.state.isComplete, isFalse);
  });

  testWidgets('Ergebnis öffnet den Block zum Korrigieren aller Wertungen', (
    tester,
  ) async {
    final scores = {
      for (final category in RuleSet.kniffel.categories) category: 0,
    };
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada', scores: scores),
          Player(name: 'Berta', scores: scores),
        ],
        isComplete: true,
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: ResultScreen(game: game)));

    await tester.tap(find.text('Wertungen korrigieren'));
    await tester.pumpAndSettle();

    expect(find.byType(BlockGameScreen), findsOneWidget);
    expect(game.state.isComplete, isTrue);
  });

  testWidgets('gespeicherte Blockzelle hat vollständige Semantik', (
    tester,
  ) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    await game.enterScore(ScoreCategory.ones, 3);
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Einser für Ada: 3 Punkte' &&
            widget.properties.hint == 'Punkte ändern oder Eintrag löschen',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Blockwertung zeigt bei Save-Fehler SnackBar', (tester) async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: _FailingRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));
    await tester.tap(find.byKey(const Key('score-ones-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('score-input')), '1');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
    expect(game.state.players.first.scores, isEmpty);
  });

  testWidgets('Setup nummeriert Standardnamen nach Entfernen neu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          repository: MemoryGameRepository(),
          onStarted: (_) {},
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('add-player')));
    await tester.tap(find.byKey(const Key('add-player')));
    await tester.pump();
    final secondRemove = find.byTooltip('Spieler entfernen').at(1);
    await tester.ensureVisible(secondRemove);
    await tester.tap(secondRemove);
    await tester.pump();
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.map((field) => field.controller!.text), [
      'Spieler 1',
      'Spieler 2',
      'Spieler 3',
    ]);
  });

  testWidgets(
    'Setup offers five public games in a responsive two-column grid',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: SetupScreen(
            repository: MemoryGameRepository(),
            onStarted: (_) {},
          ),
        ),
      );
      expect(find.text('Yahtzee/Kniffel'), findsOneWidget);
      expect(find.text('Colordice'), findsOneWidget);
      expect(find.text('10.000'), findsOneWidget);
      expect(find.text('Balut'), findsOneWidget);
      expect(find.byKey(const Key('game-kind-escalero')), findsOneWidget);
      expect(find.text('Escalero'), findsOneWidget);
      expect(find.text('Pokerwürfel · 3 Kolonnen'), findsOneWidget);
      expect(find.text('Yatzy'), findsNothing);
      final yahtzeeX = tester.getCenter(find.text('Yahtzee/Kniffel')).dx;
      final colordiceX = tester.getCenter(find.text('Colordice')).dx;
      expect((yahtzeeX - colordiceX).abs(), greaterThan(50));
      expect(find.byType(TextFormField, skipOffstage: false), findsNWidgets(2));
      expect(
        find.text('Yahtzee/Kniffel wird mit 2 bis 8 Personen gespielt.'),
        findsOneWidget,
      );
      expect(find.text('Spielart', skipOffstage: false), findsOneWidget);
      expect(find.text('Echte Würfel', skipOffstage: false), findsWidgets);
      expect(find.text('Digital würfeln', skipOffstage: false), findsWidgets);
    },
  );

  testWidgets('Escalero setup limits players to three and saves the game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = MemoryGameRepository();
    Object? started;
    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          repository: repository,
          onStarted: (controller) => started = controller,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('game-kind-escalero')));
    await tester.pump();
    expect(
      find.text('Escalero wird mit 2 bis 3 Personen gespielt.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('add-player')));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(
      tester.widget<IconButton>(find.byKey(const Key('add-player'))).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(started, isA<EscaleroController>());
    expect((await repository.load()).state, isA<EscaleroGameState>());
  });

  testWidgets('saved Escalero game resumes into its game screen', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    await repository.save(EscaleroGameState.newGame(['Ada', 'Bea']));
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partie fortsetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(EscaleroGameScreen), findsOneWidget);
  });

  testWidgets('combined setup saves Kniffel and supports both modes', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    Object? started;
    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          repository: repository,
          onStarted: (controller) => started = controller,
        ),
      ),
    );
    final digitalMode = find.byKey(
      const Key('game-mode-digital'),
      skipOffstage: false,
    );
    await tester.ensureVisible(digitalMode);
    await tester.pumpAndSettle();
    await tester.tap(digitalMode);
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();

    expect(started, isA<GameController>());
    final state = (await repository.load()).state as GameState;
    expect(state.ruleSet, RuleSet.kniffel);
    expect(state.mode, GameMode.digital);
    expect(state.players, hasLength(2));
  });

  testWidgets('setup explains the selected game mode in plain German', (
    tester,
  ) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();

    final help = find.byKey(const Key('game-mode-help'), skipOffstage: false);
    expect(help, findsOneWidget);
    await tester.ensureVisible(help);
    await tester.pumpAndSettle();
    expect(tester.widget<LocalizedText>(help).data, contains('Papierblock'));
    expect(
      find.bySemanticsLabel(RegExp(r'Papierblock')),
      findsAtLeastNWidgets(1),
    );
    await tester.tap(find.byKey(const Key('game-mode-digital')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LocalizedText>(
            find.byKey(const Key('game-mode-help'), skipOffstage: false),
          )
          .data,
      contains('Halten, Zugwechsel und Wertung'),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Halten, Zugwechsel und Wertung')),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('10.000 setup supports digital 2–8 and routes to game', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10.000'));
    await tester.pump();
    final digitalMode = find.byKey(
      const Key('game-mode-digital'),
      skipOffstage: false,
    );
    await tester.ensureVisible(digitalMode);
    await tester.pumpAndSettle();
    expect(find.text('Spielart'), findsOneWidget);
    expect(find.text('Digital würfeln'), findsWidgets);
    await tester.tap(digitalMode);
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.text('10.000 wird mit 2 bis 8 Personen gespielt.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(find.byType(TenThousandDigitalGameScreen), findsOneWidget);
    final saved = (await repository.load()).state as TenThousandGameState;
    expect(saved.mode, GameMode.digital);
  });

  testWidgets('saved incomplete and complete 10.000 route correctly', (
    tester,
  ) async {
    final repository = MemoryGameRepository();
    await repository.save(TenThousandGameState.newGame(['Ada', 'Bea']));
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.textContaining('10.000 · Echte Würfel'), findsOneWidget);
    await tester.tap(find.text('Partie fortsetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(TenThousandGameScreen), findsOneWidget);

    await repository.save(
      TenThousandGameState(
        players: [TenThousandPlayer('Ada'), TenThousandPlayer('Bea')],
        turns: [TenThousandTurn(0, 10000), TenThousandTurn(1, 0)],
      ),
    );
    await tester.pumpWidget(
      WuerfelblockApp(key: const Key('completed-app'), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partie fortsetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(TenThousandResultScreen), findsOneWidget);
  });

  testWidgets('Balut setup supports block/digital and routes to game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = MemoryGameRepository();
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balut'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(
      find.text('Balut wird mit 2 bis 8 Personen gespielt.'),
      findsOneWidget,
    );
    expect(find.text('Spielart'), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-mode-digital')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(find.byType(BalutGameScreen), findsOneWidget);
    final saved = (await repository.load()).state as BalutGameState;
    expect(saved.mode, GameMode.digital);
    expect(saved.players, hasLength(2));
  });

  testWidgets('saved Balut game resumes into the block screen', (tester) async {
    final repository = MemoryGameRepository();
    await repository.save(BalutGameState.newGame(['Ada', 'Bea']));
    await tester.pumpWidget(WuerfelblockApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.textContaining('Balut · Echte Würfel'), findsOneWidget);
    await tester.tap(find.text('Partie fortsetzen'));
    await tester.pumpAndSettle();
    expect(find.byType(BalutGameScreen), findsOneWidget);
  });

  testWidgets('Block Zusatz-Kniffel confirms player, category and scoring', (
    tester,
  ) async {
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada', scores: {ScoreCategory.yatzy: 50}),
          Player(name: 'Berta'),
        ],
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    final action = find.byKey(const Key('block-extra-kniffel'));
    expect(action, findsOneWidget);
    expect(
      find.bySemanticsLabel('Zusatz-Kniffel im Scoreblock eintragen'),
      findsOneWidget,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Zusatz-Kniffel bestätigen'), findsOneWidget);
    expect(find.textContaining('+50 Zusatzpunkte'), findsOneWidget);
    expect(find.textContaining('Höchstpunktzahl'), findsOneWidget);
    expect(find.text('Ada'), findsWidgets);

    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();
    expect(game.state.players.first.extraKniffel, 1);
    expect(game.state.players.first.scores[ScoreCategory.ones], 5);
  });

  testWidgets('Block Zusatz-Kniffel öffnet Ergebnis beim letzten Feld', (
    tester,
  ) async {
    final adaScores = <ScoreCategory, int>{
      for (final category in RuleSet.kniffel.categories)
        category: category == ScoreCategory.yatzy ? 50 : 0,
    }..remove(ScoreCategory.ones);
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada', scores: adaScores),
          Player(
            name: 'Berta',
            scores: {
              for (final category in RuleSet.kniffel.categories) category: 0,
            },
          ),
        ],
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: BlockGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('block-extra-kniffel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eintragen'));
    await tester.pumpAndSettle();

    expect(game.state.isComplete, isTrue);
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('Digitaler Zusatz-Kniffel zeigt Hinweis und Höchstwerte', (
    tester,
  ) async {
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.digital,
        players: [
          Player(name: 'Ada', scores: {ScoreCategory.yatzy: 50}),
        ],
        dice: [6, 6, 6, 6, 6],
        held: [true, true, true, true, true],
        rollCount: 1,
      ),
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(MaterialApp(home: DigitalGameScreen(game: game)));
    await tester.tap(find.text('Noch einmal würfeln'));
    await tester.pumpAndSettle();
    expect(find.text('Zusatz-Kniffel!'), findsOneWidget);
    expect(find.textContaining('+50 Punkte'), findsOneWidget);
    await tester.tap(find.text('Feld wählen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kleine Straße'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final smallStraight = find.widgetWithText(ListTile, 'Kleine Straße');
    expect(
      find.descendant(of: smallStraight, matching: find.text('30')),
      findsOneWidget,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/dragon_controller.dart';
import 'package:wuerfelblock/l10n/app_localizations.dart';
import 'package:wuerfelblock/models/dragon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/screens/dragon_game_screen.dart';
import 'package:wuerfelblock/screens/dragon_result_screen.dart';
import 'package:wuerfelblock/screens/schuppenschatz_rules_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _FailingOnceRepository extends MemoryGameRepository {
  bool failNextSave = true;

  @override
  Future<void> save(SavedGameState state) {
    if (failNextSave) {
      failNextSave = false;
      return Future.error(StateError('save failed'));
    }
    return super.save(state);
  }
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets(
    'setup exposes Schuppenschatz, limits players to four and quick game',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Object? started;
      await tester.pumpWidget(
        MaterialApp(
          home: SetupScreen(
            repository: MemoryGameRepository(),
            onStarted: (value) => started = value,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('game-kind-dragongold')));
      await tester.pump();
      expect(
        find.text('Schuppenschatz wird mit 2 bis 4 Personen gespielt.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dragon-quick-game')), findsOneWidget);
      expect(find.text('Schnelles Spiel (18 Karten)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dragon-quick-game')));
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await tester.tap(
          find.byKey(const Key('add-player'), skipOffstage: false),
        );
        await tester.pump();
      }
      final add = tester.widget<IconButton>(
        find.byKey(const Key('add-player'), skipOffstage: false),
      );
      expect(add.onPressed, isNull);
      await tester.tap(
        find.byKey(const Key('start-game'), skipOffstage: false),
      );
      await tester.pumpAndSettle();

      expect(started, isA<DragonController>());
      expect((started! as DragonController).state.cardsInGame, 18);
    },
  );

  testWidgets(
    'digital screen shows colored dice, remaining cards and ability chips',
    (tester) async {
      _useTallViewport(tester);
      const card = DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [DragonField.coloredDie(DieColor.blue, 3), DragonField.empty()],
      );
      const nextCard = DragonCard(
        id: 2,
        type: DragonType.fire,
        fields: [DragonField.empty()],
      );
      final values = [1, 2, 3, 4, 5];
      final state = DragonGameState(
        players: const [
          DragonPlayer(name: 'Ada'),
          DragonPlayer(name: 'Bob'),
        ],
        mode: GameMode.digital,
        deck: const [nextCard],
        currentCard: card,
        attempt: DragonAttempt.empty(card),
        cardsInGame: 41,
        goldPool: 48,
        fieldReductions: const [0, 0],
      );
      final game = DragonController(
        state: state,
        repository: MemoryGameRepository(),
        roller: () => values.removeAt(0),
      );

      await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
      final status = find.byKey(const Key('schuppenschatz-status'));
      expect(status, findsOneWidget);
      expect(
        find.descendant(of: status, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: status, matching: find.text('41')),
        findsNothing,
      );
      expect(
        find.descendant(of: status, matching: find.textContaining('Gold')),
        findsNothing,
      );
      for (final ability in DragonAbility.values) {
        expect(
          find.byKey(Key('dragon-ability-${ability.name}')),
          findsOneWidget,
        );
      }

      await tester.tap(find.byKey(const Key('dragon-roll')));
      await tester.pumpAndSettle();

      expect(game.state.dice, const [
        DieRoll(1, DieColor.white),
        DieRoll(2, DieColor.white),
        DieRoll(3, DieColor.blue),
        DieRoll(4, DieColor.green),
        DieRoll(5, DieColor.black),
      ]);
      expect(find.byKey(const Key('dragon-die-0')), findsOneWidget);
      expect(find.byKey(const Key('dragon-die-4')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Weißer Würfel: 1')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Blauer Würfel: 3')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('digital UI reduces a sum field by one die per roll', (
    tester,
  ) async {
    _useTallViewport(tester);
    const card = DragonCard(
      id: 10,
      type: DragonType.fire,
      fields: [
        DragonField.sum(3, sumMinDice: 2, sumMaxDice: 2),
        DragonField.empty(),
      ],
    );
    final values = [1, 4, 3, 4, 5, 2, 4, 3, 4, 5];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('dragon-roll')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('dragon-die-0')));
    await tester.tap(find.byKey(const Key('dragon-die-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('dragon-field-0')));
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();
    expect(game.state.attempt!.placed[0]!.values, [1]);
    expect(
      find.descendant(
        of: find.byKey(const Key('dragon-field-0')),
        matching: find.byIcon(Icons.north_east_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dragon-field-0')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dragon-die-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();
    expect(game.state.attempt!.placed[0]!.values, [1]);

    await tester.tap(find.byKey(const Key('dragon-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-die-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();

    expect(game.state.selectedDieIndices, isEmpty);
    expect(game.state.attempt!.placed[0]!.values, [1, 2]);
    expect(game.state.attempt!.placed[0]!.colors, [
      DieColor.white,
      DieColor.white,
    ]);
    expect(game.state.dice, hasLength(4));
  });

  testWidgets('fantasy board uses wood status, rune card and framed actions', (
    tester,
  ) async {
    _useTallViewport(tester);
    const card = DragonCard(
      id: 77,
      type: DragonType.ghost,
      fields: [DragonField.empty(), DragonField.number(3)],
    );
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
    );

    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    expect(find.byKey(const Key('dragon-wood-status')), findsOneWidget);
    expect(find.byKey(const Key('dragon-rune-card-frame')), findsOneWidget);
    expect(find.byKey(const Key('dragon-action-frame')), findsOneWidget);
    expect(find.byKey(const Key('dragon-parchment-player-0')), findsOneWidget);
  });

  testWidgets('completed dice field uses the transparent dashed board state', (
    tester,
  ) async {
    _useTallViewport(tester);
    const card = DragonCard(
      id: 11,
      type: DragonType.water,
      fields: [DragonField.number(1), DragonField.empty()],
    );
    final values = [1, 2, 3, 4, 5];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('dragon-roll')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-die-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dragon-field-done-0')), findsOneWidget);
    expect(find.byKey(const Key('dragon-field-dashed-0')), findsOneWidget);
  });

  testWidgets('block screen records the color of a physical die', (
    tester,
  ) async {
    const card = DragonCard(
      id: 19,
      type: DragonType.luck,
      fields: [DragonField.coloredDie(DieColor.green, 4), DragonField.empty()],
    );
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dragon-rune-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-manual-value-4')));
    await tester.pumpAndSettle();

    expect(game.state.attempt!.placed[0]!.values, [4]);
    expect(game.state.attempt!.placed[0]!.colors, [DieColor.green]);
  });

  testWidgets('boss card shows its HP fields', (tester) async {
    _useTallViewport(tester);
    const card = DragonCard(
      id: 37,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(12),
        DragonField.bossHp(18),
        DragonField.bossHp(8),
      ],
    );
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
    );

    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    expect(find.byKey(const Key('dragon-boss-card')), findsOneWidget);
    expect(find.byKey(const Key('dragon-card')), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('/12'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('/18'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('/8'), findsOneWidget);
  });

  testWidgets('block mode can tap a boss HP field and enter damage', (
    tester,
  ) async {
    _useTallViewport(tester);
    const card = DragonCard(
      id: 37,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(12),
        DragonField.bossHp(18),
        DragonField.bossHp(8),
      ],
    );
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
    );

    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dragon-manual-value-4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-manual-value-4')));
    await tester.pumpAndSettle();

    expect(game.state.bossRemainingHp, [8, 18, 8]);
  });

  testWidgets('game screen exposes risk, rules and fixed actions', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [
        DragonCard(
          id: 1,
          type: DragonType.water,
          fields: [DragonField.empty()],
        ),
      ],
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

    expect(find.byKey(const Key('schuppenschatz-risk')), findsOneWidget);
    expect(find.byKey(const Key('dragon-action-bar')), findsOneWidget);
    expect(find.text('Jetzt sicher: 0 Gold'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-rules')));
    await tester.pumpAndSettle();
    expect(find.byType(SchuppenschatzRulesScreen), findsOneWidget);
  });

  testWidgets('block mode can report a roll with no fitting die', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      repository: MemoryGameRepository(),
      shuffledCards: const [
        DragonCard(
          id: 1,
          type: DragonType.water,
          fields: [DragonField.empty()],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    await tester.tap(find.byKey(const Key('dragon-fail-attempt')));
    await tester.pumpAndSettle();
    expect(game.state.activePlayerIndex, 1);
    expect(game.state.cardGold, 5);
  });

  testWidgets('game screen fits 360x800 at 200 percent text scale', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [
        DragonCard(
          id: 1,
          type: DragonType.water,
          fields: [DragonField.empty()],
        ),
      ],
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: DragonGameScreen(game: game)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dragon-action-bar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result screen shows ranking, bonus and opens rules', (
    tester,
  ) async {
    const card = DragonCard(
      id: 1,
      type: DragonType.water,
      fields: [DragonField.empty()],
    );
    final values = [5, 2, 3, 4, 1];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
      roller: () => values.removeAt(0),
    );
    await game.rollDigital();
    await game.toggleDie(0);
    await game.placeSelectedOnField(0);
    expect(game.state.isComplete, isTrue);

    await tester.pumpWidget(MaterialApp(home: DragonResultScreen(game: game)));
    expect(find.text('Schuppenschatz · Ergebnis'), findsOneWidget);
    expect(find.byKey(const Key('dragon-result-summary')), findsOneWidget);
    expect(find.byKey(const Key('dragon-result-row-0')), findsOneWidget);
    expect(find.byKey(const Key('dragon-finish')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-result-rules')));
    await tester.pumpAndSettle();
    expect(find.byType(SchuppenschatzRulesScreen), findsOneWidget);
  });

  testWidgets('result screen is fully translated in English', (tester) async {
    const card = DragonCard(
      id: 1,
      type: DragonType.water,
      fields: [DragonField.empty()],
    );
    final values = [5, 2, 3, 4, 1];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
      roller: () => values.removeAt(0),
    );
    await game.rollDigital();
    await game.toggleDie(0);
    await game.placeSelectedOnField(0);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DragonResultScreen(game: game),
      ),
    );
    expect(find.text('1 dragon · 5 gold · +20 bonus'), findsOneWidget);
    expect(find.textContaining('Drachen'), findsNothing);
  });

  testWidgets('Schuppenschatz game UI is translated in English', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [
        DragonCard(
          id: 1,
          type: DragonType.water,
          fields: [DragonField.empty()],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DragonGameScreen(game: game),
      ),
    );
    expect(find.text('Scale & Gold ×1'), findsOneWidget);
    expect(find.text('Bank now: 0 gold'), findsOneWidget);
    expect(find.text('Current player'), findsOneWidget);
  });

  testWidgets(
    'digital fields and dice are disabled until valid and during retry',
    (tester) async {
      const card = DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [DragonField.number(1), DragonField.empty()],
      );
      final values = [1, 2, 3, 4, 5];
      final repository = _FailingOnceRepository();
      final game = DragonController.newGame(
        names: ['Ada', 'Bob'],
        mode: GameMode.digital,
        repository: repository,
        shuffledCards: const [card],
        roller: () => values.removeAt(0),
      );
      await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));

      expect(
        tester.widget<InkWell>(find.byKey(const Key('dragon-field-0'))).onTap,
        isNull,
      );
      await tester.ensureVisible(find.byKey(const Key('dragon-roll')));
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('dragon-roll'))),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dragon-retry-save')), findsOneWidget);
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(const Key('dragon-die-0')),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );
      expect(
        tester.widget<InkWell>(find.byKey(const Key('dragon-field-0'))).onTap,
        isNull,
      );

      await tester.ensureVisible(find.byKey(const Key('dragon-retry-save')));
      expect(find.byKey(const Key('dragon-retry-save')), findsOneWidget);
      // Directly invoke the retry-save callback (button may be off-screen in 600px tests).
      final retryButton = tester.widget<FilledButton>(
        find.byKey(const Key('dragon-retry-save')),
      );
      retryButton.onPressed!();
      await tester.pumpAndSettle();
      expect(game.needsDigitalSaveRetry, isFalse);
      await tester.ensureVisible(find.byKey(const Key('dragon-die-0')));
      // Directly invoke the die toggle callback.
      final dieInkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('dragon-die-0')),
          matching: find.byType(InkWell),
        ),
      );
      dieInkWell.onTap!();
      await tester.pumpAndSettle();
      expect(game.state.selectedDieIndices, [0]);
      expect(
        tester.widget<InkWell>(find.byKey(const Key('dragon-field-0'))).onTap,
        isNotNull,
      );
    },
  );

  testWidgets('a white six stays numeric while the joker uses a flame', (
    tester,
  ) async {
    const card = DragonCard(
      id: 1,
      type: DragonType.water,
      fields: [DragonField.empty(), DragonField.number(1)],
    );
    final values = [6, 1, 2, 3, 4];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: const [card],
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    await tester.ensureVisible(find.byKey(const Key('dragon-roll')));
    await tester.tapAt(tester.getCenter(find.byKey(const Key('dragon-roll'))));
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Weißer Würfel: 6')), findsOneWidget);
  });
}

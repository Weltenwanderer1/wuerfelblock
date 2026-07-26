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
      expect(find.text('Schnelles Spiel (20 Karten)'), findsOneWidget);
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
      expect((started! as DragonController).state.cardsInGame, 20);
    },
  );

  testWidgets('digital screen shows card, players, deck and tappable dice', (
    tester,
  ) async {
    final values = [1, 2, 3, 4, 5];
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: DragonDeck.cards,
      roller: () => values.removeAt(0),
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    expect(find.byKey(const Key('dragon-card')), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-roll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dragon-die-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('block screen enters a physical die value on a field', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      repository: MemoryGameRepository(),
      shuffledCards: DragonDeck.cards,
    );
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-manual-value-1')));
    await tester.pumpAndSettle();
    expect(game.state.attempt!.placedValues[0], 1);
  });

  testWidgets('game screen exposes status, risk, rules and fixed actions', (
    tester,
  ) async {
    final game = DragonController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      shuffledCards: DragonDeck.cards,
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    expect(find.byKey(const Key('schuppenschatz-status')), findsOneWidget);
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
      shuffledCards: DragonDeck.cards,
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
      shuffledCards: DragonDeck.cards,
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
      shuffledCards: [card],
      roller: () => values.removeAt(0),
    );
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
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
    await game.selectDie(0);
    await game.placeSelectedDie(0);
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
      shuffledCards: DragonDeck.cards,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DragonGameScreen(game: game),
      ),
    );
    expect(find.text('Scale & Gold'), findsOneWidget);
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
      await tester.tap(find.byKey(const Key('dragon-roll')));
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

      await tester.tap(find.byKey(const Key('dragon-retry-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dragon-die-0')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<InkWell>(find.byKey(const Key('dragon-field-0'))).onTap,
        isNotNull,
      );
    },
  );

  testWidgets('the internal six is rendered and announced as a flame', (
    tester,
  ) async {
    const card = DragonCard(
      id: 1,
      type: DragonType.water,
      fields: [DragonField.empty(), DragonField.empty()],
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
    await tester.tap(find.byKey(const Key('dragon-roll')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('Flamme')), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
  });
}

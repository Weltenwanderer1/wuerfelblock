import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/controllers/colordice_controller.dart';
import 'package:wuerfelblock/core/app_theme.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
import 'package:wuerfelblock/screens/colordice_game_screen.dart';
import 'package:wuerfelblock/screens/colordice_result_screen.dart';
import 'package:wuerfelblock/screens/colordice_rules_screen.dart';
import 'package:wuerfelblock/screens/rules_selection_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('Colordice scoreblock fits landscape without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('digital Colordice rolls six dice and enables matching cells', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final values = <int>[2, 5, 3, 4, 6, 1];
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );

    expect(find.byKey(const Key('colordice-roll')), findsOneWidget);
    await tester.tap(find.byKey(const Key('colordice-roll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('colordice-die-0')), findsOneWidget);
    expect(find.text('Weiß: 7'), findsOneWidget);
    expect(find.byKey(const Key('colordice-finish-turn')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'five-player Colordice honors 200% text and keeps controls reachable',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final semantics = tester.ensureSemantics();
      final controller = ColordiceController.newGame(
        names: ['Ada', 'Bea', 'Cem', 'Dora', 'Eli'],
        mode: GameMode.digital,
        repository: MemoryGameRepository(),
        roller: () => 3,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: buildTheme(),
            home: ColordiceGameScreen(game: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rollButton = find.byKey(const Key('colordice-roll'));
      expect(MediaQuery.textScalerOf(tester.element(rollButton)).scale(16), 32);
      expect(find.bySemanticsLabel('Würfeln'), findsOneWidget);
      expect(find.byKey(const Key('colordice-game-scroll')), findsOneWidget);
      final gameScroll = find.descendant(
        of: find.byKey(const Key('colordice-game-scroll')),
        matching: find.byType(Scrollable),
      );
      final scrollable = tester.state<ScrollableState>(gameScroll);
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      await tester.ensureVisible(rollButton);
      expect(rollButton.hitTestable(), findsOneWidget);
      await tester.tap(rollButton);
      await tester.pumpAndSettle();

      final redSix = find.byKey(const Key('colordice-red-6'));
      await tester.ensureVisible(redSix);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(redSix).label, 'Rot 6: verfügbar');
      final finishTurn = find.byKey(const Key('colordice-finish-turn'));
      await tester.scrollUntilVisible(finishTurn, 100, scrollable: gameScroll);
      expect(finishTurn.hitTestable(), findsOneWidget);
      await tester.tap(finishTurn);
      await tester.pumpAndSettle();

      expect(controller.state.activePlayerIndex, 1);
      expect(find.byKey(const Key('colordice-roll')), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('home offers Colordice rules and beginner sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rules-action')), findsOneWidget);
    expect(
      find.textContaining(
        'Yahtzee/Kniffel, Colordice, 10.000, Balut, Escalero und Schuppenschatz',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('rules-action')));
    await tester.pumpAndSettle();
    expect(find.byType(RulesSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('rules-link-colordice')));
    await tester.pumpAndSettle();
    expect(find.byType(ColordiceRulesScreen), findsOneWidget);
    expect(find.textContaining('78 Punkte'), findsOneWidget);
    expect(
      find.textContaining(
        'andere berechtigte Personen gleichzeitig dieselbe letzte Zahl',
      ),
      findsOneWidget,
    );
    for (final heading in [
      'Ziel & Material',
      'Von links nach rechts',
      'Aktion 1: Alle dürfen',
      'Aktion 2: Nur die aktive Person',
      'Fehlwurf',
      'Reihe schließen',
      'Spielende',
      'Punkte',
    ]) {
      expect(find.text(heading), findsOneWidget);
    }
  });

  testWidgets(
    'setup selects Colordice digital mode and enforces 2 to 5 players',
    (tester) async {
      Object? started;
      await tester.pumpWidget(
        MaterialApp(
          home: SetupScreen(
            repository: MemoryGameRepository(),
            onStarted: (game) => started = game,
          ),
        ),
      );
      await tester.tap(find.text('Colordice'));
      await tester.pump();

      final digitalMode = find.byKey(
        const Key('game-mode-digital'),
        skipOffstage: false,
      );
      await tester.ensureVisible(digitalMode);
      await tester.pumpAndSettle();
      expect(find.text('Spielart'), findsOneWidget);
      expect(find.text('Digital würfeln'), findsWidgets);
      expect(find.text('Spieler (2/5)', skipOffstage: false), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('start-game')))
            .onPressed,
        isNotNull,
      );
      await tester.tap(digitalMode);
      await tester.tap(find.byKey(const Key('start-game')));
      await tester.pumpAndSettle();
      expect(started, isA<ColordiceController>());
      expect((started as ColordiceController).state.mode, GameMode.digital);
    },
  );

  testWidgets('Colordice gameplay switches sheet, marks, persists and undoes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = MemoryGameRepository();
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );

    expect(find.text('Aktiv: Ada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('display-player-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bea').last);
    await tester.pumpAndSettle();
    expect(find.text('Block von Bea'), findsOneWidget);
    await tester.tap(find.byKey(const Key('colordice-red-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ankreuzen'));
    await tester.pumpAndSettle();

    expect(controller.state.players[1].crossed[ColordiceColor.red], {5});
    expect(
      ((await repository.load()).state as ColordiceGameState)
          .players[1]
          .crossed[ColordiceColor.red],
      {5},
    );
    await tester.tap(find.byTooltip('Letzte Änderung rückgängig'));
    await tester.pumpAndSettle();
    expect(controller.state.players[1].crossed[ColordiceColor.red], isEmpty);
  });

  testWidgets('miss affects active player and next player is explicit', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );
    await tester.tap(find.byKey(const Key('mark-miss')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fehlwurf eintragen'));
    await tester.pumpAndSettle();
    expect(controller.state.players[0].misses, 1);
    await tester.tap(find.byKey(const Key('next-player')));
    await tester.pumpAndSettle();
    expect(controller.state.activePlayerIndex, 1);
  });

  testWidgets('pending and globally closed row locks have distinct semantics', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    for (final value in ColordiceColor.red.numbers.take(5)) {
      await controller.mark(ColordiceColor.red, value);
    }
    await controller.mark(ColordiceColor.red, 12);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );

    expect(
      find.bySemanticsLabel('Rot Schloss: Schließung ausstehend'),
      findsOneWidget,
    );
    expect(find.text('ausstehend'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-player')));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Rot Schloss: geschlossen'), findsOneWidget);
    expect(find.text('geschlossen'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Colordice result blocks implicit back navigation', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceResultScreen(game: controller)),
    );

    final scope = tester.widget<PopScope<void>>(find.byType(PopScope<void>));
    expect(scope.canPop, isFalse);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
      isFalse,
    );
  });

  testWidgets('Colordice result keeps save and shows error when clear fails', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: _ClearFailRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceResultScreen(game: controller)),
    );

    await tester.tap(find.text('Zur Startseite'));
    await tester.pumpAndSettle();

    expect(find.byType(ColordiceResultScreen), findsOneWidget);
    expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
  });

  testWidgets('Colordice game remains open when abandon clear fails', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: _ClearFailRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: ColordiceGameScreen(game: controller)),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partie beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Partie beenden'));
    await tester.pumpAndSettle();

    expect(find.byType(ColordiceGameScreen), findsOneWidget);
    expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
  });

  testWidgets('Colordice result shows winner and score summary', (
    tester,
  ) async {
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    for (var i = 0; i < 4; i++) {
      await controller.markMiss();
    }
    await tester.pumpWidget(
      MaterialApp(home: ColordiceResultScreen(game: controller)),
    );
    expect(find.text('Bea gewinnt!'), findsOneWidget);
    expect(find.text('Gesamt'), findsWidgets);
    expect(find.text('-20'), findsOneWidget);
  });
}

class _ClearFailRepository extends MemoryGameRepository {
  @override
  Future<void> clear() async {
    throw StateError('disk full');
  }
}

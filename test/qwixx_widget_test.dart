import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/controllers/qwixx_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/qwixx_models.dart';
import 'package:wuerfelblock/screens/qwixx_game_screen.dart';
import 'package:wuerfelblock/screens/qwixx_result_screen.dart';
import 'package:wuerfelblock/screens/qwixx_rules_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('Qwixx scoreblock fits landscape without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('digital Qwixx rolls six dice and enables matching cells', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final values = <int>[2, 5, 3, 4, 6, 1];
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
    );

    expect(find.byKey(const Key('qwixx-roll')), findsOneWidget);
    await tester.tap(find.byKey(const Key('qwixx-roll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qwixx-die-0')), findsOneWidget);
    expect(find.text('Weiß: 7'), findsOneWidget);
    expect(find.byKey(const Key('qwixx-finish-turn')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('digital Qwixx with five players fits landscape', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea', 'Cem', 'Dora', 'Eli'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => 3,
    );

    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
    );
    await tester.tap(find.byKey(const Key('qwixx-roll')));
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home offers Qwixx rules and beginner sections', (tester) async {
    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qwixx-Regeln'), findsOneWidget);
    expect(
      find.textContaining('Yahtzee/Kniffel, Qwixx, 10.000 und Balut'),
      findsOneWidget,
    );
    await tester.tap(find.text('Qwixx-Regeln'));
    await tester.pumpAndSettle();
    expect(find.byType(QwixxRulesScreen), findsOneWidget);
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

  testWidgets('setup selects Qwixx digital mode and enforces 2 to 5 players', (
    tester,
  ) async {
    Object? started;
    await tester.pumpWidget(
      MaterialApp(
        home: SetupScreen(
          repository: MemoryGameRepository(),
          onStarted: (game) => started = game,
        ),
      ),
    );
    await tester.tap(find.text('Qwixx'));
    await tester.pump();

    expect(find.text('Spielart'), findsOneWidget);
    expect(find.text('Digital würfeln'), findsOneWidget);
    expect(find.text('Spieler (2/5)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('start-game')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Digital würfeln'));
    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();
    expect(started, isA<QwixxController>());
    expect((started as QwixxController).state.mode, GameMode.digital);
  });

  testWidgets('Qwixx gameplay switches sheet, marks, persists and undoes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = MemoryGameRepository();
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
    );

    expect(find.text('Aktiv: Ada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('display-player-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bea').last);
    await tester.pumpAndSettle();
    expect(find.text('Block von Bea'), findsOneWidget);
    await tester.tap(find.byKey(const Key('qwixx-red-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ankreuzen'));
    await tester.pumpAndSettle();

    expect(controller.state.players[1].crossed[QwixxColor.red], {5});
    expect(
      ((await repository.load()).state as QwixxGameState)
          .players[1]
          .crossed[QwixxColor.red],
      {5},
    );
    await tester.tap(find.byTooltip('Letzte Änderung rückgängig'));
    await tester.pumpAndSettle();
    expect(controller.state.players[1].crossed[QwixxColor.red], isEmpty);
  });

  testWidgets('miss affects active player and next player is explicit', (
    tester,
  ) async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
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
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    for (final value in QwixxColor.red.numbers.take(5)) {
      await controller.mark(QwixxColor.red, value);
    }
    await controller.mark(QwixxColor.red, 12);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
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

  testWidgets('Qwixx result blocks implicit back navigation', (tester) async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxResultScreen(game: controller)),
    );

    final scope = tester.widget<PopScope<void>>(find.byType(PopScope<void>));
    expect(scope.canPop, isFalse);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
      isFalse,
    );
  });

  testWidgets('Qwixx result keeps save and shows error when clear fails', (
    tester,
  ) async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: _ClearFailRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxResultScreen(game: controller)),
    );

    await tester.tap(find.text('Zur Startseite'));
    await tester.pumpAndSettle();

    expect(find.byType(QwixxResultScreen), findsOneWidget);
    expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
  });

  testWidgets('Qwixx game remains open when abandon clear fails', (
    tester,
  ) async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: _ClearFailRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: QwixxGameScreen(game: controller)),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partie beenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Partie beenden'));
    await tester.pumpAndSettle();

    expect(find.byType(QwixxGameScreen), findsOneWidget);
    expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
  });

  testWidgets('Qwixx result shows winner and score summary', (tester) async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    for (var i = 0; i < 4; i++) {
      await controller.markMiss();
    }
    await tester.pumpWidget(
      MaterialApp(home: QwixxResultScreen(game: controller)),
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

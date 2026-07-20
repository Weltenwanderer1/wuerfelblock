import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/ten_thousand_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/screens/ten_thousand_game_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_digital_game_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_result_screen.dart';
import 'package:wuerfelblock/screens/ten_thousand_rules_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('10.000 rules', () {
    testWidgets('explains every beginner fact and the doubling rule', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: TenThousandRulesScreen()),
      );

      for (final heading in [
        'Ziel & Material',
        'Punkte & Kombinationen',
        'Würfeln, sichern oder riskieren',
        'Alle 6 Würfel zählen',
        'Macke',
        'Hausbau & Brennen',
        'Letzte Runde',
        'Block oder digitale Würfel',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      for (final fact in [
        'sechs Würfeln',
        '2–8 Personen',
        'Eine einzelne 1 zählt 100 Punkte',
        'eine einzelne 5 zählt 50 Punkte',
        'mindestens 350 Punkte',
        'Dreierpasch',
        'Einsen zählen 1.000',
        '1–2–3–4–5–6 zählt 1.000',
        'drei Paare zählen 500 Punkte',
        'mit allen 6 Würfeln weiterwürfeln',
        'über mehrere Würfe ergänzt',
        'mindestens 50 Punkte',
        'alle Punkte dieses Durchgangs',
        'Wurf wiederholt',
        'mindestens 10.000',
        'höchsten Gesamtpunktzahl',
        'Verdopplungsregel',
        'Vier Zweien zählen 400 Punkte',
        'vier Einsen 2.000 Punkte',
        'Blockmodus',
        'automatisch',
      ]) {
        expect(find.textContaining(fact), findsAtLeastNWidgets(1));
      }
      expect(find.textContaining('Regelvarianten'), findsNothing);
      expect(find.textContaining('Vier Zweien zählen 2.000'), findsNothing);
    });
  });

  group('10.000 game', () {
    testWidgets('digital dice can be selected, banked and secured', (
      tester,
    ) async {
      final values = <int>[1, 1, 1, 2, 3, 4];
      final game = TenThousandController.newGame(
        names: ['Ada', 'Bea'],
        mode: GameMode.digital,
        repository: MemoryGameRepository(),
        roller: () => values.removeAt(0),
      );
      await tester.pumpWidget(
        MaterialApp(home: TenThousandDigitalGameScreen(game: game)),
      );

      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byKey(Key('tenk-die-$index')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Auswahl: 1000 Punkte'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tenk-secure')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tenk-secure')));
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 1000);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('fresh dice stay hidden and a low turn can be forfeited', (
      tester,
    ) async {
      final values = <int>[1, 2, 3, 4, 5, 6];
      final game = TenThousandController.newGame(
        names: ['Ada', 'Bea'],
        mode: GameMode.digital,
        repository: MemoryGameRepository(),
        roller: () => values.removeAt(0),
      );
      await tester.pumpWidget(
        MaterialApp(home: TenThousandDigitalGameScreen(game: game)),
      );

      expect(find.byKey(const Key('tenk-die-0')), findsNothing);
      expect(find.text('6 Würfel bereit'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Würfel 1, zur Wertung ausgewählt'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tenk-forfeit')));
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 0);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('enters valid points, rotates active player and persists', (
      tester,
    ) async {
      final repository = MemoryGameRepository();
      final game = TenThousandController.newGame(
        names: ['Ada', 'Bea'],
        repository: repository,
      );
      await _pumpGame(tester, game);

      expect(find.bySemanticsLabel('Aktive Person: Ada'), findsOneWidget);
      await tester.tap(find.byKey(const Key('enter-points')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('points-field'));
      expect(
        tester.widget<TextField>(field).keyboardType,
        const TextInputType.numberWithOptions(),
      );
      await tester.enterText(field, '350');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();

      expect(game.state.totals, [350, 0]);
      expect(game.state.activePlayer?.name, 'Bea');
      expect(find.text('350'), findsWidgets);
      expect(find.bySemanticsLabel('Aktive Person: Bea'), findsOneWidget);
      expect((await repository.load() as TenThousandGameState).totals, [
        350,
        0,
      ]);
    });

    testWidgets('invalid points are rejected in the dialog', (tester) async {
      final game = _newGame();
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('enter-points')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '125');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pump();

      expect(
        find.text('Nur 0 oder positive Vielfache von 50.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(game.state.turns, isEmpty);
    });

    testWidgets('nonzero scores below 350 are rejected', (tester) async {
      final game = _newGame();
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('enter-points')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '250');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pump();

      expect(
        find.text('Mindestens 350 Punkte oder Macke (0).'),
        findsOneWidget,
      );
      expect(game.state.turns, isEmpty);
    });

    testWidgets('Fehlwurf requires confirmation and records zero', (
      tester,
    ) async {
      final game = _newGame();
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('bust-turn')));
      await tester.pumpAndSettle();
      expect(find.text('Fehlwurf (0) eintragen?'), findsOneWidget);
      expect(game.state.turns, isEmpty);
      await tester.tap(find.byKey(const Key('confirm-bust')));
      await tester.pumpAndSettle();

      expect(game.state.turns.single.points, 0);
      expect(find.text('Fehlwurf · 0'), findsOneWidget);
    });

    testWidgets('history supports prefilled edit, delete and restore', (
      tester,
    ) async {
      final game = _newGame();
      await game.enterTurn(350);
      await game.enterTurn(400);
      await _pumpGame(tester, game);

      await tester.tap(find.byKey(const Key('turn-0')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('points-field')))
            .controller!
            .text,
        '350',
      );
      await tester.enterText(find.byKey(const Key('points-field')), '450');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();
      expect(game.state.totals, [450, 400]);

      await tester.tap(find.byKey(const Key('delete-turn-0')));
      await tester.pumpAndSettle();
      expect(find.text('Eintrag löschen?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(game.state.turns.first.isDeleted, isTrue);
      expect(find.textContaining('gelöscht'), findsOneWidget);

      await tester.tap(find.byKey(const Key('turn-0')));
      await tester.pumpAndSettle();
      expect(find.text('Eintrag wiederherstellen'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('points-field')))
            .controller!
            .text,
        '450',
      );
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();
      expect(game.state.turns.first.isDeleted, isFalse);
      expect(game.state.totals, [450, 400]);
    });

    testWidgets('correction impact names and confirms truncated entries', (
      tester,
    ) async {
      final game = TenThousandController(
        state: _state([9950, 50, 50, 50]),
        repository: MemoryGameRepository(),
      );
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('turn-0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '10000');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Diese Korrektur beendet die Partie früher und entfernt 2 spätere Einträge.',
        ),
        findsOneWidget,
      );
      expect(game.state.turns, hasLength(4));
      await tester.tap(find.byKey(const Key('confirm-truncation')));
      await tester.pumpAndSettle();

      expect(game.state.turns, hasLength(2));
      expect(find.byType(TenThousandResultScreen), findsOneWidget);
    });

    testWidgets(
      'final-round banner lists remaining names and final turn routes',
      (tester) async {
        final game = TenThousandController(
          state: _state([10000]),
          repository: MemoryGameRepository(),
        );
        await _pumpGame(tester, game);

        expect(find.text('Letzte Runde'), findsOneWidget);
        expect(find.textContaining('Noch am Zug: Bea'), findsOneWidget);
        await tester.tap(find.byKey(const Key('bust-turn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm-bust')));
        await tester.pumpAndSettle();
        expect(find.byType(TenThousandResultScreen), findsOneWidget);
        expect(find.text('Ada gewinnt!'), findsOneWidget);
      },
    );

    testWidgets('save failure keeps the game and reports an error', (
      tester,
    ) async {
      final repository = _FailingRepository(failSave: true);
      final game = TenThousandController.newGame(
        names: ['Ada', 'Bea'],
        repository: repository,
      );
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('enter-points')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '350');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();

      expect(find.byType(TenThousandGameScreen), findsOneWidget);
      expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
      expect(game.state.turns, isEmpty);
    });

    testWidgets('abandon clear failure keeps the game open', (tester) async {
      final game = TenThousandController.newGame(
        names: ['Ada', 'Bea'],
        repository: _FailingRepository(failClear: true),
      );
      await _pumpGame(tester, game);
      await tester.tap(find.byKey(const Key('abandon-game')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-abandon')));
      await tester.pumpAndSettle();

      expect(find.byType(TenThousandGameScreen), findsOneWidget);
      expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
    });

    testWidgets('is accessible and has no overflow at 360 by 800', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final semantics = tester.ensureSemantics();
      final game = TenThousandController(
        state: TenThousandGameState(
          players: [
            TenThousandPlayer('Alexandra mit langem Namen'),
            TenThousandPlayer('Bea'),
          ],
          turns: [TenThousandTurn(0, 250), TenThousandTurn(1, 0)],
        ),
        repository: MemoryGameRepository(),
      );
      await _pumpGame(tester, game);

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('Aktive Person: Alexandra mit langem Namen'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Punkte für aktive Person eintragen'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Fehlwurf mit 0 Punkten eintragen'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const Key('enter-points'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('bust-turn'))).height,
        greaterThanOrEqualTo(48),
      );
      semantics.dispose();
    });
  });

  group('10.000 result', () {
    testWidgets('shows winner, tie and sorted totals', (tester) async {
      final winner = TenThousandController(
        state: _state([10000, 500]),
        repository: MemoryGameRepository(),
      );
      await _pumpResult(tester, winner);
      expect(find.text('Ada gewinnt!'), findsOneWidget);
      expect(
        _topOf(tester, find.byKey(const Key('result-rank-0'))),
        lessThan(_topOf(tester, find.byKey(const Key('result-rank-1')))),
      );

      final tie = TenThousandController(
        state: _state([10000, 10000]),
        repository: MemoryGameRepository(),
      );
      await _pumpResult(tester, tie);
      expect(find.text('Gleichstand: Ada, Bea'), findsOneWidget);
    });

    testWidgets('blocks implicit back and has no leading back action', (
      tester,
    ) async {
      final game = TenThousandController(
        state: _state([10000, 0]),
        repository: MemoryGameRepository(),
      );
      await _pumpResult(tester, game);
      expect(
        tester.widget<PopScope<void>>(find.byType(PopScope<void>)).canPop,
        isFalse,
      );
      expect(
        tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
        isFalse,
      );
    });

    testWidgets('deleting the trigger reopens the game', (tester) async {
      final game = TenThousandController(
        state: _state([10000, 0]),
        repository: MemoryGameRepository(),
      );
      await _pumpResult(tester, game);
      await tester.tap(find.byKey(const Key('delete-turn-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();

      expect(game.state.isComplete, isFalse);
      expect(find.byType(TenThousandGameScreen), findsOneWidget);
    });

    testWidgets('a correction that stays complete updates the result', (
      tester,
    ) async {
      final game = TenThousandController(
        state: _state([10000, 500]),
        repository: MemoryGameRepository(),
      );
      await _pumpResult(tester, game);
      await tester.tap(find.byKey(const Key('turn-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('points-field')), '10000');
      await tester.tap(find.byKey(const Key('save-points')));
      await tester.pumpAndSettle();

      expect(find.byType(TenThousandResultScreen), findsOneWidget);
      expect(find.text('Gleichstand: Ada, Bea'), findsOneWidget);
    });

    testWidgets('undo that reopens routes to the game', (tester) async {
      final repository = MemoryGameRepository();
      final game = _newGame(repository: repository);
      await game.enterTurn(10000);
      await game.enterTurn(0);
      await _pumpResult(tester, game);
      await tester.tap(find.byKey(const Key('undo-result')));
      await tester.pumpAndSettle();

      expect(game.state.isComplete, isFalse);
      expect(find.byType(TenThousandGameScreen), findsOneWidget);
    });

    testWidgets('save and clear failures stay on result with feedback', (
      tester,
    ) async {
      final repository = _FailingRepository(failSave: true, failClear: true);
      final game = TenThousandController(
        state: _state([10000, 0]),
        repository: repository,
      );
      await _pumpResult(tester, game);
      await tester.tap(find.byKey(const Key('delete-turn-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
      expect(find.byType(TenThousandResultScreen), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('finish-result')),
        300,
      );
      await tester.tap(find.byKey(const Key('finish-result')));
      await tester.pumpAndSettle();
      expect(find.text('Speichern fehlgeschlagen'), findsOneWidget);
      expect(find.byType(TenThousandResultScreen), findsOneWidget);
    });
  });
}

TenThousandController _newGame({GameRepository? repository}) =>
    TenThousandController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository ?? MemoryGameRepository(),
    );

TenThousandGameState _state(List<int> points) => TenThousandGameState(
  players: [TenThousandPlayer('Ada'), TenThousandPlayer('Bea')],
  turns: [
    for (var index = 0; index < points.length; index++)
      TenThousandTurn(index, points[index]),
  ],
);

Future<void> _pumpGame(WidgetTester tester, TenThousandController game) async {
  await tester.pumpWidget(MaterialApp(home: TenThousandGameScreen(game: game)));
  await tester.pumpAndSettle();
}

Future<void> _pumpResult(
  WidgetTester tester,
  TenThousandController game,
) async {
  await tester.pumpWidget(
    MaterialApp(home: TenThousandResultScreen(game: game)),
  );
  await tester.pumpAndSettle();
}

double _topOf(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder).dy;

class _FailingRepository extends MemoryGameRepository {
  _FailingRepository({this.failSave = false, this.failClear = false});

  bool failSave;
  bool failClear;

  @override
  Future<void> save(SavedGameState state) async {
    if (failSave) throw StateError('save failed');
    await super.save(state);
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('clear failed');
    await super.clear();
  }
}

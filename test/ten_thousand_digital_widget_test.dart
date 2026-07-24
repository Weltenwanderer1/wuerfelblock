import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/ten_thousand_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/ten_thousand_digital_game_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('10.000 digital game', () {
    testWidgets('dice are always visible, selected stay locked after bank', (
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

      // Alle 6 Würfel sind VOR dem Wurf sichtbar
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }
      expect(find.text('6 Würfel bereit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();

      // Nach dem Wurf alle 6 sichtbar
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }

      // Erste drei (1,1,1) auswählen und werten
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byKey(Key('tenk-die-$index')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Auswahl: 1000 Punkte'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      // Alle 6 Würfel bleiben sichtbar — die ersten drei sind gelockt
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 3);
      expect(game.state.digitalTurn!.roundPoints, 1000);

      // Sichern
      await tester.tap(find.byKey(const Key('tenk-secure')));
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 1000);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('dice stay visible in grid and button shows remaining count', (
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

      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();

      // Alle 6 im 3×2-Grid sichtbar
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }

      // Einen Würfel (1) auswählen und werten
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      // 5 Würfel bereit zum Weiterwürfeln
      expect(find.text('5 Würfel bereit'), findsOneWidget);
      expect(find.text('Mit 5 Würfeln weiterwürfeln'), findsOneWidget);

      // Forfeit über den Controller (kein UI-Button mehr)
      await game.forfeitDigitalTurn();
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 0);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('banked dice keep their values visible', (tester) async {
      final values = <int>[5, 5, 5, 2, 4, 6, 3, 4, 6];
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

      // Drei Fünfer auswählen und werten
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.tap(find.byKey(const Key('tenk-die-1')));
      await tester.tap(find.byKey(const Key('tenk-die-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      expect(game.state.digitalTurn!.roundPoints, 500);

      // Weiterwürfeln mit 3 Würfeln
      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();

      // Alle 6 sichtbar — gelockte behalten ihre Werte
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }
      // Die ersten drei sind immer noch 5 (gelockt)
      final dice = game.state.digitalTurn!.dice;
      expect(dice[0], 5);
      expect(dice[1], 5);
      expect(dice[2], 5);
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 3);
    });

    testWidgets('hot dice reset locks and require confirmation roll', (
      tester,
    ) async {
      final values = <int>[1, 2, 3, 4, 5, 6, 2, 3, 3, 4, 4, 6];
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

      // Alle 6 auswählen und werten
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(Key('tenk-die-$i')));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      expect(game.state.digitalTurn!.roundPoints, 1000);
      expect(game.state.digitalTurn!.mustRoll, isTrue);
      expect(
        find.textContaining('Bestätigungswurf ist Pflicht'),
        findsOneWidget,
      );

      // Weiterwürfeln (alle 6)
      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();
      expect(game.state.digitalTurn!.isMacke, isTrue);
    });
  });
}

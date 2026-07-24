import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/ten_thousand_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/ten_thousand_digital_game_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('10.000 digital game', () {
    testWidgets('bank-and-roll: one action banks and rolls immediately', (
      tester,
    ) async {
      // 6 for first roll, 3 for the auto-roll after banking 3 dice (include a 5 so it's not a Macke)
      final values = <int>[1, 1, 1, 2, 3, 4, 2, 5, 4];
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

      // Würfeln
      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();

      // Nach dem Wurf alle 6 sichtbar
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }

      // Erste drei (1,1,1) auswählen → 1000 Punkte
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byKey(Key('tenk-die-$index')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Auswahl: 1000 Punkte'), findsOneWidget);

      // "Weiter würfeln" bankt UND würfelt sofort
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      // Alle 6 Würfel bleiben sichtbar — die ersten drei sind gelockt
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 3);
      expect(game.state.digitalTurn!.roundPoints, 1000);
      // hasRolled ist true — der zweite Wurf ist schon passiert
      expect(game.state.digitalTurn!.hasRolled, isTrue);

      // Sichern
      await tester.tap(find.byKey(const Key('tenk-secure')));
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 1000);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('bank-and-roll locks 1 die and rolls 5 new', (tester) async {
      final values = <int>[1, 2, 3, 4, 5, 6, 3, 4, 5, 6, 2];
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

      // Einen Würfel (1) auswählen und banken
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      // 1 Würfel gelockt, 5 neue gewürfelt
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 1);
      expect(game.state.digitalTurn!.dice[0], 1); // gelockter Wert bleibt
      expect(game.state.digitalTurn!.activeDiceCount, 5);
      expect(game.state.digitalTurn!.roundPoints, 100);
      // Zweiter Wurf ist schon passiert
      expect(game.state.digitalTurn!.hasRolled, isTrue);
    });

    testWidgets('banked dice keep their values visible after bank-and-roll', (
      tester,
    ) async {
      final values = <int>[5, 5, 5, 2, 4, 6, 3, 5, 6];
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

      // Drei Fünfer auswählen und banken
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.tap(find.byKey(const Key('tenk-die-1')));
      await tester.tap(find.byKey(const Key('tenk-die-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      expect(game.state.digitalTurn!.roundPoints, 500);

      // Alle 6 sichtbar — gelockte behalten ihre Werte
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('tenk-die-$i')), findsOneWidget);
      }
      final dice = game.state.digitalTurn!.dice;
      expect(dice[0], 5);
      expect(dice[1], 5);
      expect(dice[2], 5);
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 3);
    });

    testWidgets('hot dice bank-and-roll resets locks and rolls all 6', (
      tester,
    ) async {
      // 6 for first roll, 6 for hot-dice re-roll
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

      // Alle 6 auswählen (Straße = 1000) und banken
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(Key('tenk-die-$i')));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tenk-bank')));
      await tester.pumpAndSettle();

      expect(game.state.digitalTurn!.roundPoints, 1000);
      // Hot Dice: alle Locks zurückgesetzt, 6 neue Würfel gewürfelt
      expect(game.state.digitalTurn!.locked.where((v) => v).length, 0);
      expect(game.state.digitalTurn!.hasRolled, isTrue);
      expect(game.state.digitalTurn!.activeDiceCount, 6);

      // Der zweite Wurf [2,3,3,4,4,6] ist eine Macke
      expect(game.state.digitalTurn!.isMacke, isTrue);
      expect(find.byKey(const Key('tenk-confirm-macke')), findsOneWidget);
    });

    testWidgets('secure auto-banks open selection', (tester) async {
      final values = <int>[5, 5, 5, 1, 2, 4];
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

      // Drei Fünfer (500) + eine Eins (100) = 600 auswählen
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.tap(find.byKey(const Key('tenk-die-1')));
      await tester.tap(find.byKey(const Key('tenk-die-2')));
      await tester.tap(find.byKey(const Key('tenk-die-3')));
      await tester.pumpAndSettle();
      expect(find.text('Auswahl: 600 Punkte'), findsOneWidget);

      // Direkt Sichern — bankt die offene Auswahl automatisch
      await tester.tap(find.byKey(const Key('tenk-secure')));
      await tester.pumpAndSettle();
      expect(game.state.turns.single.points, 600);
      expect(game.state.activePlayer?.name, 'Bea');
    });

    testWidgets('secure button always visible with current points', (
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

      // Sichern-Button ist immer sichtbar (auch mit 0 Punkten, aber disabled)
      expect(find.byKey(const Key('tenk-secure')), findsOneWidget);
      expect(find.text('0 Punkte sichern'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tenk-roll')));
      await tester.pumpAndSettle();

      // Eine Eins auswählen (100 Punkte) — Sichern zeigt 100, aber disabled (< 350)
      await tester.tap(find.byKey(const Key('tenk-die-0')));
      await tester.pumpAndSettle();
      expect(find.text('100 Punkte sichern'), findsOneWidget);
    });
  });
}

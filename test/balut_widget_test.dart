import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/balut_controller.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/balut_game_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('Balut block mode fits 360 px without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = BalutController.newGame(
      names: const ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(home: BalutGameScreen(game: controller)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Balut digital mode can score a category and advance player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final values = <int>[6, 6, 6, 6, 6];
    final controller = BalutController.newGame(
      names: const ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => values.removeAt(0),
    );
    await tester.pumpWidget(
      MaterialApp(home: BalutGameScreen(game: controller)),
    );

    await tester.tap(find.byKey(const Key('balut-roll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('balut-die-0')), findsOneWidget);

    // Tapping the first open slot in the Sechser row must open the
    // digital confirm dialog and finally advance the active player.
    final firstSechser = find.byKey(const Key('balut-score-sixes-0'));
    expect(firstSechser, findsOneWidget);
    await tester.tap(firstSechser);
    await tester.pumpAndSettle();
    // The dialog title includes the suggested score for the current dice.
    expect(find.byKey(const Key('confirm-score')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-score')));
    await tester.pumpAndSettle();
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.state.players[0].entries[BalutCategory.sixes]!.first, 30);
  });
}

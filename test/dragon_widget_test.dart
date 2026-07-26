import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/dragon_controller.dart';
import 'package:wuerfelblock/models/dragon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/dragon_game_screen.dart';
import 'package:wuerfelblock/screens/setup_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('setup exposes Drachengold, limits players to four and quick game', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    Object? started;
    await tester.pumpWidget(MaterialApp(home: SetupScreen(repository: MemoryGameRepository(), onStarted: (value) => started = value)));
    await tester.tap(find.byKey(const Key('game-kind-dragongold')));
    await tester.pump();
    expect(find.text('Drachengold wird mit 2 bis 4 Personen gespielt.'), findsOneWidget);
    expect(find.byKey(const Key('dragon-quick-game')), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('add-player'), skipOffstage: false));
      await tester.pump();
    }
    final add = tester.widget<IconButton>(find.byKey(const Key('add-player'), skipOffstage: false));
    expect(add.onPressed, isNull);
    await tester.tap(find.byKey(const Key('start-game'), skipOffstage: false));
    await tester.pumpAndSettle();
    expect(started, isA<DragonController>());
  });

  testWidgets('digital screen shows card, players, deck and tappable dice', (tester) async {
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
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    expect(find.byKey(const Key('dragon-card')), findsOneWidget);
    expect(find.text('42 Karten'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dragon-roll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dragon-die-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('block screen enters a physical die value on a field', (tester) async {
    final game = DragonController.newGame(names: ['Ada', 'Bob'], repository: MemoryGameRepository(), shuffledCards: DragonDeck.cards);
    await tester.pumpWidget(MaterialApp(home: DragonGameScreen(game: game)));
    await tester.tap(find.byKey(const Key('dragon-field-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dragon-manual-value-1')));
    await tester.pumpAndSettle();
    expect(game.state.attempt!.placedValues[0], 1);
  });
}

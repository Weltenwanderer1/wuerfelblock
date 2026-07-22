import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/escalero_controller.dart';
import 'package:wuerfelblock/models/escalero_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/screens/escalero_game_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _FailingRepository extends MemoryGameRepository {
  bool fail = true;

  @override
  Future<void> save(SavedGameState state) async {
    if (fail) throw StateError('save failed');
    await super.save(state);
  }
}

void main() {
  testWidgets('Save-Retry bleibt aktiv und würfelt nicht erneut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _FailingRepository();
    var calls = 0;
    final values = <int>[1, 2, 3, 4, 5];
    final game = EscaleroController(
      state: EscaleroGameState(
        players: [
          EscaleroPlayer('Ada').withEntry(EscaleroCategory.nine, 0, 1),
          EscaleroPlayer('Bea'),
        ],
        mode: GameMode.digital,
      ),
      repository: repository,
      roller: () {
        calls++;
        return values.removeAt(0);
      },
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(home: EscaleroGameScreen(game: game)),
      ),
    );
    await tester.tap(find.byKey(const Key('escalero-roll')));
    await tester.pumpAndSettle();

    expect(game.needsDigitalSaveRetry, isTrue);
    expect(tester.takeException(), isNull);
    final scoreCell = find.byKey(const Key('escalero-score-nine-0'));
    final scoreInk = find.descendant(
      of: scoreCell,
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(scoreInk).onTap, isNull);
    expect(
      tester.getSemantics(scoreCell).flagsCollection.isButton.toString(),
      'false',
    );
    final retry = find.byKey(const Key('escalero-retry-save'));
    expect(retry, findsOneWidget);
    expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);

    repository.fail = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(game.needsDigitalSaveRetry, isFalse);
    expect(calls, 5);
  });
}

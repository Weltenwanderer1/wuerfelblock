import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/ten_thousand_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _ControlledRepository extends MemoryGameRepository {
  bool failSave = false;
  bool failClear = false;
  Completer<void>? saveGate;
  int saveCalls = 0;

  @override
  Future<void> save(SavedGameState state) async {
    saveCalls++;
    final gate = saveGate;
    if (gate != null) await gate.future;
    if (failSave) throw StateError('save failed');
    await super.save(state);
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('clear failed');
    await super.clear();
  }
}

void main() {
  test('digital turn rolls, banks and secures into ledger', () async {
    final repository = MemoryGameRepository();
    final values = <int>[1, 1, 1, 2, 3, 4];
    final controller = TenThousandController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await controller.rollDigital();
    await controller.toggleDigitalDie(0);
    await controller.toggleDigitalDie(1);
    await controller.toggleDigitalDie(2);
    await controller.bankDigitalSelection();
    expect(controller.state.digitalTurn!.roundPoints, 1000);
    await controller.secureDigitalTurn();

    expect(controller.state.turns.single.points, 1000);
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.state.digitalTurn!.roundPoints, 0);
    final saved = (await repository.load()).state as TenThousandGameState;
    expect(saved.turns.single.points, 1000);

    await controller.undo();
    expect(controller.state.turns, isEmpty);
    expect(controller.state.digitalTurn!.roundPoints, 0);
  });

  test('failed digital roll keeps dice and requires save retry', () async {
    final repository = _ControlledRepository()..failSave = true;
    final values = <int>[1, 2, 3, 4, 5, 6];
    final controller = TenThousandController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await expectLater(controller.rollDigital(), throwsA(isA<StateError>()));
    expect(controller.state.digitalTurn!.dice, [1, 2, 3, 4, 5, 6]);
    expect(controller.state.digitalTurn!.hasRolled, isTrue);
    expect(controller.needsDigitalSaveRetry, isTrue);
    expect(() => controller.toggleDigitalDie(0), throwsStateError);

    repository.failSave = false;
    await controller.retryDigitalSave();
    expect(controller.needsDigitalSaveRetry, isFalse);
    final saved = (await repository.load()).state as TenThousandGameState;
    expect(saved.digitalTurn!.dice, [1, 2, 3, 4, 5, 6]);
  });

  test('a started digital turn below 350 can be forfeited as zero', () async {
    final repository = MemoryGameRepository();
    final values = <int>[1, 2, 3, 4, 5, 6];
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await controller.rollDigital();
    await controller.forfeitDigitalTurn();

    expect(controller.state.turns.single.points, 0);
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.canUndo, isTrue);
  });

  test(
    'starting a digital turn clears undo for an older ledger turn',
    () async {
      final controller = TenThousandController.newGame(
        names: ['A', 'B'],
        mode: GameMode.digital,
        repository: MemoryGameRepository(),
        roller: () => 1,
      );
      await controller.enterTurn(350);
      expect(controller.canUndo, isTrue);

      await controller.rollDigital();

      expect(controller.canUndo, isFalse);
    },
  );

  test('newGame trims names and turn entry persists with undo', () async {
    final repository = MemoryGameRepository();
    final controller = TenThousandController.newGame(
      names: [' A ', 'B'],
      repository: repository,
    );
    await controller.enterTurn(500);
    expect(controller.state.totals, [500, 0]);
    expect(controller.canUndo, isTrue);
    expect(((await repository.load()).state as TenThousandGameState).totals, [
      500,
      0,
    ]);

    await controller.undo();
    expect(controller.state.turns, isEmpty);
    expect(
      ((await repository.load()).state as TenThousandGameState).turns,
      isEmpty,
    );
    expect(controller.canUndo, isFalse);
  });

  test('edit and ordinary delete replay; deletion tombstones', () async {
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: MemoryGameRepository(),
    );
    await controller.enterTurn(500);
    await controller.enterTurn(350);
    await controller.editTurn(0, 750);
    expect(controller.state.totals, [750, 350]);
    await controller.deleteTurn(1);
    expect(controller.state.turns[1].isDeleted, isTrue);
    expect(controller.state.totals, [750, 0]);
  });

  test(
    'correction requires confirmation, truncates atomically, and undo restores suffix',
    () async {
      final repository = MemoryGameRepository();
      final controller = TenThousandController(
        state: TenThousandGameState(
          players: [TenThousandPlayer('A'), TenThousandPlayer('B')],
          turns: [
            TenThousandTurn(0, 9950),
            TenThousandTurn(1, 50),
            TenThousandTurn(2, 50),
            TenThousandTurn(3, 50),
          ],
        ),
        repository: repository,
      );

      await expectLater(
        controller.editTurn(0, 10000),
        throwsA(
          isA<TenThousandCorrectionImpact>()
              .having((impact) => impact.illegalTrailingTurnCount, 'count', 2)
              .having((impact) => impact.firstIllegalOrdinal, 'first', 2),
        ),
      );
      expect(controller.state.turns, hasLength(4));
      expect(controller.canUndo, isFalse);

      await controller.editTurn(0, 10000, confirmTruncation: true);
      expect(controller.state.turns, hasLength(2));
      expect(controller.state.isComplete, isTrue);
      await controller.undo();
      expect(controller.state.turns, hasLength(4));
      expect(controller.state.turns.first.points, 9950);
      expect(
        ((await repository.load()).state as TenThousandGameState).turns,
        hasLength(4),
      );
    },
  );

  test('deleting a trigger reopens game and preserves chronology', () async {
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: MemoryGameRepository(),
    );
    await controller.enterTurn(10000);
    await controller.enterTurn(0);
    expect(controller.state.isComplete, isTrue);
    await controller.deleteTurn(0);
    expect(controller.state.isComplete, isFalse);
    expect(controller.state.turns, hasLength(2));
    expect(controller.state.activePlayerIndex, 0);
  });

  test('cannot enter a turn after completion', () async {
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: MemoryGameRepository(),
    );
    await controller.enterTurn(10000);
    await controller.enterTurn(0);
    await expectLater(controller.enterTurn(350), throwsStateError);
  });

  test('save failure restores state and prior undo snapshot', () async {
    final repository = _ControlledRepository();
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.enterTurn(350);
    repository.failSave = true;
    await expectLater(controller.enterTurn(400), throwsStateError);
    expect(controller.state.turns.map((turn) => turn.points), [350]);
    expect(controller.canUndo, isTrue);

    repository.failSave = false;
    await controller.undo();
    expect(controller.state.turns, isEmpty);
  });

  test('failed undo restores current state and keeps undo available', () async {
    final repository = _ControlledRepository();
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.enterTurn(350);
    repository.failSave = true;
    await expectLater(controller.undo(), throwsStateError);
    expect(controller.state.turns, hasLength(1));
    expect(controller.canUndo, isTrue);
  });

  test('busy controller ignores duplicate mutation and undo', () async {
    final repository = _ControlledRepository();
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    repository.saveGate = Completer<void>();
    final first = controller.enterTurn(350);
    expect(controller.isBusy, isTrue);
    await controller.enterTurn(400);
    await controller.undo();
    expect(repository.saveCalls, 1);
    repository.saveGate!.complete();
    await first;
    expect(controller.state.turns.map((turn) => turn.points), [350]);
  });

  test('winners and abandon delegate to replay/repository', () async {
    final repository = MemoryGameRepository();
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.enterTurn(10000);
    await controller.enterTurn(10000);
    expect(controller.winners.map((player) => player.name), ['A', 'B']);
    await controller.abandon();
    expect((await repository.load()).state, isNull);
  });
}

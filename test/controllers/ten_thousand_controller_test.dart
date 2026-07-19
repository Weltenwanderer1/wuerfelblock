import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/ten_thousand_controller.dart';
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
  test('newGame trims names and turn entry persists with undo', () async {
    final repository = MemoryGameRepository();
    final controller = TenThousandController.newGame(
      names: [' A ', 'B'],
      repository: repository,
    );
    await controller.enterTurn(500);
    expect(controller.state.totals, [500, 0]);
    expect(controller.canUndo, isTrue);
    expect((await repository.load() as TenThousandGameState).totals, [500, 0]);

    await controller.undo();
    expect(controller.state.turns, isEmpty);
    expect((await repository.load() as TenThousandGameState).turns, isEmpty);
    expect(controller.canUndo, isFalse);
  });

  test('edit and ordinary delete replay; deletion tombstones', () async {
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: MemoryGameRepository(),
    );
    await controller.enterTurn(500);
    await controller.enterTurn(250);
    await controller.editTurn(0, 750);
    expect(controller.state.totals, [750, 250]);
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
        (await repository.load() as TenThousandGameState).turns,
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
    await expectLater(controller.enterTurn(50), throwsStateError);
  });

  test('save failure restores state and prior undo snapshot', () async {
    final repository = _ControlledRepository();
    final controller = TenThousandController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.enterTurn(50);
    repository.failSave = true;
    await expectLater(controller.enterTurn(100), throwsStateError);
    expect(controller.state.turns.map((turn) => turn.points), [50]);
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
    await controller.enterTurn(50);
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
    final first = controller.enterTurn(50);
    expect(controller.isBusy, isTrue);
    await controller.enterTurn(100);
    await controller.undo();
    expect(repository.saveCalls, 1);
    repository.saveGate!.complete();
    await first;
    expect(controller.state.turns.map((turn) => turn.points), [50]);
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
    expect(await repository.load(), isNull);
  });
}

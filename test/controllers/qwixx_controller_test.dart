import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/qwixx_controller.dart';
import 'package:wuerfelblock/models/qwixx_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _FailingRepository extends MemoryGameRepository {
  bool failSave = false;

  @override
  Future<void> save(SavedGameState state) {
    if (failSave) return Future.error(StateError('save failed'));
    return super.save(state);
  }
}

void main() {
  test('mark persists, can be undone, and undo persists', () async {
    final repository = MemoryGameRepository();
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );

    await controller.mark(QwixxColor.red, 5, playerIndex: 1);
    expect(controller.state.players[1].crossed[QwixxColor.red], {5});
    expect(
      (await repository.load() as QwixxGameState).players[1].crossed[QwixxColor
          .red],
      {5},
    );
    expect(controller.canUndo, isTrue);

    await controller.undo();
    expect(controller.state.players[1].crossed[QwixxColor.red], isEmpty);
    expect(
      (await repository.load() as QwixxGameState).players[1].crossed[QwixxColor
          .red],
      isEmpty,
    );
  });

  test(
    'miss always applies to active player and next player is explicit',
    () async {
      final controller = QwixxController.newGame(
        names: ['Ada', 'Bea'],
        repository: MemoryGameRepository(),
      );

      await controller.markMiss();
      expect(controller.state.players[0].misses, 1);
      expect(controller.state.activePlayerIndex, 0);
      await controller.nextPlayer();
      expect(controller.state.activePlayerIndex, 1);
      await controller.markMiss();
      expect(controller.state.players[1].misses, 1);
    },
  );

  test('save failure rolls mark back including row closure', () async {
    final repository = _FailingRepository();
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    for (final value in [2, 3, 4, 5, 6]) {
      await controller.mark(QwixxColor.red, value);
    }
    repository.failSave = true;

    await expectLater(controller.mark(QwixxColor.red, 12), throwsStateError);
    expect(controller.state.closedColors, isEmpty);
    expect(controller.state.players.first.lockedColors, isEmpty);
    expect(
      controller.state.players.first.crossed[QwixxColor.red],
      isNot(contains(12)),
    );
  });

  test('next player persists finalization of pending row closures', () async {
    final repository = MemoryGameRepository();
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    for (final value in QwixxColor.red.numbers.take(5)) {
      await controller.mark(QwixxColor.red, value);
    }
    await controller.mark(QwixxColor.red, 12);

    expect(controller.state.pendingClosedColors, {QwixxColor.red});
    await controller.nextPlayer();

    expect(controller.state.closedColors, {QwixxColor.red});
    expect(controller.state.pendingClosedColors, isEmpty);
    final saved = await repository.load() as QwixxGameState;
    expect(saved.closedColors, {QwixxColor.red});
    expect(saved.pendingClosedColors, isEmpty);
  });

  test('four misses and winner/tie calculation', () async {
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: MemoryGameRepository(),
    );
    for (var i = 0; i < 4; i++) {
      await controller.markMiss();
    }
    expect(controller.state.isComplete, isTrue);
    expect(controller.winners.map((player) => player.name), ['Bea']);
  });

  test('abandon clears persisted game', () async {
    final repository = MemoryGameRepository();
    final controller = QwixxController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    await repository.save(controller.state);
    await controller.abandon();
    expect(await repository.load(), isNull);
  });
}

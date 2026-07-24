import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/colordice_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
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
  test('digital roll, mark and finish persist atomically', () async {
    final repository = MemoryGameRepository();
    final values = <int>[2, 5, 3, 4, 6, 1];
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await controller.rollDigital();
    expect(controller.state.dice, [2, 5, 3, 4, 6, 1]);
    await controller.markDigital(
      ColordiceColor.red,
      8,
      ColordiceDigitalAction.color,
      playerIndex: 0,
    );
    await controller.finishDigitalTurn();

    expect(controller.state.activePlayerIndex, 1);
    expect(controller.state.players[0].misses, 0);
    final saved = (await repository.load()).state as ColordiceGameState;
    expect(saved.players[0].crossed[ColordiceColor.red], {8});
    expect(saved.hasRolled, isFalse);
  });

  test('failed digital roll keeps dice and requires save retry', () async {
    final repository = _FailingRepository()..failSave = true;
    final values = <int>[2, 5, 3, 4, 6, 1];
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await expectLater(controller.rollDigital(), throwsA(isA<StateError>()));
    expect(controller.state.dice, [2, 5, 3, 4, 6, 1]);
    expect(controller.state.hasRolled, isTrue);
    expect(controller.needsDigitalSaveRetry, isTrue);
    expect(controller.finishDigitalTurn, throwsStateError);

    repository.failSave = false;
    await controller.retryDigitalSave();
    expect(controller.needsDigitalSaveRetry, isFalse);
    final saved = (await repository.load()).state as ColordiceGameState;
    expect(saved.dice, [2, 5, 3, 4, 6, 1]);
  });

  test('mark persists, can be undone, and undo persists', () async {
    final repository = MemoryGameRepository();
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );

    await controller.mark(ColordiceColor.red, 5, playerIndex: 1);
    expect(controller.state.players[1].crossed[ColordiceColor.red], {5});
    expect(
      ((await repository.load()).state as ColordiceGameState)
          .players[1]
          .crossed[ColordiceColor.red],
      {5},
    );
    expect(controller.canUndo, isTrue);

    await controller.undo();
    expect(controller.state.players[1].crossed[ColordiceColor.red], isEmpty);
    expect(
      ((await repository.load()).state as ColordiceGameState)
          .players[1]
          .crossed[ColordiceColor.red],
      isEmpty,
    );
  });

  test(
    'miss always applies to active player and next player is explicit',
    () async {
      final controller = ColordiceController.newGame(
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
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    for (final value in [2, 3, 4, 5, 6]) {
      await controller.mark(ColordiceColor.red, value);
    }
    repository.failSave = true;

    await expectLater(
      controller.mark(ColordiceColor.red, 12),
      throwsStateError,
    );
    expect(controller.state.closedColors, isEmpty);
    expect(controller.state.players.first.lockedColors, isEmpty);
    expect(
      controller.state.players.first.crossed[ColordiceColor.red],
      isNot(contains(12)),
    );
  });

  test('next player persists finalization of pending row closures', () async {
    final repository = MemoryGameRepository();
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    for (final value in ColordiceColor.red.numbers.take(5)) {
      await controller.mark(ColordiceColor.red, value);
    }
    await controller.mark(ColordiceColor.red, 12);

    expect(controller.state.pendingClosedColors, {ColordiceColor.red});
    await controller.nextPlayer();

    expect(controller.state.closedColors, {ColordiceColor.red});
    expect(controller.state.pendingClosedColors, isEmpty);
    final saved = (await repository.load()).state as ColordiceGameState;
    expect(saved.closedColors, {ColordiceColor.red});
    expect(saved.pendingClosedColors, isEmpty);
  });

  test('four misses and winner/tie calculation', () async {
    final controller = ColordiceController.newGame(
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
    final controller = ColordiceController.newGame(
      names: ['Ada', 'Bea'],
      repository: repository,
    );
    await repository.save(controller.state);
    await controller.abandon();
    expect((await repository.load()).state, isNull);
  });
}

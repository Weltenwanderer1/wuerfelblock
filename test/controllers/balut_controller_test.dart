import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/balut_controller.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
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
  test('block score persists, advances player, and can be undone', () async {
    final repository = MemoryGameRepository();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );

    await controller.scoreBlock(BalutCategory.fours, 0, 12);
    expect(controller.state.players[0].entries[BalutCategory.fours], [
      12,
      null,
      null,
      null,
    ]);
    expect(controller.state.activePlayerIndex, 1);
    expect(
      (await repository.load() as BalutGameState).toJson(),
      controller.state.toJson(),
    );
    expect(controller.canUndo, isTrue);

    await controller.undo();
    expect(
      controller.state.players[0].entries[BalutCategory.fours],
      everyElement(isNull),
    );
    expect(controller.state.activePlayerIndex, 0);
    expect(
      (await repository.load() as BalutGameState).toJson(),
      controller.state.toJson(),
    );
    expect(controller.canUndo, isFalse);
  });

  test('block score can target a selected player sheet', () async {
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: MemoryGameRepository(),
    );
    await controller.scoreBlock(BalutCategory.choice, 2, 0, playerIndex: 1);
    expect(controller.state.players[1].entries[BalutCategory.choice], [
      null,
      null,
      0,
      null,
    ]);
    expect(controller.state.activePlayerIndex, 0);
  });

  test('digital roll holds dice, rerolls only free dice, and scores', () async {
    final values = <int>[1, 2, 3, 4, 5, 6, 6, 6];
    final repository = MemoryGameRepository();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      mode: GameMode.digital,
      repository: repository,
      roller: () => values.removeAt(0),
    );

    await controller.rollDigital();
    await controller.toggleHold(1);
    await controller.toggleHold(3);
    await controller.rollDigital();
    expect(controller.state.dice, [6, 2, 6, 4, 6]);
    expect(controller.state.rollCount, 2);

    await controller.scoreDigital(BalutCategory.sixes);
    expect(controller.state.players[0].entries[BalutCategory.sixes]!.first, 18);
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.state.rollCount, 0);
    expect(controller.state.held, everyElement(isFalse));
    expect(
      (await repository.load() as BalutGameState).toJson(),
      controller.state.toJson(),
    );
  });

  test('digital controller enforces the maximum of three rolls', () async {
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      mode: GameMode.digital,
      repository: MemoryGameRepository(),
      roller: () => 1,
    );
    await controller.rollDigital();
    await controller.rollDigital();
    await controller.rollDigital();
    await expectLater(controller.rollDigital(), throwsStateError);
    expect(controller.needsDigitalSaveRetry, isFalse);
  });

  test('failed score save rolls state back and preserves prior undo', () async {
    final repository = _ControlledRepository();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.scoreBlock(BalutCategory.fours, 0, 4);
    repository.failSave = true;

    await expectLater(
      controller.scoreBlock(BalutCategory.fives, 0, 5),
      throwsStateError,
    );
    expect(
      controller.state.players[1].entries[BalutCategory.fives],
      everyElement(isNull),
    );
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.canUndo, isTrue);

    repository.failSave = false;
    await controller.undo();
    expect(
      controller.state.players[0].entries[BalutCategory.fours],
      everyElement(isNull),
    );
  });

  test(
    'failed digital persistence keeps physical dice and requires retry',
    () async {
      final repository = _ControlledRepository()..failSave = true;
      final values = <int>[1, 2, 3, 4, 5];
      final controller = BalutController.newGame(
        names: ['A', 'B'],
        mode: GameMode.digital,
        repository: repository,
        roller: () => values.removeAt(0),
      );

      await expectLater(controller.rollDigital(), throwsStateError);
      expect(controller.state.dice, [1, 2, 3, 4, 5]);
      expect(controller.state.rollCount, 1);
      expect(controller.needsDigitalSaveRetry, isTrue);
      expect(() => controller.toggleHold(0), throwsStateError);
      expect(
        () => controller.scoreDigital(BalutCategory.straights),
        throwsStateError,
      );

      repository.failSave = false;
      await controller.retryDigitalSave();
      expect(controller.needsDigitalSaveRetry, isFalse);
      expect((await repository.load() as BalutGameState).dice, [1, 2, 3, 4, 5]);
    },
  );

  test('failed undo restores current state and keeps undo available', () async {
    final repository = _ControlledRepository();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await controller.scoreBlock(BalutCategory.fours, 0, 4);
    repository.failSave = true;

    await expectLater(controller.undo(), throwsStateError);
    expect(controller.state.players[0].entries[BalutCategory.fours]!.first, 4);
    expect(controller.canUndo, isTrue);
  });

  test('busy guard ignores duplicate mutation and undo', () async {
    final repository = _ControlledRepository()..saveGate = Completer<void>();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );

    final first = controller.scoreBlock(BalutCategory.fours, 0, 4);
    expect(controller.isBusy, isTrue);
    await controller.scoreBlock(BalutCategory.fours, 1, 4);
    await controller.undo();
    expect(repository.saveCalls, 1);
    repository.saveGate!.complete();
    await first;
    expect(controller.state.filledEntryCount, 1);
  });

  test('abandon clears persistence and always releases busy guard', () async {
    final repository = _ControlledRepository();
    final controller = BalutController.newGame(
      names: ['A', 'B'],
      repository: repository,
    );
    await repository.save(controller.state);
    await controller.abandon();
    expect(await repository.load(), isNull);
    expect(controller.isBusy, isFalse);

    await repository.save(controller.state);
    repository.failClear = true;
    await expectLater(controller.abandon(), throwsStateError);
    expect(controller.isBusy, isFalse);
  });
}

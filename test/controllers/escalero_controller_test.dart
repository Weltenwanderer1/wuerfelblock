import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/escalero_controller.dart';
import 'package:wuerfelblock/models/escalero_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class TestRepository implements GameRepository {
  SavedGameState? saved;
  int saves = 0;
  int clears = 0;
  bool failNextSave = false;

  @override
  Future<void> save(SavedGameState state) async {
    saves++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    saved = state;
  }

  @override
  Future<LoadResult> load() async => LoadResult(state: saved);

  @override
  Future<void> clear() async {
    clears++;
    saved = null;
  }
}

void main() {
  test('block scoring persists, rotates, and can be undone', () async {
    final repository = TestRepository();
    final controller = EscaleroController.newGame(
      names: ['Ada', 'Bob'],
      repository: repository,
    );
    await controller.scoreBlock(EscaleroCategory.nine, 0, 3);
    expect(controller.state.players[0].entries[EscaleroCategory.nine]![0], 3);
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.canUndo, isTrue);
    final savedScore = repository.saved! as EscaleroGameState;
    expect(savedScore.players[0].entries[EscaleroCategory.nine]![0], 3);
    expect(savedScore.activePlayerIndex, 1);
    await controller.undo();
    expect(
      controller.state.players[0].entries[EscaleroCategory.nine]![0],
      isNull,
    );
    expect(controller.state.activePlayerIndex, 0);
    final savedUndo = repository.saved! as EscaleroGameState;
    expect(savedUndo.players[0].entries[EscaleroCategory.nine]![0], isNull);
    expect(savedUndo.activePlayerIndex, 0);
  });

  test('normal save failure rolls scoring back', () async {
    final repository = TestRepository()..failNextSave = true;
    final controller = EscaleroController.newGame(
      names: ['Ada', 'Bob'],
      repository: repository,
    );
    await expectLater(
      controller.scoreBlock(EscaleroCategory.nine, 0, 2),
      throwsStateError,
    );
    expect(controller.state.filledEntryCount, 0);
  });

  test(
    'editing and deleting occupied scores persists without rotating',
    () async {
      final repository = TestRepository();
      final controller = EscaleroController.newGame(
        names: ['Ada', 'Bob'],
        repository: repository,
      );
      await controller.scoreBlock(EscaleroCategory.nine, 0, 2);
      expect(controller.state.activePlayerIndex, 1);

      await controller.editScore(0, EscaleroCategory.nine, 0, 4);
      expect(controller.state.players[0].entries[EscaleroCategory.nine]![0], 4);
      expect(controller.state.activePlayerIndex, 1);
      expect(
        (repository.saved! as EscaleroGameState)
            .players[0]
            .entries[EscaleroCategory.nine]![0],
        4,
      );

      await controller.editScore(0, EscaleroCategory.nine, 0, null);
      expect(
        controller.state.players[0].entries[EscaleroCategory.nine]![0],
        isNull,
      );
      expect(controller.state.activePlayerIndex, 1);
      await controller.undo();
      expect(controller.state.players[0].entries[EscaleroCategory.nine]![0], 4);
      expect(controller.state.activePlayerIndex, 1);
    },
  );

  test('failed correction rolls back value, player and digital roll', () async {
    final repository = TestRepository();
    var state = EscaleroGameState.newGame([
      'Ada',
      'Bob',
    ], mode: GameMode.digital);
    state = state.withDigitalRoll([1, 2, 3, 4, 5]);
    state = state.withDigitalScore(EscaleroCategory.straight, 0);
    state = state.withDigitalRoll([6, 6, 6, 6, 6]);
    final controller = EscaleroController(
      state: state,
      repository: repository..failNextSave = true,
    );
    final turnBefore = controller.digitalTurn.toJson();

    await expectLater(
      controller.editScore(0, EscaleroCategory.straight, 0, 20),
      throwsStateError,
    );
    expect(
      controller.state.players[0].entries[EscaleroCategory.straight]![0],
      25,
    );
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.digitalTurn.toJson(), turnBefore);
  });

  test('digital roll, hold, reroll and score rotate player', () async {
    final values = <int>[1, 2, 3, 4, 5, 6, 6, 6, 6];
    final controller = EscaleroController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: TestRepository(),
      roller: () => values.removeAt(0),
    );
    await controller.rollDigital();
    await controller.toggleHold(0);
    await controller.rollDigital();
    expect(controller.digitalTurn.dice, [1, 6, 6, 6, 6]);
    await controller.scoreDigital(EscaleroCategory.poker, 1);
    expect(controller.state.players[0].entries[EscaleroCategory.poker]![1], 40);
    expect(controller.state.activePlayerIndex, 1);
    expect(controller.digitalTurn.rollCount, 0);
  });

  test('all held dice cannot consume an empty reroll', () async {
    final values = <int>[1, 2, 3, 4, 5];
    final controller = EscaleroController.newGame(
      names: ['Ada', 'Bob'],
      mode: GameMode.digital,
      repository: TestRepository(),
      roller: () => values.removeAt(0),
    );
    await controller.rollDigital();
    for (var index = 0; index < 5; index++) {
      await controller.toggleHold(index);
    }

    await expectLater(controller.rollDigital(), throwsStateError);
    expect(controller.digitalTurn.rollCount, 1);
    expect(controller.digitalTurn.lastRollWasAllFive, isTrue);
  });

  test(
    'failed digital roll remains visible and exact save can be retried',
    () async {
      final repository = TestRepository()..failNextSave = true;
      var calls = 0;
      final controller = EscaleroController.newGame(
        names: ['Ada', 'Bob'],
        mode: GameMode.digital,
        repository: repository,
        roller: () => ++calls,
      );
      await expectLater(controller.rollDigital(), throwsStateError);
      expect(controller.digitalTurn.dice, [1, 2, 3, 4, 5]);
      expect(controller.needsDigitalSaveRetry, isTrue);
      await expectLater(controller.rollDigital(), throwsStateError);
      expect(calls, 5);
      await controller.retryDigitalSave();
      expect(controller.needsDigitalSaveRetry, isFalse);
      expect(controller.digitalTurn.dice, [1, 2, 3, 4, 5]);
      expect(calls, 5);
    },
  );

  test('abandon clears repository', () async {
    final repository = TestRepository();
    final controller = EscaleroController.newGame(
      names: ['Ada', 'Bob'],
      repository: repository,
    );
    await controller.abandon();
    expect(repository.clears, 1);
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/backgammon_controller.dart';
import 'package:wuerfelblock/models/backgammon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class Repository implements GameRepository {
  bool fail = false;
  Completer<void>? gate;
  BackgammonGameState? saved;
  int saves = 0;
  @override
  Future<void> save(SavedGameState state) async {
    saves++;
    if (gate != null) await gate!.future;
    if (fail) throw StateError('disk failed');
    saved = BackgammonGameState.fromJson(state.toJson());
  }

  @override
  Future<LoadResult> load() async => LoadResult(state: saved);
  @override
  Future<void> clear() async {
    saved = null;
  }
}

void main() {
  test(
    'failed digital roll retained, blocked progress retry consumes no RNG',
    () async {
      final repo = Repository()..fail = true;
      var calls = 0;
      final c = BackgammonController.newGame(
        names: ['A', 'B'],
        repository: repo,
        mode: GameMode.digital,
        roller: () => ++calls == 1 ? 6 : 2,
      );
      await expectLater(c.rollDigital(), throwsStateError);
      final pending = c.state;
      expect(calls, 2);
      expect(c.needsSaveRetry, true);
      await expectLater(c.rollDigital(), throwsStateError);
      await expectLater(c.move(c.state.legalMoves.first), throwsStateError);
      await expectLater(c.undo(), throwsStateError);
      expect(calls, 2);
      expect(identical(c.state, pending), true);
      repo.fail = false;
      await c.retrySave();
      expect(c.needsSaveRetry, false);
      expect(repo.saved!.toJson(), pending.toJson());
      expect(calls, 2);
      c.dispose();
    },
  );
  test(
    'moves and undo failures retain exact pending state and history',
    () async {
      final repo = Repository();
      final c = BackgammonController.newGame(
        names: ['A', 'B'],
        repository: repo,
      );
      await c.enterRoll(6, 2);
      final rolled = c.state;
      repo.fail = true;
      await expectLater(c.move(c.state.legalMoves.first), throwsStateError);
      expect(c.state.undoHistory.length, 1);
      expect(c.canUndo, false);
      repo.fail = false;
      await c.save();
      expect(c.canUndo, true);
      final resumed = BackgammonController(
        state: repo.saved!,
        repository: repo,
      );
      repo.fail = true;
      await expectLater(resumed.undo(), throwsStateError);
      expect(resumed.state.toJson(), rolled.toJson());
      expect(resumed.needsSaveRetry, true);
      repo.fail = false;
      await resumed.retrySave();
      expect(repo.saved!.toJson(), rolled.toJson());
      c.dispose();
      resumed.dispose();
    },
  );
  test(
    'double taps ignored while saving; rejected actions are not pending saves',
    () async {
      final repo = Repository()..gate = Completer<void>();
      var calls = 0;
      final c = BackgammonController.newGame(
        names: ['A', 'B'],
        repository: repo,
        mode: GameMode.digital,
        roller: () => ++calls == 1 ? 6 : 2,
      );
      final first = c.rollDigital();
      expect(c.isBusy, true);
      await c.rollDigital();
      expect(calls, 2);
      expect(repo.saves, 1);
      repo.gate!.complete();
      await first;
      await expectLater(c.enterRoll(1, 2), throwsStateError);
      await expectLater(c.endTurn(), throwsStateError);
      await expectLater(c.rollDigital(), throwsStateError);
      expect(c.needsSaveRetry, false);
      expect(calls, 2);
      c.dispose();
    },
  );
  test('opening ties saved; physical mode never invokes RNG', () async {
    final repo = Repository();
    final c = BackgammonController.newGame(
      names: ['A', 'B'],
      repository: repo,
      roller: () => throw StateError('unexpected RNG'),
    );
    await c.enterRoll(3, 3);
    expect(repo.saved!.opening, true);
    expect(c.canUndo, false);
    await c.enterRoll(1, 5);
    expect(c.state.activePlayerIndex, 1);
    expect(c.state.remaining, [1, 5]);
    await expectLater(c.rollDigital(), throwsStateError);
    await c.move(c.state.legalMoves.first);
    expect(c.canUndo, true);
    await c.undo();
    expect(c.state.remaining, [1, 5]);
    c.dispose();
  });
}

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/backgammon_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import 'controller_transactions.dart';

class BackgammonController extends ChangeNotifier {
  BackgammonController({
    required BackgammonGameState state,
    required this.repository,
    int Function()? roller,
  }) : _state = state,
       _roller = roller ?? _secureRoller() {
    _tx = ControllerTransactions<BackgammonGameState, BackgammonGameState>(
      capture: () => _state,
      restore: (s) => _state = s,
      save: () => repository.save(_state),
      clear: repository.clear,
      notifyListeners: notifyListeners,
    );
  }
  factory BackgammonController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => BackgammonController(
    state: BackgammonGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );
  static int Function() _secureRoller() {
    final random = Random.secure();
    return () => random.nextInt(6) + 1;
  }

  BackgammonGameState _state;
  BackgammonGameState get state => _state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<BackgammonGameState, BackgammonGameState>
  _tx;
  bool get isBusy => _tx.isBusy;
  bool get needsSaveRetry => _tx.needsDigitalSaveRetry;
  bool get canUndo => !isBusy && !needsSaveRetry && state.canUndo;

  // Validate transitions before entering mutateTransient: its failure path is
  // intentionally for persistence failures, not rejected domain operations.
  Future<void> _change(BackgammonGameState Function() change) async {
    if (isBusy) return;
    _tx.ensureDigitalSaveReady();
    final next = change();
    await _tx.mutateTransient(change: () => _state = next);
  }

  Future<void> rollDigital() => _change(() {
    if (state.mode != GameMode.digital || !state.canRoll) {
      throw StateError('Cannot roll digitally now.');
    }
    return state.roll(_roller(), _roller());
  });
  Future<void> enterRoll(int first, int second) => _change(() {
    if (state.mode != GameMode.block) {
      throw StateError('Physical dice mode required.');
    }
    return state.roll(first, second);
  });
  Future<void> move(BackgammonMove move) => _change(() => state.move(move));
  Future<void> endTurn() => _change(() => state.endTurn());
  Future<void> undo() => _change(() => state.undo());
  Future<void> retrySave() => _tx.retryDigitalSave();
  Future<void> save() async {
    if (needsSaveRetry) {
      await retrySave();
      return;
    }
    await _change(() => state);
  }
}

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/balut_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';
import 'controller_transactions.dart';

class BalutController extends ChangeNotifier {
  BalutController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? (() => Random().nextInt(6) + 1) {
    _transactions = ControllerTransactions<BalutGameState, BalutGameState>(
      capture: () => state.copy(),
      restore: (snapshot) => state = snapshot.copy(),
      save: () => repository.save(state),
      clear: repository.clear,
      notifyListeners: notifyListeners,
    );
  }

  factory BalutController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => BalutController(
    state: BalutGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );

  BalutGameState state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<BalutGameState, BalutGameState>
  _transactions;

  bool get canUndo => _transactions.canUndo;
  bool get isBusy => _transactions.isBusy;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;
  List<BalutPlayer> get winners => state.winners;

  Future<void> scoreBlock(
    BalutCategory category,
    int index,
    int score, {
    int? playerIndex,
  }) {
    if (_transactions.isBusy) return Future<void>.value();
    return _mutate(
      () => state.withBlockScore(
        category,
        index,
        score,
        playerIndex: playerIndex,
      ),
    );
  }

  Future<void> rollDigital() {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return Future<void>.value();
    final diceToRoll = state.rollCount == 0
        ? 5
        : state.held.where((isHeld) => !isHeld).length;
    return _mutateTransient(
      () => state.withDigitalRoll(
        List<int>.generate(diceToRoll, (_) => _roller()),
      ),
    );
  }

  Future<void> toggleHold(int index) {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return Future<void>.value();
    return _mutateTransient(() => state.withToggledHold(index));
  }

  Future<void> scoreDigital(BalutCategory category) {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return Future<void>.value();
    return _mutate(() => state.withDigitalScore(category));
  }

  Future<void> _mutate(BalutGameState Function() mutation) =>
      _transactions.mutate(
        change: () => state = mutation(),
        undoFromSnapshot: (snapshot) => snapshot,
      );

  Future<void> _mutateTransient(BalutGameState Function() mutation) async {
    if (_transactions.isBusy) return;
    _ensureDigitalSaveReady();
    final changed = mutation();
    await _transactions.mutateTransient(
      change: () => state = changed,
      clearUndoAfterSave: true,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();

  void _ensureDigitalSaveReady() {
    _transactions.ensureDigitalSaveReady(
      PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> undo() =>
      _transactions.undo(restoreUndo: (previous) => state = previous.copy());

  Future<void> abandon() => _transactions.abandon();
}

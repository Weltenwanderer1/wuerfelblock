import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/escalero_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';
import 'controller_transactions.dart';

class EscaleroController extends ChangeNotifier {
  EscaleroController({
    required EscaleroGameState state,
    required this.repository,
    int Function()? roller,
  }) : _state = state,
       _roller = roller ?? (() => Random().nextInt(6) + 1) {
    _transactions =
        ControllerTransactions<EscaleroGameState, EscaleroGameState>(
          capture: () => state.copy(),
          restore: (snapshot) => _state = snapshot.copy(),
          save: () => repository.save(state),
          clear: repository.clear,
          notifyListeners: notifyListeners,
        );
  }

  factory EscaleroController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => EscaleroController(
    state: EscaleroGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );

  EscaleroGameState _state;
  EscaleroGameState get state => _state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<EscaleroGameState, EscaleroGameState>
  _transactions;

  GameMode get mode => state.mode;
  List<EscaleroPlayer> get players => state.players;
  List<EscaleroCategory> get categories => state.categories;
  List<int> get columns => state.columns;
  EscaleroDigitalTurn get digitalTurn => state.digitalTurn;
  List<EscaleroPlayer> get winners => state.winners;
  bool get canUndo => _transactions.canUndo;
  bool get isBusy => _transactions.isBusy;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;

  Future<void> scoreBlock(
    EscaleroCategory category,
    int column,
    int score,
  ) async {
    if (_transactions.isBusy) return;
    await _transactions.mutate(
      change: () => _state = state.withBlockScore(category, column, score),
      undoFromSnapshot: (snapshot) => snapshot,
    );
  }

  Future<void> rollDigital() async {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return;
    final count = state.digitalTurn.rollCount == 0
        ? 5
        : state.digitalTurn.held.where((held) => !held).length;
    final changed = state.withDigitalRoll(
      List<int>.generate(count, (_) => _roller()),
    );
    await _transactions.mutateTransient(
      change: () => _state = changed,
      clearUndoAfterSave: true,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> toggleHold(int index) async {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return;
    final changed = state.withToggledHold(index);
    await _transactions.mutateTransient(
      change: () => _state = changed,
      clearUndoAfterSave: true,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> scoreDigital(EscaleroCategory category, int column) async {
    _ensureDigitalSaveReady();
    if (_transactions.isBusy) return;
    await _transactions.mutate(
      change: () => _state = state.withDigitalScore(category, column),
      undoFromSnapshot: (snapshot) => snapshot,
    );
  }

  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();

  void _ensureDigitalSaveReady() {
    _transactions.ensureDigitalSaveReady(
      PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> undo() =>
      _transactions.undo(restoreUndo: (previous) => _state = previous.copy());
  Future<void> abandon() => _transactions.abandon();
}

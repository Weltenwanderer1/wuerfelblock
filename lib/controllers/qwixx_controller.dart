import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/qwixx_models.dart';
import '../models/game_models.dart';
import 'controller_transactions.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';

class QwixxController extends ChangeNotifier {
  QwixxController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? _secureRoller() {
    _transactions = ControllerTransactions<QwixxGameState, QwixxGameState>(
      capture: () => _copy(state),
      restore: (snapshot) => state = _copy(snapshot),
      save: () => repository.save(state),
      clear: repository.clear,
      notifyListeners: notifyListeners,
    );
  }

  static int Function() _secureRoller() {
    final random = Random.secure();
    return () =>
        random.nextInt(
          QwixxRules.maximumDieValue - QwixxRules.minimumDieValue + 1,
        ) +
        QwixxRules.minimumDieValue;
  }

  factory QwixxController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => QwixxController(
    state: QwixxGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );

  QwixxGameState state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<QwixxGameState, QwixxGameState>
  _transactions;

  bool get canUndo => _transactions.canUndo;
  bool get isBusy => _transactions.isBusy;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;

  List<QwixxPlayer> get winners {
    final best = state.players
        .map(state.totalFor)
        .reduce((a, b) => a > b ? a : b);
    return state.players
        .where((player) => state.totalFor(player) == best)
        .toList();
  }

  Future<void> mark(QwixxColor color, int value, {int? playerIndex}) => _mutate(
    () => state.mark(playerIndex ?? state.activePlayerIndex, color, value),
  );

  Future<void> markMiss() =>
      _mutate(() => state.markMiss(state.activePlayerIndex));

  Future<void> nextPlayer() => _mutate(state.nextPlayer);

  Future<void> rollDigital() => _mutateDigitalRoll(
    () => state.rollDigital(
      List.generate(QwixxRules.diceCount, (_) => _roller()),
    ),
  );

  Future<void> markDigital(
    QwixxColor color,
    int value,
    QwixxDigitalAction action, {
    int? playerIndex,
  }) => _mutate(
    () => state.markDigital(
      playerIndex ?? state.activePlayerIndex,
      color,
      value,
      action,
    ),
  );

  Future<void> finishDigitalTurn() => _mutate(state.finishDigitalTurn);

  Future<void> _mutate(void Function() mutation) => _transactions.mutate(
    change: mutation,
    undoFromSnapshot: (snapshot) => snapshot,
    pendingSaveMessage: PersistenceMessages.pendingQwixxRollSave,
  );

  Future<void> _mutateDigitalRoll(void Function() mutation) =>
      _transactions.mutateTransient(
        change: mutation,
        undoFromSnapshot: (snapshot) => snapshot,
        pendingSaveMessage: PersistenceMessages.pendingQwixxRollSave,
      );

  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();

  Future<void> undo() =>
      _transactions.undo(restoreUndo: (previous) => state = _copy(previous));

  Future<void> abandon() => _transactions.abandon();

  QwixxGameState _copy(QwixxGameState value) =>
      QwixxGameState.fromJson(value.toJson());
}

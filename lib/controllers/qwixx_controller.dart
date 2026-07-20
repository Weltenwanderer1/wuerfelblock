import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/qwixx_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';

class QwixxController extends ChangeNotifier {
  QwixxController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? _secureRoller();

  static int Function() _secureRoller() {
    final random = Random.secure();
    return () => random.nextInt(6) + 1;
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
  QwixxGameState? _undoState;
  QwixxGameState? _pendingDigitalUndoState;
  bool _isBusy = false;
  bool _needsDigitalSaveRetry = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;
  bool get needsDigitalSaveRetry => _needsDigitalSaveRetry;

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
    () => state.rollDigital(List.generate(6, (_) => _roller())),
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

  Future<void> _mutate(void Function() mutation) async {
    if (_isBusy) return;
    if (_needsDigitalSaveRetry) {
      throw StateError('Der letzte Wurf muss zuerst gespeichert werden.');
    }
    final before = _copy(state);
    _isBusy = true;
    notifyListeners();
    try {
      mutation();
      notifyListeners();
      await repository.save(state);
      _undoState = before;
    } catch (_) {
      state = before;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _mutateDigitalRoll(void Function() mutation) async {
    if (_isBusy) return;
    if (_needsDigitalSaveRetry) {
      throw StateError('Der letzte Wurf muss zuerst gespeichert werden.');
    }
    final before = _copy(state);
    _isBusy = true;
    notifyListeners();
    try {
      mutation();
      notifyListeners();
      await repository.save(state);
      _undoState = before;
    } catch (_) {
      _pendingDigitalUndoState = before;
      _needsDigitalSaveRetry = true;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> retryDigitalSave() async {
    if (_isBusy || !_needsDigitalSaveRetry) return;
    _isBusy = true;
    notifyListeners();
    try {
      await repository.save(state);
      _undoState = _pendingDigitalUndoState;
      _pendingDigitalUndoState = null;
      _needsDigitalSaveRetry = false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> undo() async {
    if (_isBusy) return;
    final previous = _undoState;
    if (previous == null) return;
    final current = _copy(state);
    _isBusy = true;
    notifyListeners();
    try {
      state = _copy(previous);
      notifyListeners();
      await repository.save(state);
      _undoState = null;
    } catch (_) {
      state = current;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> abandon() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      await repository.clear();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  QwixxGameState _copy(QwixxGameState value) =>
      QwixxGameState.fromJson(value.toJson());
}

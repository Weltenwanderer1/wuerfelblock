import 'package:flutter/foundation.dart';

import '../models/qwixx_models.dart';
import '../services/game_repository.dart';

class QwixxController extends ChangeNotifier {
  QwixxController({required this.state, required this.repository});

  factory QwixxController.newGame({
    required List<String> names,
    required GameRepository repository,
  }) => QwixxController(
    state: QwixxGameState.newGame(names),
    repository: repository,
  );

  QwixxGameState state;
  final GameRepository repository;
  QwixxGameState? _undoState;
  bool _isBusy = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;

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

  Future<void> _mutate(void Function() mutation) async {
    if (_isBusy) return;
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

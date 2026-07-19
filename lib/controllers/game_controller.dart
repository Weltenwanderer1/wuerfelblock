import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/scoring_engine.dart';

class _ScoreUndo {
  const _ScoreUndo(this.playerIndex, this.category, this.currentPlayerIndex);
  final int playerIndex;
  final ScoreCategory category;
  final int currentPlayerIndex;
}

class GameController extends ChangeNotifier {
  GameController({required this.state, required this.repository});
  factory GameController.newGame({
    required RuleSet ruleSet,
    required GameMode mode,
    required List<String> names,
    required GameRepository repository,
  }) {
    if (names.isEmpty || names.length > 8) {
      throw ArgumentError('Es sind 1 bis 8 Spieler erlaubt.');
    }
    return GameController(
      state: GameState(
        ruleSet: ruleSet,
        mode: mode,
        players: names.map((name) => Player(name: name)).toList(),
      ),
      repository: repository,
    );
  }

  final GameState state;
  final GameRepository repository;
  _ScoreUndo? _undo;
  bool _isBusy = false;

  bool get canUndo => _undo != null;
  bool get isBusy => _isBusy;
  double get progress =>
      state.totalEntries == 0 ? 0 : state.completedEntries / state.totalEntries;

  List<Player> get winners {
    final best = state.players
        .map((player) => player.total)
        .reduce((a, b) => a > b ? a : b);
    return state.players.where((player) => player.total == best).toList();
  }

  Future<void> enterScore(
    ScoreCategory category,
    int value, {
    int? playerIndex,
  }) {
    if (_isBusy) return Future.value();
    final target = playerIndex ?? state.currentPlayerIndex;
    if (target < 0 || target >= state.players.length) {
      throw RangeError.index(target, state.players);
    }
    if (!state.ruleSet.categories.contains(category)) {
      throw ArgumentError('Kategorie gehört nicht zum Regelwerk.');
    }
    if (!ScoringEngine.allowedScores(state.ruleSet, category).contains(value)) {
      throw ArgumentError('Ungültige Punktzahl.');
    }
    if (state.players[target].scores.containsKey(category)) {
      throw StateError('Kategorie wurde bereits gewertet.');
    }
    return _transaction(() async {
      _undo = _ScoreUndo(target, category, state.currentPlayerIndex);
      state.players[target].scores[category] = value;
      resetTurn();
      state.isComplete = state.players.every(
        (player) => player.scores.length == state.ruleSet.categories.length,
      );
      if (!state.isComplete && state.mode == GameMode.digital) {
        state.currentPlayerIndex =
            (state.currentPlayerIndex + 1) % state.players.length;
      }
      notifyListeners();
      await repository.save(state);
    });
  }

  Future<void> undo() async {
    if (_isBusy) return;
    final undo = _undo;
    if (undo == null) return;
    await _transaction(() async {
      state.players[undo.playerIndex].scores.remove(undo.category);
      state.currentPlayerIndex = undo.currentPlayerIndex;
      state.isComplete = false;
      resetTurn();
      _undo = null;
      notifyListeners();
      await repository.save(state);
    });
  }

  Future<void> persistTurn() async {
    if (_isBusy) return;
    await _transaction(() => repository.save(state));
  }

  void resetTurn() {
    state.rollCount = 0;
    for (var index = 0; index < 5; index++) {
      state.dice[index] = 1;
      state.held[index] = false;
    }
  }

  Future<void> _transaction(Future<void> Function() operation) async {
    _isBusy = true;
    notifyListeners();
    try {
      await operation();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> abandon() async {
    if (_isBusy) return;
    await _transaction(repository.clear);
  }
}

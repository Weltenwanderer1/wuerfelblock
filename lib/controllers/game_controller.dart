import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/scoring_engine.dart';

class _ScoreUndo {
  const _ScoreUndo(
    this.playerIndex,
    this.category,
    this.currentPlayerIndex,
    this.previousExtraKniffel,
    this.previousScore,
  );
  final int playerIndex;
  final ScoreCategory category;
  final int currentPlayerIndex;
  final int previousExtraKniffel;
  final int? previousScore;
}

class _StateSnapshot {
  _StateSnapshot(GameState state, this.undo)
    : scores = [for (final player in state.players) Map.of(player.scores)],
      extraKniffels = [for (final player in state.players) player.extraKniffel],
      currentPlayerIndex = state.currentPlayerIndex,
      isComplete = state.isComplete,
      dice = List.of(state.dice),
      held = List.of(state.held),
      rollCount = state.rollCount;

  final List<Map<ScoreCategory, int>> scores;
  final List<int> extraKniffels;
  final int currentPlayerIndex;
  final bool isComplete;
  final List<int> dice;
  final List<bool> held;
  final int rollCount;
  final _ScoreUndo? undo;

  void restore(GameState state) {
    for (var index = 0; index < state.players.length; index++) {
      state.players[index].scores
        ..clear()
        ..addAll(scores[index]);
      state.players[index].extraKniffel = extraKniffels[index];
    }
    state.currentPlayerIndex = currentPlayerIndex;
    state.isComplete = isComplete;
    state.dice.setAll(0, dice);
    state.held.setAll(0, held);
    state.rollCount = rollCount;
  }
}

class GameController extends ChangeNotifier {
  GameController({required this.state, required this.repository});
  factory GameController.newGame({
    required RuleSet ruleSet,
    required GameMode mode,
    required List<String> names,
    required GameRepository repository,
  }) {
    final minimumPlayers = ruleSet == RuleSet.kniffel ? 2 : 1;
    if (names.length < minimumPlayers || names.length > 8) {
      throw ArgumentError(
        ruleSet == RuleSet.kniffel
            ? 'Bei Yahtzee/Kniffel sind 2 bis 8 Spieler erlaubt.'
            : 'Bei Yatzy (klassisch) sind 1 bis 8 Spieler erlaubt.',
      );
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
        .map(state.totalFor)
        .reduce((a, b) => a > b ? a : b);
    return state.players
        .where((player) => state.totalFor(player) == best)
        .toList();
  }

  Future<void> enterScore(
    ScoreCategory category,
    int value, {
    int? playerIndex,
  }) => _enterScore(category, value, playerIndex: playerIndex);

  Future<void> editBlockScore(
    ScoreCategory category,
    int? value, {
    required int playerIndex,
  }) {
    if (_isBusy) return Future.value();
    if (state.mode != GameMode.block) {
      throw StateError('Wertungen können nur im Scoreblock bearbeitet werden.');
    }
    if (playerIndex < 0 || playerIndex >= state.players.length) {
      throw RangeError.index(playerIndex, state.players);
    }
    if (!state.ruleSet.categories.contains(category)) {
      throw ArgumentError('Kategorie gehört nicht zum Regelwerk.');
    }
    if (value != null &&
        !ScoringEngine.allowedScores(state.ruleSet, category).contains(value)) {
      throw ArgumentError('Ungültige Punktzahl.');
    }
    final player = state.players[playerIndex];
    if (!player.scores.containsKey(category)) {
      throw StateError('Kategorie wurde noch nicht gewertet.');
    }
    return _transaction(() async {
      _undo = _ScoreUndo(
        playerIndex,
        category,
        state.currentPlayerIndex,
        player.extraKniffel,
        player.scores[category],
      );
      if (value == null) {
        player.scores.remove(category);
      } else {
        player.scores[category] = value;
      }
      if (category == ScoreCategory.yatzy &&
          value != 50 &&
          player.extraKniffel > 0) {
        player.extraKniffel = 0;
      }
      _recomputeCompletion();
      notifyListeners();
      await repository.save(state);
    });
  }

  Future<void> enterExtraKniffelScore(ScoreCategory category) {
    if (state.ruleSet != RuleSet.kniffel || state.mode != GameMode.digital) {
      throw StateError(
        'Zusatz-Kniffel ist nur im digitalen Kniffel verfügbar.',
      );
    }
    final player = state.currentPlayer;
    if (player.scores[ScoreCategory.yatzy] != 50 ||
        ScoringEngine.score(state.ruleSet, ScoreCategory.yatzy, state.dice) !=
            50) {
      throw StateError('Es liegt kein Zusatz-Kniffel vor.');
    }
    return _enterScore(
      category,
      category.maxScore(state.ruleSet),
      extraKniffel: true,
    );
  }

  Future<void> enterBlockExtraKniffelScore(
    ScoreCategory category, {
    required int playerIndex,
  }) {
    if (state.ruleSet != RuleSet.kniffel || state.mode != GameMode.block) {
      throw StateError(
        'Dieser Zusatz-Kniffel ist nur im Kniffel-Scoreblock verfügbar.',
      );
    }
    if (playerIndex < 0 || playerIndex >= state.players.length) {
      throw RangeError.index(playerIndex, state.players);
    }
    if (state.players[playerIndex].scores[ScoreCategory.yatzy] != 50) {
      throw StateError('Der erste Kniffel wurde noch nicht gewertet.');
    }
    return _enterScore(
      category,
      category.maxScore(state.ruleSet),
      playerIndex: playerIndex,
      extraKniffel: true,
    );
  }

  Future<void> _enterScore(
    ScoreCategory category,
    int value, {
    int? playerIndex,
    bool extraKniffel = false,
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
      final player = state.players[target];
      _undo = _ScoreUndo(
        target,
        category,
        state.currentPlayerIndex,
        player.extraKniffel,
        null,
      );
      player.scores[category] = value;
      if (extraKniffel) player.extraKniffel++;
      resetTurn();
      _recomputeCompletion();
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
      final player = state.players[undo.playerIndex];
      if (undo.previousScore == null) {
        player.scores.remove(undo.category);
      } else {
        player.scores[undo.category] = undo.previousScore!;
      }
      player.extraKniffel = undo.previousExtraKniffel;
      state.currentPlayerIndex = undo.currentPlayerIndex;
      _recomputeCompletion();
      resetTurn();
      _undo = null;
      notifyListeners();
      await repository.save(state);
    });
  }

  Future<void> mutateAndPersist(void Function() mutation) async {
    if (_isBusy) return;
    await _transaction(() async {
      mutation();
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

  void _recomputeCompletion() {
    state.isComplete = state.players.every(
      (player) => player.scores.length == state.ruleSet.categories.length,
    );
  }

  Future<void> _transaction(Future<void> Function() operation) async {
    final snapshot = _StateSnapshot(state, _undo);
    _isBusy = true;
    notifyListeners();
    try {
      await operation();
    } catch (_) {
      snapshot.restore(state);
      _undo = snapshot.undo;
      notifyListeners();
      rethrow;
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

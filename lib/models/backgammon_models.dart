import 'dart:convert';
import 'game_models.dart';
import 'saved_game_state.dart';

enum BackgammonWinType { normal, gammon, backgammon }

class BackgammonMove {
  const BackgammonMove({
    required this.from,
    required this.to,
    required this.die,
  });
  final int from;
  final int to;
  final int die;
  @override
  bool operator ==(Object other) =>
      other is BackgammonMove &&
      from == other.from &&
      to == other.to &&
      die == other.die;
  @override
  int get hashCode => Object.hash(from, to, die);
}

/// Immutable single-game state. Points use fixed global coordinates, not
/// coordinates relative to the player. All transitions return a new state.
class BackgammonGameState implements SavedGameState {
  BackgammonGameState({
    required List<String> names,
    required this.mode,
    required List<int> points,
    List<int> bar = const [0, 0],
    List<int> off = const [0, 0],
    this.activePlayerIndex = 0,
    this.opening = false,
    List<int> dice = const [],
    List<int> remaining = const [],
    this.isComplete = false,
    this.winType,
    List<BackgammonGameState> undoHistory = const [],
  }) : names = List.unmodifiable(names),
       points = List.unmodifiable(points),
       bar = List.unmodifiable(bar),
       off = List.unmodifiable(off),
       dice = List.unmodifiable(dice),
       remaining = List.unmodifiable(remaining),
       undoHistory = List.unmodifiable(undoHistory) {
    _validate();
  }

  factory BackgammonGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
  }) {
    final points = List<int>.filled(24, 0);
    for (final e in {
      24: 2,
      13: 5,
      8: 3,
      6: 5,
      1: -2,
      12: -5,
      17: -3,
      19: -5,
    }.entries) {
      points[e.key - 1] = e.value;
    }
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: points,
      opening: true,
    );
  }
  final List<String> names;
  final GameMode mode;
  final List<int> points, bar, off, dice, remaining;
  final int activePlayerIndex;
  final bool opening;
  @override
  final bool isComplete;
  final BackgammonWinType? winType;
  final List<BackgammonGameState> undoHistory;
  @override
  List<String> get players => names;
  @override
  String get gameLabel => 'Backgammon';
  @override
  String get modeLabel =>
      mode == GameMode.block ? 'Echte Würfel' : 'Digitale Würfel';
  @override
  String get progressLabel => '${off[0]} / ${off[1]} ausgespielt';
  bool get canUndo => !isComplete && undoHistory.isNotEmpty;
  bool get canRoll => !isComplete && (opening || dice.isEmpty);
  bool get canEndTurn =>
      !isComplete && !opening && dice.isNotEmpty && legalMoves.isEmpty;
  int? get winnerIndex => isComplete ? activePlayerIndex : null;
  int get _sign => activePlayerIndex == 0 ? 1 : -1;
  int _distance(int point) => activePlayerIndex == 0 ? point : 25 - point;
  bool get _allHome =>
      bar[activePlayerIndex] == 0 &&
      !List.generate(
        24,
        (i) => i + 1,
      ).any((p) => points[p - 1] * _sign > 0 && _distance(p) > 6);

  List<BackgammonMove> _localMoves(int die) {
    final sources = bar[activePlayerIndex] > 0
        ? [0]
        : [
            for (var p = 1; p <= 24; p++)
              if (points[p - 1] * _sign > 0) p,
          ];
    final moves = <BackgammonMove>[];
    for (final from in sources) {
      final dest = from == 0
          ? (activePlayerIndex == 0 ? 25 - die : die)
          : from - _sign * die;
      if (dest >= 1 && dest <= 24) {
        if (points[dest - 1] * _sign >= -1) {
          moves.add(BackgammonMove(from: from, to: dest, die: die));
        }
      } else if (from != 0 &&
          _allHome &&
          (die == _distance(from) ||
              !sources.any((p) => _distance(p) > _distance(from)))) {
        moves.add(BackgammonMove(from: from, to: 25, die: die));
      }
    }
    return moves;
  }

  // Search the whole roll: a locally valid first move may waste a playable die.
  int _maximumUses(Map<String, int> memo) {
    if (remaining.isEmpty || isComplete) return 0;
    final key =
        '${points.join(',')}|${bar.join(',')}|${off.join(',')}|${remaining.join(',')}';
    if (memo.containsKey(key)) return memo[key]!;
    var best = 0;
    for (final die in remaining.toSet()) {
      for (final move in _localMoves(die)) {
        final used = 1 + _apply(move)._maximumUses(memo);
        if (used > best) best = used;
      }
    }
    return memo[key] = best;
  }

  List<BackgammonMove> get legalMoves {
    if (opening || isComplete || remaining.isEmpty) return const [];
    final memo = <String, int>{};
    final best = _maximumUses(memo);
    final result = <BackgammonMove>[];
    for (final die in remaining.toSet()) {
      for (final move in _localMoves(die)) {
        if (1 + _apply(move)._maximumUses(memo) == best) result.add(move);
      }
    }
    if (best == 1 && remaining.toSet().length == 2 && result.isNotEmpty) {
      final higher = result.map((m) => m.die).reduce((a, b) => a > b ? a : b);
      result.removeWhere((m) => m.die != higher);
    }
    return List.unmodifiable(result);
  }

  BackgammonGameState roll(int first, int second) {
    if (!canRoll) throw StateError('Cannot roll now.');
    if (first < 1 || first > 6 || second < 1 || second > 6) {
      throw ArgumentError('Dice must be 1..6.');
    }
    final tie = opening && first == second;
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: points,
      bar: bar,
      off: off,
      activePlayerIndex: opening && !tie
          ? (first > second ? 0 : 1)
          : activePlayerIndex,
      opening: tie,
      dice: [first, second],
      remaining: tie
          ? []
          : (first == second ? List.filled(4, first) : [first, second]),
    );
  }

  BackgammonGameState _apply(BackgammonMove move) {
    final p = List<int>.of(points),
        b = List<int>.of(bar),
        o = List<int>.of(off),
        r = List<int>.of(remaining);
    if (move.from == 0) {
      b[activePlayerIndex]--;
    } else {
      p[move.from - 1] -= _sign;
    }
    if (move.to == 25) {
      o[activePlayerIndex]++;
    } else {
      if (p[move.to - 1] == -_sign) {
        p[move.to - 1] = 0;
        b[1 - activePlayerIndex]++;
      }
      p[move.to - 1] += _sign;
    }
    r.remove(move.die);
    final complete = o[activePlayerIndex] == 15;
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: p,
      bar: b,
      off: o,
      activePlayerIndex: activePlayerIndex,
      dice: dice,
      remaining: r,
      isComplete: complete,
      winType: complete ? _classify(p, b, o, activePlayerIndex) : null,
    );
  }

  static BackgammonWinType _classify(
    List<int> p,
    List<int> b,
    List<int> o,
    int winner,
  ) {
    final loser = 1 - winner;
    if (o[loser] > 0) return BackgammonWinType.normal;
    final sign = winner == 0 ? -1 : 1;
    final start = winner == 0 ? 0 : 18;
    if (b[loser] > 0 || p.sublist(start, start + 6).any((n) => n * sign > 0)) {
      return BackgammonWinType.backgammon;
    }
    return BackgammonWinType.gammon;
  }

  BackgammonGameState move(BackgammonMove move) {
    if (!legalMoves.contains(move)) throw StateError('Illegal move.');
    final next = _apply(move);
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: next.points,
      bar: next.bar,
      off: next.off,
      activePlayerIndex: activePlayerIndex,
      dice: dice,
      remaining: next.remaining,
      isComplete: next.isComplete,
      winType: next.winType,
      undoHistory: next.isComplete
          ? const []
          : [...undoHistory, _withoutHistory()],
    );
  }

  BackgammonGameState _withoutHistory() => BackgammonGameState(
    names: names,
    mode: mode,
    points: points,
    bar: bar,
    off: off,
    activePlayerIndex: activePlayerIndex,
    opening: opening,
    dice: dice,
    remaining: remaining,
    isComplete: isComplete,
    winType: winType,
  );
  BackgammonGameState endTurn() {
    if (!canEndTurn) throw StateError('Playable dice remain or no roll.');
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: points,
      bar: bar,
      off: off,
      activePlayerIndex: 1 - activePlayerIndex,
    );
  }

  BackgammonGameState undo() {
    if (!canUndo) throw StateError('No move to undo.');
    final prev = undoHistory.last;
    return BackgammonGameState(
      names: names,
      mode: mode,
      points: prev.points,
      bar: prev.bar,
      off: prev.off,
      activePlayerIndex: activePlayerIndex,
      dice: dice,
      remaining: prev.remaining,
      undoHistory: undoHistory.sublist(0, undoHistory.length - 1),
    );
  }

  void _validate() {
    void require(bool ok) {
      if (!ok) throw const FormatException('Invalid backgammon state.');
    }

    require(
      names.length == 2 &&
          names.every((n) => n.trim().isNotEmpty && n == n.trim()) &&
          names.toSet().length == 2,
    );
    require(
      points.length == 24 &&
          bar.length == 2 &&
          off.length == 2 &&
          activePlayerIndex >= 0 &&
          activePlayerIndex <= 1,
    );
    require(
      points.every((n) => n.abs() <= 15) &&
          [...bar, ...off].every((n) => n >= 0 && n <= 15),
    );
    for (var player = 0; player < 2; player++) {
      final count = points
          .where((n) => player == 0 ? n > 0 : n < 0)
          .fold<int>(0, (a, b) => a + b.abs());
      require(count + bar[player] + off[player] == 15);
    }
    require(
      (dice.isEmpty || dice.length == 2) &&
          [...dice, ...remaining].every((n) => n >= 1 && n <= 6),
    );
    final pool = dice.isEmpty || opening
        ? <int>[]
        : dice[0] == dice[1]
        ? List<int>.filled(4, dice[0], growable: true)
        : List<int>.of(dice);
    for (final die in remaining) {
      require(pool.remove(die));
    }
    require(
      isComplete == off.contains(15) &&
          (!isComplete ||
              (off[activePlayerIndex] == 15 &&
                  off[1 - activePlayerIndex] < 15 &&
                  dice.length == 2)),
    );
    require(
      winType ==
          (isComplete ? _classify(points, bar, off, activePlayerIndex) : null),
    );
    require(
      !opening ||
          (activePlayerIndex == 0 &&
              off.every((n) => n == 0) &&
              bar.every((n) => n == 0) &&
              (dice.isEmpty || dice[0] == dice[1]) &&
              remaining.isEmpty &&
              undoHistory.isEmpty),
    );
    if (opening) {
      final start = {24: 2, 13: 5, 8: 3, 6: 5, 1: -2, 12: -5, 17: -3, 19: -5};
      require(
        List.generate(
          24,
          (i) => points[i] == (start[i + 1] ?? 0),
        ).every((v) => v),
      );
    }
    require(undoHistory.length <= 4 && (!isComplete || undoHistory.isEmpty));
    for (var i = 0; i < undoHistory.length; i++) {
      final before = undoHistory[i];
      final after = i + 1 < undoHistory.length ? undoHistory[i + 1] : this;
      require(
        before.undoHistory.isEmpty && !before.opening && !before.isComplete,
      );
      require(
        before.legalMoves.any(
          (m) =>
              jsonEncode(before._apply(m).toJson()) ==
              jsonEncode(after._withoutHistory().toJson()),
        ),
      );
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'backgammon',
    'names': names,
    'mode': mode.name,
    'points': points,
    'bar': bar,
    'off': off,
    'activePlayerIndex': activePlayerIndex,
    'opening': opening,
    'dice': dice,
    'remaining': remaining,
    'isComplete': isComplete,
    'winType': winType?.name,
    'undoHistory': undoHistory.map((s) => s.toJson()).toList(),
  };
  factory BackgammonGameState.fromJson(Map<String, dynamic> json) {
    try {
      const keys = {
        'type',
        'names',
        'mode',
        'points',
        'bar',
        'off',
        'activePlayerIndex',
        'opening',
        'dice',
        'remaining',
        'isComplete',
        'winType',
        'undoHistory',
      };
      if (json['type'] != 'backgammon' ||
          json.length != keys.length ||
          !json.keys.every(keys.contains)) {
        throw const FormatException('Invalid backgammon JSON.');
      }
      List<int> ints(String key) =>
          (json[key] as List).map((v) => v as int).toList();
      final rawHistory = json['undoHistory'] as List;
      if (rawHistory.length > 4 ||
          rawHistory.any(
            (v) => ((v as Map)['undoHistory'] as List).isNotEmpty,
          )) {
        throw const FormatException('Invalid undo history.');
      }
      return BackgammonGameState(
        names: (json['names'] as List).map((v) => v as String).toList(),
        mode: GameMode.values.byName(json['mode'] as String),
        points: ints('points'),
        bar: ints('bar'),
        off: ints('off'),
        activePlayerIndex: json['activePlayerIndex'] as int,
        opening: json['opening'] as bool,
        dice: ints('dice'),
        remaining: ints('remaining'),
        isComplete: json['isComplete'] as bool,
        winType: json['winType'] == null
            ? null
            : BackgammonWinType.values.byName(json['winType'] as String),
        undoHistory: rawHistory
            .map(
              (v) => BackgammonGameState.fromJson(
                Map<String, dynamic>.from(v as Map),
              ),
            )
            .toList(),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid backgammon JSON.', e);
    }
  }
}

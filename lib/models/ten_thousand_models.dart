import 'dart:collection';

import 'saved_game_state.dart';

class TenThousandPlayer {
  TenThousandPlayer(String name) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Der Spielername darf nicht leer sein.',
      );
    }
  }

  final String name;

  Map<String, dynamic> toJson() => {'name': name};

  factory TenThousandPlayer.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'name'});
    final name = json['name'];
    if (name is! String || name.trim().isEmpty || name != name.trim()) {
      throw const FormatException('Ungültiger Spielername.');
    }
    return TenThousandPlayer(name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenThousandPlayer && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class TenThousandTurn {
  TenThousandTurn(this.ordinal, this.points, {this.isDeleted = false}) {
    if (ordinal < 0) throw ArgumentError.value(ordinal, 'ordinal');
    _validatePoints(points);
  }

  final int ordinal;
  final int points;
  final bool isDeleted;

  int get effectivePoints => isDeleted ? 0 : points;

  TenThousandTurn asDeleted() =>
      TenThousandTurn(ordinal, points, isDeleted: true);

  Map<String, dynamic> toJson() => {
    'ordinal': ordinal,
    'points': points,
    'isDeleted': isDeleted,
  };

  factory TenThousandTurn.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'ordinal', 'points', 'isDeleted'});
    final ordinal = json['ordinal'];
    final points = json['points'];
    final isDeleted = json['isDeleted'];
    if (ordinal is! int || points is! int || isDeleted is! bool) {
      throw const FormatException('Ungültiger Zug.');
    }
    _validatePoints(points, formatException: true);
    return TenThousandTurn(ordinal, points, isDeleted: isDeleted);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenThousandTurn &&
          other.ordinal == ordinal &&
          other.points == points &&
          other.isDeleted == isDeleted;

  @override
  int get hashCode => Object.hash(ordinal, points, isDeleted);
}

class TenThousandGameState implements SavedGameState {
  TenThousandGameState({
    required List<TenThousandPlayer> players,
    List<TenThousandTurn> turns = const [],
  }) : _players = List<TenThousandPlayer>.unmodifiable(players),
       _turns = List<TenThousandTurn>.unmodifiable(turns) {
    _validatePlayers(_players);
    _validateLedgerShape(_turns);
    _replay = _Replay.compute(_players.length, _turns);
    if (_replay.legalTurnCount != _turns.length) {
      throw const FormatException(
        'Der Spielstand enthält Züge nach Spielende.',
      );
    }
  }

  factory TenThousandGameState.newGame(List<String> names) {
    final cleaned = names.map((name) => name.trim()).toList(growable: false);
    if (cleaned.length < 2 || cleaned.length > 8) {
      throw ArgumentError('Bei 10.000 sind 2 bis 8 Spieler erlaubt.');
    }
    if (cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
    return TenThousandGameState(
      players: cleaned.map(TenThousandPlayer.new).toList(growable: false),
    );
  }

  static const int schemaVersion = 1;
  static const int winningScore = 10000;

  final List<TenThousandPlayer> _players;
  final List<TenThousandTurn> _turns;
  late final _Replay _replay;

  @override
  List<TenThousandPlayer> get players =>
      UnmodifiableListView<TenThousandPlayer>(_players);

  List<TenThousandTurn> get turns =>
      UnmodifiableListView<TenThousandTurn>(_turns);

  List<int> get totals => UnmodifiableListView<int>(_replay.totals);

  int playerIndexForTurn(int ordinal) {
    if (ordinal < 0) throw RangeError.value(ordinal, 'ordinal');
    return ordinal % _players.length;
  }

  int totalFor(TenThousandPlayer player) {
    final index = _players.indexOf(player);
    if (index < 0) throw ArgumentError.value(player, 'player');
    return _replay.totals[index];
  }

  int? get activePlayerIndex =>
      isComplete ? null : _turns.length % _players.length;

  TenThousandPlayer? get activePlayer {
    final index = activePlayerIndex;
    return index == null ? null : _players[index];
  }

  int? get finalRoundTriggerOrdinal => _replay.triggerOrdinal;

  int? get finalRoundTriggerPlayerIndex {
    final ordinal = _replay.triggerOrdinal;
    return ordinal == null ? null : playerIndexForTurn(ordinal);
  }

  bool get isInFinalRound => _replay.triggerOrdinal != null && !isComplete;

  List<int> get finalRoundRemainingPlayerIndices {
    final completionOrdinal = _replay.completionOrdinal;
    if (completionOrdinal == null || isComplete) return const [];
    return List<int>.unmodifiable([
      for (var ordinal = _turns.length; ordinal <= completionOrdinal; ordinal++)
        playerIndexForTurn(ordinal),
    ]);
  }

  @override
  bool get isComplete => _replay.isComplete;

  List<int> get winnerIndices {
    final best = _replay.totals.reduce((a, b) => a > b ? a : b);
    return List<int>.unmodifiable([
      for (var index = 0; index < _players.length; index++)
        if (_replay.totals[index] == best) index,
    ]);
  }

  List<TenThousandPlayer> get winners => List<TenThousandPlayer>.unmodifiable(
    winnerIndices.map((index) => _players[index]),
  );

  TenThousandGameState withTurn(int points) {
    _validatePoints(points);
    if (isComplete) throw StateError('Die Partie ist bereits beendet.');
    return TenThousandGameState(
      players: _players,
      turns: [..._turns, TenThousandTurn(_turns.length, points)],
    );
  }

  TenThousandGameState replacingTurn(int ordinal, TenThousandTurn replacement) {
    if (ordinal < 0 || ordinal >= _turns.length) {
      throw RangeError.index(ordinal, _turns, 'ordinal');
    }
    if (replacement.ordinal != ordinal) {
      throw ArgumentError('Der Ersatzzug muss dieselbe Ordnungsnummer haben.');
    }
    _validatePoints(replacement.points);
    final replaced = List<TenThousandTurn>.of(_turns)..[ordinal] = replacement;
    return TenThousandGameState(players: _players, turns: replaced);
  }

  int legalTurnCountAfterReplacing(int ordinal, TenThousandTurn replacement) {
    if (ordinal < 0 || ordinal >= _turns.length) {
      throw RangeError.index(ordinal, _turns, 'ordinal');
    }
    if (replacement.ordinal != ordinal) {
      throw ArgumentError('Der Ersatzzug muss dieselbe Ordnungsnummer haben.');
    }
    _validatePoints(replacement.points);
    final replaced = List<TenThousandTurn>.of(_turns)..[ordinal] = replacement;
    return _Replay.compute(_players.length, replaced).legalTurnCount;
  }

  TenThousandGameState replacingTurnAndTruncating(
    int ordinal,
    TenThousandTurn replacement,
  ) {
    final replaced = List<TenThousandTurn>.of(_turns)..[ordinal] = replacement;
    final legalCount = legalTurnCountAfterReplacing(ordinal, replacement);
    return TenThousandGameState(
      players: _players,
      turns: replaced.sublist(0, legalCount),
    );
  }

  TenThousandGameState copy() =>
      TenThousandGameState(players: _players, turns: _turns);

  @override
  String get gameLabel => '10.000';

  @override
  String get modeLabel => 'Echte Würfel';

  @override
  String get progressLabel => '${_turns.length} Züge';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tenThousand',
    'schemaVersion': schemaVersion,
    'players': _players.map((player) => player.toJson()).toList(),
    'turns': _turns.map((turn) => turn.toJson()).toList(),
  };

  factory TenThousandGameState.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {
        'type',
        'schemaVersion',
        'players',
        'turns',
      });
      if (json['type'] != 'tenThousand' ||
          json['schemaVersion'] != schemaVersion) {
        throw const FormatException('Ungültiger 10.000-Spielstand.');
      }
      final rawPlayers = json['players'];
      final rawTurns = json['turns'];
      if (rawPlayers is! List || rawTurns is! List) {
        throw const FormatException('Ungültiger 10.000-Spielstand.');
      }
      final players = rawPlayers
          .map((value) {
            if (value is! Map) {
              throw const FormatException('Ungültiger Spieler.');
            }
            return TenThousandPlayer.fromJson(Map<String, dynamic>.from(value));
          })
          .toList(growable: false);
      final turns = rawTurns
          .map((value) {
            if (value is! Map) throw const FormatException('Ungültiger Zug.');
            return TenThousandTurn.fromJson(Map<String, dynamic>.from(value));
          })
          .toList(growable: false);
      return TenThousandGameState(players: players, turns: turns);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger 10.000-Spielstand.', error);
    }
  }

  static void _validatePlayers(List<TenThousandPlayer> players) {
    if (players.length < 2 || players.length > 8) {
      throw ArgumentError('Bei 10.000 sind 2 bis 8 Spieler erlaubt.');
    }
    final names = players.map((player) => player.name).toList();
    if (names.any((name) => name.isEmpty || name != name.trim()) ||
        names.toSet().length != names.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
  }

  static void _validateLedgerShape(List<TenThousandTurn> turns) {
    for (var index = 0; index < turns.length; index++) {
      if (turns[index].ordinal != index) {
        throw const FormatException('Die Zugfolge ist nicht lückenlos.');
      }
      _validatePoints(turns[index].points, formatException: true);
    }
  }
}

class _Replay {
  const _Replay({
    required this.totals,
    required this.triggerOrdinal,
    required this.completionOrdinal,
    required this.legalTurnCount,
    required this.isComplete,
  });

  factory _Replay.compute(int playerCount, List<TenThousandTurn> turns) {
    final totals = List<int>.filled(playerCount, 0);
    int? triggerOrdinal;
    int? completionOrdinal;
    var legalTurnCount = turns.length;

    for (var index = 0; index < turns.length; index++) {
      if (completionOrdinal != null && index > completionOrdinal) {
        legalTurnCount = index;
        break;
      }
      final turn = turns[index];
      final playerIndex = turn.ordinal % playerCount;
      totals[playerIndex] += turn.effectivePoints;
      if (triggerOrdinal == null &&
          !turn.isDeleted &&
          totals[playerIndex] >= TenThousandGameState.winningScore) {
        triggerOrdinal = turn.ordinal;
        completionOrdinal = turn.ordinal + playerCount - 1;
      }
    }

    final complete =
        completionOrdinal != null && turns.length > completionOrdinal;
    return _Replay(
      totals: List<int>.unmodifiable(totals),
      triggerOrdinal: triggerOrdinal,
      completionOrdinal: completionOrdinal,
      legalTurnCount: legalTurnCount,
      isComplete: complete,
    );
  }

  final List<int> totals;
  final int? triggerOrdinal;
  final int? completionOrdinal;
  final int legalTurnCount;
  final bool isComplete;
}

void _validatePoints(int points, {bool formatException = false}) {
  if (points < 0 || points % 50 != 0) {
    if (formatException) {
      throw const FormatException('Ungültige Punktzahl.');
    }
    throw ArgumentError.value(
      points,
      'points',
      'Erlaubt sind 0 oder positive Vielfache von 50.',
    );
  }
}

void _requireExactKeys(Map<String, dynamic> json, Set<String> expected) {
  if (json.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw const FormatException('Unbekannte oder fehlende JSON-Felder.');
  }
}

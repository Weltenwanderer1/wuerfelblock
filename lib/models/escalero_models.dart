import 'dart:collection';

import 'game_models.dart';
import 'saved_game_state.dart';

enum EscaleroCategory {
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
  straight,
  fullHouse,
  poker,
  grande,
}

extension EscaleroCategoryInfo on EscaleroCategory {
  String get label => switch (this) {
    EscaleroCategory.nine => '9',
    EscaleroCategory.ten => '10',
    EscaleroCategory.jack => 'B',
    EscaleroCategory.queen => 'D',
    EscaleroCategory.king => 'K',
    EscaleroCategory.ace => 'A',
    EscaleroCategory.straight => 'Straße',
    EscaleroCategory.fullHouse => 'Full House',
    EscaleroCategory.poker => 'Poker',
    EscaleroCategory.grande => 'Grande',
  };

  int? get pictureValue => index < 6 ? index + 1 : null;

  String get formation {
    if (pictureValue != null) return 'Passende Würfelwerte addieren.';
    return switch (this) {
      EscaleroCategory.straight =>
        'fünf aufeinanderfolgende Bilder (9–K oder 10–A).',
      EscaleroCategory.fullHouse =>
        'drei gleiche und zwei gleiche Bilder; fünf gleiche sind ebenfalls erlaubt.',
      EscaleroCategory.poker => 'vier oder fünf gleiche Bilder.',
      EscaleroCategory.grande => 'fünf gleiche Bilder.',
      _ => throw StateError('Unbekannte Kategorie.'),
    };
  }

  String get baseValue {
    final picture = pictureValue;
    if (picture != null) return 'Anzahl × $picture';
    return switch (this) {
      EscaleroCategory.straight => '20 Punkte',
      EscaleroCategory.fullHouse => '30 Punkte',
      EscaleroCategory.poker => '40 Punkte',
      EscaleroCategory.grande => '50 Punkte',
      _ => throw StateError('Unbekannte Kategorie.'),
    };
  }

  String get servedValue => switch (this) {
    EscaleroCategory.straight => '25 Punkte',
    EscaleroCategory.fullHouse => '35 Punkte',
    EscaleroCategory.poker => '45 Punkte',
    EscaleroCategory.grande => '80 Punkte',
    _ => 'Kein Servierungsbonus',
  };
}

abstract final class EscaleroScoring {
  static int score(
    EscaleroCategory category,
    List<int> dice, {
    bool served = false,
  }) {
    _validateDice(dice);
    final picture = category.pictureValue;
    if (picture != null) {
      return dice.where((die) => die == picture).length * picture;
    }
    final counts = <int, int>{};
    for (final die in dice) {
      counts[die] = (counts[die] ?? 0) + 1;
    }
    final groups = counts.values.toList()..sort();
    return switch (category) {
      EscaleroCategory.straight => _isStraight(dice) ? (served ? 25 : 20) : 0,
      EscaleroCategory.fullHouse =>
        (_same(groups, const [2, 3]) || groups.length == 1)
            ? (served ? 35 : 30)
            : 0,
      EscaleroCategory.poker =>
        (groups.contains(4) || groups.length == 1) ? (served ? 45 : 40) : 0,
      EscaleroCategory.grande => groups.length == 1 ? (served ? 80 : 50) : 0,
      _ => throw StateError('Unbekannte Kategorie.'),
    };
  }

  static bool isValidEntry(EscaleroCategory category, int score) {
    if (score == 0) return true;
    final picture = category.pictureValue;
    if (picture != null) {
      return score >= picture && score <= 5 * picture && score % picture == 0;
    }
    return switch (category) {
      EscaleroCategory.straight => score == 20 || score == 25,
      EscaleroCategory.fullHouse => score == 30 || score == 35,
      EscaleroCategory.poker => score == 40 || score == 45,
      EscaleroCategory.grande => score == 50 || score == 80,
      _ => false,
    };
  }

  static bool _isStraight(List<int> dice) {
    final sorted = List<int>.of(dice)..sort();
    return _same(sorted, const [1, 2, 3, 4, 5]) ||
        _same(sorted, const [2, 3, 4, 5, 6]);
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static void _validateDice(List<int> dice) {
    if (dice.length != 5 || dice.any((die) => die < 1 || die > 6)) {
      throw ArgumentError.value(
        dice,
        'dice',
        'Fünf gültige Pokerwürfel nötig.',
      );
    }
  }
}

class EscaleroPlayer {
  EscaleroPlayer(String name, {Map<EscaleroCategory, List<int?>>? entries})
    : name = name.trim(),
      _entries = {
        for (final category in EscaleroCategory.values)
          category: List<int?>.unmodifiable(
            entries?[category] ?? List<int?>.filled(columnCount, null),
          ),
      } {
    if (this.name.isEmpty) throw ArgumentError.value(name, 'name');
    if (entries != null &&
        (entries.length != EscaleroCategory.values.length ||
            !entries.keys.toSet().containsAll(EscaleroCategory.values))) {
      throw ArgumentError.value(
        entries,
        'entries',
        'Alle Kategorien sind nötig.',
      );
    }
    for (final category in EscaleroCategory.values) {
      final values = _entries[category]!;
      if (values.length != columnCount ||
          values.whereType<int>().any(
            (value) => !EscaleroScoring.isValidEntry(category, value),
          )) {
        throw ArgumentError.value(
          values,
          category.name,
          'Ungültige Wertungen.',
        );
      }
    }
  }

  static const columnCount = 3;
  static const entriesPerSheet = 30;
  final String name;
  final Map<EscaleroCategory, List<int?>> _entries;

  Map<EscaleroCategory, List<int?>> get entries =>
      UnmodifiableMapView(_entries);
  int get filledEntryCount =>
      _entries.values.expand((e) => e).where((e) => e != null).length;
  bool get isComplete => filledEntryCount == entriesPerSheet;
  int get rawTotal => _entries.values
      .expand((e) => e)
      .whereType<int>()
      .fold(0, (a, b) => a + b);
  int columnTotal(int column) {
    if (column < 0 || column >= columnCount) {
      throw RangeError.range(column, 0, columnCount - 1);
    }
    return _entries.values
        .map((values) => values[column])
        .whereType<int>()
        .fold(0, (a, b) => a + b);
  }

  EscaleroPlayer withEntry(EscaleroCategory category, int column, int score) {
    if (column < 0 || column >= columnCount) {
      throw RangeError.index(column, _entries[category]!, 'column');
    }
    if (_entries[category]![column] != null) {
      throw StateError('Dieses Feld wurde bereits gewertet.');
    }
    if (!EscaleroScoring.isValidEntry(category, score)) {
      throw ArgumentError.value(score, 'score', 'Ungültige Escalero-Wertung.');
    }
    final changed = List<int?>.of(_entries[category]!)..[column] = score;
    return EscaleroPlayer(name, entries: {..._entries, category: changed});
  }

  EscaleroPlayer withEditedEntry(
    EscaleroCategory category,
    int column,
    int? score,
  ) {
    if (column < 0 || column >= columnCount) {
      throw RangeError.index(column, _entries[category]!, 'column');
    }
    if (_entries[category]![column] == null) {
      throw StateError('Nur eine belegte Wertung kann bearbeitet werden.');
    }
    if (score != null && !EscaleroScoring.isValidEntry(category, score)) {
      throw ArgumentError.value(score, 'score', 'Ungültige Escalero-Wertung.');
    }
    final changed = List<int?>.of(_entries[category]!)..[column] = score;
    return EscaleroPlayer(name, entries: {..._entries, category: changed});
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'entries': {
      for (final category in EscaleroCategory.values)
        category.name: _entries[category],
    },
  };

  factory EscaleroPlayer.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {'name', 'entries'});
      final name = json['name'];
      final rawEntries = json['entries'];
      if (name is! String ||
          name.isEmpty ||
          name != name.trim() ||
          rawEntries is! Map) {
        throw const FormatException('Ungültiger Escalero-Spieler.');
      }
      final map = Map<String, dynamic>.from(rawEntries);
      _requireExactKeys(
        map,
        EscaleroCategory.values.map((e) => e.name).toSet(),
      );
      final entries = <EscaleroCategory, List<int?>>{};
      for (final category in EscaleroCategory.values) {
        final raw = map[category.name];
        if (raw is! List || raw.length != columnCount) {
          throw const FormatException('Ungültige Wertungen.');
        }
        entries[category] = raw
            .map<int?>((value) {
              if (value != null && value is! int) {
                throw const FormatException('Ungültige Wertung.');
              }
              return value as int?;
            })
            .toList(growable: false);
      }
      return EscaleroPlayer(name, entries: entries);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Escalero-Spieler.', error);
    }
  }
}

class EscaleroDigitalTurn {
  EscaleroDigitalTurn({
    List<int> dice = const [1, 1, 1, 1, 1],
    List<bool> held = const [false, false, false, false, false],
    this.rollCount = 0,
    this.lastRollWasAllFive = false,
  }) : _dice = List<int>.unmodifiable(dice),
       _held = List<bool>.unmodifiable(held) {
    if (_dice.length != 5 ||
        _dice.any((die) => die < 1 || die > 6) ||
        _held.length != 5 ||
        rollCount < 0 ||
        rollCount > 3 ||
        (rollCount == 0 &&
            (lastRollWasAllFive || _held.any((value) => value)))) {
      throw ArgumentError('Ungültiger digitaler Zug.');
    }
  }

  final List<int> _dice;
  final List<bool> _held;
  final int rollCount;
  final bool lastRollWasAllFive;
  List<int> get dice => UnmodifiableListView(_dice);
  List<bool> get held => UnmodifiableListView(_held);

  EscaleroDigitalTurn roll(List<int> values) {
    if (rollCount >= 3) throw StateError('Maximal drei Würfe.');
    final indices = rollCount == 0
        ? List<int>.generate(5, (i) => i)
        : [
            for (var i = 0; i < 5; i++)
              if (!_held[i]) i,
          ];
    if (indices.isEmpty) {
      throw StateError('Alle Würfel sind gehalten.');
    }
    if (values.length != indices.length ||
        values.any((die) => die < 1 || die > 6)) {
      throw ArgumentError.value(
        values,
        'values',
        'Falsche Anzahl gültiger Würfel.',
      );
    }
    final changed = List<int>.of(_dice);
    for (var i = 0; i < indices.length; i++) {
      changed[indices[i]] = values[i];
    }
    return EscaleroDigitalTurn(
      dice: changed,
      held: _held,
      rollCount: rollCount + 1,
      lastRollWasAllFive: indices.length == 5,
    );
  }

  EscaleroDigitalTurn toggleHold(int index) {
    if (rollCount == 0 || rollCount >= 3) {
      throw StateError('Jetzt können keine Würfel gehalten werden.');
    }
    if (index < 0 || index >= 5) throw RangeError.index(index, _held);
    final changed = List<bool>.of(_held)..[index] = !_held[index];
    return EscaleroDigitalTurn(
      dice: _dice,
      held: changed,
      rollCount: rollCount,
      lastRollWasAllFive: lastRollWasAllFive,
    );
  }

  Map<String, dynamic> toJson() => {
    'dice': _dice,
    'held': _held,
    'rollCount': rollCount,
    'lastRollWasAllFive': lastRollWasAllFive,
  };

  factory EscaleroDigitalTurn.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {
      'dice',
      'held',
      'rollCount',
      'lastRollWasAllFive',
    });
    final dice = json['dice'];
    final held = json['held'];
    final rollCount = json['rollCount'];
    final allFive = json['lastRollWasAllFive'];
    if (dice is! List ||
        held is! List ||
        rollCount is! int ||
        allFive is! bool ||
        dice.any((e) => e is! int) ||
        held.any((e) => e is! bool)) {
      throw const FormatException('Ungültiger digitaler Zug.');
    }
    try {
      return EscaleroDigitalTurn(
        dice: dice.cast<int>(),
        held: held.cast<bool>(),
        rollCount: rollCount,
        lastRollWasAllFive: allFive,
      );
    } catch (error) {
      throw FormatException('Ungültiger digitaler Zug.', error);
    }
  }
}

class EscaleroGameState implements SavedGameState {
  EscaleroGameState({
    required List<EscaleroPlayer> players,
    this.mode = GameMode.block,
    this.activePlayerIndex = 0,
    EscaleroDigitalTurn? digitalTurn,
  }) : _players = List<EscaleroPlayer>.unmodifiable(players),
       digitalTurn = digitalTurn ?? EscaleroDigitalTurn() {
    if (_players.length < 2 ||
        _players.length > 3 ||
        _players.map((p) => p.name).toSet().length != _players.length ||
        activePlayerIndex < 0 ||
        activePlayerIndex >= _players.length ||
        (!isComplete && _players[activePlayerIndex].isComplete) ||
        (mode == GameMode.block && this.digitalTurn.rollCount != 0) ||
        (isComplete && this.digitalTurn.rollCount != 0)) {
      throw ArgumentError('Ungültiger Escalero-Spielstand.');
    }
  }

  factory EscaleroGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
  }) {
    final cleaned = names.map((name) => name.trim()).toList(growable: false);
    if (cleaned.length < 2 ||
        cleaned.length > 3 ||
        cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError(
        'Bei Escalero sind 2 bis 3 eindeutige Spieler erlaubt.',
      );
    }
    return EscaleroGameState(
      players: cleaned.map(EscaleroPlayer.new).toList(),
      mode: mode,
    );
  }

  static const schemaVersion = 1;
  static const columnIndices = <int>[0, 1, 2];
  final List<EscaleroPlayer> _players;
  final GameMode mode;
  final int activePlayerIndex;
  final EscaleroDigitalTurn digitalTurn;

  @override
  List<EscaleroPlayer> get players => UnmodifiableListView(_players);
  List<EscaleroCategory> get categories => EscaleroCategory.values;
  List<int> get columns => columnIndices;
  EscaleroPlayer get activePlayer => _players[activePlayerIndex];
  int get filledEntryCount =>
      _players.fold(0, (sum, p) => sum + p.filledEntryCount);
  @override
  bool get isComplete => _players.every((p) => p.isComplete);

  int gamePointsFor(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= _players.length) {
      throw RangeError.index(playerIndex, _players);
    }
    var points = 0;
    final columnWinners = <int?>[];
    for (var column = 0; column < 3; column++) {
      final winner = _soleColumnWinner(column);
      columnWinners.add(winner);
      if (winner == null) continue;
      final weight = 1 << column;
      points += winner == playerIndex
          ? weight * (_players.length - 1)
          : -weight;
    }
    final sweepWinner = columnWinners.first;
    if (sweepWinner != null &&
        columnWinners.every((winner) => winner == sweepWinner)) {
      points += sweepWinner == playerIndex ? 2 * (_players.length - 1) : -2;
    }
    return points;
  }

  int? _soleColumnWinner(int column) {
    final totals = [for (final player in _players) player.columnTotal(column)];
    final highest = totals.reduce((a, b) => a > b ? a : b);
    final winners = [
      for (var index = 0; index < totals.length; index++)
        if (totals[index] == highest) index,
    ];
    return winners.length == 1 ? winners.single : null;
  }

  List<EscaleroPlayer> get ranking {
    final indexed = List<int>.generate(_players.length, (i) => i)
      ..sort((a, b) {
        final byPoints = gamePointsFor(b).compareTo(gamePointsFor(a));
        return byPoints != 0 ? byPoints : a.compareTo(b);
      });
    return List.unmodifiable(indexed.map((i) => _players[i]));
  }

  List<EscaleroPlayer> get winners {
    final bestPoints = List<int>.generate(
      _players.length,
      gamePointsFor,
    ).reduce((a, b) => a > b ? a : b);
    return List.unmodifiable(
      List<int>.generate(
        _players.length,
        (i) => i,
      ).where((i) => gamePointsFor(i) == bestPoints).map((i) => _players[i]),
    );
  }

  EscaleroGameState withBlockScore(
    EscaleroCategory category,
    int column,
    int score,
  ) {
    if (mode != GameMode.block || isComplete) {
      throw StateError('Keine Blockwertung verfügbar.');
    }
    return _withScore(category, column, score);
  }

  EscaleroGameState withDigitalRoll(List<int> values) {
    if (mode != GameMode.digital || isComplete) {
      throw StateError('Jetzt kann nicht gewürfelt werden.');
    }
    return _copy(digitalTurn: digitalTurn.roll(values));
  }

  EscaleroGameState withToggledHold(int index) {
    if (mode != GameMode.digital || isComplete) {
      throw StateError('Jetzt kann nicht gehalten werden.');
    }
    return _copy(digitalTurn: digitalTurn.toggleHold(index));
  }

  EscaleroGameState withDigitalScore(EscaleroCategory category, int column) {
    if (mode != GameMode.digital || digitalTurn.rollCount == 0 || isComplete) {
      throw StateError('Keine digitale Wertung verfügbar.');
    }
    return _withScore(
      category,
      column,
      EscaleroScoring.score(
        category,
        digitalTurn.dice,
        served: digitalTurn.lastRollWasAllFive,
      ),
      resetTurn: true,
    );
  }

  EscaleroGameState withEditedScore(
    int playerIndex,
    EscaleroCategory category,
    int column,
    int? score,
  ) {
    if (playerIndex < 0 || playerIndex >= _players.length) {
      throw RangeError.index(playerIndex, _players, 'playerIndex');
    }
    final wasComplete = isComplete;
    final changed = List<EscaleroPlayer>.of(_players);
    changed[playerIndex] = changed[playerIndex].withEditedEntry(
      category,
      column,
      score,
    );
    return EscaleroGameState(
      players: changed,
      mode: mode,
      activePlayerIndex: wasComplete && !changed[playerIndex].isComplete
          ? playerIndex
          : activePlayerIndex,
      digitalTurn: digitalTurn,
    );
  }

  EscaleroGameState _withScore(
    EscaleroCategory category,
    int column,
    int score, {
    bool resetTurn = false,
  }) {
    final changed = List<EscaleroPlayer>.of(_players);
    changed[activePlayerIndex] = activePlayer.withEntry(
      category,
      column,
      score,
    );
    return EscaleroGameState(
      players: changed,
      mode: mode,
      activePlayerIndex: _nextIncomplete(changed),
      digitalTurn: resetTurn ? EscaleroDigitalTurn() : digitalTurn,
    );
  }

  int _nextIncomplete(List<EscaleroPlayer> players) {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (activePlayerIndex + offset) % players.length;
      if (!players[index].isComplete) return index;
    }
    return activePlayerIndex;
  }

  EscaleroGameState _copy({EscaleroDigitalTurn? digitalTurn}) =>
      EscaleroGameState(
        players: _players,
        mode: mode,
        activePlayerIndex: activePlayerIndex,
        digitalTurn: digitalTurn ?? this.digitalTurn,
      );

  EscaleroGameState copy() => EscaleroGameState.fromJson(toJson());
  @override
  String get gameLabel => 'Escalero';
  @override
  String get modeLabel => mode.label;
  @override
  String get progressLabel =>
      '$filledEntryCount von ${_players.length * EscaleroPlayer.entriesPerSheet} Wertungen';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'escalero',
    'schemaVersion': schemaVersion,
    'mode': mode.name,
    'players': _players.map((p) => p.toJson()).toList(),
    'activePlayerIndex': activePlayerIndex,
    'digitalTurn': digitalTurn.toJson(),
  };

  factory EscaleroGameState.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {
        'type',
        'schemaVersion',
        'mode',
        'players',
        'activePlayerIndex',
        'digitalTurn',
      });
      if (json['type'] != 'escalero' ||
          json['schemaVersion'] != schemaVersion) {
        throw const FormatException('Ungültiger Escalero-Spielstand.');
      }
      final modeName = json['mode'];
      final rawPlayers = json['players'];
      final active = json['activePlayerIndex'];
      final rawTurn = json['digitalTurn'];
      if (modeName is! String ||
          rawPlayers is! List ||
          active is! int ||
          rawTurn is! Map) {
        throw const FormatException('Ungültiger Escalero-Spielstand.');
      }
      final mode = GameMode.values.where((e) => e.name == modeName).single;
      final players = rawPlayers
          .map((value) {
            if (value is! Map) {
              throw const FormatException('Ungültiger Spieler.');
            }
            return EscaleroPlayer.fromJson(Map<String, dynamic>.from(value));
          })
          .toList(growable: false);
      return EscaleroGameState(
        players: players,
        mode: mode,
        activePlayerIndex: active,
        digitalTurn: EscaleroDigitalTurn.fromJson(
          Map<String, dynamic>.from(rawTurn),
        ),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Escalero-Spielstand.', error);
    }
  }
}

void _requireExactKeys(Map<String, dynamic> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Unerwartete oder fehlende JSON-Felder.');
  }
}

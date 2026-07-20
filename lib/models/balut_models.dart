import 'dart:collection';

import 'game_models.dart';
import 'saved_game_state.dart';

enum BalutCategory { fours, fives, sixes, straights, fullHouse, choice, balut }

extension BalutCategoryInfo on BalutCategory {
  String get label => switch (this) {
    BalutCategory.fours => 'Vierer',
    BalutCategory.fives => 'Fünfer',
    BalutCategory.sixes => 'Sechser',
    BalutCategory.straights => 'Straßen',
    BalutCategory.fullHouse => 'Full House',
    BalutCategory.choice => 'Choice',
    BalutCategory.balut => 'Balut',
  };
}

abstract final class BalutScoring {
  static int score(BalutCategory category, List<int> dice) {
    _validateDice(dice);
    final sum = dice.fold(0, (total, die) => total + die);
    return switch (category) {
      BalutCategory.fours => dice.where((die) => die == 4).length * 4,
      BalutCategory.fives => dice.where((die) => die == 5).length * 5,
      BalutCategory.sixes => dice.where((die) => die == 6).length * 6,
      BalutCategory.straights => _straightScore(dice),
      BalutCategory.fullHouse => _isFullHouse(dice) ? sum : 0,
      BalutCategory.choice => sum,
      BalutCategory.balut => dice.toSet().length == 1 ? 20 + sum : 0,
    };
  }

  static bool isValidEntry(BalutCategory category, int score) {
    if (score == 0) return true;
    return switch (category) {
      BalutCategory.fours => score >= 4 && score <= 20 && score % 4 == 0,
      BalutCategory.fives => score >= 5 && score <= 25 && score % 5 == 0,
      BalutCategory.sixes => score >= 6 && score <= 30 && score % 6 == 0,
      BalutCategory.straights => score == 15 || score == 20,
      BalutCategory.fullHouse => _fullHouseScores.contains(score),
      BalutCategory.choice => score >= 5 && score <= 30,
      BalutCategory.balut =>
        score >= 25 && score <= 50 && (score - 20) % 5 == 0,
    };
  }

  static int rawTotalIncentive(int rawTotal) {
    if (rawTotal < 0 || rawTotal > 812) {
      throw RangeError.range(rawTotal, 0, 812, 'rawTotal');
    }
    if (rawTotal < 300) return -2;
    if (rawTotal < 350) return -1;
    if (rawTotal < 400) return 0;
    if (rawTotal < 450) return 1;
    if (rawTotal < 500) return 2;
    if (rawTotal < 550) return 3;
    if (rawTotal < 600) return 4;
    if (rawTotal < 650) return 5;
    return 6;
  }

  static final Set<int> _fullHouseScores = {
    for (var triple = 1; triple <= 6; triple++)
      for (var pair = 1; pair <= 6; pair++)
        if (triple != pair) 3 * triple + 2 * pair,
  };

  static int _straightScore(List<int> dice) {
    final sorted = List<int>.of(dice)..sort();
    if (_sameValues(sorted, const [1, 2, 3, 4, 5])) return 15;
    if (_sameValues(sorted, const [2, 3, 4, 5, 6])) return 20;
    return 0;
  }

  static bool _isFullHouse(List<int> dice) {
    final counts = <int, int>{};
    for (final die in dice) {
      counts[die] = (counts[die] ?? 0) + 1;
    }
    final groups = counts.values.toList()..sort();
    return _sameValues(groups, const [2, 3]);
  }

  static bool _sameValues(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static void _validateDice(List<int> dice) {
    if (dice.length != 5 || dice.any((die) => die < 1 || die > 6)) {
      throw ArgumentError.value(dice, 'dice', 'Fünf gültige Würfel nötig.');
    }
  }
}

class BalutPlayer {
  BalutPlayer(String name, {Map<BalutCategory, List<int?>>? entries})
    : name = name.trim(),
      _entries = {
        for (final category in BalutCategory.values)
          category: List<int?>.unmodifiable(
            entries?[category] ?? List<int?>.filled(entriesPerCategory, null),
          ),
      } {
    if (this.name.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Der Spielername darf nicht leer sein.',
      );
    }
    if (entries != null &&
        (entries.length != BalutCategory.values.length ||
            !entries.keys.toSet().containsAll(BalutCategory.values))) {
      throw ArgumentError.value(
        entries,
        'entries',
        'Alle Kategorien sind nötig.',
      );
    }
    for (final category in BalutCategory.values) {
      final values = _entries[category]!;
      if (values.length != entriesPerCategory ||
          values.whereType<int>().any(
            (score) => !BalutScoring.isValidEntry(category, score),
          )) {
        throw ArgumentError.value(
          values,
          category.name,
          'Ungültige Wertungen.',
        );
      }
    }
  }

  static const entriesPerCategory = 4;
  static const entriesPerSheet = entriesPerCategory * 7;

  final String name;
  final Map<BalutCategory, List<int?>> _entries;

  Map<BalutCategory, List<int?>> get entries => UnmodifiableMapView(_entries);

  int get filledEntryCount => _entries.values
      .expand((values) => values)
      .where((score) => score != null)
      .length;
  bool get isComplete => filledEntryCount == entriesPerSheet;
  int get rawTotal => _entries.values
      .expand((values) => values)
      .whereType<int>()
      .fold(0, (sum, score) => sum + score);

  int categoryTotal(BalutCategory category) =>
      _entries[category]!.whereType<int>().fold(0, (sum, score) => sum + score);

  int get categoryIncentivePoints {
    var points = 0;
    if (categoryTotal(BalutCategory.fours) >= 52) points += 2;
    if (categoryTotal(BalutCategory.fives) >= 65) points += 2;
    if (categoryTotal(BalutCategory.sixes) >= 78) points += 2;
    if (_allNonzero(BalutCategory.straights)) points += 4;
    if (_allNonzero(BalutCategory.fullHouse)) points += 3;
    if (categoryTotal(BalutCategory.choice) >= 100) points += 2;
    return points;
  }

  int get balutIncentivePoints =>
      _entries[BalutCategory.balut]!
          .whereType<int>()
          .where((score) => score > 0)
          .length *
      2;
  int get rawTotalIncentivePoints => BalutScoring.rawTotalIncentive(rawTotal);
  int get incentivePoints =>
      categoryIncentivePoints + balutIncentivePoints + rawTotalIncentivePoints;

  int? firstOpenIndex(BalutCategory category) {
    final index = _entries[category]!.indexOf(null);
    return index < 0 ? null : index;
  }

  BalutPlayer withEntry(BalutCategory category, int index, int score) {
    if (index < 0 || index >= entriesPerCategory) {
      throw RangeError.index(index, _entries[category]!, 'index');
    }
    if (_entries[category]![index] != null) {
      throw StateError('Dieses Feld wurde bereits gewertet.');
    }
    if (!BalutScoring.isValidEntry(category, score)) {
      throw ArgumentError.value(score, 'score', 'Ungültige Wertung.');
    }
    final changed = List<int?>.of(_entries[category]!)..[index] = score;
    return BalutPlayer(name, entries: {..._entries, category: changed});
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'entries': {
      for (final category in BalutCategory.values)
        category.name: _entries[category],
    },
  };

  factory BalutPlayer.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {'name', 'entries'});
      final name = json['name'];
      final rawEntries = json['entries'];
      if (name is! String ||
          name.trim().isEmpty ||
          name != name.trim() ||
          rawEntries is! Map) {
        throw const FormatException('Ungültiger Balut-Spieler.');
      }
      final entryMap = Map<String, dynamic>.from(rawEntries);
      _requireExactKeys(
        entryMap,
        BalutCategory.values.map((value) => value.name).toSet(),
      );
      final entries = <BalutCategory, List<int?>>{};
      for (final category in BalutCategory.values) {
        final rawValues = entryMap[category.name];
        if (rawValues is! List || rawValues.length != entriesPerCategory) {
          throw const FormatException('Ungültige Balut-Wertungen.');
        }
        entries[category] = rawValues
            .map<int?>((value) {
              if (value != null && value is! int) {
                throw const FormatException('Ungültige Balut-Wertung.');
              }
              return value as int?;
            })
            .toList(growable: false);
      }
      return BalutPlayer(name, entries: entries);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Balut-Spieler.', error);
    }
  }

  bool _allNonzero(BalutCategory category) {
    final values = _entries[category]!;
    return values.every((score) => score != null && score > 0);
  }
}

class BalutGameState implements SavedGameState {
  BalutGameState({
    required List<BalutPlayer> players,
    this.mode = GameMode.block,
    this.activePlayerIndex = 0,
    List<int> dice = const [1, 1, 1, 1, 1],
    List<bool> held = const [false, false, false, false, false],
    this.rollCount = 0,
  }) : _players = List<BalutPlayer>.unmodifiable(players),
       _dice = List<int>.unmodifiable(dice),
       _held = List<bool>.unmodifiable(held) {
    _validateState();
  }

  factory BalutGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
  }) {
    final cleaned = names.map((name) => name.trim()).toList(growable: false);
    if (cleaned.length < 2 || cleaned.length > 8) {
      throw ArgumentError('Bei Balut sind 2 bis 8 Spieler erlaubt.');
    }
    if (cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
    return BalutGameState(
      players: cleaned.map(BalutPlayer.new).toList(growable: false),
      mode: mode,
    );
  }

  static const schemaVersion = 1;

  final List<BalutPlayer> _players;
  final GameMode mode;
  final int activePlayerIndex;
  final List<int> _dice;
  final List<bool> _held;
  final int rollCount;

  @override
  List<BalutPlayer> get players => UnmodifiableListView(_players);
  List<int> get dice => UnmodifiableListView(_dice);
  List<bool> get held => UnmodifiableListView(_held);
  BalutPlayer get activePlayer => _players[activePlayerIndex];
  int get filledEntryCount =>
      _players.fold(0, (sum, player) => sum + player.filledEntryCount);

  @override
  bool get isComplete => _players.every((player) => player.isComplete);
  List<BalutPlayer> get winners {
    final best = _players
        .map((player) => player.incentivePoints)
        .reduce((a, b) => a > b ? a : b);
    return List.unmodifiable(
      _players.where((player) => player.incentivePoints == best),
    );
  }

  BalutGameState withBlockScore(
    BalutCategory category,
    int index,
    int score, {
    int? playerIndex,
  }) {
    if (mode != GameMode.block || isComplete) {
      throw StateError('Keine Blockwertung verfügbar.');
    }
    final target = playerIndex ?? activePlayerIndex;
    if (target < 0 || target >= _players.length) {
      throw RangeError.index(target, _players, 'playerIndex');
    }
    return _withPlayerScore(target, category, index, score);
  }

  BalutGameState withDigitalRoll(List<int> values) {
    if (mode != GameMode.digital || isComplete || rollCount >= 3) {
      throw StateError('Jetzt kann nicht gewürfelt werden.');
    }
    final rerolledIndices = rollCount == 0
        ? List<int>.generate(5, (index) => index)
        : [
            for (var index = 0; index < 5; index++)
              if (!_held[index]) index,
          ];
    if (values.length != rerolledIndices.length ||
        values.any((value) => value < 1 || value > 6)) {
      throw ArgumentError.value(
        values,
        'values',
        'Falsche Anzahl gültiger Würfel.',
      );
    }
    final changedDice = List<int>.of(_dice);
    for (var index = 0; index < rerolledIndices.length; index++) {
      changedDice[rerolledIndices[index]] = values[index];
    }
    return _copy(dice: changedDice, rollCount: rollCount + 1);
  }

  BalutGameState withToggledHold(int index) {
    if (mode != GameMode.digital ||
        rollCount == 0 ||
        rollCount >= 3 ||
        isComplete) {
      throw StateError('Jetzt können keine Würfel gehalten werden.');
    }
    if (index < 0 || index >= 5) throw RangeError.index(index, _held, 'index');
    final changed = List<bool>.of(_held)..[index] = !_held[index];
    return _copy(held: changed);
  }

  BalutGameState withDigitalScore(BalutCategory category) {
    if (mode != GameMode.digital || rollCount == 0 || isComplete) {
      throw StateError('Keine digitale Wertung verfügbar.');
    }
    final index = activePlayer.firstOpenIndex(category);
    if (index == null) throw StateError('Diese Kategorie ist vollständig.');
    final score = BalutScoring.score(category, _dice);
    return _withPlayerScore(
      activePlayerIndex,
      category,
      index,
      score,
      resetDigitalTurn: true,
    );
  }

  BalutGameState copy() => BalutGameState.fromJson(toJson());

  BalutGameState _withPlayerScore(
    int playerIndex,
    BalutCategory category,
    int index,
    int score, {
    bool resetDigitalTurn = false,
  }) {
    final changedPlayers = List<BalutPlayer>.of(_players);
    changedPlayers[playerIndex] = changedPlayers[playerIndex].withEntry(
      category,
      index,
      score,
    );
    final nextActive = _nextIncompletePlayer(changedPlayers, playerIndex);
    return BalutGameState(
      players: changedPlayers,
      mode: mode,
      activePlayerIndex: nextActive,
      dice: resetDigitalTurn ? const [1, 1, 1, 1, 1] : _dice,
      held: resetDigitalTurn
          ? const [false, false, false, false, false]
          : _held,
      rollCount: resetDigitalTurn ? 0 : rollCount,
    );
  }

  int _nextIncompletePlayer(List<BalutPlayer> players, int after) {
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (after + offset) % players.length;
      if (!players[index].isComplete) return index;
    }
    return after;
  }

  BalutGameState _copy({List<int>? dice, List<bool>? held, int? rollCount}) =>
      BalutGameState(
        players: _players,
        mode: mode,
        activePlayerIndex: activePlayerIndex,
        dice: dice ?? _dice,
        held: held ?? _held,
        rollCount: rollCount ?? this.rollCount,
      );

  @override
  String get gameLabel => 'Balut';
  @override
  String get modeLabel => mode.label;
  @override
  String get progressLabel =>
      '$filledEntryCount von ${_players.length * BalutPlayer.entriesPerSheet} Wertungen';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'balut',
    'schemaVersion': schemaVersion,
    'mode': mode.name,
    'players': _players.map((player) => player.toJson()).toList(),
    'activePlayerIndex': activePlayerIndex,
    'dice': _dice,
    'held': _held,
    'rollCount': rollCount,
  };

  factory BalutGameState.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {
        'type',
        'schemaVersion',
        'mode',
        'players',
        'activePlayerIndex',
        'dice',
        'held',
        'rollCount',
      });
      if (json['type'] != 'balut' || json['schemaVersion'] != schemaVersion) {
        throw const FormatException('Ungültiger Balut-Spielstand.');
      }
      final rawPlayers = json['players'];
      final rawMode = json['mode'];
      final activePlayerIndex = json['activePlayerIndex'];
      final rawDice = json['dice'];
      final rawHeld = json['held'];
      final rollCount = json['rollCount'];
      if (rawPlayers is! List ||
          rawMode is! String ||
          activePlayerIndex is! int ||
          rawDice is! List ||
          rawHeld is! List ||
          rollCount is! int) {
        throw const FormatException('Ungültiger Balut-Spielstand.');
      }
      final players = rawPlayers
          .map((value) {
            if (value is! Map) {
              throw const FormatException('Ungültiger Balut-Spieler.');
            }
            return BalutPlayer.fromJson(Map<String, dynamic>.from(value));
          })
          .toList(growable: false);
      final dice = rawDice
          .map((value) {
            if (value is! int) throw const FormatException('Ungültige Würfel.');
            return value;
          })
          .toList(growable: false);
      final held = rawHeld
          .map((value) {
            if (value is! bool) {
              throw const FormatException('Ungültige Haltemarker.');
            }
            return value;
          })
          .toList(growable: false);
      return BalutGameState(
        players: players,
        mode: GameMode.values.byName(rawMode),
        activePlayerIndex: activePlayerIndex,
        dice: dice,
        held: held,
        rollCount: rollCount,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Balut-Spielstand.', error);
    }
  }

  void _validateState() {
    if (_players.length < 2 || _players.length > 8) {
      throw ArgumentError('Bei Balut sind 2 bis 8 Spieler erlaubt.');
    }
    final names = _players.map((player) => player.name).toList();
    if (names.toSet().length != names.length ||
        activePlayerIndex < 0 ||
        activePlayerIndex >= _players.length ||
        _dice.length != 5 ||
        _dice.any((die) => die < 1 || die > 6) ||
        _held.length != 5 ||
        rollCount < 0 ||
        rollCount > 3 ||
        (rollCount == 0 && _held.any((value) => value)) ||
        (mode == GameMode.block &&
            (rollCount != 0 || _held.any((value) => value)))) {
      throw const FormatException('Ungültiger Balut-Spielstand.');
    }
  }
}

void _requireExactKeys(Map<dynamic, dynamic> json, Set<String> expected) {
  if (json.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw const FormatException('Unbekannte oder fehlende JSON-Felder.');
  }
}

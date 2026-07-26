import 'dart:collection';
import 'dart:math';

import 'game_models.dart';
import 'saved_game_state.dart';

enum DragonType { water, fire, luck }

enum DragonFieldKind { number, flame, empty }

extension DragonTypeInfo on DragonType {
  String get label => switch (this) {
    DragonType.water => 'Wasserdrache',
    DragonType.fire => 'Feuerdrache',
    DragonType.luck => 'Glücksdrache',
  };
  String get icon => switch (this) {
    DragonType.water => '💧',
    DragonType.fire => '🔥',
    DragonType.luck => '★',
  };
}

class DragonField {
  const DragonField.number(this.number, {this.mandatory = false})
    : kind = DragonFieldKind.number;
  const DragonField.flame()
    : kind = DragonFieldKind.flame,
      number = null,
      mandatory = false;
  const DragonField.empty()
    : kind = DragonFieldKind.empty,
      number = null,
      mandatory = false;

  final DragonFieldKind kind;
  final int? number;
  final bool mandatory;

  bool accepts(int die, {required DragonCard card}) {
    if (die < 1 || die > 6) throw ArgumentError.value(die, 'die');
    if (card.type == DragonType.fire && die == 6) return false;
    return switch (kind) {
      DragonFieldKind.number =>
        die == number || (die == 6 && card.type != DragonType.fire),
      DragonFieldKind.flame => die == 6,
      DragonFieldKind.empty => true,
    };
  }

  String get symbol => switch (kind) {
    DragonFieldKind.number => '${mandatory ? '★' : ''}$number',
    DragonFieldKind.flame => '🔥',
    DragonFieldKind.empty => '◇',
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'number': number,
    'mandatory': mandatory,
  };
  factory DragonField.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'kind', 'number', 'mandatory'});
    final kind = DragonFieldKind.values.byName(json['kind'] as String);
    final number = json['number'];
    final mandatory = json['mandatory'];
    if (mandatory is! bool || (number != null && number is! int)) {
      throw const FormatException('Ungültiges Drachenfeld.');
    }
    return switch (kind) {
      DragonFieldKind.number => DragonField.number(
        number as int,
        mandatory: mandatory,
      ),
      DragonFieldKind.flame => const DragonField.flame(),
      DragonFieldKind.empty => const DragonField.empty(),
    };
  }
}

class DragonCard {
  const DragonCard({
    required this.id,
    required this.type,
    required this.fields,
  });
  final int id;
  final DragonType type;
  final List<DragonField> fields;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'fields': fields.map((e) => e.toJson()).toList(),
  };
  factory DragonCard.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'id', 'type', 'fields'});
    final raw = json['fields'];
    if (json['id'] is! int || json['type'] is! String || raw is! List) {
      throw const FormatException('Ungültige Drachenkarte.');
    }
    return DragonCard(
      id: json['id'] as int,
      type: DragonType.values.byName(json['type'] as String),
      fields: raw
          .map((e) => DragonField.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}

abstract final class DragonDeck {
  static const n1 = DragonField.number(1),
      n2 = DragonField.number(2),
      n3 = DragonField.number(3),
      n4 = DragonField.number(4),
      n5 = DragonField.number(5);
  static const f = DragonField.flame(), e = DragonField.empty();
  static const m1 = DragonField.number(1, mandatory: true),
      m2 = DragonField.number(2, mandatory: true),
      m3 = DragonField.number(3, mandatory: true),
      m4 = DragonField.number(4, mandatory: true),
      m5 = DragonField.number(5, mandatory: true);
  static const cards = <DragonCard>[
    DragonCard(id: 1, type: DragonType.water, fields: [n1, e]),
    DragonCard(id: 2, type: DragonType.water, fields: [n2, n3]),
    DragonCard(id: 3, type: DragonType.water, fields: [n1, e, n4]),
    DragonCard(id: 4, type: DragonType.water, fields: [n2, n3, e]),
    DragonCard(id: 5, type: DragonType.water, fields: [f, n1]),
    DragonCard(id: 6, type: DragonType.water, fields: [n3, n4, e]),
    DragonCard(id: 7, type: DragonType.water, fields: [n1, n2, n5]),
    DragonCard(id: 8, type: DragonType.water, fields: [f, n2, n3]),
    DragonCard(id: 9, type: DragonType.water, fields: [n1, n3, n5, e]),
    DragonCard(id: 10, type: DragonType.water, fields: [n2, n4, f, e]),
    DragonCard(id: 11, type: DragonType.water, fields: [n1, n2, n3, n4]),
    DragonCard(id: 12, type: DragonType.water, fields: [f, n1, n4, e]),
    DragonCard(id: 13, type: DragonType.water, fields: [n2, n3, n5, f]),
    DragonCard(id: 14, type: DragonType.water, fields: [n1, n3, n4, n5, e]),
    DragonCard(id: 15, type: DragonType.fire, fields: [n1, n2, e, e]),
    DragonCard(id: 16, type: DragonType.fire, fields: [n2, n3, n4, e]),
    DragonCard(id: 17, type: DragonType.fire, fields: [n1, n3, n5, e]),
    DragonCard(id: 18, type: DragonType.fire, fields: [n2, n4, n5, e]),
    DragonCard(id: 19, type: DragonType.fire, fields: [n1, n2, n3, n4]),
    DragonCard(id: 20, type: DragonType.fire, fields: [n3, n4, n5, e]),
    DragonCard(id: 21, type: DragonType.fire, fields: [n1, n2, n4, n5]),
    DragonCard(id: 22, type: DragonType.fire, fields: [n2, n3, n4, n5]),
    DragonCard(id: 23, type: DragonType.fire, fields: [n1, n3, n4, e]),
    DragonCard(id: 24, type: DragonType.fire, fields: [n2, n3, n5, e]),
    DragonCard(id: 25, type: DragonType.fire, fields: [n1, n2, n3, n5]),
    DragonCard(id: 26, type: DragonType.fire, fields: [n3, n4, n5, n1]),
    DragonCard(id: 27, type: DragonType.fire, fields: [n2, n4, n5, n3]),
    DragonCard(id: 28, type: DragonType.fire, fields: [n1, n3, n4, n5]),
    DragonCard(id: 29, type: DragonType.luck, fields: [m1, n2, e, n3]),
    DragonCard(id: 30, type: DragonType.luck, fields: [m2, m3, e, n4]),
    DragonCard(id: 31, type: DragonType.luck, fields: [m1, n2, n3, e]),
    DragonCard(id: 32, type: DragonType.luck, fields: [m2, n3, m4, n5]),
    DragonCard(id: 33, type: DragonType.luck, fields: [m1, m3, e, e]),
    DragonCard(id: 34, type: DragonType.luck, fields: [m2, m4, n1, n3]),
    DragonCard(id: 35, type: DragonType.luck, fields: [m1, n2, m3, n4, e]),
    DragonCard(id: 36, type: DragonType.luck, fields: [m2, m3, m4, e]),
    DragonCard(id: 37, type: DragonType.luck, fields: [m1, m2, n3, n4, e]),
    DragonCard(id: 38, type: DragonType.luck, fields: [m3, m5, n1, e, e]),
    DragonCard(id: 39, type: DragonType.luck, fields: [m1, m2, m3, n4, e]),
    DragonCard(id: 40, type: DragonType.luck, fields: [m2, m4, m5, n1, e]),
    DragonCard(id: 41, type: DragonType.luck, fields: [m1, m3, m5, n2, e]),
  ];
}

class DragonAttempt {
  DragonAttempt({required this.card, required List<int?> placedValues})
    : _placedValues = List<int?>.unmodifiable(placedValues) {
    if (_placedValues.length != card.fields.length) {
      throw ArgumentError('Falsche Feldanzahl.');
    }
  }
  factory DragonAttempt.empty(DragonCard card) => DragonAttempt(
    card: card,
    placedValues: List<int?>.filled(card.fields.length, null),
  );
  final DragonCard card;
  final List<int?> _placedValues;
  List<int?> get placedValues => UnmodifiableListView(_placedValues);
  int get placedCount => _placedValues.whereType<int>().length;
  int get diceGold => _placedValues
      .whereType<int>()
      .where((v) => v != 6)
      .fold(0, (a, b) => a + b);
  bool get isTamed => placedCount == card.fields.length;
  bool get allMandatoryCovered {
    for (var i = 0; i < card.fields.length; i++) {
      if (card.fields[i].mandatory && _placedValues[i] == null) return false;
    }
    return true;
  }

  List<int> get openFieldIndices => [
    for (var i = 0; i < _placedValues.length; i++)
      if (_placedValues[i] == null) i,
  ];
  DragonAttempt place(int fieldIndex, int die) {
    if (fieldIndex < 0 || fieldIndex >= card.fields.length) {
      throw RangeError.index(fieldIndex, card.fields);
    }
    if (_placedValues[fieldIndex] != null) {
      throw StateError('Feld ist bereits belegt.');
    }
    if (!card.fields[fieldIndex].accepts(die, card: card)) {
      throw ArgumentError.value(die, 'die', 'Würfel passt nicht.');
    }
    final changed = List<int?>.of(_placedValues)..[fieldIndex] = die;
    return DragonAttempt(card: card, placedValues: changed);
  }

  Map<String, dynamic> toJson() => {
    'card': card.toJson(),
    'placedValues': _placedValues,
  };
  factory DragonAttempt.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'card', 'placedValues'});
    final raw = json['placedValues'];
    if (json['card'] is! Map ||
        raw is! List ||
        raw.any((e) => e != null && e is! int)) {
      throw const FormatException('Ungültiger Versuch.');
    }
    return DragonAttempt(
      card: DragonCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)),
      placedValues: raw.cast<int?>(),
    );
  }
}

class DragonPlayer {
  const DragonPlayer({
    required this.name,
    this.gold = 0,
    this.bonusGold = 0,
    this.tamedDragonIds = const [],
  });
  final String name;
  final int gold;
  final int bonusGold;
  final List<int> tamedDragonIds;
  int get totalGold => gold + bonusGold;
  int get tamedCount => tamedDragonIds.length;
  DragonPlayer copyWith({
    int? gold,
    int? bonusGold,
    List<int>? tamedDragonIds,
  }) => DragonPlayer(
    name: name,
    gold: gold ?? this.gold,
    bonusGold: bonusGold ?? this.bonusGold,
    tamedDragonIds: List<int>.unmodifiable(
      tamedDragonIds ?? this.tamedDragonIds,
    ),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'gold': gold,
    'bonusGold': bonusGold,
    'tamedDragonIds': tamedDragonIds,
  };
  factory DragonPlayer.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {
      'name',
      'gold',
      'bonusGold',
      'tamedDragonIds',
    });
    final ids = json['tamedDragonIds'];
    if (json['name'] is! String ||
        json['gold'] is! int ||
        json['bonusGold'] is! int ||
        ids is! List ||
        ids.any((e) => e is! int)) {
      throw const FormatException('Ungültiger Spieler.');
    }
    return DragonPlayer(
      name: json['name'] as String,
      gold: json['gold'] as int,
      bonusGold: json['bonusGold'] as int,
      tamedDragonIds: ids.cast<int>(),
    );
  }
}

const _unset = Object();

class DragonGameState implements SavedGameState {
  DragonGameState({
    required List<DragonPlayer> players,
    required this.mode,
    required List<DragonCard> deck,
    required this.currentCard,
    required this.attempt,
    required this.cardsInGame,
    required this.goldPool,
    this.activePlayerIndex = 0,
    this.cardGold = 0,
    List<int> triedPlayerIndices = const [],
    List<int> dice = const [],
    this.selectedDieIndex,
    this.placementsSinceRoll = 0,
    List<int> escapedDragonIds = const [],
    this.bonusWinnerIndex,
  }) : _players = List.unmodifiable(players),
       _deck = List.unmodifiable(deck),
       _tried = List.unmodifiable(triedPlayerIndices),
       _dice = List.unmodifiable(dice),
       _escaped = List.unmodifiable(escapedDragonIds) {
    if (_players.length < 2 ||
        _players.length > 4 ||
        activePlayerIndex < 0 ||
        activePlayerIndex >= _players.length ||
        goldPool < 0 ||
        cardGold < 0) {
      throw ArgumentError('Ungültiger Schuppenschatz-Spielstand.');
    }
  }
  factory DragonGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
    bool quickGame = false,
    List<DragonCard>? shuffledCards,
    Random? random,
  }) {
    final cleaned = names.map((e) => e.trim()).toList();
    if (cleaned.length < 2 ||
        cleaned.length > 4 ||
        cleaned.any((e) => e.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Schuppenschatz braucht 2 bis 4 eindeutige Spieler.');
    }
    final cards = List<DragonCard>.of(shuffledCards ?? DragonDeck.cards);
    if (shuffledCards == null) cards.shuffle(random);
    final chosen = cards.take(quickGame ? 20 : cards.length).toList();
    if (chosen.isEmpty) {
      throw ArgumentError('Mindestens eine Drachenkarte ist nötig.');
    }
    final current = chosen.removeAt(0);
    return DragonGameState(
      players: cleaned.map((e) => DragonPlayer(name: e)).toList(),
      mode: mode,
      deck: chosen,
      currentCard: current,
      attempt: DragonAttempt.empty(current),
      cardsInGame: chosen.length + 1,
      goldPool: 48,
    );
  }
  static const schemaVersion = 1;
  final List<DragonPlayer> _players;
  final GameMode mode;
  final List<DragonCard> _deck;
  final DragonCard? currentCard;
  final DragonAttempt? attempt;
  final int cardsInGame;
  final int goldPool;
  final int activePlayerIndex;
  final int cardGold;
  final List<int> _tried;
  final List<int> _dice;
  final int? selectedDieIndex;
  final int placementsSinceRoll;
  final List<int> _escaped;
  final int? bonusWinnerIndex;
  @override
  List<DragonPlayer> get players => UnmodifiableListView(_players);
  List<DragonCard> get deck => UnmodifiableListView(_deck);
  List<int> get triedPlayerIndices => UnmodifiableListView(_tried);
  List<int> get dice => UnmodifiableListView(_dice);
  List<int> get escapedDragonIds => UnmodifiableListView(_escaped);
  DragonPlayer get activePlayer => _players[activePlayerIndex];
  int get cardsRemaining => _deck.length + (currentCard == null ? 0 : 1);
  @override
  bool get isComplete => currentCard == null && _deck.isEmpty;
  List<DragonPlayer> get ranking => List<DragonPlayer>.of(_players)
    ..sort((a, b) {
      final by = b.totalGold.compareTo(a.totalGold);
      return by != 0 ? by : _players.indexOf(a).compareTo(_players.indexOf(b));
    });
  List<DragonPlayer> get winners {
    final best = _players.map((e) => e.totalGold).reduce(max);
    return List.unmodifiable(_players.where((e) => e.totalGold == best));
  }

  DragonGameState copyWith({
    List<DragonPlayer>? players,
    List<DragonCard>? deck,
    Object? currentCard = _unset,
    Object? attempt = _unset,
    int? goldPool,
    int? activePlayerIndex,
    int? cardGold,
    List<int>? triedPlayerIndices,
    List<int>? dice,
    Object? selectedDieIndex = _unset,
    int? placementsSinceRoll,
    List<int>? escapedDragonIds,
    Object? bonusWinnerIndex = _unset,
  }) => DragonGameState(
    players: players ?? _players,
    mode: mode,
    deck: deck ?? _deck,
    currentCard: identical(currentCard, _unset)
        ? this.currentCard
        : currentCard as DragonCard?,
    attempt: identical(attempt, _unset)
        ? this.attempt
        : attempt as DragonAttempt?,
    cardsInGame: cardsInGame,
    goldPool: goldPool ?? this.goldPool,
    activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
    cardGold: cardGold ?? this.cardGold,
    triedPlayerIndices: triedPlayerIndices ?? _tried,
    dice: dice ?? _dice,
    selectedDieIndex: identical(selectedDieIndex, _unset)
        ? this.selectedDieIndex
        : selectedDieIndex as int?,
    placementsSinceRoll: placementsSinceRoll ?? this.placementsSinceRoll,
    escapedDragonIds: escapedDragonIds ?? _escaped,
    bonusWinnerIndex: identical(bonusWinnerIndex, _unset)
        ? this.bonusWinnerIndex
        : bonusWinnerIndex as int?,
  );
  DragonGameState copy() => DragonGameState.fromJson(toJson());
  @override
  String get gameLabel => 'Schuppenschatz';
  @override
  String get modeLabel => mode.label;
  @override
  String get progressLabel => '$cardsRemaining Drachenkarten übrig';
  @override
  Map<String, dynamic> toJson() => {
    'type': 'dragongold',
    'schemaVersion': schemaVersion,
    'mode': mode.name,
    'players': _players.map((e) => e.toJson()).toList(),
    'deck': _deck.map((e) => e.toJson()).toList(),
    'currentCard': currentCard?.toJson(),
    'attempt': attempt?.toJson(),
    'cardsInGame': cardsInGame,
    'goldPool': goldPool,
    'activePlayerIndex': activePlayerIndex,
    'cardGold': cardGold,
    'triedPlayerIndices': _tried,
    'dice': _dice,
    'selectedDieIndex': selectedDieIndex,
    'placementsSinceRoll': placementsSinceRoll,
    'escapedDragonIds': _escaped,
    'bonusWinnerIndex': bonusWinnerIndex,
  };
  factory DragonGameState.fromJson(Map<String, dynamic> json) {
    try {
      _requireExactKeys(json, const {
        'type',
        'schemaVersion',
        'mode',
        'players',
        'deck',
        'currentCard',
        'attempt',
        'cardsInGame',
        'goldPool',
        'activePlayerIndex',
        'cardGold',
        'triedPlayerIndices',
        'dice',
        'selectedDieIndex',
        'placementsSinceRoll',
        'escapedDragonIds',
        'bonusWinnerIndex',
      });
      if (json['type'] != 'dragongold' ||
          json['schemaVersion'] != schemaVersion) {
        throw const FormatException('Ungültiger Schuppenschatz-Spielstand.');
      }
      List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
        final raw = json[key];
        if (raw is! List) throw const FormatException('Ungültige Liste.');
        return raw
            .map((e) => parse(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      final current = json['currentCard'];
      final attempt = json['attempt'];
      return DragonGameState(
        players: list('players', DragonPlayer.fromJson),
        mode: GameMode.values.byName(json['mode'] as String),
        deck: list('deck', DragonCard.fromJson),
        currentCard: current == null
            ? null
            : DragonCard.fromJson(Map<String, dynamic>.from(current as Map)),
        attempt: attempt == null
            ? null
            : DragonAttempt.fromJson(Map<String, dynamic>.from(attempt as Map)),
        cardsInGame: json['cardsInGame'] as int,
        goldPool: json['goldPool'] as int,
        activePlayerIndex: json['activePlayerIndex'] as int,
        cardGold: json['cardGold'] as int,
        triedPlayerIndices: (json['triedPlayerIndices'] as List).cast<int>(),
        dice: (json['dice'] as List).cast<int>(),
        selectedDieIndex: json['selectedDieIndex'] as int?,
        placementsSinceRoll: json['placementsSinceRoll'] as int,
        escapedDragonIds: (json['escapedDragonIds'] as List).cast<int>(),
        bonusWinnerIndex: json['bonusWinnerIndex'] as int?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Ungültiger Schuppenschatz-Spielstand.', e);
    }
  }
}

void _requireExactKeys(Map<String, dynamic> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Unerwartete oder fehlende JSON-Felder.');
  }
}

import 'dart:collection';
import 'dart:math';

import 'game_models.dart';
import 'saved_game_state.dart';

// ─── Würfel ───────────────────────────────────────────────────────────────────

enum DieColor { white, blue, green, black }

extension DieColorInfo on DieColor {
  String get label => switch (this) {
    DieColor.white => 'Weiß',
    DieColor.blue => 'Blau',
    DieColor.green => 'Grün',
    DieColor.black => 'Schwarz',
  };
}

class DieRoll {
  const DieRoll(this.value, this.color);
  final int value;
  final DieColor color;

  Map<String, dynamic> toJson() => {'value': value, 'color': color.name};
  factory DieRoll.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'value', 'color'});
    if (json['value'] is! int || json['color'] is! String) {
      throw const FormatException('Ungültiger Würfel.');
    }
    return DieRoll(
      json['value'] as int,
      DieColor.values.byName(json['color'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DieRoll && other.value == value && other.color == color;
  @override
  int get hashCode => Object.hash(value, color);
  @override
  String toString() => '${color.name}:$value';
}

/// Standard-Würfelsatz: 2 weiß + 1 blau + 1 grün + 1 schwarz
const standardDiceColors = [
  DieColor.white,
  DieColor.white,
  DieColor.blue,
  DieColor.green,
  DieColor.black,
];

// ─── Drachenarten ─────────────────────────────────────────────────────────────

enum DragonType { water, fire, luck, ghost, boss }

extension DragonTypeInfo on DragonType {
  String get label => switch (this) {
    DragonType.water => 'Wasserdrache',
    DragonType.fire => 'Feuerdrache',
    DragonType.luck => 'Glücksdrache',
    DragonType.ghost => 'Geisterdrache',
    DragonType.boss => 'Boss-Drache',
  };
  String get icon => switch (this) {
    DragonType.water => '💧',
    DragonType.fire => '🔥',
    DragonType.luck => '★',
    DragonType.ghost => '👻',
    DragonType.boss => '🐉',
  };
}

// ─── Felder ───────────────────────────────────────────────────────────────────

enum DragonFieldKind { number, flame, empty, coloredDie, sum, bossHp }

class DragonField {
  const DragonField.number(this.number, {this.mandatory = false})
    : kind = DragonFieldKind.number,
      dieColor = null,
      sumTarget = null,
      sumMinDice = 0,
      sumMaxDice = 0,
      bossHp = null;

  const DragonField.flame()
    : kind = DragonFieldKind.flame,
      number = null,
      mandatory = false,
      dieColor = null,
      sumTarget = null,
      sumMinDice = 0,
      sumMaxDice = 0,
      bossHp = null;

  const DragonField.empty()
    : kind = DragonFieldKind.empty,
      number = null,
      mandatory = false,
      dieColor = null,
      sumTarget = null,
      sumMinDice = 0,
      sumMaxDice = 0,
      bossHp = null;

  /// Farbwürfel-Feld: braucht exakt diesen Würfel mit dieser Augenzahl.
  const DragonField.coloredDie(this.dieColor, this.number)
    : kind = DragonFieldKind.coloredDie,
      mandatory = false,
      sumTarget = null,
      sumMinDice = 0,
      sumMaxDice = 0,
      bossHp = null;

  /// Summenfeld: Die Zielsumme wird über beliebig viele Würfe aufgebaut.
  /// [sumMaxDice] bleibt nur als Metadatum für alte Karten erhalten.
  const DragonField.sum(
    this.sumTarget, {
    this.sumMinDice = 2,
    this.sumMaxDice = 4,
  }) : kind = DragonFieldKind.sum,
       number = null,
       mandatory = false,
       dieColor = null,
       bossHp = null;

  /// Boss-Lebenspunkte-Feld.
  const DragonField.bossHp(this.bossHp)
    : kind = DragonFieldKind.bossHp,
      number = null,
      mandatory = false,
      dieColor = null,
      sumTarget = null,
      sumMinDice = 0,
      sumMaxDice = 0;

  final DragonFieldKind kind;
  final int? number;
  final bool mandatory;
  final DieColor? dieColor;
  final int? sumTarget;
  final int sumMinDice;
  final int sumMaxDice;
  final int? bossHp;

  /// Prüft, ob ein einzelner Würfel auf dieses Feld passt.
  /// Für Summenfelder immer false (die werden separat geprüft).
  /// [reduction] reduziert den Zielwert (Reduce-Fähigkeit).
  bool acceptsDie(
    DieRoll die, {
    required DragonCard card,
    int effectiveBossHp = 0,
    int reduction = 0,
  }) {
    if (die.value < 1 || die.value > 6) throw ArgumentError.value(die, 'die');
    return switch (kind) {
      DragonFieldKind.number =>
        die.color == DieColor.white && die.value == (number ?? 0) - reduction,
      DragonFieldKind.flame => die.color == DieColor.white && die.value == 6,
      DragonFieldKind.empty =>
        die.color == DieColor.white ||
            die.color == DieColor.blue ||
            die.color == DieColor.green ||
            die.color == DieColor.black,
      DragonFieldKind.coloredDie =>
        die.color == dieColor && die.value == (number ?? 0) - reduction,
      DragonFieldKind.sum => false, // separat geprüft
      DragonFieldKind.bossHp => die.value <= effectiveBossHp && die.value > 0,
    };
  }

  /// Prüft, ob eine Gruppe von Würfeln das Summenfeld erfüllt (oder teilweise erfüllt).
  /// existingSum = bereits auf dem Feld liegende Summe, existingCount = bereits liegende Würfel.
  /// [reduction] reduziert das Summenziel (Reduce-Fähigkeit).
  bool acceptsSum(
    List<DieRoll> dice, {
    required DragonCard card,
    int existingSum = 0,
    int existingCount = 0,
    int reduction = 0,
  }) {
    if (kind != DragonFieldKind.sum) return false;
    if (dice.length != 1) return false;
    final totalSum = existingSum + dice.fold(0, (a, d) => a + d.value);
    final target = (sumTarget ?? 0) - reduction;
    if (totalSum > target) return false;
    return true;
  }

  /// Prüft, ob ein Summenfeld mit der aktuellen Belegung vollständig ist.
  /// [reduction] reduziert das Summenziel (Reduce-Fähigkeit).
  bool isSumComplete(int currentSum, int currentCount, {int reduction = 0}) {
    if (kind != DragonFieldKind.sum) return false;
    final target = (sumTarget ?? 0) - reduction;
    return currentCount >= sumMinDice && currentSum == target;
  }

  /// Restliche Zielsumme für dieses Feld.
  int remainingTarget(int currentSum, {int reduction = 0}) =>
      kind == DragonFieldKind.sum
      ? (sumTarget ?? 0) - reduction - currentSum
      : 0;

  /// Effektiver Wert unter Berücksichtigung von Reduktionen.
  int effectiveNumber(int reduction) => switch (kind) {
    DragonFieldKind.number ||
    DragonFieldKind.coloredDie => (number ?? 0) - reduction,
    DragonFieldKind.sum => (sumTarget ?? 0) - reduction,
    _ => 0,
  };

  String get symbol => switch (kind) {
    DragonFieldKind.number => '${mandatory ? '★' : ''}$number',
    DragonFieldKind.flame => '6',
    DragonFieldKind.empty => '🔥',
    DragonFieldKind.coloredDie => '${_colorDot(dieColor!)}$number',
    DragonFieldKind.sum => '↗$sumTarget',
    DragonFieldKind.bossHp => '♥$bossHp',
  };

  String _colorDot(DieColor c) => switch (c) {
    DieColor.blue => '🔵',
    DieColor.green => '🟢',
    DieColor.black => '⚫',
    DieColor.white => '⚪',
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'number': number,
    'mandatory': mandatory,
    'dieColor': dieColor?.name,
    'sumTarget': sumTarget,
    'sumMinDice': sumMinDice,
    'sumMaxDice': sumMaxDice,
    'bossHp': bossHp,
  };

  factory DragonField.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {
      'kind',
      'number',
      'mandatory',
      'dieColor',
      'sumTarget',
      'sumMinDice',
      'sumMaxDice',
      'bossHp',
    });
    final kind = DragonFieldKind.values.byName(json['kind'] as String);
    final number = json['number'];
    final mandatory = json['mandatory'];
    if (mandatory is! bool || (number != null && number is! int)) {
      throw const FormatException('Ungültiges Drachenfeld.');
    }
    final dieColorRaw = json['dieColor'];
    final dieColor = dieColorRaw == null
        ? null
        : DieColor.values.byName(dieColorRaw as String);
    return switch (kind) {
      DragonFieldKind.number => DragonField.number(
        number as int,
        mandatory: mandatory,
      ),
      DragonFieldKind.flame => const DragonField.number(6),
      DragonFieldKind.empty => const DragonField.empty(),
      DragonFieldKind.coloredDie => DragonField.coloredDie(
        dieColor!,
        number as int,
      ),
      DragonFieldKind.sum => DragonField.sum(
        json['sumTarget'] as int,
        sumMinDice: json['sumMinDice'] as int,
        sumMaxDice: json['sumMaxDice'] as int,
      ),
      DragonFieldKind.bossHp => DragonField.bossHp(json['bossHp'] as int),
    };
  }
}

// ─── Karte ────────────────────────────────────────────────────────────────────

class DragonCard {
  const DragonCard({
    required this.id,
    required this.type,
    required this.fields,
    this.bonusPoints = 0,
  });
  final int id;
  final DragonType type;
  final List<DragonField> fields;
  final int bonusPoints;

  bool get isBoss => type == DragonType.boss;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'fields': fields.map((e) => e.toJson()).toList(),
    'bonusPoints': bonusPoints,
  };
  factory DragonCard.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'id', 'type', 'fields', 'bonusPoints'});
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
      bonusPoints: (json['bonusPoints'] as int?) ?? 0,
    );
  }
}

// ─── Deck ─────────────────────────────────────────────────────────────────────

abstract final class DragonDeck {
  // Shorthand
  static const _n1 = DragonField.number(1),
      _n2 = DragonField.number(2),
      _n3 = DragonField.number(3),
      _n4 = DragonField.number(4),
      _n5 = DragonField.number(5);
  static const _e = DragonField.empty();
  static const _m1 = DragonField.number(1, mandatory: true),
      _m2 = DragonField.number(2, mandatory: true),
      _m3 = DragonField.number(3, mandatory: true),
      _m4 = DragonField.number(4, mandatory: true);
  static const _b1 = DragonField.coloredDie(DieColor.blue, 1),
      _b2 = DragonField.coloredDie(DieColor.blue, 2),
      _b3 = DragonField.coloredDie(DieColor.blue, 3);
  static const _g1 = DragonField.coloredDie(DieColor.green, 1),
      _g2 = DragonField.coloredDie(DieColor.green, 2),
      _g3 = DragonField.coloredDie(DieColor.green, 3),
      _g4 = DragonField.coloredDie(DieColor.green, 4);
  static const _k1 = DragonField.coloredDie(DieColor.black, 1),
      _k2 = DragonField.coloredDie(DieColor.black, 2),
      _k3 = DragonField.coloredDie(DieColor.black, 3),
      _k4 = DragonField.coloredDie(DieColor.black, 4),
      _k5 = DragonField.coloredDie(DieColor.black, 5);

  static const normalCards = <DragonCard>[
    // ── Wasserdrachen (1–9): Einfach, 2–3 Felder, max ~8–12 Gold
    DragonCard(id: 1, type: DragonType.water, fields: [_b2, _e]),
    DragonCard(id: 2, type: DragonType.water, fields: [_n3, _b2]),
    DragonCard(id: 3, type: DragonType.water, fields: [_b1, _e, _n4]),
    DragonCard(id: 4, type: DragonType.water, fields: [_n2, _b3, _e]),
    DragonCard(id: 5, type: DragonType.water, fields: [_n5, _b2]),
    DragonCard(id: 6, type: DragonType.water, fields: [_b3, _e, _n3]),
    DragonCard(id: 7, type: DragonType.water, fields: [_n4, _b1, _n2]),
    DragonCard(id: 8, type: DragonType.water, fields: [_n4, _b3, _e]),
    DragonCard(id: 9, type: DragonType.water, fields: [_b1, _n4, _e, _n3]),

    // ── Feuerdrachen (10–18): Mittelschwer, Summenfeld 6–12 + 1–2 Zahlen, max ~10–16
    DragonCard(
      id: 10,
      type: DragonType.fire,
      fields: [DragonField.sum(6, sumMaxDice: 3), _n3, _e],
    ),
    DragonCard(
      id: 11,
      type: DragonType.fire,
      fields: [_n2, DragonField.sum(7, sumMaxDice: 3), _e],
    ),
    DragonCard(
      id: 12,
      type: DragonType.fire,
      fields: [DragonField.sum(8, sumMaxDice: 3), _n4, _n1],
    ),
    DragonCard(
      id: 13,
      type: DragonType.fire,
      fields: [_n2, _n4, DragonField.sum(8, sumMaxDice: 3)],
    ),
    DragonCard(
      id: 14,
      type: DragonType.fire,
      fields: [DragonField.sum(9, sumMaxDice: 3), _n2, _n3],
    ),
    DragonCard(
      id: 15,
      type: DragonType.fire,
      fields: [_n1, DragonField.sum(10, sumMaxDice: 3), _n4],
    ),
    DragonCard(
      id: 16,
      type: DragonType.fire,
      fields: [DragonField.sum(10, sumMaxDice: 3), _n3, _n3],
    ),
    DragonCard(
      id: 17,
      type: DragonType.fire,
      fields: [_n3, DragonField.sum(11, sumMaxDice: 3), _n2],
    ),
    DragonCard(
      id: 18,
      type: DragonType.fire,
      fields: [DragonField.sum(12, sumMaxDice: 3), _n4, _n2],
    ),

    // ── Glücksdrachen (19–27): Mittel–schwer, Pflichtfelder + grün, max ~10–16
    DragonCard(id: 19, type: DragonType.luck, fields: [_g2, _m1, _e]),
    DragonCard(id: 20, type: DragonType.luck, fields: [_m2, _g3, _e]),
    DragonCard(id: 21, type: DragonType.luck, fields: [_g1, _m3, _n3]),
    DragonCard(id: 22, type: DragonType.luck, fields: [_m3, _g3, _m1]),
    DragonCard(id: 23, type: DragonType.luck, fields: [_g4, _m2, _e]),
    DragonCard(id: 24, type: DragonType.luck, fields: [_m1, _g3, _m3]),
    DragonCard(id: 25, type: DragonType.luck, fields: [_g2, _m4, _n3, _e]),
    DragonCard(id: 26, type: DragonType.luck, fields: [_m2, _g2, _m3]),
    DragonCard(id: 27, type: DragonType.luck, fields: [_g4, _m2, _m3, _e]),

    // ── Geisterdrachen (28–36): Schwer, Farbwürfel + Summe 10–14 + Bonus, max ~16–22
    DragonCard(
      id: 28,
      type: DragonType.ghost,
      fields: [_k2, DragonField.sum(10), _e],
      bonusPoints: 5,
    ),
    DragonCard(
      id: 29,
      type: DragonType.ghost,
      fields: [_k4, DragonField.sum(10), _n2],
      bonusPoints: 6,
    ),
    DragonCard(
      id: 30,
      type: DragonType.ghost,
      fields: [_k1, DragonField.sum(11), _e],
      bonusPoints: 7,
    ),
    DragonCard(
      id: 31,
      type: DragonType.ghost,
      fields: [_k3, DragonField.sum(12), _n2],
      bonusPoints: 8,
    ),
    DragonCard(
      id: 32,
      type: DragonType.ghost,
      fields: [_k2, DragonField.sum(12), _e],
      bonusPoints: 9,
    ),
    DragonCard(
      id: 33,
      type: DragonType.ghost,
      fields: [_k5, DragonField.sum(12), _n1],
      bonusPoints: 10,
    ),
    DragonCard(
      id: 34,
      type: DragonType.ghost,
      fields: [_k3, DragonField.sum(10), _n3, _e],
      bonusPoints: 7,
    ),
    DragonCard(
      id: 35,
      type: DragonType.ghost,
      fields: [_k4, DragonField.sum(12), _n3],
      bonusPoints: 8,
    ),
    DragonCard(
      id: 36,
      type: DragonType.ghost,
      fields: [_k3, DragonField.sum(14), _e, _n2],
      bonusPoints: 10,
    ),
  ];

  static const bossCards = <DragonCard>[
    DragonCard(
      id: 37,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(12),
        DragonField.bossHp(16),
        DragonField.bossHp(8),
      ],
    ),
    DragonCard(
      id: 38,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(14),
        DragonField.bossHp(18),
        DragonField.bossHp(10),
      ],
    ),
    DragonCard(
      id: 39,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(10),
        DragonField.bossHp(14),
        DragonField.bossHp(18),
        DragonField.bossHp(6),
      ],
    ),
    DragonCard(
      id: 40,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(16),
        DragonField.bossHp(22),
        DragonField.bossHp(10),
      ],
    ),
    DragonCard(
      id: 41,
      type: DragonType.boss,
      fields: [
        DragonField.bossHp(18),
        DragonField.bossHp(22),
        DragonField.bossHp(14),
        DragonField.bossHp(8),
      ],
    ),
  ];

  /// Baut das 41-Karten-Deck: 36 normale gemischt, jeder 7. Platz ein Boss.
  static List<DragonCard> buildDeck({Random? random}) {
    final normals = List<DragonCard>.of(normalCards)..shuffle(random);
    final bosses = List<DragonCard>.of(bossCards);
    final deck = <DragonCard>[];
    var normalIdx = 0;
    var bossIdx = 0;
    for (var pos = 1; pos <= 41; pos++) {
      if (pos % 7 == 0 && bossIdx < bosses.length) {
        deck.add(bosses[bossIdx++]);
      } else {
        deck.add(normals[normalIdx++]);
      }
    }
    return deck;
  }

  /// Alle 41 Karten (für Kompatibilität / Tests).
  static List<DragonCard> get cards => buildDeck();
}

// ─── Fähigkeiten ──────────────────────────────────────────────────────────────

enum DragonAbility { reroll, reduce, handicap }

extension DragonAbilityInfo on DragonAbility {
  String get label => switch (this) {
    DragonAbility.reroll => '🔄 Neu würfeln',
    DragonAbility.reduce => '📉 Reduzieren',
    DragonAbility.handicap => '🎯 Gegner schwächen',
  };
  String get description => switch (this) {
    DragonAbility.reroll => 'Den letzten Wurf komplett neu würfeln.',
    DragonAbility.reduce => 'Eine Vorgabe auf der Karte um 1–3 Punkte senken.',
    DragonAbility.handicap =>
      'Der nächste Gegner würfelt mit 2 Würfeln weniger.',
  };
}

// ─── Versuch (normale Karten) ─────────────────────────────────────────────────

/// Ein belegtes Feld: welche Würfel (Werte + Farben) dort liegen.
class PlacedField {
  const PlacedField({required this.values, required this.colors});
  final List<int> values;
  final List<DieColor> colors;

  int get sum => values.fold(0, (a, b) => a + b);
  int get gold => values.fold(0, (a, b) => a + b);

  PlacedField addDice(List<DieRoll> dice) => PlacedField(
    values: [...values, ...dice.map((d) => d.value)],
    colors: [...colors, ...dice.map((d) => d.color)],
  );

  Map<String, dynamic> toJson() => {
    'values': values,
    'colors': colors.map((c) => c.name).toList(),
  };
  factory PlacedField.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'values', 'colors'});
    final vals = json['values'];
    final cols = json['colors'];
    if (vals is! List || cols is! List) {
      throw const FormatException('Ungültiges belegtes Feld.');
    }
    return PlacedField(
      values: vals.cast<int>(),
      colors: (cols.cast<String>()).map(DieColor.values.byName).toList(),
    );
  }
}

class DragonAttempt {
  DragonAttempt({required this.card, required List<PlacedField?> placed})
    : _placed = List<PlacedField?>.unmodifiable(placed) {
    if (_placed.length != card.fields.length) {
      throw ArgumentError('Falsche Feldanzahl.');
    }
  }
  factory DragonAttempt.empty(DragonCard card) => DragonAttempt(
    card: card,
    placed: List<PlacedField?>.filled(card.fields.length, null),
  );

  final DragonCard card;
  final List<PlacedField?> _placed;
  List<PlacedField?> get placed => UnmodifiableListView(_placed);

  int get placedCount => _placed.whereType<PlacedField>().length;
  int get diceGold =>
      _placed.whereType<PlacedField>().fold(0, (a, p) => a + p.gold);

  bool isTamed(List<int> fieldReductions) {
    var effectivePlaced = 0;
    for (var i = 0; i < card.fields.length; i++) {
      final field = card.fields[i];
      if (_placed[i] != null) {
        effectivePlaced++;
      } else if (_isReducedToZero(field, i, fieldReductions)) {
        effectivePlaced++;
      }
    }
    if (effectivePlaced != card.fields.length) return false;
    for (var i = 0; i < card.fields.length; i++) {
      final field = card.fields[i];
      final pf = _placed[i];
      if (pf == null) continue; // reduced to zero, skip
      if (field.kind == DragonFieldKind.sum &&
          !field.isSumComplete(
            pf.sum,
            pf.values.length,
            reduction: fieldReductions.length > i ? fieldReductions[i] : 0,
          )) {
        return false;
      }
    }
    return true;
  }

  bool _isReducedToZero(DragonField field, int i, List<int> fieldReductions) {
    if (field.kind != DragonFieldKind.number &&
        field.kind != DragonFieldKind.coloredDie) {
      return false;
    }
    final reduction = fieldReductions.length > i ? fieldReductions[i] : 0;
    return field.effectiveNumber(reduction) <= 0;
  }

  bool allMandatoryCovered(List<int> fieldReductions) {
    for (var i = 0; i < card.fields.length; i++) {
      if (!card.fields[i].mandatory) continue;
      if (_placed[i] != null) continue;
      if (_isReducedToZero(card.fields[i], i, fieldReductions)) continue;
      return false;
    }
    return true;
  }

  /// Offene Felder: null (noch nichts) ODER Summenfeld das noch nicht vollständig ist.
  List<int> get openFieldIndices => [
    for (var i = 0; i < _placed.length; i++)
      if (_isFieldOpen(i)) i,
  ];

  bool _isFieldOpen(int i) {
    final pf = _placed[i];
    if (pf == null) return true;
    final field = card.fields[i];
    if (field.kind == DragonFieldKind.sum &&
        !field.isSumComplete(pf.sum, pf.values.length)) {
      return true;
    }
    return false;
  }

  /// Legt einen einzelnen Würfel auf ein Feld (number/flame/empty/coloredDie/bossHp).
  DragonAttempt placeSingle(int fieldIndex, DieRoll die, {int reduction = 0}) {
    _checkFieldIndex(fieldIndex);
    if (_placed[fieldIndex] != null) {
      throw StateError('Feld ist bereits belegt.');
    }
    if (!card.fields[fieldIndex].acceptsDie(
      die,
      card: card,
      reduction: reduction,
    )) {
      throw ArgumentError.value(die, 'die', 'Würfel passt nicht.');
    }
    return _withPlaced(
      fieldIndex,
      PlacedField(values: [die.value], colors: [die.color]),
    );
  }

  /// Legt mehrere Würfel auf ein Summenfeld. Akkumuliert bei bereits liegenden Würfeln.
  DragonAttempt placeSum(
    int fieldIndex,
    List<DieRoll> dice, {
    int reduction = 0,
  }) {
    _checkFieldIndex(fieldIndex);
    final existing = _placed[fieldIndex];
    final field = card.fields[fieldIndex];
    final existingSum = existing?.sum ?? 0;
    final existingCount = existing?.values.length ?? 0;
    if (field.kind != DragonFieldKind.sum) {
      throw ArgumentError('Nur Summenfelder akzeptieren mehrere Würfel.');
    }
    if (field.isSumComplete(existingSum, existingCount, reduction: reduction)) {
      throw StateError('Summenfeld ist bereits vollständig.');
    }
    if (!field.acceptsSum(
      dice,
      card: card,
      existingSum: existingSum,
      existingCount: existingCount,
      reduction: reduction,
    )) {
      throw ArgumentError('Würfelsumme passt nicht.');
    }
    final merged = existing != null
        ? existing.addDice(dice)
        : PlacedField(
            values: dice.map((d) => d.value).toList(),
            colors: dice.map((d) => d.color).toList(),
          );
    return _withPlaced(fieldIndex, merged);
  }

  void _checkFieldIndex(int i) {
    if (i < 0 || i >= card.fields.length) {
      throw RangeError.index(i, card.fields);
    }
  }

  DragonAttempt _withPlaced(int index, PlacedField pf) {
    final changed = List<PlacedField?>.of(_placed)..[index] = pf;
    return DragonAttempt(card: card, placed: changed);
  }

  Map<String, dynamic> toJson() => {
    'card': card.toJson(),
    'placed': _placed.map((p) => p?.toJson()).toList(),
  };
  factory DragonAttempt.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {'card', 'placed'});
    final raw = json['placed'];
    if (json['card'] is! Map || raw is! List) {
      throw const FormatException('Ungültiger Versuch.');
    }
    return DragonAttempt(
      card: DragonCard.fromJson(Map<String, dynamic>.from(json['card'] as Map)),
      placed: raw
          .map(
            (e) => e == null
                ? null
                : PlacedField.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

// ─── Spieler ──────────────────────────────────────────────────────────────────

class DragonPlayer {
  const DragonPlayer({
    required this.name,
    this.gold = 0,
    this.bonusGold = 0,
    this.tamedDragonIds = const [],
    this.usedAbilities = const [],
  });
  final String name;
  final int gold;
  final int bonusGold;
  final List<int> tamedDragonIds;
  final List<DragonAbility> usedAbilities;

  int get totalGold => gold + bonusGold;
  int get tamedCount => tamedDragonIds.length;
  bool canUse(DragonAbility a) => !usedAbilities.contains(a);

  DragonPlayer copyWith({
    int? gold,
    int? bonusGold,
    List<int>? tamedDragonIds,
    List<DragonAbility>? usedAbilities,
  }) => DragonPlayer(
    name: name,
    gold: gold ?? this.gold,
    bonusGold: bonusGold ?? this.bonusGold,
    tamedDragonIds: List<int>.unmodifiable(
      tamedDragonIds ?? this.tamedDragonIds,
    ),
    usedAbilities: List<DragonAbility>.unmodifiable(
      usedAbilities ?? this.usedAbilities,
    ),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'gold': gold,
    'bonusGold': bonusGold,
    'tamedDragonIds': tamedDragonIds,
    'usedAbilities': usedAbilities.map((a) => a.name).toList(),
  };
  factory DragonPlayer.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, const {
      'name',
      'gold',
      'bonusGold',
      'tamedDragonIds',
      'usedAbilities',
    });
    final ids = json['tamedDragonIds'];
    final abilities = json['usedAbilities'];
    if (json['name'] is! String ||
        json['gold'] is! int ||
        json['bonusGold'] is! int ||
        ids is! List ||
        ids.any((e) => e is! int) ||
        abilities is! List) {
      throw const FormatException('Ungültiger Spieler.');
    }
    return DragonPlayer(
      name: json['name'] as String,
      gold: json['gold'] as int,
      bonusGold: json['bonusGold'] as int,
      tamedDragonIds: ids.cast<int>(),
      usedAbilities: (abilities.cast<String>())
          .map(DragonAbility.values.byName)
          .toList(),
    );
  }
}

// ─── Spielzustand ─────────────────────────────────────────────────────────────

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
    List<DieRoll> dice = const [],
    List<int> selectedDieIndices = const [],
    this.placementsSinceRoll = 0,
    List<int> escapedDragonIds = const [],
    this.bonusWinnerIndex,
    List<int> bossRemainingHp = const [],
    this.handicapDice = 0,
    List<int> fieldReductions = const [],
    List<int> sumFieldsReducedThisRoll = const [],
    List<int> bossFieldsUsedThisRoll = const [],
    this.rollCount = 0,
  }) : _players = List.unmodifiable(players),
       _deck = List.unmodifiable(deck),
       _tried = List.unmodifiable(triedPlayerIndices),
       _dice = List.unmodifiable(dice),
       _selected = List.unmodifiable(selectedDieIndices),
       _escaped = List.unmodifiable(escapedDragonIds),
       _bossHp = List.unmodifiable(bossRemainingHp),
       _reductions = List.unmodifiable(fieldReductions),
       _sumFieldsReduced = List.unmodifiable(sumFieldsReducedThisRoll),
       _bossFieldsUsed = List.unmodifiable(bossFieldsUsedThisRoll) {
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
    final cards = shuffledCards ?? DragonDeck.buildDeck(random: random);
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
      attempt: current.isBoss ? null : DragonAttempt.empty(current),
      cardsInGame: chosen.length + 1,
      goldPool: 48,
      bossRemainingHp: current.isBoss
          ? current.fields.map((f) => f.bossHp ?? 0).toList()
          : const [],
      fieldReductions: List<int>.filled(current.fields.length, 0),
    );
  }

  static const schemaVersion = 4;
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
  final List<DieRoll> _dice;
  final List<int> _selected;
  final int placementsSinceRoll;
  final List<int> _escaped;
  final int? bonusWinnerIndex;
  final List<int> _bossHp;
  final int handicapDice;
  final List<int> _reductions;
  final List<int> _sumFieldsReduced;
  final List<int> _bossFieldsUsed;
  final int rollCount;

  @override
  List<DragonPlayer> get players => UnmodifiableListView(_players);
  List<DragonCard> get deck => UnmodifiableListView(_deck);
  List<int> get triedPlayerIndices => UnmodifiableListView(_tried);
  List<DieRoll> get dice => UnmodifiableListView(_dice);
  List<int> get selectedDieIndices => UnmodifiableListView(_selected);
  List<int> get escapedDragonIds => UnmodifiableListView(_escaped);
  List<int> get bossRemainingHp => UnmodifiableListView(_bossHp);
  List<int> get fieldReductions => UnmodifiableListView(_reductions);
  List<int> get sumFieldsReducedThisRoll =>
      UnmodifiableListView(_sumFieldsReduced);
  List<int> get bossFieldsUsedThisRoll => UnmodifiableListView(_bossFieldsUsed);

  DragonPlayer get activePlayer => _players[activePlayerIndex];
  int get cardsRemaining => _deck.length + (currentCard == null ? 0 : 1);
  bool get isBossCard => currentCard?.isBoss ?? false;
  bool get bossDefeated =>
      isBossCard && _bossHp.isNotEmpty && _bossHp.every((hp) => hp <= 0);

  int effectiveFieldValue(int fieldIndex) {
    final card = currentCard;
    if (card == null || fieldIndex >= _reductions.length) return 0;
    return card.fields[fieldIndex].effectiveNumber(_reductions[fieldIndex]);
  }

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
    List<DieRoll>? dice,
    List<int>? selectedDieIndices,
    int? placementsSinceRoll,
    List<int>? escapedDragonIds,
    Object? bonusWinnerIndex = _unset,
    List<int>? bossRemainingHp,
    int? handicapDice,
    List<int>? fieldReductions,
    List<int>? sumFieldsReducedThisRoll,
    List<int>? bossFieldsUsedThisRoll,
    int? rollCount,
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
    selectedDieIndices: selectedDieIndices ?? _selected,
    placementsSinceRoll: placementsSinceRoll ?? this.placementsSinceRoll,
    escapedDragonIds: escapedDragonIds ?? _escaped,
    bonusWinnerIndex: identical(bonusWinnerIndex, _unset)
        ? this.bonusWinnerIndex
        : bonusWinnerIndex as int?,
    bossRemainingHp: bossRemainingHp ?? _bossHp,
    handicapDice: handicapDice ?? this.handicapDice,
    fieldReductions: fieldReductions ?? _reductions,
    sumFieldsReducedThisRoll: sumFieldsReducedThisRoll ?? _sumFieldsReduced,
    bossFieldsUsedThisRoll: bossFieldsUsedThisRoll ?? _bossFieldsUsed,
    rollCount: rollCount ?? this.rollCount,
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
    'dice': _dice.map((d) => d.toJson()).toList(),
    'selectedDieIndices': _selected,
    'placementsSinceRoll': placementsSinceRoll,
    'escapedDragonIds': _escaped,
    'bonusWinnerIndex': bonusWinnerIndex,
    'bossRemainingHp': _bossHp,
    'handicapDice': handicapDice,
    'fieldReductions': _reductions,
    'sumFieldsReducedThisRoll': _sumFieldsReduced,
    'bossFieldsUsedThisRoll': _bossFieldsUsed,
    'rollCount': rollCount,
  };

  factory DragonGameState.fromJson(Map<String, dynamic> json) {
    try {
      final version = json['schemaVersion'];
      if (json['type'] != 'dragongold' ||
          (version != 2 && version != 3 && version != schemaVersion)) {
        throw const FormatException('Ungültiger Schuppenschatz-Spielstand.');
      }
      final expectedKeys = <String>{
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
        'selectedDieIndices',
        'placementsSinceRoll',
        'escapedDragonIds',
        'bonusWinnerIndex',
        'bossRemainingHp',
        'handicapDice',
        'fieldReductions',
      };
      if (version == schemaVersion) {
        expectedKeys.add('sumFieldsReducedThisRoll');
        expectedKeys.add('bossFieldsUsedThisRoll');
        expectedKeys.add('rollCount');
      }
      if (version == 3) {
        expectedKeys.add('sumFieldsReducedThisRoll');
      }
      _requireExactKeys(json, expectedKeys);
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
        dice: list('dice', DieRoll.fromJson),
        selectedDieIndices: (json['selectedDieIndices'] as List).cast<int>(),
        placementsSinceRoll: json['placementsSinceRoll'] as int,
        escapedDragonIds: (json['escapedDragonIds'] as List).cast<int>(),
        bonusWinnerIndex: json['bonusWinnerIndex'] as int?,
        bossRemainingHp: (json['bossRemainingHp'] as List).cast<int>(),
        handicapDice: (json['handicapDice'] as int?) ?? 0,
        fieldReductions: (json['fieldReductions'] as List).cast<int>(),
        sumFieldsReducedThisRoll: version >= 3
            ? (json['sumFieldsReducedThisRoll'] as List).cast<int>()
            : const [],
        bossFieldsUsedThisRoll: version >= 4
            ? (json['bossFieldsUsedThisRoll'] as List).cast<int>()
            : const [],
        rollCount: (json['rollCount'] as int?) ?? 0,
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

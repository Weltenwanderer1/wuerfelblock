import 'ten_thousand_rules.dart';

class TenThousandDiceTurn {
  TenThousandDiceTurn({
    required List<int> dice,
    required List<bool> selected,
    required List<bool> locked,
    required this.hasRolled,
    required this.roundPoints,
    required this.mustRoll,
  }) : dice = List<int>.unmodifiable(dice),
       selected = List<bool>.unmodifiable(selected),
       locked = List<bool>.unmodifiable(locked) {
    _validate();
  }

  factory TenThousandDiceTurn.fresh() => TenThousandDiceTurn(
    dice: TenThousandRules.initialDice,
    selected: TenThousandRules.initialSelection,
    locked: const [false, false, false, false, false, false],
    hasRolled: false,
    roundPoints: 0,
    mustRoll: false,
  );

  /// Immer 6 Würfel — gelockte behalten ihren Wert, nicht-gelockte werden
  /// beim nächsten Wurf neu gewürfelt.
  final List<int> dice;

  /// Welche nicht-gelockten Würfel in diesem Wurf zur Wertung ausgewählt sind.
  final List<bool> selected;

  /// Bereits gewertete Würfel — bleiben sichtbar, werden nicht neu gewürfelt.
  final List<bool> locked;
  final bool hasRolled;
  final int roundPoints;
  final bool mustRoll;

  /// Anzahl der Würfel, die beim nächsten Wurf gewürfelt werden.
  int get activeDiceCount {
    var count = 0;
    for (final isLocked in locked) {
      if (!isLocked) count++;
    }
    return count;
  }

  bool get isFresh =>
      !hasRolled &&
      roundPoints == 0 &&
      !mustRoll &&
      activeDiceCount == TenThousandRules.diceCount;

  List<int> get selectedValues => [
    for (var index = 0; index < dice.length; index++)
      if (!locked[index] && selected[index]) dice[index],
  ];

  int? get selectedScore => _scoreSelection(selectedValues);

  bool get isMacke {
    if (!hasRolled) return false;
    final activeValues = [
      for (var index = 0; index < dice.length; index++)
        if (!locked[index]) dice[index],
    ];
    if (activeValues.isEmpty) return false;
    final counts = _counts(activeValues);
    if (counts[1] != null || counts[5] != null) return false;
    if (counts.values.any((count) => count >= 3)) return false;
    if (activeValues.length == TenThousandRules.diceCount &&
        _isStraight(counts)) {
      return false;
    }
    if (activeValues.length == TenThousandRules.diceCount &&
        _isThreePairs(counts)) {
      return false;
    }
    return true;
  }

  bool get canBank =>
      hasRolled && selectedValues.isNotEmpty && selectedScore != null;

  /// Punkte die beim Sichern verbucht würden (Runde + offene Auswahl).
  int get securePoints => roundPoints + (selectedScore ?? 0);

  bool get canSecure =>
      securePoints >= TenThousandRules.minimumBankScore &&
      !mustRoll &&
      !isMacke;

  TenThousandDiceTurn rolled(List<int> values) {
    if (hasRolled) {
      throw StateError('Die aktuellen Würfel müssen zuerst gewertet werden.');
    }
    final activeCount = activeDiceCount;
    if (values.length != activeCount ||
        values.any(
          (value) =>
              value < TenThousandRules.minimumDieValue ||
              value > TenThousandRules.maximumDieValue,
        )) {
      throw ArgumentError.value(values, 'values', 'Ungültiger Wurf.');
    }
    final newDice = List<int>.of(dice);
    var valueIndex = 0;
    for (var index = 0; index < dice.length; index++) {
      if (!locked[index]) {
        newDice[index] = values[valueIndex++];
      }
    }
    return TenThousandDiceTurn(
      dice: newDice,
      selected: List<bool>.filled(dice.length, false),
      locked: locked,
      hasRolled: true,
      roundPoints: roundPoints,
      mustRoll: false,
    );
  }

  TenThousandDiceTurn toggled(int index) {
    if (!hasRolled || locked[index] || index < 0 || index >= dice.length) {
      throw RangeError.index(index, dice, 'index');
    }
    final next = List<bool>.of(selected)..[index] = !selected[index];
    return TenThousandDiceTurn(
      dice: dice,
      selected: next,
      locked: locked,
      hasRolled: hasRolled,
      roundPoints: roundPoints,
      mustRoll: mustRoll,
    );
  }

  TenThousandDiceTurn banked() {
    if (!canBank) throw StateError('Die Auswahl ist keine gültige Wertung.');
    final score = _scoreSelection(selectedValues)!;
    final newLocked = List<bool>.of(locked);
    for (var index = 0; index < dice.length; index++) {
      if (!locked[index] && selected[index]) newLocked[index] = true;
    }
    final allLocked = newLocked.every((isLocked) => isLocked);
    return TenThousandDiceTurn(
      dice: dice,
      selected: List<bool>.filled(dice.length, false),
      locked: allLocked ? List<bool>.filled(dice.length, false) : newLocked,
      hasRolled: false,
      roundPoints: roundPoints + score,
      mustRoll: allLocked,
    );
  }

  static int? scoreSelection(List<int> values) => _scoreSelection(values);

  /// Wertet eine Auswahl — Verdopplung gilt nur innerhalb eines Wurfs.
  static int? _scoreSelection(List<int> values) {
    if (values.isEmpty ||
        values.any(
          (value) =>
              value < TenThousandRules.minimumDieValue ||
              value > TenThousandRules.maximumDieValue,
        )) {
      return null;
    }
    final counts = _counts(values);
    if (values.length == TenThousandRules.diceCount && _isStraight(counts)) {
      return 1000;
    }
    if (values.length == TenThousandRules.diceCount && _isThreePairs(counts)) {
      return 500;
    }

    var score = 0;
    for (final entry in counts.entries) {
      final face = entry.key;
      final count = entry.value;
      if (count >= 3) {
        score += _paschValue(face, count);
      } else if (face == 1) {
        score += count * 100;
      } else if (face == 5) {
        score += count * 50;
      } else {
        return null;
      }
    }
    return score == 0 ? null : score;
  }

  static int _paschValue(int face, int count) {
    final base = face == 1 ? 1000 : face * 100;
    return base * (1 << (count - 3));
  }

  static Map<int, int> _counts(List<int> values) {
    final counts = <int, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts;
  }

  static bool _isStraight(Map<int, int> counts) =>
      counts.length == 6 && counts.values.every((count) => count == 1);

  static bool _isThreePairs(Map<int, int> counts) =>
      counts.length == 3 && counts.values.every((count) => count == 2);

  Map<String, dynamic> toJson() => {
    'dice': dice,
    'selected': selected,
    'locked': locked,
    'hasRolled': hasRolled,
    'roundPoints': roundPoints,
    'mustRoll': mustRoll,
  };

  factory TenThousandDiceTurn.fromJson(Map<String, dynamic> json) {
    try {
      final rawLocked = json['locked'] as List?;
      final locked = rawLocked != null
          ? rawLocked.map((value) => value as bool).toList()
          : List<bool>.filled(TenThousandRules.diceCount, false);
      return TenThousandDiceTurn(
        dice: (json['dice'] as List).map((value) => value as int).toList(),
        selected: (json['selected'] as List)
            .map((value) => value as bool)
            .toList(),
        locked: locked,
        hasRolled: json['hasRolled'] as bool,
        roundPoints: json['roundPoints'] as int,
        mustRoll: json['mustRoll'] as bool,
      );
    } catch (error) {
      throw FormatException('Ungültiger digitaler 10.000-Zug.', error);
    }
  }

  void _validate() {
    if (dice.length != TenThousandRules.diceCount ||
        dice.any(
          (value) =>
              value < TenThousandRules.minimumDieValue ||
              value > TenThousandRules.maximumDieValue,
        ) ||
        selected.length != dice.length ||
        locked.length != dice.length ||
        roundPoints < 0 ||
        roundPoints % TenThousandRules.scoreIncrement != 0 ||
        (!hasRolled && selected.any((value) => value)) ||
        (hasRolled && mustRoll)) {
      throw const FormatException('Ungültiger digitaler 10.000-Zug.');
    }
  }
}

class TenThousandDiceTurn {
  TenThousandDiceTurn({
    required List<int> dice,
    required List<bool> selected,
    required this.hasRolled,
    required this.roundPoints,
    required Map<int, int> paschCounts,
    required this.mustRoll,
  }) : dice = List<int>.unmodifiable(dice),
       selected = List<bool>.unmodifiable(selected),
       paschCounts = Map<int, int>.unmodifiable(paschCounts) {
    _validate();
  }

  factory TenThousandDiceTurn.fresh() => TenThousandDiceTurn(
    dice: const [1, 1, 1, 1, 1, 1],
    selected: const [false, false, false, false, false, false],
    hasRolled: false,
    roundPoints: 0,
    paschCounts: const {},
    mustRoll: false,
  );

  final List<int> dice;
  final List<bool> selected;
  final bool hasRolled;
  final int roundPoints;
  final Map<int, int> paschCounts;
  final bool mustRoll;

  int get activeDiceCount => dice.length;
  bool get isFresh =>
      !hasRolled &&
      roundPoints == 0 &&
      paschCounts.isEmpty &&
      !mustRoll &&
      dice.length == 6;
  List<int> get selectedValues => [
    for (var index = 0; index < dice.length; index++)
      if (selected[index]) dice[index],
  ];

  int? get selectedScore =>
      _scoreWithPasches(selectedValues, paschCounts)?.score;

  bool get isMacke {
    if (!hasRolled) return false;
    final counts = _counts(dice);
    if (counts[1] != null || counts[5] != null) return false;
    if (counts.values.any((count) => count >= 3)) {
      return false;
    }
    if (dice.any(paschCounts.containsKey)) {
      return false;
    }
    if (dice.length == 6 && _isThreePairs(counts)) {
      return false;
    }
    return true;
  }

  bool get canBank =>
      hasRolled && selectedValues.isNotEmpty && selectedScore != null;
  bool get canSecure => roundPoints >= 350 && !hasRolled && !mustRoll;

  TenThousandDiceTurn rolled(List<int> values) {
    if (hasRolled) {
      throw StateError('Die aktuellen Würfel müssen zuerst gewertet werden.');
    }
    if (values.length != activeDiceCount ||
        values.any((value) => value < 1 || value > 6)) {
      throw ArgumentError.value(values, 'values', 'Ungültiger Wurf.');
    }
    return TenThousandDiceTurn(
      dice: values,
      selected: List<bool>.filled(values.length, false),
      hasRolled: true,
      roundPoints: roundPoints,
      paschCounts: paschCounts,
      mustRoll: false,
    );
  }

  TenThousandDiceTurn toggled(int index) {
    if (!hasRolled || index < 0 || index >= dice.length) {
      throw RangeError.index(index, dice, 'index');
    }
    final next = List<bool>.of(selected)..[index] = !selected[index];
    return TenThousandDiceTurn(
      dice: dice,
      selected: next,
      hasRolled: hasRolled,
      roundPoints: roundPoints,
      paschCounts: paschCounts,
      mustRoll: mustRoll,
    );
  }

  TenThousandDiceTurn banked() {
    if (!canBank) throw StateError('Die Auswahl ist keine gültige Wertung.');
    final result = _scoreWithPasches(selectedValues, paschCounts)!;
    final remaining = dice.length - selectedValues.length;
    final hotDice = remaining == 0;
    final nextCount = hotDice ? 6 : remaining;
    return TenThousandDiceTurn(
      dice: List<int>.filled(nextCount, 1),
      selected: List<bool>.filled(nextCount, false),
      hasRolled: false,
      roundPoints: roundPoints + result.score,
      paschCounts: result.paschCounts,
      mustRoll: hotDice,
    );
  }

  static int? scoreSelection(List<int> values) =>
      _scoreWithPasches(values, const {})?.score;

  static ({int score, Map<int, int> paschCounts})? _scoreWithPasches(
    List<int> values,
    Map<int, int> existingPasches,
  ) {
    if (values.isEmpty || values.any((value) => value < 1 || value > 6)) {
      return null;
    }
    final counts = _counts(values);
    if (values.length == 6 && _isStraight(counts)) {
      return (score: 1000, paschCounts: Map<int, int>.of(existingPasches));
    }
    if (values.length == 6 && _isThreePairs(counts)) {
      return (score: 500, paschCounts: Map<int, int>.of(existingPasches));
    }

    var score = 0;
    final pasches = Map<int, int>.of(existingPasches);
    for (final entry in counts.entries) {
      final face = entry.key;
      final count = entry.value;
      final existing = pasches[face] ?? 0;
      if (existing >= 3) {
        final oldValue = _paschValue(face, existing);
        final newCount = existing + count;
        score += _paschValue(face, newCount) - oldValue;
        pasches[face] = newCount;
      } else if (count >= 3) {
        score += _paschValue(face, count);
        pasches[face] = count;
      } else if (face == 1) {
        score += count * 100;
      } else if (face == 5) {
        score += count * 50;
      } else {
        return null;
      }
    }
    return score == 0 ? null : (score: score, paschCounts: pasches);
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
    'hasRolled': hasRolled,
    'roundPoints': roundPoints,
    'paschCounts': {
      for (final entry in paschCounts.entries) '${entry.key}': entry.value,
    },
    'mustRoll': mustRoll,
  };

  factory TenThousandDiceTurn.fromJson(Map<String, dynamic> json) {
    try {
      return TenThousandDiceTurn(
        dice: (json['dice'] as List).map((value) => value as int).toList(),
        selected: (json['selected'] as List)
            .map((value) => value as bool)
            .toList(),
        hasRolled: json['hasRolled'] as bool,
        roundPoints: json['roundPoints'] as int,
        paschCounts: Map<String, dynamic>.from(
          json['paschCounts'] as Map,
        ).map((key, value) => MapEntry(int.parse(key), value as int)),
        mustRoll: json['mustRoll'] as bool,
      );
    } catch (error) {
      throw FormatException('Ungültiger digitaler 10.000-Zug.', error);
    }
  }

  void _validate() {
    if (dice.isEmpty ||
        dice.length > 6 ||
        dice.any((value) => value < 1 || value > 6) ||
        selected.length != dice.length ||
        roundPoints < 0 ||
        roundPoints % 50 != 0 ||
        paschCounts.entries.any(
          (entry) => entry.key < 1 || entry.key > 6 || entry.value < 3,
        ) ||
        (!hasRolled && selected.any((value) => value)) ||
        (hasRolled && mustRoll)) {
      throw const FormatException('Ungültiger digitaler 10.000-Zug.');
    }
  }
}

import '../models/game_models.dart';

class ScoringEngine {
  static final Map<(RuleSet, ScoreCategory), Set<int>> _allowedCache = {};

  static Set<int> allowedScores(RuleSet rules, ScoreCategory category) =>
      _allowedCache.putIfAbsent((rules, category), () {
        final values = <int>{0};
        for (var encoded = 0; encoded < 7776; encoded++) {
          var remainder = encoded;
          final dice = List<int>.generate(5, (_) {
            final die = remainder % 6 + 1;
            remainder ~/= 6;
            return die;
          });
          values.add(score(rules, category, dice));
        }
        return Set.unmodifiable(values);
      });

  static int score(RuleSet rules, ScoreCategory category, List<int> dice) {
    if (dice.length != 5 || dice.any((die) => die < 1 || die > 6)) {
      throw ArgumentError('Es werden fünf Würfelwerte von 1 bis 6 benötigt.');
    }
    final counts = <int, int>{
      for (var value = 1; value <= 6; value++) value: 0,
    };
    for (final die in dice) {
      counts[die] = counts[die]! + 1;
    }
    final sum = dice.fold(0, (a, b) => a + b);
    if (category.isUpper) {
      final face = category.index + 1;
      return counts[face]! * face;
    }
    return switch (category) {
      ScoreCategory.onePair =>
        _pairs(counts).isEmpty ? 0 : _pairs(counts).first * 2,
      ScoreCategory.twoPairs =>
        _pairs(counts).length < 2
            ? 0
            : (_pairs(counts)[0] + _pairs(counts)[1]) * 2,
      ScoreCategory.threeOfAKind => _ofAKind(
        counts,
        3,
        rules == RuleSet.kniffel ? sum : null,
      ),
      ScoreCategory.fourOfAKind => _ofAKind(
        counts,
        4,
        rules == RuleSet.kniffel ? sum : null,
      ),
      ScoreCategory.smallStraight =>
        rules == RuleSet.kniffel
            ? (_containsRun(counts, 4) ? 30 : 0)
            : (_exact(dice, [1, 2, 3, 4, 5]) ? 15 : 0),
      ScoreCategory.largeStraight =>
        rules == RuleSet.kniffel
            ? (_containsRun(counts, 5) ? 40 : 0)
            : (_exact(dice, [2, 3, 4, 5, 6]) ? 20 : 0),
      ScoreCategory.fullHouse =>
        counts.values.toSet().containsAll({2, 3})
            ? (rules == RuleSet.kniffel ? 25 : sum)
            : 0,
      ScoreCategory.chance => sum,
      ScoreCategory.yatzy => counts.values.contains(5) ? 50 : 0,
      _ => 0,
    };
  }

  static List<int> _pairs(Map<int, int> counts) => counts.entries
      .where((entry) => entry.value >= 2)
      .map((entry) => entry.key)
      .toList()
      .reversed
      .toList();

  static int _ofAKind(Map<int, int> counts, int amount, int? fullSum) {
    final values = counts.entries
        .where((entry) => entry.value >= amount)
        .map((entry) => entry.key);
    if (values.isEmpty) return 0;
    return fullSum ?? values.reduce((a, b) => a > b ? a : b) * amount;
  }

  static bool _containsRun(Map<int, int> counts, int length) {
    var run = 0;
    for (var value = 1; value <= 6; value++) {
      run = counts[value]! > 0 ? run + 1 : 0;
      if (run >= length) return true;
    }
    return false;
  }

  static bool _exact(List<int> dice, List<int> expected) {
    final sorted = [...dice]..sort();
    return List.generate(
      5,
      (index) => sorted[index] == expected[index],
    ).every((value) => value);
  }

  static int bonus(int upperTotal) => upperTotal >= 63 ? 35 : 0;
}

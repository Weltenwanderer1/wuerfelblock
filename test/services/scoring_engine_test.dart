import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/services/scoring_engine.dart';

void main() {
  group('Kniffel-Wertung', () {
    const rules = RuleSet.kniffel;
    test('wertet oberen Block und Chance', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.threes, [3, 3, 3, 2, 6]),
        9,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.chance, [3, 3, 3, 2, 6]),
        17,
      );
    });
    test('wertet Pasche mit Gesamtsumme', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.threeOfAKind, [4, 4, 4, 2, 3]),
        17,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.fourOfAKind, [5, 5, 5, 5, 2]),
        22,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.fourOfAKind, [5, 5, 5, 2, 2]),
        0,
      );
    });
    test('wertet Full House und Straßen exakt', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.fullHouse, [2, 2, 5, 5, 5]),
        25,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.smallStraight, [
          1,
          2,
          3,
          4,
          4,
        ]),
        30,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.smallStraight, [
          2,
          3,
          4,
          5,
          5,
        ]),
        30,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.largeStraight, [
          2,
          3,
          4,
          5,
          6,
        ]),
        40,
      );
    });
    test('wertet Kniffel', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.yatzy, [6, 6, 6, 6, 6]),
        50,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.yatzy, [6, 6, 6, 6, 5]),
        0,
      );
    });
  });

  group('Skandinavisches Yatzy', () {
    const rules = RuleSet.yatzy;
    test('wertet höchstes Paar und zwei verschiedene Paare', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.onePair, [2, 2, 5, 5, 6]),
        10,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.twoPairs, [2, 2, 5, 5, 5]),
        14,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.twoPairs, [2, 2, 2, 2, 6]),
        0,
      );
    });
    test('wertet Pasche nur mit passenden Würfeln', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.threeOfAKind, [4, 4, 4, 2, 3]),
        12,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.fourOfAKind, [5, 5, 5, 5, 2]),
        20,
      );
    });
    test('wertet Straßen, Full House und Yatzy', () {
      expect(
        ScoringEngine.score(rules, ScoreCategory.smallStraight, [
          1,
          2,
          3,
          4,
          5,
        ]),
        15,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.smallStraight, [
          2,
          3,
          4,
          5,
          6,
        ]),
        0,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.largeStraight, [
          2,
          3,
          4,
          5,
          6,
        ]),
        20,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.fullHouse, [3, 3, 6, 6, 6]),
        24,
      );
      expect(
        ScoringEngine.score(rules, ScoreCategory.yatzy, [1, 1, 1, 1, 1]),
        50,
      );
    });
  });

  test('Bonus ist 35 ab 63 Punkten', () {
    expect(ScoringEngine.bonus(62), 0);
    expect(ScoringEngine.bonus(63), 35);
  });
}

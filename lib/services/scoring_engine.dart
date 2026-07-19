import '../models/game_models.dart';

class ScoringEngine {
  static Set<int> allowedScores(RuleSet rules, ScoreCategory category) =>
      ScoreRules.allowedScores(rules, category);

  static int score(RuleSet rules, ScoreCategory category, List<int> dice) =>
      ScoreRules.score(rules, category, dice);

  static int bonus(RuleSet rules, int upperTotal) =>
      ScoreRules.bonus(rules, upperTotal);
}

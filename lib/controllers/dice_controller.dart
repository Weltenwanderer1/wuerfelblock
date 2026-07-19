import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/game_models.dart';
import '../services/scoring_engine.dart';
import 'game_controller.dart';

class DiceController extends ChangeNotifier {
  DiceController({required this.game, int Function()? roller})
    : _roller = roller ?? (() => Random().nextInt(6) + 1);
  final GameController game;
  final int Function() _roller;
  List<int> get dice => game.state.dice;
  List<bool> get held => game.state.held;
  int get rollCount => game.state.rollCount;
  bool get canRoll => rollCount < 3;
  bool get hasRolled => rollCount > 0;

  Future<void> roll() async {
    if (game.isBusy) return;
    if (!canRoll) throw StateError('Es sind höchstens drei Würfe erlaubt.');
    for (var index = 0; index < dice.length; index++) {
      if (!held[index]) dice[index] = _roller();
    }
    game.state.rollCount++;
    notifyListeners();
    await game.persistTurn();
  }

  Future<void> toggleHold(int index) async {
    if (!hasRolled || game.isBusy) return;
    held[index] = !held[index];
    notifyListeners();
    await game.persistTurn();
  }

  int suggestion(ScoreCategory category) =>
      ScoringEngine.score(game.state.ruleSet, category, dice);

  Future<void> score(ScoreCategory category) async {
    if (game.isBusy) return;
    if (!hasRolled) throw StateError('Vor der Wertung muss gewürfelt werden.');
    await game.enterScore(category, suggestion(category));
  }

  void resetTurn() {
    game.resetTurn();
    notifyListeners();
  }

  Future<void> undo() async {
    if (game.isBusy) return;
    await game.undo();
    notifyListeners();
  }
}

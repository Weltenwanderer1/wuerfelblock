import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  test('winners are determined by raw + incentive, not incentive alone', () {
    final ada = BalutPlayer(
      'Ada',
      entries: {
        BalutCategory.fours: [20, 20, 20, 20],
        BalutCategory.fives: [25, 25, 25, 25],
        BalutCategory.sixes: [30, 30, 30, 30],
        BalutCategory.straights: [20, 20, 20, 20],
        BalutCategory.fullHouse: [28, 28, 28, 28],
        BalutCategory.choice: [30, 30, 30, 30],
        BalutCategory.balut: [50, 50, 50, 50],
      },
    );
    final bea = BalutPlayer(
      'Bea',
      entries: {
        BalutCategory.fours: [4, 4, 4, 4],
        BalutCategory.fives: [5, 5, 5, 5],
        BalutCategory.sixes: [6, 6, 6, 6],
        BalutCategory.straights: [20, 20, 20, 20],
        BalutCategory.fullHouse: [28, 28, 28, 28],
        BalutCategory.choice: [30, 30, 30, 30],
        BalutCategory.balut: [50, 50, 50, 50],
      },
    );
    final state = BalutGameState(
      players: [ada, bea],
      mode: GameMode.block,
      activePlayerIndex: 0,
      dice: const [1, 1, 1, 1, 1],
      held: const [false, false, false, false, false],
      rollCount: 0,
    );
    // Ada has strictly more total points (raw + bonus) than Bea.
    // Bug behaviour: pick the player with the larger bonus only.
    // Fixed behaviour: pick the player with the larger raw + incentive total.
    final adaTotal = ada.rawTotal + ada.incentivePoints;
    final beaTotal = bea.rawTotal + bea.incentivePoints;
    expect(adaTotal, greaterThan(beaTotal));
    expect(state.winners.map((p) => p.name).toList(), ['Ada']);
  });
}

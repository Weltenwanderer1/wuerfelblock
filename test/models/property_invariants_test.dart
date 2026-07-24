import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';

void main() {
  test('Balut scoring invariants hold for all 7776 five-die rolls', () {
    var checked = 0;
    for (var first = 1; first <= 6; first++) {
      for (var second = 1; second <= 6; second++) {
        for (var third = 1; third <= 6; third++) {
          for (var fourth = 1; fourth <= 6; fourth++) {
            for (var fifth = 1; fifth <= 6; fifth++) {
              final dice = [first, second, third, fourth, fifth];
              final sum = dice.fold(0, (total, die) => total + die);
              final counts = <int, int>{};
              for (final die in dice) {
                counts[die] = (counts[die] ?? 0) + 1;
              }
              final sorted = [...dice]..sort();
              final groups = counts.values.toList()..sort();
              final isFullHouse =
                  groups.length == 2 && groups[0] == 2 && groups[1] == 3;

              expect(
                BalutScoring.score(BalutCategory.fours, dice),
                (counts[4] ?? 0) * 4,
              );
              expect(
                BalutScoring.score(BalutCategory.fives, dice),
                (counts[5] ?? 0) * 5,
              );
              expect(
                BalutScoring.score(BalutCategory.sixes, dice),
                (counts[6] ?? 0) * 6,
              );
              expect(BalutScoring.score(BalutCategory.choice, dice), sum);
              expect(
                BalutScoring.score(BalutCategory.straights, dice),
                sorted.toString() == '[1, 2, 3, 4, 5]'
                    ? 15
                    : sorted.toString() == '[2, 3, 4, 5, 6]'
                    ? 20
                    : 0,
              );
              expect(
                BalutScoring.score(BalutCategory.fullHouse, dice),
                isFullHouse ? sum : 0,
              );
              expect(
                BalutScoring.score(BalutCategory.balut, dice),
                counts.length == 1 ? 20 + sum : 0,
              );
              checked++;
            }
          }
        }
      }
    }
    expect(checked, 7776);
  });

  test('Colordice row order always contains each number exactly once', () {
    const allNumbers = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
    for (final color in ColordiceColor.values) {
      final numbers = color.numbers;
      expect(numbers, hasLength(11));
      expect(numbers.toSet(), allNumbers);
      expect(
        numbers,
        color == ColordiceColor.red || color == ColordiceColor.yellow
            ? orderedEquals([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
            : orderedEquals([12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]),
      );
    }
  });

  test(
    '10.000 trigger and final-round ownership stay cyclic for 2–8 players',
    () {
      for (var playerCount = 2; playerCount <= 8; playerCount++) {
        for (var starter = 0; starter < playerCount; starter++) {
          var state = TenThousandGameState.newGame(
            List.generate(playerCount, (index) => 'P$index'),
          );
          for (var ordinal = 0; ordinal <= starter; ordinal++) {
            state = state.withTurn(
              ordinal == starter ? TenThousandGameState.winningScore : 0,
            );
          }

          expect(state.finalRoundTriggerPlayerIndex, starter);
          expect(state.finalRoundRemainingPlayerIndices, [
            for (var offset = 1; offset < playerCount; offset++)
              (starter + offset) % playerCount,
          ]);
          expect(
            state.turns.map((turn) => turn.ordinal),
            List.generate(starter + 1, (index) => index),
          );
        }
      }
    },
  );
}

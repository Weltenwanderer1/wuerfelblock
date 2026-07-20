import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/ten_thousand_dice.dart';

void main() {
  group('10.000 digital scoring', () {
    test('fresh state is distinguishable from a started turn', () {
      expect(TenThousandDiceTurn.fresh().isFresh, isTrue);
      expect(
        TenThousandDiceTurn.fresh().rolled([1, 2, 3, 4, 5, 6]).isFresh,
        isFalse,
      );
    });

    test('scores singles, triples, doubling, straight and three pairs', () {
      expect(TenThousandDiceTurn.scoreSelection([1, 5]), 150);
      expect(TenThousandDiceTurn.scoreSelection([2, 2, 2]), 200);
      expect(TenThousandDiceTurn.scoreSelection([1, 1, 1]), 1000);
      expect(TenThousandDiceTurn.scoreSelection([2, 2, 2, 2]), 400);
      expect(TenThousandDiceTurn.scoreSelection([1, 2, 3, 4, 5, 6]), 1000);
      expect(TenThousandDiceTurn.scoreSelection([1, 1, 3, 3, 6, 6]), 500);
      expect(TenThousandDiceTurn.scoreSelection([2, 3]), isNull);
    });

    test('extends a pasch over later rolls by doubling', () {
      var turn = TenThousandDiceTurn.fresh();
      turn = turn.rolled([3, 3, 3, 1, 2, 4]);
      turn = turn.toggled(0).toggled(1).toggled(2).banked();
      expect(turn.roundPoints, 300);
      expect(turn.paschCounts[3], 3);

      turn = turn.rolled([3, 1, 2]);
      turn = turn.toggled(0).banked();
      expect(turn.roundPoints, 600);
      expect(turn.paschCounts[3], 4);
    });

    test('hot dice require another valid roll and Macke is detected', () {
      var turn = TenThousandDiceTurn.fresh().rolled([1, 2, 3, 4, 5, 6]);
      for (var index = 0; index < 6; index++) {
        turn = turn.toggled(index);
      }
      turn = turn.banked();
      expect(turn.roundPoints, 1000);
      expect(turn.activeDiceCount, 6);
      expect(turn.mustRoll, isTrue);
      expect(turn.canSecure, isFalse);

      turn = turn.rolled([2, 3, 3, 4, 4, 6]);
      expect(turn.isMacke, isTrue);
    });

    test('a single die matching an earlier pasch prevents Macke', () {
      var turn = TenThousandDiceTurn.fresh().rolled([3, 3, 3, 1, 2, 4]);
      turn = turn.toggled(0).toggled(1).toggled(2).banked();
      turn = turn.rolled([3, 2, 4]);
      expect(turn.isMacke, isFalse);
      expect(turn.toggled(0).selectedScore, 300);
    });

    test('secured score needs 350 and JSON preserves an active turn', () {
      var turn = TenThousandDiceTurn.fresh().rolled([1, 5, 2, 3, 4, 6]);
      turn = turn.toggled(0).toggled(1).banked();
      expect(turn.roundPoints, 150);
      expect(turn.canSecure, isFalse);

      final decoded = TenThousandDiceTurn.fromJson(turn.toJson());
      expect(decoded.toJson(), turn.toJson());
    });

    test('Macke matches exhaustive legal subsets up to six dice', () {
      for (var length = 1; length <= 6; length++) {
        for (final dice in _canonicalRolls(length)) {
          final turn = TenThousandDiceTurn(
            dice: List<int>.filled(length, 1),
            selected: List<bool>.filled(length, false),
            hasRolled: false,
            roundPoints: 0,
            paschCounts: const {},
            mustRoll: false,
          ).rolled(dice);
          var hasLegalSubset = false;
          for (var mask = 1; mask < 1 << dice.length; mask++) {
            final selected = <int>[
              for (var index = 0; index < dice.length; index++)
                if (mask & (1 << index) != 0) dice[index],
            ];
            final score = TenThousandDiceTurn.scoreSelection(selected);
            if (score != null) {
              expect(score, greaterThan(0));
              expect(score % 50, 0);
              hasLegalSubset = true;
            }
          }
          expect(turn.isMacke, !hasLegalSubset, reason: 'Wurf $dice');
        }
      }
    });
  });
}

Iterable<List<int>> _canonicalRolls(int length, [int minimum = 1]) sync* {
  if (length == 0) {
    yield const [];
    return;
  }
  for (var value = minimum; value <= 6; value++) {
    for (final tail in _canonicalRolls(length - 1, value)) {
      yield [value, ...tail];
    }
  }
}

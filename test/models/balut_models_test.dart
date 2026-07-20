import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  group('Balut scoring', () {
    test('defines the seven categories and four entries per category', () {
      expect(BalutCategory.values, [
        BalutCategory.fours,
        BalutCategory.fives,
        BalutCategory.sixes,
        BalutCategory.straights,
        BalutCategory.fullHouse,
        BalutCategory.choice,
        BalutCategory.balut,
      ]);
      expect(BalutPlayer.entriesPerCategory, 4);
      expect(BalutPlayer.entriesPerSheet, 28);
    });

    test('scores number categories using matching dice only', () {
      expect(BalutScoring.score(BalutCategory.fours, [4, 4, 2, 4, 6]), 12);
      expect(BalutScoring.score(BalutCategory.fives, [5, 1, 5, 3, 5]), 15);
      expect(BalutScoring.score(BalutCategory.sixes, [6, 6, 6, 6, 1]), 24);
    });

    test('scores both straights and rejects duplicate or incomplete runs', () {
      expect(BalutScoring.score(BalutCategory.straights, [5, 1, 3, 2, 4]), 15);
      expect(BalutScoring.score(BalutCategory.straights, [6, 3, 5, 2, 4]), 20);
      expect(BalutScoring.score(BalutCategory.straights, [1, 2, 3, 4, 4]), 0);
    });

    test('scores full house, choice, Balut, and invalid combinations', () {
      expect(BalutScoring.score(BalutCategory.fullHouse, [2, 2, 5, 5, 5]), 19);
      expect(BalutScoring.score(BalutCategory.fullHouse, [2, 2, 2, 2, 5]), 0);
      expect(BalutScoring.score(BalutCategory.choice, [1, 2, 3, 4, 6]), 16);
      expect(BalutScoring.score(BalutCategory.balut, [6, 6, 6, 6, 6]), 50);
      expect(BalutScoring.score(BalutCategory.balut, [6, 6, 6, 6, 5]), 0);
    });

    test('requires exactly five valid dice', () {
      expect(
        () => BalutScoring.score(BalutCategory.choice, [1, 2, 3, 4]),
        throwsArgumentError,
      );
      expect(
        () => BalutScoring.score(BalutCategory.choice, [1, 2, 3, 4, 7]),
        throwsArgumentError,
      );
    });
  });

  group('Balut sheet totals', () {
    test('a category can be struck as zero and filled only once per slot', () {
      final player = BalutPlayer('Ada');
      final changed = player.withEntry(BalutCategory.fours, 0, 0);
      expect(changed.entries[BalutCategory.fours], [0, null, null, null]);
      expect(
        () => changed.withEntry(BalutCategory.fours, 0, 4),
        throwsStateError,
      );
      expect(
        () => player.withEntry(BalutCategory.fours, 0, 5),
        throwsArgumentError,
      );
    });

    test('calculates all category incentives and the raw bracket', () {
      final player = BalutPlayer(
        'Ada',
        entries: {
          BalutCategory.fours: [12, 12, 12, 16],
          BalutCategory.fives: [15, 15, 15, 20],
          BalutCategory.sixes: [18, 18, 18, 24],
          BalutCategory.straights: [15, 15, 20, 20],
          BalutCategory.fullHouse: [11, 15, 20, 24],
          BalutCategory.choice: [25, 25, 25, 25],
          BalutCategory.balut: [25, 30, 0, 0],
        },
      );

      expect(player.rawTotal, 490);
      expect(player.categoryIncentivePoints, 15);
      expect(player.balutIncentivePoints, 4);
      expect(player.rawTotalIncentivePoints, 2);
      expect(player.incentivePoints, 21);
    });

    test('requires every straight/full house to be nonzero for incentives', () {
      final player = BalutPlayer(
        'Ada',
        entries: {
          BalutCategory.fours: [0, 0, 0, 0],
          BalutCategory.fives: [0, 0, 0, 0],
          BalutCategory.sixes: [0, 0, 0, 0],
          BalutCategory.straights: [15, 15, 20, 0],
          BalutCategory.fullHouse: [11, 15, 20, 0],
          BalutCategory.choice: [0, 0, 0, 0],
          BalutCategory.balut: [0, 0, 0, 0],
        },
      );
      expect(player.categoryIncentivePoints, 0);
      expect(player.rawTotalIncentivePoints, -2);
    });

    test('raw score brackets include every boundary', () {
      expect(BalutScoring.rawTotalIncentive(0), -2);
      expect(BalutScoring.rawTotalIncentive(299), -2);
      expect(BalutScoring.rawTotalIncentive(300), -1);
      expect(BalutScoring.rawTotalIncentive(350), 0);
      expect(BalutScoring.rawTotalIncentive(400), 1);
      expect(BalutScoring.rawTotalIncentive(450), 2);
      expect(BalutScoring.rawTotalIncentive(500), 3);
      expect(BalutScoring.rawTotalIncentive(550), 4);
      expect(BalutScoring.rawTotalIncentive(600), 5);
      expect(BalutScoring.rawTotalIncentive(650), 6);
      expect(BalutScoring.rawTotalIncentive(812), 6);
      expect(() => BalutScoring.rawTotalIncentive(813), throwsRangeError);
    });

    test('the theoretical maximum is 812 raw and 29 incentive points', () {
      final player = BalutPlayer(
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
      expect(player.rawTotal, 812);
      expect(player.incentivePoints, 29);
      expect(player.isComplete, isTrue);
    });
  });

  group('Balut game state and strict persistence', () {
    test('new game supports 2-8 unique trimmed players in both modes', () {
      final state = BalutGameState.newGame([
        ' Ada ',
        'Bea',
      ], mode: GameMode.digital);
      expect(state.players.map((player) => player.name), ['Ada', 'Bea']);
      expect(state.activePlayerIndex, 0);
      expect(state.dice, [1, 1, 1, 1, 1]);
      expect(state.held, [false, false, false, false, false]);
      expect(state.rollCount, 0);
      expect(() => BalutGameState.newGame(['A']), throwsArgumentError);
      expect(
        () => BalutGameState.newGame(List.generate(9, (i) => 'P$i')),
        throwsArgumentError,
      );
      expect(() => BalutGameState.newGame(['A', ' A ']), throwsArgumentError);
    });

    test(
      'digital turn rolls all dice first then only unheld dice, at most 3 times',
      () {
        var state = BalutGameState.newGame(['A', 'B'], mode: GameMode.digital);
        state = state.withDigitalRoll([1, 2, 3, 4, 5]);
        state = state.withToggledHold(1);
        state = state.withToggledHold(3);
        state = state.withDigitalRoll([6, 6, 6]);
        expect(state.dice, [6, 2, 6, 4, 6]);
        expect(state.rollCount, 2);
        state = state.withDigitalRoll([5, 5, 5]);
        expect(state.rollCount, 3);
        expect(() => state.withDigitalRoll(const []), throwsStateError);
      },
    );

    test('digital score uses dice, advances player, and resets the turn', () {
      var state = BalutGameState.newGame(['A', 'B'], mode: GameMode.digital);
      state = state.withDigitalRoll([4, 4, 4, 1, 2]);
      state = state.withDigitalScore(BalutCategory.fours);
      expect(state.players[0].entries[BalutCategory.fours]!.first, 12);
      expect(state.activePlayerIndex, 1);
      expect(state.rollCount, 0);
      expect(state.held, everyElement(isFalse));
    });

    test('JSON round-trip is exact and retains active digital turn', () {
      var state = BalutGameState.newGame(['A', 'B'], mode: GameMode.digital);
      state = state.withDigitalRoll([1, 2, 3, 4, 5]);
      state = state.withToggledHold(0);
      final json = state.toJson();
      expect(json['type'], 'balut');
      expect(json.keys.toSet(), {
        'type',
        'schemaVersion',
        'mode',
        'players',
        'activePlayerIndex',
        'dice',
        'held',
        'rollCount',
      });
      final restored = BalutGameState.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored.gameLabel, 'Balut');
      expect(restored.progressLabel, '0 von 56 Wertungen');
    });

    test(
      'strict JSON rejects unknown, missing, mistyped, and inconsistent data',
      () {
        final valid = BalutGameState.newGame(['A', 'B']).toJson();
        expect(
          () => BalutGameState.fromJson({...valid, 'extra': true}),
          throwsFormatException,
        );
        final missing = Map<String, dynamic>.from(valid)..remove('held');
        expect(() => BalutGameState.fromJson(missing), throwsFormatException);
        expect(
          () => BalutGameState.fromJson({...valid, 'type': 'classic'}),
          throwsFormatException,
        );
        expect(
          () => BalutGameState.fromJson({...valid, 'rollCount': '0'}),
          throwsFormatException,
        );
        expect(
          () => BalutGameState.fromJson({
            ...valid,
            'held': [true, false, false, false, false],
          }),
          throwsFormatException,
        );
        final players = (valid['players'] as List)
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList();
        players[0] = {...players[0], 'extra': true};
        expect(
          () => BalutGameState.fromJson({...valid, 'players': players}),
          throwsFormatException,
        );
      },
    );
  });
}

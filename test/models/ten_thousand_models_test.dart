import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';

void main() {
  group('players and points', () {
    test('accepts 2 and 8 trimmed unique players defensively', () {
      final names = [' Ada ', 'Bea'];
      final two = TenThousandGameState.newGame(names);
      names[0] = 'Changed';
      expect(two.players.map((player) => player.name), ['Ada', 'Bea']);
      expect(
        TenThousandGameState.newGame(
          List.generate(8, (index) => 'P$index'),
        ).players,
        hasLength(8),
      );
      expect(
        () => two.players.add(TenThousandPlayer('C')),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid player counts, blanks, and trimmed duplicates', () {
      for (final names in <List<String>>[
        ['only'],
        List.generate(9, (index) => 'P$index'),
        ['A', '  '],
        ['Ada', ' Ada '],
      ]) {
        expect(() => TenThousandGameState.newGame(names), throwsArgumentError);
      }
    });

    test('accepts zero and positive multiples of 50 only', () {
      final state = TenThousandGameState.newGame(['A', 'B']);
      expect(state.withTurn(0).turns.single.points, 0);
      expect(state.withTurn(50).turns.single.points, 50);
      for (final points in [-50, 1, 49, 75]) {
        expect(() => state.withTurn(points), throwsArgumentError);
        expect(() => TenThousandTurn(0, points), throwsArgumentError);
      }
      expect(() => TenThousandTurn(-1, 50), throwsArgumentError);
    });
  });

  group('replay', () {
    test('assigns turns cyclically and derives totals', () {
      var state = TenThousandGameState.newGame(['A', 'B', 'C']);
      for (final points in [100, 0, 250, 300]) {
        state = state.withTurn(points);
      }
      expect(state.turns.map((turn) => turn.ordinal), [0, 1, 2, 3]);
      expect(state.playerIndexForTurn(3), 0);
      expect(state.totals, [400, 0, 250]);
      expect(state.activePlayerIndex, 1);
      expect(state.finalRoundRemainingPlayerIndices, isEmpty);
    });

    test('each starter can trigger by hitting or overshooting 10000', () {
      for (final triggerPoints in [10000, 10050]) {
        for (var starter = 0; starter < 3; starter++) {
          var state = TenThousandGameState.newGame(['A', 'B', 'C']);
          for (var ordinal = 0; ordinal <= starter; ordinal++) {
            state = state.withTurn(ordinal == starter ? triggerPoints : 0);
          }
          expect(state.finalRoundTriggerPlayerIndex, starter);
          expect(state.finalRoundRemainingPlayerIndices, [
            for (var offset = 1; offset < 3; offset++) (starter + offset) % 3,
          ]);
        }
      }
    });

    test('allows exactly N-1 final attempts and never retriggers', () {
      var state = TenThousandGameState.newGame(['A', 'B', 'C']);
      state = state.withTurn(10000);
      expect(state.isComplete, isFalse);
      expect(state.finalRoundRemainingPlayerIndices, [1, 2]);
      state = state.withTurn(20000);
      expect(state.finalRoundTriggerPlayerIndex, 0);
      expect(state.finalRoundRemainingPlayerIndices, [2]);
      state = state.withTurn(0);
      expect(state.isComplete, isTrue);
      expect(state.finalRoundRemainingPlayerIndices, isEmpty);
      expect(() => state.withTurn(50), throwsStateError);
    });

    test('derives ties and winners from final totals', () {
      var state = TenThousandGameState.newGame(['A', 'B']);
      state = state.withTurn(10000).withTurn(10000);
      expect(state.isComplete, isTrue);
      expect(state.winnerIndices, [0, 1]);
      expect(state.winners.map((player) => player.name), ['A', 'B']);
    });

    test('tombstones score zero while retaining ordinal ownership', () {
      var state = TenThousandGameState.newGame(['A', 'B']);
      state = state.withTurn(500).withTurn(250);
      final deleted = state.replacingTurn(0, state.turns[0].asDeleted());
      expect(deleted.turns, hasLength(2));
      expect(deleted.turns[0].ordinal, 0);
      expect(deleted.turns[0].isDeleted, isTrue);
      expect(deleted.playerIndexForTurn(0), 0);
      expect(deleted.totals, [0, 250]);
    });
  });

  group('JSON', () {
    test('roundtrips normal, final, complete, and tombstoned states', () {
      final states = <TenThousandGameState>[
        TenThousandGameState.newGame(['A', 'B']).withTurn(50),
        TenThousandGameState.newGame(['A', 'B', 'C']).withTurn(10000),
        TenThousandGameState.newGame(['A', 'B']).withTurn(10000).withTurn(0),
        TenThousandGameState.newGame(['A', 'B'])
            .withTurn(50)
            .replacingTurn(0, TenThousandTurn(0, 50, isDeleted: true)),
      ];
      for (final state in states) {
        final decoded = TenThousandGameState.fromJson(state.toJson());
        expect(decoded.toJson(), state.toJson());
        expect(decoded.totals, state.totals);
      }
    });

    test('emits only schema, players, and contiguous ledger', () {
      final json = TenThousandGameState.newGame([
        'A',
        'B',
      ]).withTurn(50).toJson();
      expect(json.keys, {'type', 'schemaVersion', 'players', 'turns'});
      expect(json['type'], 'tenThousand');
      expect(json['schemaVersion'], TenThousandGameState.schemaVersion);
    });

    test(
      'strictly rejects unknown, malformed, noncontiguous, and post-complete JSON',
      () {
        final valid = TenThousandGameState.newGame(['A', 'B']).toJson();
        final cases = <Map<String, dynamic>>[
          {...valid, 'extra': true},
          {...valid, 'type': 'classic'},
          {...valid, 'schemaVersion': 999},
          {...valid, 'players': <dynamic>[]},
          {
            ...valid,
            'players': [
              {'name': 'A', 'extra': 1},
              {'name': 'B'},
            ],
          },
          {
            ...valid,
            'turns': [
              {'ordinal': 1, 'points': 50, 'isDeleted': false},
            ],
          },
          {
            ...valid,
            'turns': [
              {'ordinal': 0, 'points': 75, 'isDeleted': false},
            ],
          },
          {
            ...valid,
            'turns': [
              {'ordinal': 0, 'points': 10000, 'isDeleted': false},
              {'ordinal': 1, 'points': 0, 'isDeleted': false},
              {'ordinal': 2, 'points': 50, 'isDeleted': false},
            ],
          },
        ];
        for (final json in cases) {
          expect(
            () => TenThousandGameState.fromJson(json),
            throwsFormatException,
          );
        }
      },
    );
  });
}

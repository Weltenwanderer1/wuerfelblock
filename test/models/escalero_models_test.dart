import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/escalero_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  group('EscaleroScoring', () {
    test('scores picture categories as count times value', () {
      expect(EscaleroScoring.score(EscaleroCategory.nine, [1, 1, 2, 3, 6]), 2);
      expect(EscaleroScoring.score(EscaleroCategory.ace, [6, 6, 6, 2, 3]), 18);
    });

    test('scores combinations and served bonuses', () {
      expect(
        EscaleroScoring.score(EscaleroCategory.straight, [1, 2, 3, 4, 5]),
        20,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.straight, [
          2,
          3,
          4,
          5,
          6,
        ], served: true),
        25,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.fullHouse, [
          2,
          2,
          2,
          5,
          5,
        ], served: true),
        35,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.poker, [4, 4, 4, 4, 2]),
        40,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.poker, [4, 4, 4, 4, 4]),
        40,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.poker, [
          4,
          4,
          4,
          4,
          4,
        ], served: true),
        45,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.fullHouse, [5, 5, 5, 5, 5]),
        30,
      );
      expect(
        EscaleroScoring.score(EscaleroCategory.grande, [
          3,
          3,
          3,
          3,
          3,
        ], served: true),
        80,
      );
    });

    test('validates block entries per category', () {
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.queen, 16), isTrue);
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.queen, 15), isFalse);
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.poker, 45), isTrue);
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.poker, 50), isFalse);
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.grande, 80), isTrue);
      expect(EscaleroScoring.isValidEntry(EscaleroCategory.grande, 0), isTrue);
    });
  });

  test('player has ten categories and three columns', () {
    final player = EscaleroPlayer('Ada');
    expect(EscaleroCategory.values, hasLength(10));
    expect(player.filledEntryCount, 0);
    final changed = player.withEntry(EscaleroCategory.nine, 2, 0);
    expect(changed.entries[EscaleroCategory.nine]![2], 0);
    expect(changed.filledEntryCount, 1);
    expect(
      () => changed.withEntry(EscaleroCategory.nine, 2, 1),
      throwsStateError,
    );
  });

  test('three-player settlement follows the original booklet example', () {
    EscaleroPlayer withColumns(String name, List<int> values) {
      var player = EscaleroPlayer(name);
      for (var column = 0; column < 3; column++) {
        player = player.withEntry(
          EscaleroCategory.nine,
          column,
          values[column],
        );
      }
      return player;
    }

    final state = EscaleroGameState(
      players: [
        withColumns('A', [2, 4, 2]),
        withColumns('B', [3, 2, 4]),
        withColumns('C', [1, 1, 1]),
      ],
    );

    expect(state.gamePointsFor(0), -1);
    expect(state.gamePointsFor(1), 8);
    expect(state.gamePointsFor(2), -7);
  });

  test('winning all columns pays nine points per opponent', () {
    EscaleroPlayer withColumns(String name, List<int> values) {
      var player = EscaleroPlayer(name);
      for (var column = 0; column < 3; column++) {
        player = player.withEntry(
          EscaleroCategory.nine,
          column,
          values[column],
        );
      }
      return player;
    }

    final state = EscaleroGameState(
      players: [
        withColumns('A', [5, 5, 5]),
        withColumns('B', [2, 2, 2]),
        withColumns('C', [1, 1, 1]),
      ],
    );

    expect(state.gamePointsFor(0), 18);
    expect(state.gamePointsFor(1), -9);
    expect(state.gamePointsFor(2), -9);
  });

  test('column ties and overall ranking do not use raw-score tie-breaks', () {
    EscaleroPlayer withColumns(String name, List<int> values) {
      var player = EscaleroPlayer(name);
      for (var column = 0; column < 3; column++) {
        player = player.withEntry(
          EscaleroCategory.nine,
          column,
          values[column],
        );
      }
      return player;
    }

    final state = EscaleroGameState(
      players: [
        withColumns('A', [5, 5, 5]),
        withColumns('B', [5, 5, 5]),
        withColumns('C', [1, 2, 3]),
      ],
    );

    expect([for (var i = 0; i < 3; i++) state.gamePointsFor(i)], [0, 0, 0]);
    expect(state.ranking.map((player) => player.name), ['A', 'B', 'C']);
    expect(state.winners.map((player) => player.name), ['A', 'B', 'C']);
  });

  test('digital served depends on all five dice in decisive roll', () {
    var state = EscaleroGameState.newGame([
      'Ada',
      'Bob',
    ], mode: GameMode.digital);
    state = state.withDigitalRoll([1, 2, 3, 4, 5]);
    state = state.withDigitalScore(EscaleroCategory.straight, 0);
    expect(state.players.first.entries[EscaleroCategory.straight]![0], 25);

    state = state.withDigitalRoll([2, 2, 2, 2, 2]);
    state = state.withToggledHold(0);
    state = state.withDigitalRoll([3, 3, 3, 3]);
    state = state.withDigitalScore(EscaleroCategory.poker, 0);
    expect(state.players[1].entries[EscaleroCategory.poker]![0], 40);

    state = state.withDigitalRoll([1, 1, 1, 1, 1]);
    state = state.withToggledHold(0);
    state = state.withDigitalRoll([2, 2, 2, 2]);
    state = state.withToggledHold(0);
    state = state.withDigitalRoll([2, 3, 4, 5, 6]);
    state = state.withDigitalScore(EscaleroCategory.straight, 1);
    expect(state.players[0].entries[EscaleroCategory.straight]![1], 25);
  });

  test('served poker loses bonus after rerolling the fifth die for Grande', () {
    var state = EscaleroGameState.newGame([
      'Ada',
      'Bob',
    ], mode: GameMode.digital);

    state = state.withDigitalRoll([2, 2, 2, 2, 3]);
    for (var index = 0; index < 4; index++) {
      state = state.withToggledHold(index);
    }
    state = state.withDigitalRoll([4]);
    state = state.withDigitalScore(EscaleroCategory.poker, 0);

    expect(state.players.first.entries[EscaleroCategory.poker]![0], 40);
  });

  test('strict JSON round-trip rejects missing and unknown keys', () {
    final state = EscaleroGameState.newGame([
      'Ada',
      'Bob',
    ], mode: GameMode.digital).withDigitalRoll([1, 2, 3, 4, 5]);
    expect(EscaleroGameState.fromJson(state.toJson()).toJson(), state.toJson());
    final extra = {...state.toJson(), 'future': true};
    expect(() => EscaleroGameState.fromJson(extra), throwsFormatException);
    final missing = {...state.toJson()}..remove('digitalTurn');
    expect(() => EscaleroGameState.fromJson(missing), throwsFormatException);
  });

  test('strict JSON rejects a completed active player in an open game', () {
    var complete = EscaleroPlayer('Ada');
    for (final category in EscaleroCategory.values) {
      for (var column = 0; column < 3; column++) {
        complete = complete.withEntry(category, column, 0);
      }
    }
    final valid = EscaleroGameState(
      players: [complete, EscaleroPlayer('Bob')],
      activePlayerIndex: 1,
    );
    final invalidJson = {...valid.toJson(), 'activePlayerIndex': 0};
    expect(
      () => EscaleroGameState.fromJson(invalidJson),
      throwsFormatException,
    );
  });
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/backgammon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

BackgammonGameState position(
  Map<int, int> board, {
  List<int> bar = const [0, 0],
  List<int>? off,
  int player = 0,
}) {
  final points = List<int>.filled(24, 0);
  board.forEach((p, n) => points[p - 1] = n);
  final totals = [0, 0];
  for (final n in points) {
    totals[n >= 0 ? 0 : 1] += n.abs();
  }
  return BackgammonGameState(
    names: const ['Light', 'Dark'],
    mode: GameMode.block,
    points: points,
    bar: bar,
    off: off ?? [15 - totals[0] - bar[0], 15 - totals[1] - bar[1]],
    activePlayerIndex: player,
  );
}

const m = BackgammonMove.new;
void main() {
  test(
    'only lower playable remains compulsory, not falsely blocked by higher rule',
    () {
      final s = position(
        {19: -2, 18: -2, 1: -11},
        bar: const [1, 0],
      ).roll(1, 6);
      expect(s.legalMoves, [m(from: 0, to: 24, die: 1)]);
      final entered = s.move(s.legalMoves.single);
      expect(entered.canEndTurn, true);
      expect(entered.remaining, [6]);
    },
  );
  test(
    'complete seeded classical game preserves every saved turn through victory',
    () {
      final random = Random(1729);
      var s = BackgammonGameState.newGame(['Ada', 'Ben']);
      var turns = 0;
      while (!s.isComplete && turns < 2000) {
        s = s.roll(random.nextInt(6) + 1, random.nextInt(6) + 1);
        if (s.opening) continue;
        var legal = s.legalMoves;
        while (legal.isNotEmpty) {
          s = s.move(legal[random.nextInt(legal.length)]);
          legal = s.legalMoves;
        }
        s = BackgammonGameState.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
        );
        if (!s.isComplete) s = s.endTurn();
        turns++;
      }
      expect(s.isComplete, true);
      expect(s.off[s.winnerIndex!], 15);
      expect(s.winType, isNotNull);
    },
  );
  test('classical setup immutable and opening winner uses both dice', () {
    final s = BackgammonGameState.newGame(['Light', 'Dark']);
    expect(s.points[23], 2);
    expect(s.points[0], -2);
    expect(() => s.points[0] = 0, throwsUnsupportedError);
    final tie = s.roll(4, 4);
    expect(tie.opening, true);
    expect(tie.dice, [4, 4]);
    expect(tie.remaining, isEmpty);
    expect(BackgammonGameState.fromJson(tie.toJson()).opening, true);
    final first = tie.roll(2, 6);
    expect(first.activePlayerIndex, 1);
    expect(first.remaining, [2, 6]);
    expect(() => first.roll(1, 1), throwsStateError);
    expect(() => first.endTurn(), throwsStateError);
  });
  test('global maximum rejects a locally legal dead end', () {
    // Bearing off immediately wastes die 1; moving to 1 uses both.
    final s = position({2: 1, 24: -15}).roll(1, 2);
    expect(s.legalMoves, isNot(contains(m(from: 2, to: 25, die: 2))));
    expect(s.legalMoves, contains(m(from: 2, to: 1, die: 1)));
  });
  test('higher die compulsory when either but not both playable', () {
    final s = position({1: 1, 24: -15}).roll(2, 5);
    expect(s.legalMoves, [m(from: 1, to: 25, die: 5)]);
  });
  test('bar entry hits and undo persists without rewinding roll', () {
    final s = position({20: -1, 1: -14}, bar: [1, 0]).roll(5, 2);
    expect(s.legalMoves.every((v) => v.from == 0), true);
    final next = s.move(m(from: 0, to: 20, die: 5));
    expect(next.bar, [0, 1]);
    expect(next.points[19], 1);
    final restored = BackgammonGameState.fromJson(
      jsonDecode(jsonEncode(next.toJson())) as Map<String, dynamic>,
    );
    expect(restored.canUndo, true);
    expect(restored.undo().toJson(), s.toJson());
  });
  test('blocked bar can pass; cannot move normal checkers', () {
    final s = position({6: 1, 24: -2, 23: -2, 1: -11}, bar: [1, 0]).roll(1, 2);
    expect(s.legalMoves, isEmpty);
    expect(s.canEndTurn, true);
    final next = s.endTurn();
    expect(next.activePlayerIndex, 1);
    expect(next.dice, isEmpty);
  });
  test('doubles require four moves and undo is confined to roll', () {
    var s = position({8: 4, 24: -15}).roll(2, 2);
    expect(s.remaining, [2, 2, 2, 2]);
    for (var i = 0; i < 4; i++) {
      s = s.move(m(from: 8, to: 6, die: 2));
    }
    expect(s.remaining, isEmpty);
    expect(s.undoHistory.length, 4);
    expect(BackgammonGameState.fromJson(s.toJson()).undo().remaining, [2]);
    expect(s.endTurn().canUndo, false);
  });
  test('bearing off requires all home, overshoot only farthest checker', () {
    final s = position({2: 1, 6: 1, 24: -15}).roll(5, 5);
    expect(s.legalMoves, isNot(contains(m(from: 2, to: 25, die: 5))));
    final outside = position({1: 1, 7: 1, 24: -15}).roll(6, 6);
    expect(outside.legalMoves.any((v) => v.to == 25), false);
    final dark = position({23: -1, 19: -1, 1: 15}, player: 1).roll(5, 5);
    expect(dark.legalMoves, isNot(contains(m(from: 23, to: 25, die: 5))));
  });
  test(
    'normal gammon backgammon wins in both directions; final undo disabled',
    () {
      for (final player in [0, 1]) {
        for (final type in BackgammonWinType.values) {
          final board = <int, int>{player == 0 ? 1 : 24: player == 0 ? 1 : -1};
          final loserPoint = type == BackgammonWinType.backgammon
              ? (player == 0 ? 2 : 23)
              : (player == 0 ? 24 : 1);
          board[loserPoint] =
              (player == 0 ? -1 : 1) *
              (type == BackgammonWinType.normal ? 14 : 15);
          final s = position(board, player: player).roll(1, 2);
          final won = s.move(s.legalMoves.first);
          expect(won.winType, type);
          expect(won.isComplete, true);
          expect(won.canUndo, false);
          expect(BackgammonGameState.fromJson(won.toJson()).winType, type);
        }
      }
    },
  );
  test(
    'partial doubles reenter maximum possible and dark entry mirrors light',
    () {
      var s = position({18: -2, 1: -13}, bar: [2, 0]).roll(3, 3);
      expect(s.legalMoves, [m(from: 0, to: 22, die: 3)]);
      s = s.move(s.legalMoves.first);
      s = s.move(s.legalMoves.first);
      // Two entries plus one move to 19; point 16 is open, so four uses.
      expect(s.remaining, [3, 3]);
      final dark = position({3: 1, 24: 14}, bar: [0, 1], player: 1).roll(3, 1);
      expect(dark.legalMoves.every((v) => v.from == 0), true);
      final hit = dark.move(m(from: 0, to: 3, die: 3));
      expect(hit.bar, [1, 0]);
      expect(hit.points[2], -1);
      final partial = position({19: -2, 1: -13}, bar: [2, 0]).roll(3, 3);
      final twice = partial.move(partial.legalMoves.first);
      final blocked = twice.move(twice.legalMoves.first);
      expect(blocked.legalMoves, isEmpty);
      expect(blocked.remaining, [3, 3]);
      expect(blocked.canEndTurn, true);
    },
  );
  test('backgammon includes loser on bar', () {
    final s = position({1: 1, 24: -14}, bar: [0, 1]).roll(2, 3);
    expect(s.move(s.legalMoves.first).winType, BackgammonWinType.backgammon);
  });
  test('strict JSON rejects corrupt counts types status dice and history', () {
    final s = BackgammonGameState.newGame(['Light', 'Dark']).roll(6, 2);
    for (final corrupt in <String, dynamic>{
      'type': 'classic',
      'points': List.filled(24, 0),
      'remaining': [6, 6],
      'isComplete': true,
      'winType': 'gammon',
      'activePlayerIndex': 2,
      'extra': 1,
      'dice': [1.0, 2],
      'names': ['A', 'A'],
    }.entries) {
      expect(
        () => BackgammonGameState.fromJson({
          ...s.toJson(),
          corrupt.key: corrupt.value,
        }),
        throwsFormatException,
        reason: corrupt.key,
      );
    }
    final moved = s.move(s.legalMoves.first);
    final fake = {
      ...moved.toJson(),
      'undoHistory': [s.rollImpossibleForTest()],
    };
    expect(() => BackgammonGameState.fromJson(fake), throwsFormatException);
  });
}

extension on BackgammonGameState {
  Map<String, dynamic> rollImpossibleForTest() => {
    ...toJson(),
    'remaining': [2],
  };
}

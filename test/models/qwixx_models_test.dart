import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/qwixx_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('Qwixx rows', () {
    test('number orders match the four official rows', () {
      expect(QwixxColor.red.numbers, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(QwixxColor.yellow.numbers, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(QwixxColor.green.numbers, [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]);
      expect(QwixxColor.blue.numbers, [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]);
    });

    test('skipped values stay unavailable and marks only move right', () {
      final player = QwixxPlayer(name: 'Ada');
      player.mark(QwixxColor.red, 5);

      expect(player.canMark(QwixxColor.red, 4), isFalse);
      expect(player.canMark(QwixxColor.red, 5), isFalse);
      expect(player.canMark(QwixxColor.red, 6), isTrue);
      expect(() => player.mark(QwixxColor.red, 4), throwsStateError);
    });

    test('last number needs five prior crosses and adds lock to score', () {
      final player = QwixxPlayer(name: 'Ada');
      for (final value in [2, 3, 4, 5]) {
        player.mark(QwixxColor.red, value);
      }
      expect(player.canMark(QwixxColor.red, 12), isFalse);
      player.mark(QwixxColor.red, 6);
      expect(player.canMark(QwixxColor.red, 12), isTrue);

      player.mark(QwixxColor.red, 12);
      expect(player.lockedColors, contains(QwixxColor.red));
      expect(player.crossCount(QwixxColor.red), 7);
      expect(player.rowScore(QwixxColor.red), 28);
    });

    test('triangular row scoring and misses are calculated officially', () {
      const scores = [0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66];
      for (var crosses = 0; crosses <= 11; crosses++) {
        expect(QwixxPlayer.scoreForCrosses(crosses), scores[crosses]);
      }
      final player = QwixxPlayer(name: 'Ada', misses: 3);
      expect(player.missPenalty, -15);
    });

    test('lock cross raises the maximum row score to 78', () {
      expect(QwixxPlayer.scoreForCrosses(12), 78);
    });
  });

  group('Qwixx state and persistence', () {
    test('eligible players can simultaneously close the same pending row', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (final player in state.players) {
        for (final value in QwixxColor.red.numbers.take(5)) {
          player.mark(QwixxColor.red, value);
        }
      }

      state.mark(0, QwixxColor.red, 12);

      expect(state.pendingClosedColors, {QwixxColor.red});
      expect(state.closedColors, isEmpty);
      expect(state.canMark(1, QwixxColor.red, 12), isTrue);
      expect(
        state.canMark(1, QwixxColor.red, 7),
        isFalse,
        reason: 'only the same terminal number remains available while pending',
      );

      state.mark(1, QwixxColor.red, 12);
      expect(state.players[0].crossCount(QwixxColor.red), 7);
      expect(state.players[1].crossCount(QwixxColor.red), 7);
      expect(state.players[0].rowScore(QwixxColor.red), 28);
      expect(state.players[1].rowScore(QwixxColor.red), 28);
    });

    test('next player finalizes pending closures before rotating', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (final value in QwixxColor.red.numbers.take(5)) {
        state.players.first.mark(QwixxColor.red, value);
      }
      state.mark(0, QwixxColor.red, 12);

      state.nextPlayer();

      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {QwixxColor.red});
      expect(state.activePlayerIndex, 1);
      expect(state.canMark(1, QwixxColor.red, 12), isFalse);
    });

    test('two pending closures end only on finalization without rotation', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (final color in [QwixxColor.red, QwixxColor.green]) {
        for (final value in color.numbers.take(5)) {
          state.players.first.mark(color, value);
        }
        state.mark(0, color, color.numbers.last);
      }

      expect(state.pendingClosedColors, {QwixxColor.red, QwixxColor.green});
      expect(state.closedColors, isEmpty);
      expect(state.isComplete, isFalse);

      state.nextPlayer();

      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {QwixxColor.red, QwixxColor.green});
      expect(state.isComplete, isTrue);
      expect(state.activePlayerIndex, 0);
    });

    test('miss finalizes pending shared row closures', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (final value in QwixxColor.red.numbers.take(5)) {
        state.players[1].mark(QwixxColor.red, value);
      }
      state.mark(1, QwixxColor.red, 12);

      state.markMiss(0);

      expect(state.players.first.misses, 1);
      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {QwixxColor.red});
    });

    test('fourth miss ends game immediately', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (var i = 0; i < 4; i++) {
        state.markMiss(0);
      }
      expect(state.players.first.misses, 4);
      expect(state.isComplete, isTrue);
    });

    test('Qwixx JSON roundtrip validates data', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      state.mark(1, QwixxColor.blue, 10);
      state.markMiss(0);
      state.activePlayerIndex = 1;

      final restored = QwixxGameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(restored.players[1].crossed[QwixxColor.blue], {10});
      expect(restored.players[0].misses, 1);
      expect(restored.activePlayerIndex, 1);
      expect(
        () => QwixxGameState.fromJson({
          ...state.toJson(),
          'players': [
            {'name': 'Ada', 'crossed': {}, 'lockedColors': [], 'misses': 5},
            state.players[1].toJson(),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => QwixxGameState.fromJson({
          ...state.toJson(),
          'closedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'global closures must be backed by a personal row lock',
      );
    });

    test('pending closures roundtrip and closure sets are validated', () {
      final state = QwixxGameState.newGame(['Ada', 'Bea']);
      for (final value in QwixxColor.red.numbers.take(5)) {
        state.players.first.mark(QwixxColor.red, value);
      }
      state.mark(0, QwixxColor.red, 12);

      final restored = QwixxGameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(restored.pendingClosedColors, {QwixxColor.red});
      expect(restored.closedColors, isEmpty);
      expect(restored.players.first.lockedColors, {QwixxColor.red});

      expect(
        () => QwixxGameState.fromJson({
          ...state.toJson(),
          'closedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'closed and pending colors must be disjoint',
      );
      expect(
        () => QwixxGameState.fromJson({
          ...state.toJson(),
          'pendingClosedColors': <String>[],
        }),
        throwsFormatException,
        reason: 'every personal lock must be globally closed or pending',
      );
      final openState = QwixxGameState.newGame(['Ada', 'Bea']);
      expect(
        () => QwixxGameState.fromJson({
          ...openState.toJson(),
          'pendingClosedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'pending closures must be backed by a personal row lock',
      );
    });

    test('legacy Qwixx saves without pending closures default to empty', () {
      final json = QwixxGameState.newGame(['Ada', 'Bea']).toJson()
        ..remove('pendingClosedColors');

      final restored = QwixxGameState.fromJson(json);

      expect(restored.pendingClosedColors, isEmpty);
    });

    test(
      'repository dispatches Qwixx and loads saves without discriminator',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final repository = SharedPreferencesGameRepository(preferences);
        final qwixx = QwixxGameState.newGame(['Ada', 'Bea']);
        await repository.save(qwixx);
        expect(await repository.load(), isA<QwixxGameState>());

        final legacy = GameState(
          ruleSet: RuleSet.yatzy,
          mode: GameMode.block,
          players: [Player(name: 'Alt')],
        );
        await preferences.setString(
          SharedPreferencesGameRepository.key,
          jsonEncode(legacy.toJson()..remove('type')),
        );
        final loaded = await repository.load();
        expect(loaded, isA<GameState>());
        expect((loaded as GameState).players.single.name, 'Alt');
      },
    );
  });
}

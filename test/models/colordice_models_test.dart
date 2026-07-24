import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('Colordice digital dice', () {
    test('allows each player white sum and active player one color sum', () {
      final state = ColordiceGameState.newGame([
        'Ada',
        'Bea',
      ], mode: GameMode.digital);
      state.rollDigital([2, 5, 3, 4, 6, 1]);

      expect(state.whiteSum, 7);
      expect(state.coloredSums[ColordiceColor.red], {5, 8});
      expect(
        state.canMarkDigital(
          1,
          ColordiceColor.yellow,
          7,
          ColordiceDigitalAction.white,
        ),
        isTrue,
      );
      expect(
        state.canMarkDigital(
          1,
          ColordiceColor.yellow,
          6,
          ColordiceDigitalAction.color,
        ),
        isFalse,
      );
      state.markDigital(
        1,
        ColordiceColor.yellow,
        7,
        ColordiceDigitalAction.white,
      );
      state.markDigital(0, ColordiceColor.red, 8, ColordiceDigitalAction.color);
      expect(
        state.canMarkDigital(
          1,
          ColordiceColor.blue,
          7,
          ColordiceDigitalAction.white,
        ),
        isFalse,
      );
      expect(
        state.canMarkDigital(
          0,
          ColordiceColor.green,
          11,
          ColordiceDigitalAction.color,
        ),
        isFalse,
      );
    });

    test(
      'finishing rotates player and misses only if active marked nothing',
      () {
        final state = ColordiceGameState.newGame([
          'Ada',
          'Bea',
        ], mode: GameMode.digital);
        state.rollDigital([1, 2, 3, 4, 5, 6]);
        state.markDigital(
          1,
          ColordiceColor.red,
          3,
          ColordiceDigitalAction.white,
        );
        state.finishDigitalTurn();
        expect(state.players[0].misses, 1);
        expect(state.activePlayerIndex, 1);
        expect(state.hasRolled, isFalse);
        expect(state.whiteMarkedPlayerIndices, isEmpty);
      },
    );

    test('digital turn and legacy block mode survive JSON', () {
      final state = ColordiceGameState.newGame([
        'Ada',
        'Bea',
      ], mode: GameMode.digital)..rollDigital([1, 2, 3, 4, 5, 6]);
      final decoded = ColordiceGameState.fromJson(state.toJson());
      expect(decoded.mode, GameMode.digital);
      expect(decoded.dice, [1, 2, 3, 4, 5, 6]);
      expect(decoded.hasRolled, isTrue);

      final legacy = Map<String, dynamic>.from(state.toJson())
        ..remove('mode')
        ..remove('dice')
        ..remove('hasRolled')
        ..remove('whiteMarkedPlayerIndices')
        ..remove('colorMarked');
      expect(ColordiceGameState.fromJson(legacy).mode, GameMode.block);

      final invalidBlock = state.toJson()
        ..['mode'] = GameMode.block.name
        ..['hasRolled'] = true;
      expect(
        () => ColordiceGameState.fromJson(invalidBlock),
        throwsFormatException,
      );
    });
  });

  group('Colordice rows', () {
    test('number orders match the four official rows', () {
      expect(ColordiceColor.red.numbers, [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(ColordiceColor.yellow.numbers, [
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
      ]);
      expect(ColordiceColor.green.numbers, [
        12,
        11,
        10,
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
      ]);
      expect(ColordiceColor.blue.numbers, [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2]);
    });

    test('skipped values stay unavailable and marks only move right', () {
      final player = ColordicePlayer(name: 'Ada');
      player.mark(ColordiceColor.red, 5);

      expect(player.canMark(ColordiceColor.red, 4), isFalse);
      expect(player.canMark(ColordiceColor.red, 5), isFalse);
      expect(player.canMark(ColordiceColor.red, 6), isTrue);
      expect(() => player.mark(ColordiceColor.red, 4), throwsStateError);
    });

    test('last number needs five prior crosses and adds lock to score', () {
      final player = ColordicePlayer(name: 'Ada');
      for (final value in [2, 3, 4, 5]) {
        player.mark(ColordiceColor.red, value);
      }
      expect(player.canMark(ColordiceColor.red, 12), isFalse);
      player.mark(ColordiceColor.red, 6);
      expect(player.canMark(ColordiceColor.red, 12), isTrue);

      player.mark(ColordiceColor.red, 12);
      expect(player.lockedColors, contains(ColordiceColor.red));
      expect(player.crossCount(ColordiceColor.red), 7);
      expect(player.rowScore(ColordiceColor.red), 28);
    });

    test('triangular row scoring and misses are calculated officially', () {
      const scores = [0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66];
      for (var crosses = 0; crosses <= 11; crosses++) {
        expect(ColordicePlayer.scoreForCrosses(crosses), scores[crosses]);
      }
      final player = ColordicePlayer(name: 'Ada', misses: 3);
      expect(player.missPenalty, -15);
    });

    test('lock cross raises the maximum row score to 78', () {
      expect(ColordicePlayer.scoreForCrosses(12), 78);
    });
  });

  group('Colordice state and persistence', () {
    test('eligible players can simultaneously close the same pending row', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (final player in state.players) {
        for (final value in ColordiceColor.red.numbers.take(5)) {
          player.mark(ColordiceColor.red, value);
        }
      }

      state.mark(0, ColordiceColor.red, 12);

      expect(state.pendingClosedColors, {ColordiceColor.red});
      expect(state.closedColors, isEmpty);
      expect(state.canMark(1, ColordiceColor.red, 12), isTrue);
      expect(
        state.canMark(1, ColordiceColor.red, 7),
        isFalse,
        reason: 'only the same terminal number remains available while pending',
      );

      state.mark(1, ColordiceColor.red, 12);
      expect(state.players[0].crossCount(ColordiceColor.red), 7);
      expect(state.players[1].crossCount(ColordiceColor.red), 7);
      expect(state.players[0].rowScore(ColordiceColor.red), 28);
      expect(state.players[1].rowScore(ColordiceColor.red), 28);
    });

    test('next player finalizes pending closures before rotating', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (final value in ColordiceColor.red.numbers.take(5)) {
        state.players.first.mark(ColordiceColor.red, value);
      }
      state.mark(0, ColordiceColor.red, 12);

      state.nextPlayer();

      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {ColordiceColor.red});
      expect(state.activePlayerIndex, 1);
      expect(state.canMark(1, ColordiceColor.red, 12), isFalse);
    });

    test('two pending closures end only on finalization without rotation', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (final color in [ColordiceColor.red, ColordiceColor.green]) {
        for (final value in color.numbers.take(5)) {
          state.players.first.mark(color, value);
        }
        state.mark(0, color, color.numbers.last);
      }

      expect(state.pendingClosedColors, {
        ColordiceColor.red,
        ColordiceColor.green,
      });
      expect(state.closedColors, isEmpty);
      expect(state.isComplete, isFalse);

      state.nextPlayer();

      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {ColordiceColor.red, ColordiceColor.green});
      expect(state.isComplete, isTrue);
      expect(state.activePlayerIndex, 0);
    });

    test('miss finalizes pending shared row closures', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (final value in ColordiceColor.red.numbers.take(5)) {
        state.players[1].mark(ColordiceColor.red, value);
      }
      state.mark(1, ColordiceColor.red, 12);

      state.markMiss(0);

      expect(state.players.first.misses, 1);
      expect(state.pendingClosedColors, isEmpty);
      expect(state.closedColors, {ColordiceColor.red});
    });

    test('fourth miss ends game immediately', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (var i = 0; i < 4; i++) {
        state.markMiss(0);
      }
      expect(state.players.first.misses, 4);
      expect(state.isComplete, isTrue);
    });

    test('Colordice JSON roundtrip validates data', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      state.mark(1, ColordiceColor.blue, 10);
      state.markMiss(0);
      state.activePlayerIndex = 1;

      final restored = ColordiceGameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(restored.players[1].crossed[ColordiceColor.blue], {10});
      expect(restored.players[0].misses, 1);
      expect(restored.activePlayerIndex, 1);
      expect(
        () => ColordiceGameState.fromJson({
          ...state.toJson(),
          'players': [
            {'name': 'Ada', 'crossed': {}, 'lockedColors': [], 'misses': 5},
            state.players[1].toJson(),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => ColordiceGameState.fromJson({
          ...state.toJson(),
          'closedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'global closures must be backed by a personal row lock',
      );
    });

    test('pending closures roundtrip and closure sets are validated', () {
      final state = ColordiceGameState.newGame(['Ada', 'Bea']);
      for (final value in ColordiceColor.red.numbers.take(5)) {
        state.players.first.mark(ColordiceColor.red, value);
      }
      state.mark(0, ColordiceColor.red, 12);

      final restored = ColordiceGameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(restored.pendingClosedColors, {ColordiceColor.red});
      expect(restored.closedColors, isEmpty);
      expect(restored.players.first.lockedColors, {ColordiceColor.red});

      expect(
        () => ColordiceGameState.fromJson({
          ...state.toJson(),
          'closedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'closed and pending colors must be disjoint',
      );
      expect(
        () => ColordiceGameState.fromJson({
          ...state.toJson(),
          'pendingClosedColors': <String>[],
        }),
        throwsFormatException,
        reason: 'every personal lock must be globally closed or pending',
      );
      final openState = ColordiceGameState.newGame(['Ada', 'Bea']);
      expect(
        () => ColordiceGameState.fromJson({
          ...openState.toJson(),
          'pendingClosedColors': ['red'],
        }),
        throwsFormatException,
        reason: 'pending closures must be backed by a personal row lock',
      );
    });

    test(
      'legacy Colordice saves without pending closures default to empty',
      () {
        final json = ColordiceGameState.newGame(['Ada', 'Bea']).toJson()
          ..remove('pendingClosedColors');

        final restored = ColordiceGameState.fromJson(json);

        expect(restored.pendingClosedColors, isEmpty);
      },
    );

    test(
      'repository dispatches Colordice and loads saves without discriminator',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final repository = SharedPreferencesGameRepository(preferences);
        final colordice = ColordiceGameState.newGame(['Ada', 'Bea']);
        await repository.save(colordice);
        final loadedResult = await repository.load();
        expect(loadedResult.state, isA<ColordiceGameState>());

        final legacy = GameState(
          ruleSet: RuleSet.yatzy,
          mode: GameMode.block,
          players: [Player(name: 'Alt')],
        );
        await preferences.setString(
          SharedPreferencesGameRepository.key,
          jsonEncode(legacy.toJson()..remove('type')),
        );
        final legacyResult = await repository.load();
        expect(legacyResult.state, isA<GameState>());
        expect((legacyResult.state as GameState).players.single.name, 'Alt');
      },
    );
  });
}

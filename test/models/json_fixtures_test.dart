import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/balut_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/colordice_models.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

Future<Map<String, dynamic>> _fixture(String name) async {
  final file = File('test/fixtures/$name');
  return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
}

void main() {
  test('classic v1.0 fixture migrates without type and extraKniffel', () async {
    final decoded = decodeSavedGameState(
      await _fixture('classic_v1_0_legacy.json'),
    );

    expect(decoded, isA<GameState>());
    expect(decoded.gameLabel, 'Yahtzee/Kniffel');
    expect(decoded.progressLabel, '1 von 13 Einträgen');
  });

  test('legacy Colordice fixture restores block defaults', () async {
    final decoded = decodeSavedGameState(
      await _fixture('colordice_v1_legacy_block.json'),
    );
    final state = decoded as ColordiceGameState;

    expect(state.mode, GameMode.block);
    expect(state.players.first.crossed[ColordiceColor.red], {2});
    expect(state.pendingClosedColors, isEmpty);
    expect(state.hasRolled, isFalse);
  });

  test('legacy 10.000 fixture restores a normal ledger', () async {
    final decoded = decodeSavedGameState(
      await _fixture('ten_thousand_v1_legacy_normal.json'),
    );
    final state = decoded as TenThousandGameState;

    expect(state.mode, GameMode.block);
    expect(state.turns, hasLength(1));
    expect(state.totals, [350, 0]);
  });

  test(
    '10.000 final-round fixture remains incomplete until attempts finish',
    () async {
      final state =
          decodeSavedGameState(
                await _fixture('ten_thousand_current_final_round.json'),
              )
              as TenThousandGameState;

      expect(state.isInFinalRound, isTrue);
      expect(state.isComplete, isFalse);
      expect(state.finalRoundTriggerPlayerIndex, 0);
      expect(state.finalRoundRemainingPlayerIndices, [1, 2]);
    },
  );

  test('10.000 complete tombstone fixture preserves chronology', () async {
    final state =
        decodeSavedGameState(
              await _fixture('ten_thousand_current_complete_tombstone.json'),
            )
            as TenThousandGameState;

    expect(state.isComplete, isTrue);
    expect(state.turns, hasLength(4));
    expect(state.turns.first.isDeleted, isTrue);
    expect(state.playerIndexForTurn(0), 0);
  });

  test('Balut digital fixture restores the active turn', () async {
    final state =
        decodeSavedGameState(await _fixture('balut_current_digital_turn.json'))
            as BalutGameState;

    expect(state.mode, GameMode.digital);
    expect(state.rollCount, 1);
    expect(state.dice, [1, 2, 3, 4, 5]);
    expect(state.activePlayerIndex, 0);
  });
}

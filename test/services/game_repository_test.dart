import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/qwixx_models.dart';
import 'package:wuerfelblock/models/ten_thousand_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  test(
    'decoder dispatches legacy classic, explicit classic, Qwixx, and 10.000',
    () {
      final classic = GameState(
        ruleSet: RuleSet.yatzy,
        mode: GameMode.block,
        players: [Player(name: 'Ada')],
      );
      final legacy = Map<String, dynamic>.from(classic.toJson())
        ..remove('type');
      expect(decodeSavedGameState(legacy), isA<GameState>());
      expect(decodeSavedGameState(classic.toJson()), isA<GameState>());
      expect(
        decodeSavedGameState(QwixxGameState.newGame(['A', 'B']).toJson()),
        isA<QwixxGameState>(),
      );
      expect(
        decodeSavedGameState(TenThousandGameState.newGame(['A', 'B']).toJson()),
        isA<TenThousandGameState>(),
      );
    },
  );

  test('decoder rejects an unknown persisted game type', () {
    expect(
      () => decodeSavedGameState({'type': 'future-game'}),
      throwsFormatException,
    );
  });

  test('legacy yatzy JSON keeps its label and original categories', () {
    final decoded =
        decodeSavedGameState({
              'ruleSet': 'yatzy',
              'mode': 'block',
              'players': [
                {'name': 'Ada', 'scores': <String, int>{}},
              ],
              'currentPlayerIndex': 0,
              'isComplete': false,
              'dice': [1, 1, 1, 1, 1],
              'held': [false, false, false, false, false],
              'rollCount': 0,
            })
            as GameState;

    expect(decoded.ruleSet, RuleSet.yatzy);
    expect(decoded.gameLabel, 'Yatzy (klassisch)');
    expect(decoded.ruleSet.categories, contains(ScoreCategory.onePair));
    expect(decoded.ruleSet.categories, contains(ScoreCategory.twoPairs));
    expect(decoded.ruleSet.categories, hasLength(15));
  });

  test('beschädigter Save wird defensiv gelöscht', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesGameRepository.key:
          '{"ruleSet":"kniffel","mode":"digital","players":[]}',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = SharedPreferencesGameRepository(preferences);

    expect(await repository.load(), isNull);
    expect(
      preferences.containsKey(SharedPreferencesGameRepository.key),
      isFalse,
    );
  });
}

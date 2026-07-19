import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
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

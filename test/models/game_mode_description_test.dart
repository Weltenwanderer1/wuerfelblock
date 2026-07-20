import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  test('GameMode exposes long and short description in German', () {
    expect(GameMode.block.shortDescription, equals('Echte Würfel'));
    expect(GameMode.digital.shortDescription, equals('Digital würfeln'));
    expect(
      GameMode.block.longDescription,
      equals(
        'Ihr würfelt am Tisch. Die App ersetzt nur den Papierblock; '
        'Einträge können korrigiert werden.',
      ),
    );
    expect(
      GameMode.digital.longDescription,
      equals(
        'Die App würfelt und prüft gültige Aktionen. '
        'Halten, Zugwechsel und Wertung laufen in der App.',
      ),
    );
  });
}

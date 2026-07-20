import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  group('GameRepository.load', () {
    test(
      'returns the saved state and no corruption reason on success',
      () async {
        final repository = MemoryGameRepository();
        await repository.save(
          GameState(
            ruleSet: RuleSet.kniffel,
            mode: GameMode.block,
            players: [
              Player(name: 'Ada'),
              Player(name: 'Bea'),
            ],
          ),
        );
        final result = await repository.load();
        expect(result.state, isNotNull);
        expect(result.corruptionReason, isNull);
        expect(result.hadCorruption, isFalse);
      },
    );

    test(
      'returns null state and a reason when the payload is garbage',
      () async {
        final repository = MemoryGameRepository()..backingStore = '{not json';
        final result = await repository.load();
        expect(result.state, isNull);
        expect(result.corruptionReason, isNotNull);
        expect(result.corruptionReason, contains('verworfen'));
        expect(result.hadCorruption, isTrue);
      },
    );

    test(
      'returns null state and a reason when the payload has unknown type',
      () async {
        final repository = MemoryGameRepository()
          ..backingStore = '{"type": "mystery"}';
        final result = await repository.load();
        expect(result.state, isNull);
        expect(result.corruptionReason, isNotNull);
        expect(result.corruptionReason, contains('Spieltyp'));
      },
    );

    test(
      'returns null state and a reason when the payload has missing keys',
      () async {
        final repository = MemoryGameRepository()
          ..backingStore = '{"type": "classic"}';
        final result = await repository.load();
        expect(result.state, isNull);
        expect(result.corruptionReason, isNotNull);
      },
    );

    test('clears the corrupt payload so the next load is silent', () async {
      final repository = MemoryGameRepository()..backingStore = 'garbage';
      await repository.load();
      final second = await repository.load();
      expect(second.state, isNull);
      expect(second.corruptionReason, isNull);
    });
  });
}

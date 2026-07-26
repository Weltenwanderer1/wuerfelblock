import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/dragon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  const expected = <int, String>{
    1: 'W:n1,e',
    2: 'W:n2,n3',
    3: 'W:n1,e,n4',
    4: 'W:n2,n3,e',
    5: 'W:f,n1',
    6: 'W:n3,n4,e',
    7: 'W:n1,n2,n5',
    8: 'W:f,n2,n3',
    9: 'W:n1,n3,n5,e',
    10: 'W:n2,n4,f,e',
    11: 'W:n1,n2,n3,n4',
    12: 'W:f,n1,n4,e',
    13: 'W:n2,n3,n5,f',
    14: 'W:n1,n3,n4,n5,e',
    15: 'F:n1,n2,e,e',
    16: 'F:n2,n3,n4,e',
    17: 'F:n1,n3,n5,e',
    18: 'F:n2,n4,n5,e',
    19: 'F:n1,n2,n3,n4',
    20: 'F:n3,n4,n5,e',
    21: 'F:n1,n2,n4,n5',
    22: 'F:n2,n3,n4,n5',
    23: 'F:n1,n3,n4,e',
    24: 'F:n2,n3,n5,e',
    25: 'F:n1,n2,n3,n5',
    26: 'F:n3,n4,n5,n1',
    27: 'F:n2,n4,n5,n3',
    28: 'F:n1,n3,n4,n5',
    29: 'L:m1,n2,e,n3',
    30: 'L:m2,m3,e,n4',
    31: 'L:m1,n2,n3,e',
    32: 'L:m2,n3,m4,n5',
    33: 'L:m1,m3,e,e',
    34: 'L:m2,m4,n1,n3',
    35: 'L:m1,n2,m3,n4,e',
    36: 'L:m2,m3,m4,e',
    37: 'L:m1,m2,n3,n4,e',
    38: 'L:m3,m5,n1,e,e',
    39: 'L:m1,m2,m3,n4,e',
    40: 'L:m2,m4,m5,n1,e',
    41: 'L:m1,m3,m5,n2,e',
    42: 'L:m1,m2,m3,m4,n5',
  };

  String signature(DragonCard card) {
    final type = switch (card.type) {
      DragonType.water => 'W',
      DragonType.fire => 'F',
      DragonType.luck => 'L',
    };
    final fields = card.fields
        .map(
          (field) => switch (field.kind) {
            DragonFieldKind.number =>
              '${field.mandatory ? 'm' : 'n'}${field.number}',
            DragonFieldKind.flame => 'f',
            DragonFieldKind.empty => 'e',
          },
        )
        .join(',');
    return '$type:$fields';
  }

  group('the 42-card deck', () {
    test('contains every id exactly once', () {
      expect(DragonDeck.cards, hasLength(42));
      expect(DragonDeck.cards.map((c) => c.id).toSet(), expected.keys.toSet());
    });
    for (final entry in expected.entries) {
      test('card ${entry.key} is defined exactly', () {
        final card = DragonDeck.cards.singleWhere((c) => c.id == entry.key);
        expect(signature(card), entry.value);
      });
    }
    test('contains fourteen cards of every dragon type', () {
      for (final type in DragonType.values) {
        expect(DragonDeck.cards.where((c) => c.type == type), hasLength(14));
      }
    });
    test('fire dragons have four fields and no flame field', () {
      for (final card in DragonDeck.cards.where(
        (c) => c.type == DragonType.fire,
      )) {
        expect(card.fields, hasLength(4));
        expect(
          card.fields.any((f) => f.kind == DragonFieldKind.flame),
          isFalse,
        );
      }
    });
  });

  group('field matching', () {
    const normal = DragonCard(id: 99, type: DragonType.water, fields: []);
    const fire = DragonCard(id: 98, type: DragonType.fire, fields: []);
    test('number fields accept exact values', () {
      expect(const DragonField.number(3).accepts(3, card: normal), isTrue);
      expect(const DragonField.number(3).accepts(2, card: normal), isFalse);
    });
    test('six is a wildcard on normal number fields', () {
      expect(const DragonField.number(3).accepts(6, card: normal), isTrue);
    });
    test('flame fields accept only six', () {
      expect(const DragonField.flame().accepts(6, card: normal), isTrue);
      expect(const DragonField.flame().accepts(5, card: normal), isFalse);
    });
    test('empty fields accept every die', () {
      for (var value = 1; value <= 6; value++) {
        expect(const DragonField.empty().accepts(value, card: normal), isTrue);
      }
    });
    test('fire dragons reject six on every field', () {
      expect(const DragonField.number(3).accepts(6, card: fire), isFalse);
      expect(const DragonField.empty().accepts(6, card: fire), isFalse);
    });
    test('fire number fields require exact values', () {
      expect(const DragonField.number(3).accepts(3, card: fire), isTrue);
      expect(const DragonField.number(3).accepts(4, card: fire), isFalse);
    });
    test('invalid die values are rejected', () {
      expect(
        () => const DragonField.empty().accepts(0, card: normal),
        throwsArgumentError,
      );
      expect(
        () => const DragonField.empty().accepts(7, card: normal),
        throwsArgumentError,
      );
    });
  });

  group('attempt and scoring', () {
    final luck = DragonDeck.cards.singleWhere((c) => c.id == 30);
    test('mandatory fields remain open until covered', () {
      var attempt = DragonAttempt.empty(luck);
      expect(attempt.allMandatoryCovered, isFalse);
      attempt = attempt.place(0, 2);
      expect(attempt.allMandatoryCovered, isFalse);
      attempt = attempt.place(1, 3);
      expect(attempt.allMandatoryCovered, isTrue);
    });
    test('a six contributes zero gold', () {
      var attempt = DragonAttempt.empty(DragonDeck.cards.first);
      attempt = attempt.place(0, 6).place(1, 5);
      expect(attempt.diceGold, 5);
    });
    test('all fields covered means tamed', () {
      var attempt = DragonAttempt.empty(DragonDeck.cards.first);
      attempt = attempt.place(0, 1).place(1, 2);
      expect(attempt.isTamed, isTrue);
    });
    test('occupied and mismatching placements are rejected', () {
      final attempt = DragonAttempt.empty(DragonDeck.cards.first).place(0, 1);
      expect(() => attempt.place(0, 1), throwsStateError);
      expect(() => attempt.place(1, 7), throwsArgumentError);
    });
  });

  group('game state', () {
    test('new game supports two to four unique players', () {
      expect(DragonGameState.newGame(['A', 'B']).players, hasLength(2));
      expect(
        DragonGameState.newGame(['A', 'B', 'C', 'D']).players,
        hasLength(4),
      );
      expect(() => DragonGameState.newGame(['A']), throwsArgumentError);
      expect(() => DragonGameState.newGame(['A', 'A']), throwsArgumentError);
      expect(
        () => DragonGameState.newGame(['A', 'B', 'C', 'D', 'E']),
        throwsArgumentError,
      );
    });
    test(
      'full and quick games contain 42 and 20 cards including current card',
      () {
        expect(DragonGameState.newGame(['A', 'B']).cardsInGame, 42);
        expect(
          DragonGameState.newGame(['A', 'B'], quickGame: true).cardsInGame,
          20,
        );
      },
    );
    test('starts with 48 pool gold and zero player gold', () {
      final state = DragonGameState.newGame(['A', 'B']);
      expect(state.goldPool, 48);
      expect(state.players.every((p) => p.gold == 0), isTrue);
    });
    test('JSON roundtrip preserves an active digital game', () {
      final state = DragonGameState.newGame(
        ['A', 'B'],
        mode: GameMode.digital,
        quickGame: true,
        shuffledCards: DragonDeck.cards,
      );
      expect(DragonGameState.fromJson(state.toJson()).toJson(), state.toJson());
    });
    test('JSON rejects unknown fields', () {
      final json = DragonGameState.newGame(['A', 'B']).toJson()
        ..['surprise'] = true;
      expect(() => DragonGameState.fromJson(json), throwsFormatException);
    });
  });
}

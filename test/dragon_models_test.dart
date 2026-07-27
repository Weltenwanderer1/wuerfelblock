import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/dragon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';

void main() {
  const expected = <int, String>{
    1: 'W:b3,e',
    2: 'W:n2,b4',
    3: 'W:b2,e,n5',
    4: 'W:n3,b5,e',
    5: 'W:f,b1',
    6: 'W:b3,n4,e',
    7: 'W:n1,b5,n2',
    8: 'W:f,b4,n3',
    9: 'W:b2,n5,e,n3',
    10: 'F:s8/2-3,n2,e',
    11: 'F:n3,s10/2-3,e',
    12: 'F:s7/2-3,n4,n1',
    13: 'F:n2,n5,s12/2-3',
    14: 'F:s9/2-3,n3,n4',
    15: 'F:n1,s11/2-3,n5',
    16: 'F:s13/2-3,n2,n3',
    17: 'F:n4,s14/2-3,n1',
    18: 'F:s15/2-3,n5,n3',
    19: 'L:g2,m1,e',
    20: 'L:m3,g4,e',
    21: 'L:g1,m2,n5',
    22: 'L:m4,g3,m1',
    23: 'L:g5,m2,e',
    24: 'L:m1,g4,m3',
    25: 'L:g2,m5,n3,e',
    26: 'L:m3,g1,m4',
    27: 'L:g5,m2,m3,e',
    28: 'G:k3,s10/2-4,e+5',
    29: 'G:k5,s12/2-4,n2+6',
    30: 'G:k1,s14/2-4,e+7',
    31: 'G:k4,s16/2-4,n3+8',
    32: 'G:k2,s18/2-4,e+9',
    33: 'G:k6,s20/2-4,n1+10',
    34: 'G:k3,s15/2-4,n5,e+7',
    35: 'G:k5,s17/2-4,n2+8',
    36: 'G:k4,s19/2-4,e,n1+10',
    37: 'B:h12,h18,h8',
    38: 'B:h15,h20,h10',
    39: 'B:h10,h16,h22,h6',
    40: 'B:h18,h24,h12',
    41: 'B:h20,h25,h15,h8',
  };

  String signature(DragonCard card) {
    final type = switch (card.type) {
      DragonType.water => 'W',
      DragonType.fire => 'F',
      DragonType.luck => 'L',
      DragonType.ghost => 'G',
      DragonType.boss => 'B',
    };
    final fields = card.fields
        .map(
          (field) => switch (field.kind) {
            DragonFieldKind.number =>
              '${field.mandatory ? 'm' : 'n'}${field.number}',
            DragonFieldKind.flame => 'f',
            DragonFieldKind.empty => 'e',
            DragonFieldKind.coloredDie =>
              '${switch (field.dieColor!) {
                DieColor.blue => 'b',
                DieColor.green => 'g',
                DieColor.black => 'k',
                DieColor.white => 'w',
              }}${field.number}',
            DragonFieldKind.sum =>
              's${field.sumTarget}/${field.sumMinDice}-${field.sumMaxDice}',
            DragonFieldKind.bossHp => 'h${field.bossHp}',
          },
        )
        .join(',');
    return '$type:$fields${card.bonusPoints == 0 ? '' : '+${card.bonusPoints}'}';
  }

  group('dice', () {
    test('defines all four die colors and their labels', () {
      expect(DieColor.values, [
        DieColor.white,
        DieColor.blue,
        DieColor.green,
        DieColor.black,
      ]);
      expect(DieColor.values.map((color) => color.label), [
        'Weiß',
        'Blau',
        'Grün',
        'Schwarz',
      ]);
      expect(standardDiceColors, [
        DieColor.white,
        DieColor.white,
        DieColor.blue,
        DieColor.green,
        DieColor.black,
      ]);
    });

    test('DieRoll exposes value, color, equality, flame, and text', () {
      const flame = DieRoll(6, DieColor.white);
      expect(flame.value, 6);
      expect(flame.color, DieColor.white);
      expect(flame.isFlame, isTrue);
      expect(const DieRoll(6, DieColor.blue).isFlame, isFalse);
      expect(flame, const DieRoll(6, DieColor.white));
      expect(flame, isNot(const DieRoll(5, DieColor.white)));
      expect(flame.toString(), 'white:6');
    });

    test('DieRoll JSON roundtrip preserves value and color', () {
      const die = DieRoll(4, DieColor.green);
      expect(DieRoll.fromJson(die.toJson()), die);
      expect(
        () => DieRoll.fromJson({'value': 4, 'color': 'green', 'extra': 1}),
        throwsFormatException,
      );
    });
  });

  group('the 41-card Schuppenschatz deck', () {
    final deck = DragonDeck.buildDeck(random: Random(1234));

    test('contains every id exactly once', () {
      expect(deck, hasLength(41));
      expect(deck.map((card) => card.id).toSet(), expected.keys.toSet());
    });
    for (final entry in expected.entries) {
      test('card ${entry.key} is defined exactly', () {
        final card = deck.singleWhere((candidate) => candidate.id == entry.key);
        expect(signature(card), entry.value);
      });
    }
    test('contains all five dragon types', () {
      expect(deck.map((card) => card.type).toSet(), DragonType.values.toSet());
    });
    test('places a boss on every seventh position', () {
      expect(
        [
          for (var index = 0; index < deck.length; index++)
            if (deck[index].isBoss) index + 1,
        ],
        [7, 14, 21, 28, 35],
      );
      expect(
        [for (var index = 6; index < deck.length; index += 7) deck[index].id],
        [37, 38, 39, 40, 41],
      );
    });
    test('fire dragons contain one sum field and no flame field', () {
      for (final card in deck.where((card) => card.type == DragonType.fire)) {
        expect(
          card.fields.where((field) => field.kind == DragonFieldKind.sum),
          hasLength(1),
        );
        expect(
          card.fields.any((field) => field.kind == DragonFieldKind.flame),
          isFalse,
        );
      }
    });
    test('ghost dragons expose their bonus points', () {
      final ghosts = deck
          .where((card) => card.type == DragonType.ghost)
          .toList();
      expect(ghosts, hasLength(9));
      expect(ghosts.every((card) => card.bonusPoints > 0), isTrue);
      expect(
        {for (final card in ghosts) card.id: card.bonusPoints},
        {28: 5, 29: 6, 30: 7, 31: 8, 32: 9, 33: 10, 34: 7, 35: 8, 36: 10},
      );
    });
  });

  group('field matching', () {
    const normal = DragonCard(id: 99, type: DragonType.water, fields: []);
    const fire = DragonCard(id: 98, type: DragonType.fire, fields: []);
    const boss = DragonCard(id: 97, type: DragonType.boss, fields: []);

    test(
      'number fields accept exact white values and a white six wildcard',
      () {
        expect(
          const DragonField.number(
            3,
          ).acceptsDie(const DieRoll(3, DieColor.white), card: normal),
          isTrue,
        );
        expect(
          const DragonField.number(
            3,
          ).acceptsDie(const DieRoll(6, DieColor.white), card: normal),
          isTrue,
        );
        expect(
          const DragonField.number(
            3,
          ).acceptsDie(const DieRoll(3, DieColor.blue), card: normal),
          isFalse,
        );
        expect(
          const DragonField.number(
            3,
          ).acceptsDie(const DieRoll(2, DieColor.white), card: normal),
          isFalse,
        );
      },
    );
    test('flame fields accept only a white six', () {
      expect(
        const DragonField.flame().acceptsDie(
          const DieRoll(6, DieColor.white),
          card: normal,
        ),
        isTrue,
      );
      expect(
        const DragonField.flame().acceptsDie(
          const DieRoll(6, DieColor.blue),
          card: normal,
        ),
        isFalse,
      );
      expect(
        const DragonField.flame().acceptsDie(
          const DieRoll(5, DieColor.white),
          card: normal,
        ),
        isFalse,
      );
    });
    test('empty fields accept every standard die color', () {
      for (final color in DieColor.values) {
        expect(
          const DragonField.empty().acceptsDie(DieRoll(4, color), card: normal),
          isTrue,
        );
      }
    });
    test('colored-die fields require exact color and value', () {
      const field = DragonField.coloredDie(DieColor.green, 4);
      expect(field.kind, DragonFieldKind.coloredDie);
      expect(field.dieColor, DieColor.green);
      expect(field.number, 4);
      expect(field.mandatory, isTrue);
      expect(
        field.acceptsDie(const DieRoll(4, DieColor.green), card: normal),
        isTrue,
      );
      expect(
        field.acceptsDie(const DieRoll(4, DieColor.blue), card: normal),
        isFalse,
      );
      expect(
        field.acceptsDie(const DieRoll(3, DieColor.green), card: normal),
        isFalse,
      );
    });
    test('sum fields enforce target and die-count range', () {
      const field = DragonField.sum(10, sumMinDice: 2, sumMaxDice: 3);
      expect(field.kind, DragonFieldKind.sum);
      expect(field.sumTarget, 10);
      expect(field.sumMinDice, 2);
      expect(field.sumMaxDice, 3);
      expect(
        field.acceptsSum(const [
          DieRoll(4, DieColor.white),
          DieRoll(6, DieColor.blue),
        ], card: normal),
        isTrue,
      );
      expect(
        field.acceptsSum(const [DieRoll(4, DieColor.white)], card: normal),
        isTrue, // partial sums are allowed; completeness checked by isSumComplete
      );
      expect(
        field.isSumComplete(4, 1),
        isFalse, // 1 die, sum=4 — not complete yet
      );
      expect(
        field.isSumComplete(10, 2),
        isTrue,
      );
      expect(
        field.acceptsSum(const [
          DieRoll(4, DieColor.white),
          DieRoll(5, DieColor.blue),
        ], card: normal),
        isTrue, // partial sums are allowed (9 <= 10)
      );
      expect(
        field.isSumComplete(9, 2),
        isFalse, // 9 != 10
      );
      expect(
        field.acceptsSum(const [
          DieRoll(6, DieColor.white),
          DieRoll(5, DieColor.blue),
        ], card: normal),
        isFalse, // exceeds target (11 > 10)
      );
      expect(
        field.acceptsDie(const DieRoll(5, DieColor.white), card: normal),
        isFalse,
      );
    });
    test('fire dragons reject six on number and sum fields', () {
      expect(
        const DragonField.number(
          3,
        ).acceptsDie(const DieRoll(6, DieColor.white), card: fire),
        isFalse,
      );
      expect(
        const DragonField.sum(8).acceptsSum(const [
          DieRoll(2, DieColor.white),
          DieRoll(6, DieColor.blue),
        ], card: fire),
        isFalse,
      );
    });
    test('boss HP fields expose HP and respect effective remaining HP', () {
      const field = DragonField.bossHp(18);
      expect(field.kind, DragonFieldKind.bossHp);
      expect(field.bossHp, 18);
      expect(field.symbol, '♥18');
      expect(
        field.acceptsDie(
          const DieRoll(5, DieColor.black),
          card: boss,
          effectiveBossHp: 5,
        ),
        isTrue,
      );
      expect(
        field.acceptsDie(
          const DieRoll(6, DieColor.white),
          card: boss,
          effectiveBossHp: 5,
        ),
        isFalse,
      );
    });
    test('effective values apply field reductions', () {
      expect(const DragonField.number(5).effectiveNumber(2), 3);
      expect(
        const DragonField.coloredDie(DieColor.blue, 4).effectiveNumber(1),
        3,
      );
      expect(const DragonField.sum(12).effectiveNumber(3), 9);
      expect(const DragonField.bossHp(12).effectiveNumber(3), 0);
    });
    test('invalid die values are rejected', () {
      expect(
        () => const DragonField.empty().acceptsDie(
          const DieRoll(0, DieColor.white),
          card: normal,
        ),
        throwsArgumentError,
      );
      expect(
        () => const DragonField.empty().acceptsDie(
          const DieRoll(7, DieColor.white),
          card: normal,
        ),
        throwsArgumentError,
      );
    });
  });

  group('attempt and scoring', () {
    const luck = DragonCard(
      id: 96,
      type: DragonType.luck,
      fields: [
        DragonField.coloredDie(DieColor.green, 2),
        DragonField.number(1, mandatory: true),
        DragonField.empty(),
      ],
    );

    test('mandatory fields remain open until covered', () {
      var attempt = DragonAttempt.empty(luck);
      expect(attempt.allMandatoryCovered, isFalse);
      attempt = attempt.placeSingle(0, const DieRoll(2, DieColor.green));
      expect(attempt.allMandatoryCovered, isFalse);
      attempt = attempt.placeSingle(1, const DieRoll(1, DieColor.white));
      expect(attempt.allMandatoryCovered, isTrue);
    });
    test('placeSingle records values and colors in placed fields', () {
      final attempt = DragonAttempt.empty(
        luck,
      ).placeSingle(0, const DieRoll(2, DieColor.green));
      expect(attempt.placed, hasLength(3));
      expect(attempt.placed[0]!.values, [2]);
      expect(attempt.placed[0]!.colors, [DieColor.green]);
      expect(attempt.placed[0]!.sum, 2);
      expect(attempt.openFieldIndices, [1, 2]);
      expect(
        () => attempt.placed[1] = attempt.placed[0],
        throwsUnsupportedError,
      );
    });
    test('placeSum records every die and contributes their gold', () {
      const card = DragonCard(
        id: 95,
        type: DragonType.ghost,
        fields: [DragonField.sum(10)],
      );
      final attempt = DragonAttempt.empty(card).placeSum(0, const [
        DieRoll(4, DieColor.white),
        DieRoll(6, DieColor.black),
      ]);
      expect(attempt.placed[0]!.values, [4, 6]);
      expect(attempt.placed[0]!.colors, [DieColor.white, DieColor.black]);
      expect(attempt.placed[0]!.sum, 10);
      expect(attempt.placed[0]!.gold, 4);
      expect(attempt.diceGold, 4);
      expect(attempt.isTamed, isTrue);
    });
    test('a six contributes zero gold', () {
      const card = DragonCard(
        id: 94,
        type: DragonType.water,
        fields: [DragonField.empty(), DragonField.empty()],
      );
      final attempt = DragonAttempt.empty(card)
          .placeSingle(0, const DieRoll(6, DieColor.white))
          .placeSingle(1, const DieRoll(5, DieColor.blue));
      expect(attempt.diceGold, 5);
    });
    test('occupied and mismatching placements are rejected', () {
      final attempt = DragonAttempt.empty(
        luck,
      ).placeSingle(0, const DieRoll(2, DieColor.green));
      expect(
        () => attempt.placeSingle(0, const DieRoll(2, DieColor.green)),
        throwsStateError,
      );
      expect(
        () => attempt.placeSingle(1, const DieRoll(2, DieColor.white)),
        throwsArgumentError,
      );
      expect(
        () => attempt.placeSum(2, const [
          DieRoll(1, DieColor.white),
          DieRoll(2, DieColor.blue),
        ]),
        throwsArgumentError,
      );
      expect(
        () => attempt.placeSingle(3, const DieRoll(1, DieColor.white)),
        throwsRangeError,
      );
    });
    test('JSON roundtrip preserves placed single and sum fields', () {
      const card = DragonCard(
        id: 93,
        type: DragonType.ghost,
        fields: [DragonField.empty(), DragonField.sum(7)],
        bonusPoints: 4,
      );
      final attempt = DragonAttempt.empty(card)
          .placeSingle(0, const DieRoll(5, DieColor.black))
          .placeSum(1, const [
            DieRoll(3, DieColor.white),
            DieRoll(4, DieColor.green),
          ]);
      expect(
        DragonAttempt.fromJson(attempt.toJson()).toJson(),
        attempt.toJson(),
      );
    });
  });

  group('abilities and players', () {
    test('defines the three dragon abilities with user-facing information', () {
      expect(DragonAbility.values, [
        DragonAbility.reroll,
        DragonAbility.reduce,
        DragonAbility.handicap,
      ]);
      expect(
        DragonAbility.values.every((ability) => ability.label.isNotEmpty),
        isTrue,
      );
      expect(
        DragonAbility.values.every((ability) => ability.description.isNotEmpty),
        isTrue,
      );
    });
    test('usedAbilities prevents reusing an ability', () {
      const player = DragonPlayer(
        name: 'A',
        gold: 12,
        bonusGold: 5,
        tamedDragonIds: [1, 28],
        usedAbilities: [DragonAbility.reduce, DragonAbility.handicap],
      );
      expect(player.totalGold, 17);
      expect(player.tamedCount, 2);
      expect(player.canUse(DragonAbility.reroll), isTrue);
      expect(player.canUse(DragonAbility.reduce), isFalse);
      expect(player.canUse(DragonAbility.handicap), isFalse);
      expect(DragonPlayer.fromJson(player.toJson()).toJson(), player.toJson());
    });
    test('copyWith updates and preserves used abilities', () {
      const player = DragonPlayer(name: 'A');
      final changed = player.copyWith(
        gold: 8,
        usedAbilities: const [DragonAbility.reroll],
      );
      expect(changed.name, 'A');
      expect(changed.gold, 8);
      expect(changed.usedAbilities, [DragonAbility.reroll]);
      expect(changed.canUse(DragonAbility.reroll), isFalse);
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
      'full and quick games contain 41 and 20 cards including current card',
      () {
        final deck = DragonDeck.buildDeck(random: Random(4));
        expect(
          DragonGameState.newGame(['A', 'B'], shuffledCards: deck).cardsInGame,
          41,
        );
        expect(
          DragonGameState.newGame(
            ['A', 'B'],
            quickGame: true,
            shuffledCards: deck,
          ).cardsInGame,
          20,
        );
      },
    );
    test('starts with 48 pool gold and zero player gold', () {
      final state = DragonGameState.newGame(['A', 'B']);
      expect(state.goldPool, 48);
      expect(state.players.every((player) => player.gold == 0), isTrue);
    });
    test('boss cards initialize and expose remaining HP', () {
      final state = DragonGameState.newGame(
        ['A', 'B'],
        shuffledCards: [DragonDeck.bossCards.first],
      );
      expect(state.isBossCard, isTrue);
      expect(state.attempt, isNull);
      expect(state.bossRemainingHp, [12, 18, 8]);
      expect(state.bossDefeated, isFalse);
      final defeated = state.copyWith(bossRemainingHp: [0, -2, 0]);
      expect(defeated.bossDefeated, isTrue);
    });
    test('field reductions change effective card values', () {
      const card = DragonCard(
        id: 92,
        type: DragonType.fire,
        fields: [DragonField.number(5), DragonField.sum(12)],
      );
      final state = DragonGameState.newGame(
        ['A', 'B'],
        shuffledCards: const [card],
      ).copyWith(fieldReductions: [2, 3]);
      expect(state.fieldReductions, [2, 3]);
      expect(state.effectiveFieldValue(0), 3);
      expect(state.effectiveFieldValue(1), 9);
      expect(state.effectiveFieldValue(2), 0);
    });
    test('handicapDice and DieRoll dice are preserved', () {
      final state = DragonGameState.newGame(['A', 'B'], mode: GameMode.digital)
          .copyWith(
            handicapDice: 2,
            dice: const [
              DieRoll(1, DieColor.white),
              DieRoll(4, DieColor.blue),
              DieRoll(6, DieColor.black),
            ],
            selectedDieIndices: [1],
          );
      expect(state.handicapDice, 2);
      expect(state.dice, const [
        DieRoll(1, DieColor.white),
        DieRoll(4, DieColor.blue),
        DieRoll(6, DieColor.black),
      ]);
      expect(state.selectedDieIndices, [1]);
    });
    test('JSON roundtrip preserves all new active digital fields', () {
      final deck = DragonDeck.buildDeck(random: Random(8));
      final state =
          DragonGameState.newGame(
            ['A', 'B'],
            mode: GameMode.digital,
            quickGame: true,
            shuffledCards: deck,
          ).copyWith(
            players: const [
              DragonPlayer(name: 'A', usedAbilities: [DragonAbility.reroll]),
              DragonPlayer(name: 'B'),
            ],
            dice: const [
              DieRoll(2, DieColor.white),
              DieRoll(5, DieColor.green),
            ],
            selectedDieIndices: [0],
            handicapDice: 2,
            fieldReductions: List<int>.filled(deck.first.fields.length, 1),
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

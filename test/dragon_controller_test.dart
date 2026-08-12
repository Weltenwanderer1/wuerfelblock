import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/dragon_controller.dart';
import 'package:wuerfelblock/models/dragon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class TestRepository implements GameRepository {
  SavedGameState? saved;
  int saves = 0;
  int clears = 0;

  @override
  Future<void> save(SavedGameState state) async {
    saves++;
    saved = state;
  }

  @override
  Future<LoadResult> load() async => LoadResult(state: saved);

  @override
  Future<void> clear() async {
    clears++;
    saved = null;
  }
}

const permissiveCard = DragonCard(
  id: 1,
  type: DragonType.water,
  fields: [
    DragonField.empty(),
    DragonField.empty(),
    DragonField.empty(),
    DragonField.empty(),
    DragonField.empty(),
  ],
);

DragonController digital({
  required List<int> rolls,
  List<DragonCard> cards = const [permissiveCard],
  List<String> names = const ['Ada', 'Bob'],
  TestRepository? repository,
  DragonAbility Function()? abilityRewarder,
}) {
  final values = List<int>.of(rolls);
  return DragonController.newGame(
    names: names,
    mode: GameMode.digital,
    repository: repository ?? TestRepository(),
    shuffledCards: cards,
    roller: () => values.removeAt(0),
    abilityRewarder: abilityRewarder,
  );
}

DragonController block({
  List<DragonCard> cards = const [permissiveCard],
  TestRepository? repository,
}) => DragonController.newGame(
  names: const ['Ada', 'Bob'],
  mode: GameMode.block,
  repository: repository ?? TestRepository(),
  shuffledCards: cards,
);

void main() {
  group('newGame', () {
    test('creates a fresh game with the requested mode, players, and card', () {
      final game = DragonController.newGame(
        names: const [' Ada ', 'Bob'],
        mode: GameMode.digital,
        repository: TestRepository(),
        shuffledCards: const [permissiveCard],
      );

      expect(game.state.players.map((player) => player.name), ['Ada', 'Bob']);
      expect(game.state.mode, GameMode.digital);
      expect(game.state.currentCard, same(permissiveCard));
      expect(game.state.cardsInGame, 1);
      expect(game.state.dice, isEmpty);
      expect(game.state.selectedDieIndices, isEmpty);
      expect(game.state.handicapDice, 0);
      expect(game.state.players.every((player) => player.gold == 0), isTrue);
    });

    test('supports the eighteen-card quick game', () {
      final game = DragonController.newGame(
        names: const ['Ada', 'Bob'],
        quickGame: true,
        repository: TestRepository(),
        shuffledCards: DragonDeck.cards,
      );

      expect(game.state.cardsInGame, 18);
      expect(game.state.cardsRemaining, 18);
    });
  });

  test('rollDigital creates five value-and-color DieRoll objects', () async {
    final game = digital(rolls: [1, 2, 3, 4, 5]);

    await game.rollDigital();

    expect(game.state.dice, const [
      DieRoll(1, DieColor.white),
      DieRoll(2, DieColor.white),
      DieRoll(3, DieColor.blue),
      DieRoll(4, DieColor.green),
      DieRoll(5, DieColor.black),
    ]);
  });

  test('toggleDie supports multi-select and toggling a die off', () async {
    final game = digital(rolls: [1, 2, 3, 4, 5]);
    await game.rollDigital();

    await game.toggleDie(0);
    await game.toggleDie(3);
    expect(game.state.selectedDieIndices, [0, 3]);

    await game.toggleDie(0);
    expect(game.state.selectedDieIndices, [3]);
  });

  test(
    'placeSingleField places one selected colored die and removes it',
    () async {
      const card = DragonCard(
        id: 2,
        type: DragonType.water,
        fields: [DragonField.coloredDie(DieColor.blue, 3), DragonField.empty()],
      );
      final game = digital(rolls: [1, 2, 3, 4, 5], cards: const [card]);
      await game.rollDigital();
      await game.toggleDie(2);

      await game.placeSelectedOnField(0);

      expect(game.state.attempt!.placed[0]!.values, [3]);
      expect(game.state.attempt!.placed[0]!.colors, [DieColor.blue]);
      expect(game.state.dice, const [
        DieRoll(1, DieColor.white),
        DieRoll(2, DieColor.white),
        DieRoll(4, DieColor.green),
        DieRoll(5, DieColor.black),
      ]);
      expect(game.state.selectedDieIndices, isEmpty);
      expect(game.state.placementsSinceRoll, 1);
    },
  );

  test(
    'sum field accepts one die per roll and accumulates across rolls',
    () async {
      const card = DragonCard(
        id: 10,
        type: DragonType.fire,
        fields: [DragonField.sum(3), DragonField.empty()],
      );
      final game = digital(
        rolls: [1, 4, 4, 5, 3, 2, 4, 4, 5, 3],
        cards: const [card],
      );
      await game.rollDigital();
      await game.toggleDie(0);
      await game.placeSelectedOnField(0);
      expect(game.state.attempt!.placed[0]!.values, [1]);
      expect(game.state.dice, hasLength(4));

      await game.toggleDie(0);
      expect(() => game.placeSelectedOnField(0), throwsStateError);

      await game.continueRolling();
      await game.toggleDie(0);
      await game.placeSelectedOnField(0);

      expect(game.state.attempt!.placed[0]!.values, [1, 2]);
      expect(game.state.attempt!.placed[0]!.sum, 3);
      expect(game.state.selectedDieIndices, isEmpty);
    },
  );

  test('sum field remains playable beyond its legacy dice maximum', () async {
    const card = DragonCard(
      id: 11,
      type: DragonType.fire,
      fields: [DragonField.sum(10, sumMinDice: 2, sumMaxDice: 2)],
    );
    final game = digital(
      rolls: [1, 4, 4, 5, 3, 2, 4, 4, 5, 3, 3, 4, 4, 5, 2, 4, 4, 5, 3, 2],
      cards: const [card],
    );

    await game.rollDigital();
    for (final value in [1, 2, 3]) {
      await game.toggleDie(
        game.state.dice.indexWhere((die) => die.value == value),
      );
      await game.placeSelectedOnField(0);
      await game.continueRolling();
    }
    await game.toggleDie(game.state.dice.indexWhere((die) => die.value == 4));
    await game.placeSelectedOnField(0);

    expect(game.state.players.first.tamedDragonIds, [11]);
    expect(game.state.players.first.gold, 10);
  });

  test('block sum field also accepts one die per physical roll', () async {
    const card = DragonCard(
      id: 10,
      type: DragonType.fire,
      fields: [DragonField.sum(3), DragonField.empty()],
    );
    final game = block(cards: const [card]);

    await game.placeManualSum(0, const [(1, DieColor.white)]);
    expect(game.state.attempt!.placed[0]!.values, [1]);
    expect(
      () => game.placeManualSum(0, const [(2, DieColor.white)]),
      throwsStateError,
    );

    await game.continueRolling();
    await game.placeManualSum(0, const [(2, DieColor.white)]);
    expect(game.state.attempt!.placed[0]!.values, [1, 2]);
  });

  group('boss cards', () {
    test('placing a die reduces the selected boss HP field', () async {
      const boss = DragonCard(
        id: 37,
        type: DragonType.boss,
        fields: [DragonField.bossHp(5), DragonField.bossHp(7)],
      );
      final game = digital(rolls: [3, 2, 4, 5, 1], cards: const [boss]);
      await game.rollDigital();
      await game.toggleDie(0);

      await game.placeSelectedOnField(0);

      expect(game.state.bossRemainingHp, [2, 7]);
      expect(game.state.dice, hasLength(4));
      expect(game.canBossEndTurn, isTrue);
    });

    test('defeating the boss awards exactly 25 regular gold', () async {
      const boss = DragonCard(
        id: 37,
        type: DragonType.boss,
        fields: [DragonField.bossHp(1)],
      );
      final game = digital(rolls: [1, 2, 3, 4, 5], cards: const [boss]);
      await game.rollDigital();
      await game.toggleDie(0);

      await game.placeSelectedOnField(0);

      expect(game.state.players[0].gold, 25);
      expect(game.state.players[0].tamedDragonIds, [37]);
      expect(game.state.isComplete, isTrue);
      expect(game.lastMessage, contains('25 Gold'));
    });

    test(
      'a boss Fehlwurf passes it unchanged without a retroactive winner',
      () async {
        const boss = DragonCard(
          id: 37,
          type: DragonType.boss,
          fields: [DragonField.bossHp(1)],
        );
        final game = digital(rolls: [2, 3, 4, 5, 6], cards: const [boss]);

        await game.rollDigital();

        expect(game.state.activePlayerIndex, 1);
        expect(game.state.bossRemainingHp, [1]);
        expect(game.state.players.map((player) => player.gold), [0, 0]);
        expect(game.state.dice, isEmpty);
        expect(game.lastMessage, contains('Fehlwurf'));
      },
    );

    test(
      'endTurn passes an injured boss and preserves its remaining HP',
      () async {
        const boss = DragonCard(
          id: 37,
          type: DragonType.boss,
          fields: [DragonField.bossHp(5)],
        );
        final game = digital(rolls: [2, 1, 3, 4, 5], cards: const [boss]);
        await game.rollDigital();
        await game.toggleDie(0);
        await game.placeSelectedOnField(0);

        await game.endTurn();

        expect(game.state.activePlayerIndex, 1);
        expect(game.state.bossRemainingHp, [3]);
        expect(game.state.dice, isEmpty);
        expect(game.lastMessage, contains('nächsten Spieler'));
      },
    );

    test(
      'boss reroll uses only the unplaced dice after at least one hit',
      () async {
        const boss = DragonCard(
          id: 37,
          type: DragonType.boss,
          fields: [DragonField.bossHp(8)],
        );
        final game = digital(
          rolls: [2, 1, 3, 4, 5, 6, 5, 4, 3],
          cards: const [boss],
        );
        await game.rollDigital();
        await game.toggleDie(0);
        await game.placeSelectedOnField(0);

        expect(game.canContinue, isTrue);
        await game.continueRolling();

        expect(game.state.dice.map((die) => die.value), [6, 5, 4, 3]);
        expect(game.state.placementsSinceRoll, 0);
        expect(game.state.bossFieldsUsedThisRoll, isEmpty);
      },
    );

    test('boss cannot reroll before placing at least one die', () async {
      const boss = DragonCard(
        id: 37,
        type: DragonType.boss,
        fields: [DragonField.bossHp(8)],
      );
      final game = digital(rolls: [2, 1, 3, 4, 5], cards: const [boss]);
      await game.rollDigital();

      expect(game.canContinue, isFalse);
      expect(game.continueRolling(), throwsStateError);
    });
  });

  group('abilities', () {
    test(
      'reroll replaces the complete roll and can only be used once',
      () async {
        final game = digital(rolls: [1, 2, 3, 4, 5, 5, 4, 3, 2, 1]);
        await game.rollDigital();

        await game.useAbility(DragonAbility.reroll);

        expect(game.state.dice.map((die) => die.value), [5, 4, 3, 2, 1]);
        expect(game.state.activePlayer.usedAbilities, [DragonAbility.reroll]);
        await expectLater(
          game.useAbility(DragonAbility.reroll),
          throwsStateError,
        );
      },
    );

    test('reroll is also consumed in block mode without app dice', () async {
      final game = block();

      await game.useAbility(DragonAbility.reroll);

      expect(game.state.activePlayer.usedAbilities, [DragonAbility.reroll]);
      expect(game.lastMessage, contains('Fähigkeit verbraucht'));
    });

    test('reduce records a one-to-three point field reduction', () async {
      const card = DragonCard(
        id: 3,
        type: DragonType.water,
        fields: [DragonField.number(5), DragonField.empty()],
      );
      final game = digital(rolls: [1, 2, 3, 4, 5], cards: const [card]);

      await game.useAbility(DragonAbility.reduce, fieldIndex: 0, reduction: 2);

      expect(game.state.fieldReductions, [2, 0]);
      expect(game.state.effectiveFieldValue(0), 3);
      expect(game.state.activePlayer.usedAbilities, [DragonAbility.reduce]);
    });

    for (final mode in GameMode.values) {
      test(
        'reduce immediately tames an unplaced zero field in ${mode.name} mode',
        () async {
          const card = DragonCard(
            id: 10,
            type: DragonType.fire,
            fields: [DragonField.sum(3, sumMinDice: 2)],
          );
          const nextCard = DragonCard(
            id: 2,
            type: DragonType.water,
            fields: [DragonField.empty()],
          );
          final game = mode == GameMode.digital
              ? digital(rolls: [], cards: const [card, nextCard])
              : block(cards: const [card, nextCard]);

          await game.useAbility(
            DragonAbility.reduce,
            fieldIndex: 0,
            reduction: 3,
          );

          expect(game.state.players[0].tamedDragonIds, [10]);
          expect(game.state.players[0].gold, 0);
          expect(game.state.players[0].usedAbilities, [DragonAbility.reduce]);
          expect(game.state.currentCard, same(nextCard));
          expect(game.lastMessage, contains('gezähmt'));
        },
      );

      test(
        'reduce immediately completes a partial sum in ${mode.name} mode',
        () async {
          const card = DragonCard(
            id: 10,
            type: DragonType.fire,
            fields: [DragonField.sum(5, sumMinDice: 2)],
          );
          const nextCard = DragonCard(
            id: 2,
            type: DragonType.water,
            fields: [DragonField.empty()],
          );
          final game = mode == GameMode.digital
              ? digital(rolls: [3, 1, 2, 4, 5], cards: const [card, nextCard])
              : block(cards: const [card, nextCard]);
          if (mode == GameMode.digital) {
            await game.rollDigital();
            await game.toggleDie(0);
            await game.placeSelectedOnField(0);
          } else {
            await game.placeManualSum(0, const [(3, DieColor.white)]);
          }

          await game.useAbility(
            DragonAbility.reduce,
            fieldIndex: 0,
            reduction: 2,
          );

          expect(game.state.players[0].tamedDragonIds, [10]);
          expect(game.state.players[0].gold, 3);
          expect(game.state.players[0].usedAbilities, [DragonAbility.reduce]);
          expect(game.state.currentCard, same(nextCard));
          expect(game.lastMessage, contains('gezähmt'));
        },
      );

      test(
        'reduce does not tame an over-reduced partial sum in ${mode.name} mode',
        () async {
          const card = DragonCard(
            id: 10,
            type: DragonType.fire,
            fields: [DragonField.sum(3, sumMinDice: 2)],
          );
          const nextCard = DragonCard(
            id: 2,
            type: DragonType.water,
            fields: [DragonField.empty()],
          );
          final game = mode == GameMode.digital
              ? digital(rolls: [1, 2, 3, 4, 5], cards: const [card, nextCard])
              : block(cards: const [card, nextCard]);
          if (mode == GameMode.digital) {
            await game.rollDigital();
            await game.toggleDie(0);
            await game.placeSelectedOnField(0);
          } else {
            await game.placeManualSum(0, const [(1, DieColor.white)]);
          }

          await game.useAbility(
            DragonAbility.reduce,
            fieldIndex: 0,
            reduction: 3,
          );

          expect(game.state.players[0].tamedDragonIds, isEmpty);
          expect(game.state.currentCard, same(card));
          expect(
            game.state.attempt!.isTamed(game.state.fieldReductions),
            isFalse,
          );
        },
      );
    }

    test('reduce lets a die match the lowered value', () async {
      const card = DragonCard(
        id: 3,
        type: DragonType.water,
        fields: [DragonField.number(5), DragonField.empty()],
      );
      final game = digital(rolls: [3, 2, 4, 5, 1], cards: const [card]);

      await game.useAbility(DragonAbility.reduce, fieldIndex: 0, reduction: 2);
      await game.rollDigital();
      await game.toggleDie(0); // 3

      await game.placeSelectedOnField(0);

      expect(game.state.attempt!.placed[0]!.values, [3]);
      expect(game.state.attempt!.placedCount, 1);
    });

    test('reduce also weakens a selected boss HP field', () async {
      const boss = DragonCard(
        id: 37,
        type: DragonType.boss,
        fields: [DragonField.bossHp(5), DragonField.bossHp(7)],
      );
      final game = digital(rolls: [1, 2, 3, 4, 5], cards: const [boss]);

      await game.useAbility(DragonAbility.reduce, fieldIndex: 1, reduction: 3);

      expect(game.state.bossRemainingHp, [5, 4]);
      expect(game.state.activePlayer.usedAbilities, [DragonAbility.reduce]);
      expect(game.lastMessage, contains('Boss-Feld'));
    });

    test('reduce on a sum field lowers the target', () async {
      const card = DragonCard(
        id: 10,
        type: DragonType.fire,
        fields: [DragonField.sum(8, sumMaxDice: 3), DragonField.empty()],
      );
      const nextCard = DragonCard(
        id: 2,
        type: DragonType.water,
        fields: [DragonField.empty()],
      );
      final game = digital(
        rolls: [3, 2, 4, 5, 1, 2, 4, 4, 5, 3],
        cards: const [card, nextCard],
      );

      await game.useAbility(DragonAbility.reduce, fieldIndex: 0, reduction: 3);
      await game.rollDigital();
      await game.toggleDie(0); // 3
      await game.placeSelectedOnField(0);
      expect(game.state.attempt!.placed[0]!.values, [3]);
      expect(game.state.attempt!.placed[0]!.sum, 3);

      await game.continueRolling();
      await game.toggleDie(0); // 2
      await game.placeSelectedOnField(0);

      expect(game.state.attempt!.placed[0]!.values, [3, 2]);
      expect(game.state.attempt!.placed[0]!.sum, 5);
      // both fields filled: sum is complete
      await game.toggleDie(0); // 4
      await game.placeSelectedOnField(1); // empty field
      // after taming, a new card is drawn — check the player got gold
      expect(game.state.players[0].gold, 9); // 3+2+4 dice gold
    });

    test('handicapDice removes two dice from the next digital roll', () async {
      final game = digital(rolls: [1, 2, 3]);

      await game.useAbility(DragonAbility.handicap);
      expect(game.state.handicapDice, 2);
      await game.rollDigital();

      expect(game.state.dice, const [
        DieRoll(1, DieColor.white),
        DieRoll(2, DieColor.white),
        DieRoll(3, DieColor.blue),
      ]);
      expect(game.state.activePlayer.usedAbilities, [DragonAbility.handicap]);
    });
  });

  test('taming a luck dragon grants a random extra ability charge', () async {
    const luck = DragonCard(
      id: 19,
      type: DragonType.luck,
      fields: [DragonField.empty()],
    );
    const next = DragonCard(
      id: 1,
      type: DragonType.water,
      fields: [DragonField.empty()],
    );
    final game = digital(
      rolls: [4, 1, 2, 3, 5],
      cards: const [luck, next],
      abilityRewarder: () => DragonAbility.reroll,
    );

    await game.rollDigital();
    await game.toggleDie(0);
    await game.placeSelectedOnField(0);

    final winner = game.state.players.first;
    expect(winner.earnedAbilities, [DragonAbility.reroll]);
    expect(winner.availableAbilityCount(DragonAbility.reroll), 2);
    expect(winner.availableAbilityCount(DragonAbility.reduce), 1);
  });

  test('taming a ghost adds its bonusPoints to placed-dice gold', () async {
    const ghost = DragonCard(
      id: 28,
      type: DragonType.ghost,
      fields: [DragonField.empty()],
      bonusPoints: 7,
    );
    final game = digital(rolls: [4, 1, 2, 3, 5], cards: const [ghost]);
    await game.rollDigital();
    await game.toggleDie(0);

    await game.placeSelectedOnField(0);

    expect(game.state.players[0].gold, 11);
    expect(game.state.players[0].tamedDragonIds, [28]);
    expect(game.lastMessage, contains('gezähmt'));
  });

  test('failedAttempt passes a normal card and adds five card gold', () async {
    final game = block();

    await game.failAttempt();

    expect(game.state.activePlayerIndex, 1);
    expect(game.state.triedPlayerIndices, [0]);
    expect(game.state.cardGold, 5);
    expect(game.state.attempt!.placedCount, 0);
  });

  test(
    'endTurn banks placed die gold, adds five card gold, and passes',
    () async {
      const card = DragonCard(
        id: 4,
        type: DragonType.water,
        fields: [DragonField.number(2), DragonField.empty()],
      );
      final game = digital(rolls: [2, 1, 3, 4, 5], cards: const [card]);
      await game.rollDigital();
      await game.toggleDie(0);
      await game.placeSelectedOnField(0);

      await game.endTurn();

      expect(game.state.players[0].gold, 2);
      expect(game.state.cardGold, 5);
      expect(game.state.activePlayerIndex, 1);
      expect(game.state.triedPlayerIndices, [0]);
      expect(game.state.dice, isEmpty);
    },
  );

  test(
    'continueRolling requires a placement and starts a fresh colored roll',
    () async {
      final game = digital(rolls: [1, 2, 3, 4, 5, 5, 4, 3, 2, 1]);
      await game.rollDigital();
      await expectLater(game.continueRolling(), throwsStateError);
      await game.toggleDie(0);
      await game.placeSelectedOnField(0);

      await game.continueRolling();

      expect(game.state.dice, const [
        DieRoll(5, DieColor.white),
        DieRoll(4, DieColor.white),
        DieRoll(3, DieColor.blue),
        DieRoll(2, DieColor.green),
        DieRoll(1, DieColor.black),
      ]);
      expect(game.state.placementsSinceRoll, 0);
      expect(game.state.selectedDieIndices, isEmpty);
    },
  );

  test('JSON round-trip preserves schemaVersion 3 controller state', () async {
    const card = DragonCard(
      id: 29,
      type: DragonType.ghost,
      fields: [DragonField.coloredDie(DieColor.blue, 3), DragonField.sum(6)],
      bonusPoints: 6,
    );
    final game = digital(rolls: [1, 2, 3, 4, 5], cards: const [card]);
    await game.rollDigital();
    await game.toggleDie(0);
    await game.toggleDie(4);
    await game.useAbility(DragonAbility.reduce, fieldIndex: 1, reduction: 1);

    final json = game.state.toJson();
    final restored = DragonGameState.fromJson(json);

    expect(json['schemaVersion'], 4);
    expect(restored.toJson(), json);
    expect(restored.dice, game.state.dice);
    expect(restored.selectedDieIndices, [0, 4]);
    expect(restored.fieldReductions, [0, 1]);
    expect(restored.players[0].usedAbilities, [DragonAbility.reduce]);

    final version2 = Map<String, dynamic>.of(json)
      ..['schemaVersion'] = 2
      ..remove('sumFieldsReducedThisRoll')
      ..remove('bossFieldsUsedThisRoll')
      ..remove('rollCount');
    expect(
      DragonGameState.fromJson(version2).sumFieldsReducedThisRoll,
      isEmpty,
    );
  });

  test('abandon clears the repository', () async {
    final repository = TestRepository();
    final game = block(repository: repository);

    await game.abandon();

    expect(repository.clears, 1);
  });
}

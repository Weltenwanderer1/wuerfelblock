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
  bool failNextSave = false;
  @override
  Future<void> save(SavedGameState state) async {
    saves++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
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

DragonController digital({
  List<int>? rolls,
  List<DragonCard>? cards,
  List<String> names = const ['Ada', 'Bob'],
  TestRepository? repository,
}) {
  final values = List<int>.of(rolls ?? [1, 2, 3, 4, 5]);
  return DragonController.newGame(
    names: names,
    mode: GameMode.digital,
    repository: repository ?? TestRepository(),
    shuffledCards: cards ?? DragonDeck.cards,
    roller: () => values.removeAt(0),
  );
}

void main() {
  test('digital mode rolls five dice and selects one', () async {
    final game = digital();
    await game.rollDigital();
    expect(game.state.dice, [1, 2, 3, 4, 5]);
    await game.selectDie(0);
    expect(game.state.selectedDieIndex, 0);
  });

  test('digital placement validates field and removes the die', () async {
    final game = digital();
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    expect(game.state.attempt!.placedValues[0], 1);
    expect(game.state.dice, [2, 3, 4, 5]);
    expect(game.state.placementsSinceRoll, 1);
  });

  test('cannot continue before placing at least one die', () async {
    final game = digital(rolls: [1, 2, 3, 4, 5]);
    await game.rollDigital();
    await expectLater(game.continueRolling(), throwsStateError);
  });

  test('continue rerolls only remaining dice', () async {
    final game = digital(rolls: [1, 2, 3, 4, 5, 5, 4, 3, 2]);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    await game.continueRolling();
    expect(game.state.dice, [5, 4, 3, 2]);
    expect(game.state.placementsSinceRoll, 0);
  });

  test(
    'voluntary stop awards pip gold, six scores zero, and passes card',
    () async {
      final card = const DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [
          DragonField.number(1),
          DragonField.empty(),
          DragonField.empty(),
        ],
      );
      final game = digital(rolls: [6, 5, 2, 3, 4], cards: [card]);
      await game.rollDigital();
      await game.selectDie(0);
      await game.placeSelectedDie(0);
      await game.selectDie(0);
      await game.placeSelectedDie(1);
      await game.endTurn();
      expect(game.state.players[0].gold, 5);
      expect(game.state.cardGold, 5);
      expect(game.state.goldPool, 48);
      expect(game.state.activePlayerIndex, 1);
    },
  );

  test(
    'luck dragon cannot be stopped before all mandatory fields are covered',
    () async {
      final game = digital(
        rolls: [2, 1, 3, 4, 5],
        cards: [DragonDeck.cards[29]],
      );
      await game.rollDigital();
      await game.selectDie(0);
      await game.placeSelectedDie(0);
      expect(game.canEndTurn, isFalse);
      await expectLater(game.endTurn(), throwsStateError);
    },
  );

  test('luck dragon can stop once all mandatory fields are covered', () async {
    final game = digital(rolls: [2, 3, 1, 4, 5], cards: [DragonDeck.cards[29]]);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    await game.selectDie(0);
    await game.placeSelectedDie(1);
    expect(game.canEndTurn, isTrue);
  });

  test(
    'a luck roll may use a matching optional field while mandatory fields remain open',
    () async {
      final game = digital(
        rolls: [1, 1, 1, 1, 1],
        cards: [DragonDeck.cards[29]],
      );
      await game.rollDigital();
      expect(game.state.activePlayerIndex, 0);
      expect(game.state.dice, hasLength(5));
      await game.selectDie(0);
      await game.placeSelectedDie(2);
      expect(game.state.attempt!.placedValues[2], 1);
      expect(game.canEndTurn, isFalse);
    },
  );

  test('block mode can report that no die fits and pass the card', () async {
    final game = DragonController.newGame(
      names: ['A', 'B'],
      mode: GameMode.block,
      repository: TestRepository(),
      shuffledCards: DragonDeck.cards,
    );
    await game.failAttempt();
    expect(game.state.activePlayerIndex, 1);
    expect(game.state.triedPlayerIndices, [0]);
    expect(game.state.cardGold, 5);
  });

  test('a roll with no fitting die fails immediately', () async {
    final fire = const DragonCard(
      id: 15,
      type: DragonType.fire,
      fields: [
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
      ],
    );
    final game = digital(rolls: [1, 2, 3, 4, 6], cards: [fire]);
    await game.rollDigital();
    expect(game.state.activePlayerIndex, 1);
    expect(game.lastMessage, 'Kein passender Würfel! Zug beendet.');
  });

  test('dragon passes with five gold after a failed attempt', () async {
    final fire = const DragonCard(
      id: 15,
      type: DragonType.fire,
      fields: [
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
      ],
    );
    final game = digital(rolls: [1, 2, 3, 4, 6], cards: [fire]);
    await game.rollDigital();
    expect(game.state.cardGold, 5);
    expect(game.state.goldPool, 48);
  });

  test('dragon escapes after all players tried', () async {
    final fire = const DragonCard(
      id: 15,
      type: DragonType.fire,
      fields: [
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
        DragonField.number(5),
      ],
    );
    final game = digital(rolls: [1, 2, 3, 4, 6, 1, 2, 3, 4, 6], cards: [fire]);
    await game.rollDigital();
    await game.rollDigital();
    expect(game.state.isComplete, isTrue);
    expect(game.state.escapedDragonIds, [15]);
    expect(game.lastMessage, contains('entkommen'));
  });

  test(
    'taming awards dice and accumulated card gold plus dragon card',
    () async {
      final card = const DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [DragonField.number(1), DragonField.empty()],
      );
      final game = digital(rolls: [1, 5, 2, 3, 4], cards: [card]);
      await game.rollDigital();
      await game.selectDie(0);
      await game.placeSelectedDie(0);
      await game.selectDie(0);
      await game.placeSelectedDie(1);
      expect(game.state.players[0].gold, 6);
      expect(game.state.players[0].tamedDragonIds, [1]);
      expect(game.state.isComplete, isTrue);
    },
  );

  test('block mode accepts valid manual die entry', () async {
    final game = DragonController.newGame(
      names: ['A', 'B'],
      mode: GameMode.block,
      repository: TestRepository(),
      shuffledCards: DragonDeck.cards,
    );
    await game.placeManualDie(0, 1);
    expect(game.state.attempt!.placedValues[0], 1);
    expect(game.state.placementsSinceRoll, 1);
  });

  test('block mode rejects invalid manual die entry', () async {
    final game = DragonController.newGame(
      names: ['A', 'B'],
      mode: GameMode.block,
      repository: TestRepository(),
      shuffledCards: DragonDeck.cards,
    );
    await expectLater(game.placeManualDie(0, 2), throwsArgumentError);
  });

  test('block continue starts a fresh physical roll', () async {
    final game = DragonController.newGame(
      names: ['A', 'B'],
      mode: GameMode.block,
      repository: TestRepository(),
      shuffledCards: DragonDeck.cards,
    );
    await game.placeManualDie(0, 1);
    await game.continueRolling();
    expect(game.state.placementsSinceRoll, 0);
  });

  test(
    'normal save failure rolls placement and success message back',
    () async {
      const card = DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [DragonField.empty()],
      );
      final repo = TestRepository()..failNextSave = true;
      final game = DragonController.newGame(
        names: ['A', 'B'],
        mode: GameMode.block,
        repository: repo,
        shuffledCards: const [card],
      );
      await expectLater(game.placeManualDie(0, 1), throwsStateError);
      expect(game.state.attempt!.placedValues.every((v) => v == null), isTrue);
      expect(game.lastMessage, isNull);
    },
  );

  test('failed digital roll stays visible and can retry exact save', () async {
    final repo = TestRepository()..failNextSave = true;
    var calls = 0;
    final game = DragonController.newGame(
      names: ['A', 'B'],
      mode: GameMode.digital,
      repository: repo,
      shuffledCards: DragonDeck.cards,
      roller: () => ++calls,
    );
    await expectLater(game.rollDigital(), throwsStateError);
    expect(game.state.dice, [1, 2, 3, 4, 5]);
    expect(game.needsDigitalSaveRetry, isTrue);
    await game.retryDigitalSave();
    expect(game.needsDigitalSaveRetry, isFalse);
    expect(calls, 5);
  });

  test(
    'undo is blocked during save retry and restores the pre-roll state',
    () async {
      final repo = TestRepository();
      final game = digital(
        rolls: [1, 2, 3, 4, 5, 5, 4, 3, 2],
        repository: repo,
      );
      await game.rollDigital();
      await game.selectDie(0);
      await game.placeSelectedDie(0);
      repo.failNextSave = true;
      await expectLater(game.continueRolling(), throwsStateError);
      expect(game.state.dice, [5, 4, 3, 2]);
      expect(game.needsDigitalSaveRetry, isTrue);

      await expectLater(game.undo(), throwsStateError);
      expect(game.state.dice, [5, 4, 3, 2]);
      await game.retryDigitalSave();
      await game.undo();
      expect(game.state.dice, [2, 3, 4, 5]);
      expect(game.state.placementsSinceRoll, 1);
    },
  );

  test(
    'digital scoring never truncates gold because token count is not value',
    () async {
      const card = DragonCard(
        id: 1,
        type: DragonType.water,
        fields: [DragonField.empty(), DragonField.empty()],
      );
      final initial = DragonGameState.newGame(
        ['A', 'B'],
        mode: GameMode.block,
        shuffledCards: const [card],
      ).copyWith(goldPool: 1);
      final game = DragonController(
        state: initial,
        repository: TestRepository(),
      );
      await game.placeManualDie(0, 5);
      await game.endTurn();
      expect(game.state.players[0].gold, 5);
      expect(game.state.cardGold, 5);
    },
  );

  test('unique most dragons gets the twenty-gold bonus', () async {
    final cards = const [
      DragonCard(id: 1, type: DragonType.water, fields: [DragonField.empty()]),
      DragonCard(id: 2, type: DragonType.water, fields: [DragonField.empty()]),
      DragonCard(id: 3, type: DragonType.water, fields: [DragonField.empty()]),
    ];
    final game = digital(
      rolls: [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
      cards: cards,
    );
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    expect(game.state.players[0].bonusGold, 20);
    expect(game.state.players[1].bonusGold, 0);
    expect(game.state.bonusWinnerIndex, 0);
  });

  test('tie for most dragons awards no bonus', () async {
    final cards = const [
      DragonCard(id: 1, type: DragonType.water, fields: [DragonField.empty()]),
      DragonCard(id: 2, type: DragonType.water, fields: [DragonField.empty()]),
    ];
    final game = digital(rolls: [1, 2, 3, 4, 5, 1, 2, 3, 4, 5], cards: cards);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    await game.rollDigital();
    await game.selectDie(0);
    await game.placeSelectedDie(0);
    expect(game.state.players.map((p) => p.tamedCount), [1, 1]);
    expect(game.state.bonusWinnerIndex, isNull);
    expect(game.state.players.every((p) => p.bonusGold == 0), isTrue);
  });

  test('ranking uses total gold including bonus', () {
    final state = DragonGameState(
      players: const [
        DragonPlayer(name: 'A', gold: 5, bonusGold: 20),
        DragonPlayer(name: 'B', gold: 24),
      ],
      mode: GameMode.block,
      deck: const [],
      currentCard: null,
      attempt: null,
      cardsInGame: 0,
      goldPool: 19,
    );
    expect(state.ranking.first.name, 'A');
    expect(state.winners.single.name, 'A');
  });

  test('abandon clears repository', () async {
    final repo = TestRepository();
    final game = DragonController.newGame(
      names: ['A', 'B'],
      repository: repo,
      shuffledCards: DragonDeck.cards,
    );
    await game.abandon();
    expect(repo.clears, 1);
  });
}

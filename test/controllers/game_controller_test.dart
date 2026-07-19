import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/dice_controller.dart';
import 'package:wuerfelblock/controllers/game_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _DelayedRepository extends MemoryGameRepository {
  final pending = <Completer<void>>[];
  int saveCalls = 0;

  @override
  Future<void> save(SavedGameState state) async {
    saveCalls++;
    final completer = Completer<void>();
    pending.add(completer);
    await completer.future;
    await super.save(state);
  }
}

class _FailingSaveRepository extends MemoryGameRepository {
  @override
  Future<void> save(SavedGameState state) =>
      Future.error(Exception('save failed'));
}

class _ToggleRepository extends MemoryGameRepository {
  bool fail = false;

  @override
  Future<void> save(SavedGameState state) =>
      fail ? Future.error(Exception('save failed')) : super.save(state);
}

void main() {
  test('new Kniffel games require 2 to 8 players', () {
    expect(
      () => GameController.newGame(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        names: ['Ada'],
        repository: MemoryGameRepository(),
      ),
      throwsArgumentError,
    );
    expect(
      GameController.newGame(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        names: ['Ada', 'Berta'],
        repository: MemoryGameRepository(),
      ).state.players,
      hasLength(2),
    );
    expect(
      GameController.newGame(
        ruleSet: RuleSet.yatzy,
        mode: GameMode.block,
        names: ['Ada'],
        repository: MemoryGameRepository(),
      ).state.players,
      hasLength(1),
    );
  });

  group('physical block Zusatz-Kniffel', () {
    GameController game({GameRepository? repository, int firstKniffel = 50}) =>
        GameController(
          state: GameState(
            ruleSet: RuleSet.kniffel,
            mode: GameMode.block,
            players: [
              Player(name: 'Ada', scores: {ScoreCategory.yatzy: firstKniffel}),
              Player(name: 'Berta'),
            ],
          ),
          repository: repository ?? MemoryGameRepository(),
        );

    test('adds 50 bonus and category maximum for chosen player', () async {
      final controller = game();
      await controller.enterBlockExtraKniffelScore(
        ScoreCategory.smallStraight,
        playerIndex: 0,
      );
      expect(controller.state.players.first.extraKniffel, 1);
      expect(
        controller.state.players.first.scores[ScoreCategory.smallStraight],
        30,
      );
    });

    test('rejects without first Kniffel and rejects occupied target', () async {
      final noFirst = game(firstKniffel: 0);
      expect(
        () => noFirst.enterBlockExtraKniffelScore(
          ScoreCategory.ones,
          playerIndex: 0,
        ),
        throwsStateError,
      );
      final occupied = game();
      occupied.state.players.first.scores[ScoreCategory.ones] = 3;
      expect(
        () => occupied.enterBlockExtraKniffelScore(
          ScoreCategory.ones,
          playerIndex: 0,
        ),
        throwsStateError,
      );
    });

    test('undo removes both category score and bonus', () async {
      final controller = game();
      await controller.enterBlockExtraKniffelScore(
        ScoreCategory.ones,
        playerIndex: 0,
      );
      await controller.undo();
      expect(controller.state.players.first.extraKniffel, 0);
      expect(
        controller.state.players.first.scores.containsKey(ScoreCategory.ones),
        isFalse,
      );
    });

    test('save failure rolls back both category score and bonus', () async {
      final controller = game(repository: _FailingSaveRepository());
      await expectLater(
        controller.enterBlockExtraKniffelScore(
          ScoreCategory.ones,
          playerIndex: 0,
        ),
        throwsException,
      );
      expect(controller.state.players.first.extraKniffel, 0);
      expect(
        controller.state.players.first.scores.containsKey(ScoreCategory.ones),
        isFalse,
      );
      expect(controller.canUndo, isFalse);
    });
  });

  test('Wertung wechselt Spieler und Undo stellt Zustand wieder her', () async {
    final repository = MemoryGameRepository();
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: repository,
    );
    await game.enterScore(ScoreCategory.ones, 3);
    expect(game.state.currentPlayerIndex, 1);
    expect(game.state.players.first.scores[ScoreCategory.ones], 3);
    expect(repository.saved, isNotNull);
    await game.undo();
    expect(game.state.currentPlayerIndex, 0);
    expect(
      game.state.players.first.scores.containsKey(ScoreCategory.ones),
      isFalse,
    );
  });

  test('manuelle Eingabe validiert Bereich und erlaubt Null', () async {
    final game = GameController.newGame(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.block,
      names: ['Ada'],
      repository: MemoryGameRepository(),
    );
    expect(() => game.enterScore(ScoreCategory.yatzy, 51), throwsArgumentError);
    await game.enterScore(ScoreCategory.yatzy, 0);
    expect(game.state.players.first.scores[ScoreCategory.yatzy], 0);
  });

  test('fünf Würfel, Hold und maximal drei Würfe', () async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    var next = 0;
    final dice = DiceController(game: game, roller: () => (next++ % 6) + 1);
    await dice.roll();
    final heldValue = dice.dice.first;
    await dice.toggleHold(0);
    await dice.roll();
    expect(dice.dice.first, heldValue);
    await dice.roll();
    expect(dice.rollCount, 3);
    expect(dice.canRoll, isFalse);
    expect(() => dice.roll(), throwsStateError);
  });

  test('Spiel endet nach allen Kategorien und erkennt Gleichstand', () async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    for (final category in RuleSet.kniffel.categories) {
      await game.enterScore(category, 0, playerIndex: 0);
      await game.enterScore(category, 0, playerIndex: 1);
    }
    expect(game.state.isComplete, isTrue);
    expect(game.winners.map((p) => p.name), ['Ada', 'Berta']);
  });

  test('laufender Digitalzug wird gespeichert und wiederhergestellt', () async {
    final repository = MemoryGameRepository();
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: repository,
    );
    var next = 0;
    final dice = DiceController(game: game, roller: () => (next++ % 6) + 1);

    await dice.roll();
    await dice.toggleHold(0);

    final restored = await repository.load() as GameState;
    expect(restored.rollCount, 1);
    expect(restored.dice, dice.dice);
    expect(restored.held, [true, false, false, false, false]);
    final restoredDice = DiceController(
      game: GameController(state: restored, repository: repository),
    );
    expect(restoredDice.rollCount, 1);
    expect(restoredDice.held.first, isTrue);
  });

  test('Undo verwirft einen bereits begonnenen Folgezug vollständig', () async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    final dice = DiceController(game: game, roller: () => 6);
    await dice.roll();
    await dice.score(ScoreCategory.sixes);
    await dice.roll();
    await dice.toggleHold(0);

    await dice.undo();

    expect(game.state.currentPlayerIndex, 0);
    expect(game.state.players.first.scores, isEmpty);
    expect(dice.rollCount, 0);
    expect(dice.dice, [1, 1, 1, 1, 1]);
    expect(dice.held, everyElement(isFalse));
  });

  test('parallele Wertungen werden während Save ignoriert', () async {
    final repository = _DelayedRepository();
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.digital,
      names: ['Ada', 'Berta'],
      repository: repository,
    );

    final first = game.enterScore(ScoreCategory.ones, 1);
    expect(game.isBusy, isTrue);
    await game.enterScore(ScoreCategory.twos, 2);
    expect(game.state.players.first.scores.keys, [ScoreCategory.ones]);
    repository.pending.single.complete();
    await first;
    expect(repository.saveCalls, 1);
  });

  test('Wertung validiert regelabhängig mögliche Punkte', () async {
    final game = GameController.newGame(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      names: ['Ada', 'Berta'],
      repository: MemoryGameRepository(),
    );
    expect(
      () => game.enterScore(ScoreCategory.smallStraight, 17),
      throwsArgumentError,
    );
    await game.enterScore(ScoreCategory.smallStraight, 30);
  });

  test(
    'GameState JSON validiert Daten und alte Saves erhalten Zug-Defaults',
    () {
      final legacy = <String, dynamic>{
        'ruleSet': 'kniffel',
        'mode': 'digital',
        'players': [
          {'name': 'Ada', 'scores': <String, dynamic>{}},
        ],
        'currentPlayerIndex': 0,
        'isComplete': false,
      };
      final state = GameState.fromJson(legacy);
      expect(state.dice, [1, 1, 1, 1, 1]);
      expect(state.held, everyElement(isFalse));
      expect(state.rollCount, 0);
      expect(state.players.single.extraKniffel, 0);

      expect(
        () => GameState.fromJson({...legacy, 'currentPlayerIndex': 3}),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson({
          ...legacy,
          'dice': [1, 2, 3, 4, 9],
        }),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson({
          ...legacy,
          'players': [
            {
              'name': 'Ada',
              'scores': {'smallStraight': 17},
            },
          ],
        }),
        throwsFormatException,
      );
    },
  );

  test('regelabhängiger Bonus fließt in Total ein', () {
    final upper = {
      ScoreCategory.ones: 3,
      ScoreCategory.twos: 6,
      ScoreCategory.threes: 9,
      ScoreCategory.fours: 12,
      ScoreCategory.fives: 15,
      ScoreCategory.sixes: 18,
    };
    final yatzy = GameState(
      ruleSet: RuleSet.yatzy,
      mode: GameMode.block,
      players: [Player(name: 'Ada', scores: upper)],
    );
    final kniffel = GameState(
      ruleSet: RuleSet.kniffel,
      mode: GameMode.block,
      players: [Player(name: 'Ada', scores: upper)],
    );
    expect(yatzy.totalFor(yatzy.players.single), 113);
    expect(kniffel.totalFor(kniffel.players.single), 98);
  });

  test(
    'zweiter Kniffel gibt Zusatzbonus und Höchstwert im freien Feld',
    () async {
      final game = GameController(
        state: GameState(
          ruleSet: RuleSet.kniffel,
          mode: GameMode.digital,
          players: [
            Player(name: 'Ada', scores: {ScoreCategory.yatzy: 50}),
          ],
          dice: [6, 6, 6, 6, 6],
          rollCount: 1,
        ),
        repository: MemoryGameRepository(),
      );
      final dice = DiceController(game: game);

      expect(dice.isExtraKniffel, isTrue);
      expect(dice.suggestion(ScoreCategory.smallStraight), 30);
      await dice.score(ScoreCategory.smallStraight);

      expect(game.state.players.single.extraKniffel, 1);
      expect(game.state.players.single.scores[ScoreCategory.smallStraight], 30);
      expect(game.state.totalFor(game.state.players.single), 130);
    },
  );

  test('extraKniffel JSON-Roundtrip und Legacy-Default', () {
    final player = Player(name: 'Ada', extraKniffel: 2);
    expect(Player.fromJson(player.toJson()).extraKniffel, 2);
    expect(
      Player.fromJson({
        'name': 'Ada',
        'scores': <String, dynamic>{},
      }).extraKniffel,
      0,
    );
  });

  test('Save-Fehler bei Wertung rollt den gesamten Zustand zurück', () async {
    final game = GameController(
      state: GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.digital,
        players: [
          Player(name: 'Ada'),
          Player(name: 'Berta'),
        ],
        dice: [6, 6, 6, 6, 6],
        held: [true, false, true, false, true],
        rollCount: 2,
      ),
      repository: _FailingSaveRepository(),
    );

    await expectLater(
      game.enterScore(ScoreCategory.sixes, 30),
      throwsException,
    );
    expect(game.state.players.first.scores, isEmpty);
    expect(game.state.currentPlayerIndex, 0);
    expect(game.state.isComplete, isFalse);
    expect(game.state.dice, [6, 6, 6, 6, 6]);
    expect(game.state.held, [true, false, true, false, true]);
    expect(game.state.rollCount, 2);
    expect(game.canUndo, isFalse);
  });

  test(
    'Save-Fehler bei Undo stellt Wertung und Undo-Möglichkeit wieder her',
    () async {
      final repository = _ToggleRepository();
      final game = GameController.newGame(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        names: ['Ada', 'Berta'],
        repository: repository,
      );
      await game.enterScore(ScoreCategory.ones, 1);
      repository.fail = true;

      await expectLater(game.undo(), throwsException);

      expect(game.state.players.first.scores, {ScoreCategory.ones: 1});
      expect(game.canUndo, isTrue);
    },
  );
}

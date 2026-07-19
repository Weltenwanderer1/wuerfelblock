import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/dice_controller.dart';
import 'package:wuerfelblock/controllers/game_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/services/game_repository.dart';

class _DelayedRepository extends MemoryGameRepository {
  final pending = <Completer<void>>[];
  int saveCalls = 0;

  @override
  Future<void> save(GameState state) async {
    saveCalls++;
    final completer = Completer<void>();
    pending.add(completer);
    await completer.future;
    await super.save(state);
  }
}

void main() {
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
      names: ['Ada'],
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
      names: ['Ada'],
      repository: repository,
    );
    var next = 0;
    final dice = DiceController(game: game, roller: () => (next++ % 6) + 1);

    await dice.roll();
    await dice.toggleHold(0);

    final restored = await repository.load();
    expect(restored!.rollCount, 1);
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
      names: ['Ada'],
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
      names: ['Ada'],
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
    },
  );
}

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/dragon_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';
import 'controller_transactions.dart';

class DragonController extends ChangeNotifier {
  DragonController({
    required DragonGameState state,
    required this.repository,
    int Function()? roller,
  }) : _state = state,
       _roller = roller ?? (() => Random().nextInt(6) + 1) {
    _transactions = ControllerTransactions<DragonGameState, DragonGameState>(
      capture: () => _state.copy(),
      restore: (snapshot) => _state = snapshot.copy(),
      save: () => repository.save(_state),
      clear: repository.clear,
      notifyListeners: notifyListeners,
    );
  }

  factory DragonController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    bool quickGame = false,
    List<DragonCard>? shuffledCards,
    int Function()? roller,
  }) => DragonController(
    state: DragonGameState.newGame(
      names,
      mode: mode,
      quickGame: quickGame,
      shuffledCards: shuffledCards,
    ),
    repository: repository,
    roller: roller,
  );

  DragonGameState _state;
  DragonGameState get state => _state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<DragonGameState, DragonGameState>
  _transactions;
  String? lastMessage;

  bool get isBusy => _transactions.isBusy;
  bool get canUndo => _transactions.canUndo;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;
  bool get canEndTurn =>
      !state.isComplete &&
      state.placementsSinceRoll > 0 &&
      (state.attempt?.allMandatoryCovered ?? false);
  bool get canContinue =>
      !state.isComplete &&
      state.placementsSinceRoll > 0 &&
      (state.attempt?.placedCount ?? 0) < 5;

  Future<void> rollDigital() async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.digital ||
        state.isComplete ||
        state.dice.isNotEmpty) {
      throw StateError('Jetzt kann nicht gewürfelt werden.');
    }
    final count = 5 - state.attempt!.placedCount;
    final values = List<int>.generate(count, (_) => _roller());
    var changed = state.copyWith(
      dice: values,
      selectedDieIndex: null,
      placementsSinceRoll: 0,
    );
    String? message;
    if (!_hasRequiredFit(changed, values)) {
      final escapes =
          changed.triedPlayerIndices.length + 1 >= changed.players.length;
      changed = _failedAttempt(changed);
      message = escapes
          ? 'Der Drache ist entkommen.'
          : 'Kein passender Würfel! Zug beendet.';
    }
    await _transactions.mutateTransient(
      change: () {
        _state = changed;
        lastMessage = message;
      },
      clearUndoAfterSave: true,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> selectDie(int index) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.digital ||
        index < 0 ||
        index >= state.dice.length) {
      throw RangeError.index(index, state.dice);
    }
    await _transactions.mutateTransient(
      change: () => _state = state.copyWith(selectedDieIndex: index),
      clearUndoAfterSave: true,
    );
  }

  Future<void> placeSelectedDie(int fieldIndex) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    final selected = state.selectedDieIndex;
    if (state.mode != GameMode.digital || selected == null) {
      throw StateError('Kein Würfel ausgewählt.');
    }
    final value = state.dice[selected];
    await _place(fieldIndex, value, digitalDieIndex: selected);
  }

  Future<void> placeManualDie(int fieldIndex, int value) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.block) {
      throw StateError('Nur im Blockmodus verfügbar.');
    }
    if (value < 1 || value > 6) throw ArgumentError.value(value, 'value');
    await _place(fieldIndex, value);
  }

  Future<void> _place(int fieldIndex, int value, {int? digitalDieIndex}) async {
    await _transactions.mutate(
      change: () {
        final placed = state.attempt!.place(fieldIndex, value);
        var dice = state.dice;
        if (digitalDieIndex != null) {
          dice = List<int>.of(dice)..removeAt(digitalDieIndex);
        }
        var changed = state.copyWith(
          attempt: placed,
          dice: dice,
          selectedDieIndex: null,
          placementsSinceRoll: state.placementsSinceRoll + 1,
        );
        if (placed.isTamed) {
          changed = _tamed(changed);
          lastMessage = 'Drache gezähmt! Gold erhalten.';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> continueRolling() async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (!canContinue) {
      throw StateError('Mindestens ein Würfel muss gelegt werden.');
    }
    if (state.mode == GameMode.block) {
      await _transactions.mutate(
        change: () => _state = state.copyWith(
          dice: const [],
          selectedDieIndex: null,
          placementsSinceRoll: 0,
        ),
        undoFromSnapshot: (snapshot) => snapshot,
        pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
      );
      return;
    }
    final values = List<int>.generate(
      5 - state.attempt!.placedCount,
      (_) => _roller(),
    );
    var changed = state.copyWith(
      dice: values,
      selectedDieIndex: null,
      placementsSinceRoll: 0,
    );
    String? message;
    if (!_hasRequiredFit(changed, values)) {
      final escapes =
          changed.triedPlayerIndices.length + 1 >= changed.players.length;
      changed = _failedAttempt(changed);
      message = escapes
          ? 'Der Drache ist entkommen.'
          : 'Kein passender Würfel! Zug beendet.';
    }
    await _transactions.mutateTransient(
      change: () {
        _state = changed;
        lastMessage = message;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> endTurn() async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (!canEndTurn) {
      throw StateError('Pflichtfelder müssen zuerst belegt werden.');
    }
    await _transactions.mutate(
      change: () {
        var changed = state;
        final reward = min(changed.goldPool, changed.attempt!.diceGold);
        final players = List<DragonPlayer>.of(changed.players);
        players[changed.activePlayerIndex] = players[changed.activePlayerIndex]
            .copyWith(gold: players[changed.activePlayerIndex].gold + reward);
        changed = changed.copyWith(
          players: players,
          goldPool: changed.goldPool - reward,
        );
        _state = _failedAttempt(changed);
        lastMessage = '$reward Gold erhalten. Der Drache zieht weiter.';
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  bool _hasRequiredFit(DragonGameState state, List<int> dice) {
    final attempt = state.attempt!;
    final mandatory = attempt.openFieldIndices
        .where((i) => attempt.card.fields[i].mandatory)
        .toList();
    final targets = mandatory.isNotEmpty ? mandatory : attempt.openFieldIndices;
    return dice.any(
      (die) => targets.any(
        (i) => attempt.card.fields[i].accepts(die, card: attempt.card),
      ),
    );
  }

  DragonGameState _failedAttempt(DragonGameState source) {
    final tried = [...source.triedPlayerIndices, source.activePlayerIndex];
    final nextPlayer = (source.activePlayerIndex + 1) % source.players.length;
    if (tried.length >= source.players.length) {
      final escaped = [...source.escapedDragonIds, source.currentCard!.id];
      final returnedPool = source.goldPool + source.cardGold;
      lastMessage = 'Der Drache ist entkommen.';
      return _drawNext(
        source.copyWith(
          activePlayerIndex: nextPlayer,
          goldPool: returnedPool,
          cardGold: 0,
          triedPlayerIndices: const [],
          dice: const [],
          selectedDieIndex: null,
          placementsSinceRoll: 0,
          escapedDragonIds: escaped,
        ),
      );
    }
    final coin = min(5, source.goldPool);
    return source.copyWith(
      activePlayerIndex: nextPlayer,
      cardGold: source.cardGold + coin,
      goldPool: source.goldPool - coin,
      triedPlayerIndices: tried,
      attempt: DragonAttempt.empty(source.currentCard!),
      dice: const [],
      selectedDieIndex: null,
      placementsSinceRoll: 0,
    );
  }

  DragonGameState _tamed(DragonGameState source) {
    final diceReward = min(source.goldPool, source.attempt!.diceGold);
    final players = List<DragonPlayer>.of(source.players);
    final player = players[source.activePlayerIndex];
    players[source.activePlayerIndex] = player.copyWith(
      gold: player.gold + diceReward + source.cardGold,
      tamedDragonIds: [...player.tamedDragonIds, source.currentCard!.id],
    );
    return _drawNext(
      source.copyWith(
        players: players,
        goldPool: source.goldPool - diceReward,
        activePlayerIndex:
            (source.activePlayerIndex + 1) % source.players.length,
        cardGold: 0,
        triedPlayerIndices: const [],
        dice: const [],
        selectedDieIndex: null,
        placementsSinceRoll: 0,
      ),
    );
  }

  DragonGameState _drawNext(DragonGameState source) {
    if (source.deck.isEmpty) {
      var completed = source.copyWith(
        currentCard: null,
        attempt: null,
        deck: const [],
      );
      final highest = completed.players.map((p) => p.tamedCount).reduce(max);
      final leaders = [
        for (var i = 0; i < completed.players.length; i++)
          if (completed.players[i].tamedCount == highest) i,
      ];
      if (leaders.length == 1) {
        final players = List<DragonPlayer>.of(completed.players);
        players[leaders.single] = players[leaders.single].copyWith(
          bonusGold: 20,
        );
        completed = completed.copyWith(
          players: players,
          bonusWinnerIndex: leaders.single,
        );
      }
      return completed;
    }
    final deck = List<DragonCard>.of(source.deck);
    final card = deck.removeAt(0);
    return source.copyWith(
      deck: deck,
      currentCard: card,
      attempt: DragonAttempt.empty(card),
    );
  }

  void _ensureReady() => _transactions.ensureDigitalSaveReady(
    PersistenceMessages.pendingDigitalDiceSave,
  );
  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();
  Future<void> undo() =>
      _transactions.undo(restoreUndo: (previous) => _state = previous.copy());
  Future<void> abandon() => _transactions.abandon();
}

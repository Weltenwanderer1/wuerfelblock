import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/dragon_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';
import 'controller_transactions.dart';

typedef _DragonSnapshot = ({DragonGameState state, String? message});

class DragonController extends ChangeNotifier {
  DragonController({
    required DragonGameState state,
    required this.repository,
    int Function()? roller,
    DragonAbility Function()? abilityRewarder,
  }) : _state = state,
       _roller = roller ?? (() => Random().nextInt(6) + 1),
       _abilityRewarder =
           abilityRewarder ??
           (() =>
               DragonAbility.values[Random().nextInt(
                 DragonAbility.values.length,
               )]) {
    _transactions = ControllerTransactions<_DragonSnapshot, _DragonSnapshot>(
      capture: () => (state: _state.copy(), message: lastMessage),
      restore: _restoreSnapshot,
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
    DragonAbility Function()? abilityRewarder,
  }) => DragonController(
    state: DragonGameState.newGame(
      names,
      mode: mode,
      quickGame: quickGame,
      shuffledCards: shuffledCards,
    ),
    repository: repository,
    roller: roller,
    abilityRewarder: abilityRewarder,
  );

  DragonGameState _state;
  DragonGameState get state => _state;
  final GameRepository repository;
  final int Function() _roller;
  final DragonAbility Function() _abilityRewarder;
  late final ControllerTransactions<_DragonSnapshot, _DragonSnapshot>
  _transactions;
  String? lastMessage;

  void _restoreSnapshot(_DragonSnapshot snapshot) {
    _state = snapshot.state.copy();
    lastMessage = snapshot.message;
  }

  bool get isBusy => _transactions.isBusy;
  bool get canUndo => _transactions.canUndo;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;

  // ── Aktionsbedingungen ─────────────────────────────────────────────────────

  bool get canEndTurn =>
      !state.isComplete &&
      !state.isBossCard &&
      state.placementsSinceRoll > 0 &&
      (state.attempt?.allMandatoryCovered(state.fieldReductions) ?? false);

  bool get canContinue =>
      !state.isComplete &&
      state.placementsSinceRoll > 0 &&
      (state.isBossCard
          ? state.mode == GameMode.block || state.dice.isNotEmpty
          : (state.attempt?.openFieldIndices.isNotEmpty ?? false));

  bool get canBossEndTurn =>
      !state.isComplete && state.isBossCard && state.placementsSinceRoll > 0;

  /// Würfel die noch nicht platziert wurden.
  List<int> get unplacedDieIndices {
    final placed = state.selectedDieIndices.toSet();
    return [
      for (var i = 0; i < state.dice.length; i++)
        if (!placed.contains(i)) i,
    ];
  }

  // ── Würfeln ────────────────────────────────────────────────────────────────

  List<DieRoll> _rollDice({int? count}) {
    final diceCount =
        count ?? max(1, standardDiceColors.length - state.handicapDice);
    return List<DieRoll>.generate(
      diceCount,
      (i) => DieRoll(_roller(), standardDiceColors[i]),
    );
  }

  Future<void> rollDigital() async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.digital ||
        state.isComplete ||
        state.dice.isNotEmpty) {
      throw StateError('Jetzt kann nicht gewürfelt werden.');
    }
    final values = _rollDice();
    var changed = state.copyWith(
      dice: values,
      selectedDieIndices: const [],
      placementsSinceRoll: 0,
      sumFieldsReducedThisRoll: const [],
      bossFieldsUsedThisRoll: const [],
      rollCount: state.rollCount + 1,
      handicapDice: 0, // consumed
    );
    String? message;
    if (state.isBossCard && !_hasAnyBossFit(changed)) {
      changed = _passBoss(changed);
      message = 'Fehlwurf – der Boss zieht unverändert weiter.';
    } else if (!state.isBossCard && !_hasAnyFit(changed)) {
      final escapes =
          changed.triedPlayerIndices.length + 1 >= changed.players.length;
      changed = _failedNormalAttempt(changed);
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

  // ── Würfel auswählen (Multi-Select) ───────────────────────────────────────

  Future<void> toggleDie(int index) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (index < 0 || index >= state.dice.length) {
      throw RangeError.index(index, state.dice);
    }
    await _transactions.mutateTransient(
      change: () {
        final sel = List<int>.of(state.selectedDieIndices);
        if (sel.contains(index)) {
          sel.remove(index);
        } else {
          sel.add(index);
        }
        _state = state.copyWith(selectedDieIndices: sel);
      },
      clearUndoAfterSave: true,
    );
  }

  // ── Auf Feld platzieren ────────────────────────────────────────────────────

  Future<void> placeSelectedOnField(int fieldIndex) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    final selected = state.selectedDieIndices;
    if (selected.isEmpty) throw StateError('Kein Würfel ausgewählt.');

    final card = state.currentCard!;
    final field = card.fields[fieldIndex];

    if (field.kind == DragonFieldKind.sum) {
      await _placeSumField(fieldIndex, selected);
    } else {
      if (selected.length != 1) throw StateError('Genau einen Würfel wählen.');
      await _placeSingleField(fieldIndex, selected.single);
    }
  }

  Future<void> _placeSingleField(int fieldIndex, int dieIndex) async {
    final die = state.dice[dieIndex];
    final card = state.currentCard!;

    if (card.isBoss) {
      await _placeBossDie(fieldIndex, dieIndex);
      return;
    }

    await _transactions.mutate(
      change: () {
        final reduction = state.fieldReductions.length > fieldIndex
            ? state.fieldReductions[fieldIndex]
            : 0;
        final placed = state.attempt!.placeSingle(
          fieldIndex,
          die,
          reduction: reduction,
        );
        final dice = List<DieRoll>.of(state.dice)..removeAt(dieIndex);
        var changed = state.copyWith(
          attempt: placed,
          dice: dice,
          selectedDieIndices: const [],
          placementsSinceRoll: state.placementsSinceRoll + 1,
        );
        if (placed.isTamed(state.fieldReductions)) {
          changed = _tamed(changed);
          lastMessage = 'Drache gezähmt! Gold erhalten.';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> _placeSumField(int fieldIndex, List<int> dieIndices) async {
    if (dieIndices.length != 1) {
      throw StateError('Pro Wurf darf genau ein Würfel auf ein Summenfeld.');
    }
    if (state.sumFieldsReducedThisRoll.contains(fieldIndex)) {
      throw StateError(
        'Dieses Summenfeld wurde in diesem Wurf bereits reduziert.',
      );
    }
    final dice = [for (final i in dieIndices) state.dice[i]];
    await _transactions.mutate(
      change: () {
        final reduction = state.fieldReductions.length > fieldIndex
            ? state.fieldReductions[fieldIndex]
            : 0;
        final placed = state.attempt!.placeSum(
          fieldIndex,
          dice,
          reduction: reduction,
        );
        final remaining = List<DieRoll>.of(state.dice);
        for (final i in dieIndices.sorted().reversed) {
          remaining.removeAt(i);
        }
        var changed = state.copyWith(
          attempt: placed,
          dice: remaining,
          selectedDieIndices: const [],
          placementsSinceRoll: state.placementsSinceRoll + 1,
          sumFieldsReducedThisRoll: [
            ...state.sumFieldsReducedThisRoll,
            fieldIndex,
          ],
        );
        if (placed.isTamed(state.fieldReductions)) {
          changed = _tamed(changed);
          lastMessage = 'Drache gezähmt! Gold erhalten.';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> _placeBossDie(int fieldIndex, int dieIndex) async {
    final die = state.dice[dieIndex];
    if (state.bossFieldsUsedThisRoll.contains(fieldIndex)) {
      throw StateError(
        'Dieses Boss-Feld wurde in diesem Wurf bereits verwendet.',
      );
    }
    await _transactions.mutate(
      change: () {
        final hp = List<int>.of(state.bossRemainingHp);
        final reduction = die.value;
        if (reduction > hp[fieldIndex]) {
          throw ArgumentError('Würfel zu hoch für dieses Feld.');
        }
        hp[fieldIndex] -= reduction;
        final dice = List<DieRoll>.of(state.dice)..removeAt(dieIndex);

        var changed = state.copyWith(
          bossRemainingHp: hp,
          dice: dice,
          selectedDieIndices: const [],
          placementsSinceRoll: state.placementsSinceRoll + 1,
          bossFieldsUsedThisRoll: [...state.bossFieldsUsedThisRoll, fieldIndex],
        );

        if (hp.every((h) => h <= 0)) {
          changed = _bossDefeated(changed);
          lastMessage = 'Boss-Drache besiegt! 25 Gold!';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  // ── Block-Modus: manuelle Eingabe ─────────────────────────────────────────

  Future<void> placeManualDie(
    int fieldIndex,
    int value, {
    DieColor color = DieColor.white,
  }) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.block) {
      throw StateError('Nur im Blockmodus verfügbar.');
    }
    if (value < 1 || value > 6) throw ArgumentError.value(value, 'value');
    final die = DieRoll(value, color);

    if (state.isBossCard) {
      if (state.bossFieldsUsedThisRoll.contains(fieldIndex)) {
        throw StateError(
          'Dieses Boss-Feld wurde in diesem Wurf bereits verwendet.',
        );
      }
      await _transactions.mutate(
        change: () {
          final hp = List<int>.of(state.bossRemainingHp);
          if (value > hp[fieldIndex]) throw ArgumentError('Zu hoch.');
          hp[fieldIndex] -= value;
          var changed = state.copyWith(
            bossRemainingHp: hp,
            placementsSinceRoll: state.placementsSinceRoll + 1,
            bossFieldsUsedThisRoll: [
              ...state.bossFieldsUsedThisRoll,
              fieldIndex,
            ],
          );
          if (hp.every((h) => h <= 0)) {
            changed = _bossDefeated(changed);
            lastMessage = 'Boss-Drache besiegt! 25 Gold!';
          }
          _state = changed;
        },
        undoFromSnapshot: (snapshot) => snapshot,
        pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
      );
      return;
    }

    await _transactions.mutate(
      change: () {
        final reduction = state.fieldReductions.length > fieldIndex
            ? state.fieldReductions[fieldIndex]
            : 0;
        final placed = state.attempt!.placeSingle(
          fieldIndex,
          die,
          reduction: reduction,
        );
        var changed = state.copyWith(
          attempt: placed,
          placementsSinceRoll: state.placementsSinceRoll + 1,
        );
        if (placed.isTamed(state.fieldReductions)) {
          changed = _tamed(changed);
          lastMessage = 'Drache gezähmt! Gold erhalten.';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> placeManualSum(
    int fieldIndex,
    List<(int, DieColor)> dice,
  ) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.block) {
      throw StateError('Nur im Blockmodus verfügbar.');
    }
    if (dice.length != 1) {
      throw StateError('Pro Wurf darf genau ein Würfel auf ein Summenfeld.');
    }
    if (state.sumFieldsReducedThisRoll.contains(fieldIndex)) {
      throw StateError(
        'Dieses Summenfeld wurde in diesem Wurf bereits reduziert.',
      );
    }
    final rolls = dice.map((d) => DieRoll(d.$1, d.$2)).toList();
    await _transactions.mutate(
      change: () {
        final reduction = state.fieldReductions.length > fieldIndex
            ? state.fieldReductions[fieldIndex]
            : 0;
        final placed = state.attempt!.placeSum(
          fieldIndex,
          rolls,
          reduction: reduction,
        );
        var changed = state.copyWith(
          attempt: placed,
          placementsSinceRoll: state.placementsSinceRoll + 1,
          sumFieldsReducedThisRoll: [
            ...state.sumFieldsReducedThisRoll,
            fieldIndex,
          ],
        );
        if (placed.isTamed(state.fieldReductions)) {
          changed = _tamed(changed);
          lastMessage = 'Drache gezähmt! Gold erhalten.';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  // ── Weiterwürfeln ──────────────────────────────────────────────────────────

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
          selectedDieIndices: const [],
          placementsSinceRoll: 0,
          sumFieldsReducedThisRoll: const [],
          bossFieldsUsedThisRoll: const [],
          rollCount: state.rollCount + 1,
        ),
        undoFromSnapshot: (snapshot) => snapshot,
        pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
      );
      return;
    }

    final values = _rollDice(
      count: state.isBossCard ? state.dice.length : null,
    );
    var changed = state.copyWith(
      dice: values,
      selectedDieIndices: const [],
      placementsSinceRoll: 0,
      sumFieldsReducedThisRoll: const [],
      bossFieldsUsedThisRoll: const [],
      rollCount: state.rollCount + 1,
      handicapDice: 0, // consumed
    );
    String? message;
    if (state.isBossCard && !_hasAnyBossFit(changed)) {
      changed = _passBoss(changed);
      message = 'Fehlwurf – der Boss zieht unverändert weiter.';
    } else if (!state.isBossCard && !_hasAnyFit(changed)) {
      final escapes =
          changed.triedPlayerIndices.length + 1 >= changed.players.length;
      changed = _failedNormalAttempt(changed);
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

  // ── Zug beenden ────────────────────────────────────────────────────────────

  Future<void> endTurn() async {
    _ensureReady();
    if (_transactions.isBusy) return;

    if (state.isBossCard) {
      await _bossEndTurn();
      return;
    }

    if (!canEndTurn) {
      throw StateError('Pflichtfelder müssen zuerst belegt werden.');
    }
    await _transactions.mutate(
      change: () {
        var changed = state;
        final reward = changed.attempt!.diceGold;
        final players = List<DragonPlayer>.of(changed.players);
        players[changed.activePlayerIndex] = players[changed.activePlayerIndex]
            .copyWith(gold: players[changed.activePlayerIndex].gold + reward);
        changed = changed.copyWith(players: players);
        _state = _failedNormalAttempt(changed);
        lastMessage = '$reward Gold erhalten. Der Drache zieht weiter.';
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  Future<void> _bossEndTurn() async {
    if (!canBossEndTurn) {
      throw StateError('Mindestens ein Würfel muss gelegt werden.');
    }
    await _transactions.mutate(
      change: () {
        _state = _passBoss(state);
        lastMessage = 'Boss zieht weiter zum nächsten Spieler.';
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  // ── Block: Fehlversuch ─────────────────────────────────────────────────────

  Future<void> failAttempt() async {
    _ensureReady();
    if (_transactions.isBusy) return;
    if (state.mode != GameMode.block || state.isComplete) {
      throw StateError('Nur ein physischer Wurf kann so beendet werden.');
    }
    if (state.placementsSinceRoll > 0) {
      throw StateError('Nach einer Ablage muss zuerst weitergewürfelt werden.');
    }
    await _transactions.mutate(
      change: () {
        if (state.isBossCard) {
          _state = _passBoss(state);
          lastMessage = 'Boss zieht weiter.';
        } else {
          final escapes =
              state.triedPlayerIndices.length + 1 >= state.players.length;
          _state = _failedNormalAttempt(state);
          lastMessage = escapes
              ? 'Der Drache ist entkommen.'
              : 'Kein Würfel passt. Der Drache zieht weiter.';
        }
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  // ── Fähigkeiten ────────────────────────────────────────────────────────────

  Future<void> useAbility(
    DragonAbility ability, {
    int? fieldIndex,
    int? reduction,
  }) async {
    _ensureReady();
    if (_transactions.isBusy) return;
    final player = state.activePlayer;
    if (!player.canUse(ability)) {
      throw StateError('Fähigkeit bereits verbraucht.');
    }

    await _transactions.mutate(
      change: () {
        final players = List<DragonPlayer>.of(state.players);
        players[state.activePlayerIndex] = player.copyWith(
          usedAbilities: [...player.usedAbilities, ability],
        );

        var changed = state.copyWith(players: players);

        switch (ability) {
          case DragonAbility.reroll:
            if (state.mode == GameMode.digital && state.dice.isEmpty) {
              throw StateError('Kein Wurf zum Neuwerfen.');
            }
            changed = changed.copyWith(
              dice: state.mode == GameMode.digital
                  ? _rollDice(count: state.dice.length)
                  : const [],
              selectedDieIndices: const [],
            );
            lastMessage = state.mode == GameMode.digital
                ? '🔄 Wurf neu gewürfelt!'
                : '🔄 Würfel neu werfen – Fähigkeit verbraucht!';
          case DragonAbility.reduce:
            if (fieldIndex == null || reduction == null) {
              throw ArgumentError('Feld und Reduktion nötig.');
            }
            if (reduction < 1 || reduction > 3) {
              throw ArgumentError('Reduktion: 1–3.');
            }
            if (fieldIndex < 0 ||
                fieldIndex >= state.currentCard!.fields.length) {
              throw RangeError.index(fieldIndex, state.currentCard!.fields);
            }
            if (state.isBossCard) {
              final hp = List<int>.of(state.bossRemainingHp);
              hp[fieldIndex] = max(0, hp[fieldIndex] - reduction);
              changed = changed.copyWith(bossRemainingHp: hp);
              if (hp.every((value) => value == 0)) {
                changed = _bossDefeated(changed);
                lastMessage = '📉 Boss geschwächt und besiegt! 25 Gold!';
              } else {
                lastMessage = '📉 Boss-Feld um $reduction HP geschwächt!';
              }
            } else {
              final reds = List<int>.of(state.fieldReductions);
              reds[fieldIndex] += reduction;
              changed = changed.copyWith(fieldReductions: reds);
              lastMessage = '📉 Vorgabe um $reduction gesenkt!';
            }
          case DragonAbility.handicap:
            final nextIdx =
                (state.activePlayerIndex + 1) % state.players.length;
            changed = changed.copyWith(handicapDice: 2);
            lastMessage =
                '🎯 ${changed.players[nextIdx].name} würfelt mit 2 Würfeln weniger!';
        }
        _state = changed;
      },
      undoFromSnapshot: (snapshot) => snapshot,
      pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
    );
  }

  // ── Interne Logik ──────────────────────────────────────────────────────────

  bool _hasAnyFit(DragonGameState st) {
    final card = st.currentCard;
    if (card == null || card.isBoss) return true; // Boss: immer möglich
    final attempt = st.attempt;
    if (attempt == null) return false;
    final reductions = st.fieldReductions;
    return st.dice.any(
          (die) => attempt.openFieldIndices.any((i) {
            final field = attempt.card.fields[i];
            // Reduced-to-zero fields are not open
            if (field.kind == DragonFieldKind.number ||
                field.kind == DragonFieldKind.coloredDie) {
              final reduction = reductions.length > i ? reductions[i] : 0;
              if (field.effectiveNumber(reduction) <= 0) return false;
            }
            return field.acceptsDie(
              die,
              card: card,
              reduction: reductions.length > i ? reductions[i] : 0,
            );
          }),
        ) ||
        _hasSumFit(st);
  }

  bool _hasAnyBossFit(DragonGameState st) =>
      st.dice.any((die) => st.bossRemainingHp.any((hp) => die.value <= hp));

  bool _hasSumFit(DragonGameState st) {
    final attempt = st.attempt;
    if (attempt == null) return false;
    final card = st.currentCard!;
    final reductions = st.fieldReductions;
    final reduced = st.sumFieldsReducedThisRoll;
    for (final i in attempt.openFieldIndices) {
      final field = card.fields[i];
      if (field.kind != DragonFieldKind.sum) continue;
      if (reduced.contains(i)) continue; // bereits in diesem Wurf reduziert
      final existing = attempt.placed[i];
      final existingSum = existing?.sum ?? 0;
      final existingCount = existing?.values.length ?? 0;
      final reduction = reductions.length > i ? reductions[i] : 0;
      if (st.dice.any(
        (die) => field.acceptsSum(
          [die],
          card: card,
          existingSum: existingSum,
          existingCount: existingCount,
          reduction: reduction,
        ),
      )) {
        return true;
      }
    }
    return false;
  }

  DragonGameState _failedNormalAttempt(DragonGameState source) {
    final tried = [...source.triedPlayerIndices, source.activePlayerIndex];
    final nextPlayer = (source.activePlayerIndex + 1) % source.players.length;
    if (tried.length >= source.players.length) {
      final escaped = [...source.escapedDragonIds, source.currentCard!.id];
      lastMessage = 'Der Drache ist entkommen.';
      return _drawNext(
        source.copyWith(
          activePlayerIndex: nextPlayer,
          cardGold: 0,
          triedPlayerIndices: const [],
          dice: const [],
          selectedDieIndices: const [],
          placementsSinceRoll: 0,
          sumFieldsReducedThisRoll: const [],
          bossFieldsUsedThisRoll: const [],
          escapedDragonIds: escaped,
          rollCount: 0,
        ),
      );
    }
    return source.copyWith(
      activePlayerIndex: nextPlayer,
      cardGold: source.cardGold + 5,
      triedPlayerIndices: tried,
      attempt: DragonAttempt.empty(source.currentCard!),
      dice: const [],
      selectedDieIndices: const [],
      placementsSinceRoll: 0,
      sumFieldsReducedThisRoll: const [],
      bossFieldsUsedThisRoll: const [],
      rollCount: 0,
    );
  }

  DragonGameState _tamed(DragonGameState source) {
    final card = source.currentCard!;
    final diceReward = source.attempt!.diceGold + card.bonusPoints;
    final players = List<DragonPlayer>.of(source.players);
    final player = players[source.activePlayerIndex];
    final reward = card.type == DragonType.luck ? _abilityRewarder() : null;
    players[source.activePlayerIndex] = player.copyWith(
      gold: player.gold + diceReward + source.cardGold,
      tamedDragonIds: [...player.tamedDragonIds, card.id],
      earnedAbilities: reward == null
          ? player.earnedAbilities
          : [...player.earnedAbilities, reward],
    );
    return _drawNext(
      source.copyWith(
        players: players,
        activePlayerIndex:
            (source.activePlayerIndex + 1) % source.players.length,
        cardGold: 0,
        triedPlayerIndices: const [],
        dice: const [],
        selectedDieIndices: const [],
        placementsSinceRoll: 0,
        sumFieldsReducedThisRoll: const [],
        bossFieldsUsedThisRoll: const [],
        handicapDice: 0,
        rollCount: 0,
      ),
    );
  }

  DragonGameState _bossDefeated(DragonGameState source) {
    final players = List<DragonPlayer>.of(source.players);
    final player = players[source.activePlayerIndex];
    players[source.activePlayerIndex] = player.copyWith(
      gold: player.gold + 25,
      tamedDragonIds: [...player.tamedDragonIds, source.currentCard!.id],
    );
    return _drawNext(
      source.copyWith(
        players: players,
        activePlayerIndex:
            (source.activePlayerIndex + 1) % source.players.length,
        triedPlayerIndices: const [],
        dice: const [],
        selectedDieIndices: const [],
        placementsSinceRoll: 0,
        sumFieldsReducedThisRoll: const [],
        bossFieldsUsedThisRoll: const [],
        handicapDice: 0,
        rollCount: 0,
      ),
    );
  }

  DragonGameState _passBoss(DragonGameState source) {
    final nextPlayer = (source.activePlayerIndex + 1) % source.players.length;
    return source.copyWith(
      activePlayerIndex: nextPlayer,
      dice: const [],
      selectedDieIndices: const [],
      placementsSinceRoll: 0,
      sumFieldsReducedThisRoll: const [],
      bossFieldsUsedThisRoll: const [],
      rollCount: 0,
    );
  }

  DragonGameState _drawNext(DragonGameState source) {
    if (source.deck.isEmpty) {
      var completed = source.copyWith(
        currentCard: null,
        attempt: null,
        deck: const [],
        bossRemainingHp: const [],
        fieldReductions: const [],
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
      attempt: card.isBoss ? null : DragonAttempt.empty(card),
      bossRemainingHp: card.isBoss
          ? card.fields.map((f) => f.bossHp ?? 0).toList()
          : const [],
      fieldReductions: List<int>.filled(card.fields.length, 0),
      handicapDice: 0,
    );
  }

  void _ensureReady() => _transactions.ensureDigitalSaveReady(
    PersistenceMessages.pendingDigitalDiceSave,
  );
  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();
  Future<void> undo() async {
    _ensureReady();
    await _transactions.undo(restoreUndo: _restoreSnapshot);
  }

  Future<void> abandon() => _transactions.abandon();
}

extension _Sorted on List<int> {
  List<int> sorted() => List<int>.of(this)..sort();
}

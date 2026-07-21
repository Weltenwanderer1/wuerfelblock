import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/ten_thousand_models.dart';
import '../models/ten_thousand_rules.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';
import 'controller_transactions.dart';

class TenThousandCorrectionImpact implements Exception {
  const TenThousandCorrectionImpact({
    required this.firstIllegalOrdinal,
    required this.illegalTrailingTurnCount,
  });

  final int firstIllegalOrdinal;
  final int illegalTrailingTurnCount;

  @override
  String toString() =>
      'TenThousandCorrectionImpact('
      'firstIllegalOrdinal: $firstIllegalOrdinal, '
      'illegalTrailingTurnCount: $illegalTrailingTurnCount)';
}

class TenThousandController extends ChangeNotifier {
  TenThousandController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? _secureRoller() {
    _transactions =
        ControllerTransactions<TenThousandGameState, TenThousandGameState>(
          capture: () => state.copy(),
          restore: (snapshot) => state = snapshot.copy(),
          save: () => repository.save(state),
          clear: repository.clear,
          notifyListeners: notifyListeners,
        );
  }

  static int Function() _secureRoller() {
    final random = Random.secure();
    return () =>
        random.nextInt(
          TenThousandRules.maximumDieValue -
              TenThousandRules.minimumDieValue +
              1,
        ) +
        TenThousandRules.minimumDieValue;
  }

  factory TenThousandController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => TenThousandController(
    state: TenThousandGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );

  TenThousandGameState state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<TenThousandGameState, TenThousandGameState>
  _transactions;

  bool get canUndo => _transactions.canUndo;
  bool get isBusy => _transactions.isBusy;
  bool get needsDigitalSaveRetry => _transactions.needsDigitalSaveRetry;
  List<TenThousandPlayer> get winners => state.winners;

  Future<void> rollDigital() {
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(
      () => state.withDigitalTurn(
        turn.rolled(List.generate(turn.activeDiceCount, (_) => _roller())),
      ),
    );
  }

  Future<void> toggleDigitalDie(int index) {
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(() => state.withDigitalTurn(turn.toggled(index)));
  }

  Future<void> bankDigitalSelection() {
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(() => state.withDigitalTurn(turn.banked()));
  }

  Future<void> secureDigitalTurn() {
    final turn = state.digitalTurn;
    if (turn == null || !turn.canSecure) {
      throw StateError('Dieser Durchgang kann noch nicht gesichert werden.');
    }
    final undoBaseline = TenThousandGameState(
      players: state.players,
      turns: state.turns,
      mode: state.mode,
    );
    return _mutate(
      () => state.withTurn(turn.roundPoints),
      undoBaseline: undoBaseline,
    );
  }

  Future<void> confirmDigitalMacke() {
    final turn = state.digitalTurn;
    if (turn == null || !turn.isMacke) {
      throw StateError('Der aktuelle Wurf ist keine Macke.');
    }
    final undoBaseline = TenThousandGameState(
      players: state.players,
      turns: state.turns,
      mode: state.mode,
    );
    return _mutate(() => state.withTurn(0), undoBaseline: undoBaseline);
  }

  Future<void> forfeitDigitalTurn() {
    final turn = state.digitalTurn;
    if (turn == null ||
        turn.isFresh ||
        turn.roundPoints >= TenThousandRules.minimumBankScore) {
      throw StateError(
        'Dieser Durchgang kann nicht als Nullrunde beendet werden.',
      );
    }
    final undoBaseline = TenThousandGameState(
      players: state.players,
      turns: state.turns,
      mode: state.mode,
    );
    return _mutate(() => state.withTurn(0), undoBaseline: undoBaseline);
  }

  Future<void> enterTurn(int points) {
    if (_transactions.isBusy) return Future<void>.value();
    return _mutate(() => state.withTurn(points));
  }

  Future<void> editTurn(
    int ordinal,
    int points, {
    bool confirmTruncation = false,
  }) {
    if (_transactions.isBusy) return Future<void>.value();
    return _correctTurn(
      ordinal,
      TenThousandTurn(ordinal, points),
      confirmTruncation: confirmTruncation,
    );
  }

  Future<void> deleteTurn(int ordinal, {bool confirmTruncation = false}) {
    if (_transactions.isBusy) return Future<void>.value();
    if (ordinal < 0 || ordinal >= state.turns.length) {
      throw RangeError.index(ordinal, state.turns, 'ordinal');
    }
    return _correctTurn(
      ordinal,
      state.turns[ordinal].asDeleted(),
      confirmTruncation: confirmTruncation,
    );
  }

  Future<void> _correctTurn(
    int ordinal,
    TenThousandTurn replacement, {
    required bool confirmTruncation,
  }) async {
    final legalCount = state.legalTurnCountAfterReplacing(ordinal, replacement);
    final illegalCount = state.turns.length - legalCount;
    if (illegalCount > 0 && !confirmTruncation) {
      throw TenThousandCorrectionImpact(
        firstIllegalOrdinal: legalCount,
        illegalTrailingTurnCount: illegalCount,
      );
    }
    return _mutate(
      () => illegalCount == 0
          ? state.replacingTurn(ordinal, replacement)
          : state.replacingTurnAndTruncating(ordinal, replacement),
    );
  }

  Future<void> _mutate(
    TenThousandGameState Function() mutation, {
    TenThousandGameState? undoBaseline,
  }) => _transactions.mutate(
    change: () => state = mutation(),
    undoFromSnapshot: (snapshot) => undoBaseline ?? snapshot,
  );

  Future<void> _mutateTransient(TenThousandGameState Function() mutation) =>
      _transactions.mutateTransient(
        change: () => state = mutation(),
        clearUndoAfterSave: true,
        pendingSaveMessage: PersistenceMessages.pendingDigitalDiceSave,
      );

  Future<void> retryDigitalSave() => _transactions.retryDigitalSave();

  Future<void> undo() =>
      _transactions.undo(restoreUndo: (previous) => state = previous.copy());

  Future<void> abandon() => _transactions.abandon();
}

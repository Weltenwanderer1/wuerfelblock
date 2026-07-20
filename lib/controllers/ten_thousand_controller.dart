import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/ten_thousand_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';

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
  }) : _roller = roller ?? _secureRoller();

  static int Function() _secureRoller() {
    final random = Random.secure();
    return () => random.nextInt(6) + 1;
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
  TenThousandGameState? _undoState;
  bool _isBusy = false;
  bool _needsDigitalSaveRetry = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;
  bool get needsDigitalSaveRetry => _needsDigitalSaveRetry;
  List<TenThousandPlayer> get winners => state.winners;

  Future<void> rollDigital() {
    _ensureDigitalSaveReady();
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(
      () => state.withDigitalTurn(
        turn.rolled(List.generate(turn.activeDiceCount, (_) => _roller())),
      ),
    );
  }

  Future<void> toggleDigitalDie(int index) {
    _ensureDigitalSaveReady();
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(() => state.withDigitalTurn(turn.toggled(index)));
  }

  Future<void> bankDigitalSelection() {
    _ensureDigitalSaveReady();
    final turn = state.digitalTurn;
    if (turn == null) throw StateError('Kein digitaler Zug.');
    return _mutateTransient(() => state.withDigitalTurn(turn.banked()));
  }

  Future<void> secureDigitalTurn() {
    _ensureDigitalSaveReady();
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
    _ensureDigitalSaveReady();
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
    _ensureDigitalSaveReady();
    final turn = state.digitalTurn;
    if (turn == null || turn.isFresh || turn.roundPoints >= 350) {
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
    if (_isBusy) return Future<void>.value();
    return _mutate(() => state.withTurn(points));
  }

  Future<void> editTurn(
    int ordinal,
    int points, {
    bool confirmTruncation = false,
  }) {
    if (_isBusy) return Future<void>.value();
    return _correctTurn(
      ordinal,
      TenThousandTurn(ordinal, points),
      confirmTruncation: confirmTruncation,
    );
  }

  Future<void> deleteTurn(int ordinal, {bool confirmTruncation = false}) {
    if (_isBusy) return Future<void>.value();
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
  }) async {
    if (_isBusy) return;
    final before = state.copy();
    final previousUndo = _undoState;
    _isBusy = true;
    notifyListeners();
    try {
      state = mutation();
      notifyListeners();
      await repository.save(state);
      _undoState = undoBaseline ?? before;
    } catch (_) {
      state = before;
      _undoState = previousUndo;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _mutateTransient(
    TenThousandGameState Function() mutation,
  ) async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      state = mutation();
      notifyListeners();
      await repository.save(state);
      _needsDigitalSaveRetry = false;
      _undoState = null;
    } catch (_) {
      _needsDigitalSaveRetry = true;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> retryDigitalSave() async {
    if (_isBusy || !_needsDigitalSaveRetry) return;
    _isBusy = true;
    notifyListeners();
    try {
      await repository.save(state);
      _needsDigitalSaveRetry = false;
      _undoState = null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _ensureDigitalSaveReady() {
    if (_needsDigitalSaveRetry) {
      throw StateError(
        'Der letzte Würfelstand muss zuerst gespeichert werden.',
      );
    }
  }

  Future<void> undo() async {
    if (_isBusy) return;
    final previous = _undoState;
    if (previous == null) return;
    final current = state.copy();
    final previousUndo = _undoState;
    _isBusy = true;
    notifyListeners();
    try {
      state = previous.copy();
      notifyListeners();
      await repository.save(state);
      _undoState = null;
    } catch (_) {
      state = current;
      _undoState = previousUndo;
      notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> abandon() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      await repository.clear();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';

import '../models/ten_thousand_models.dart';
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
  TenThousandController({required this.state, required this.repository});

  factory TenThousandController.newGame({
    required List<String> names,
    required GameRepository repository,
  }) => TenThousandController(
    state: TenThousandGameState.newGame(names),
    repository: repository,
  );

  TenThousandGameState state;
  final GameRepository repository;
  TenThousandGameState? _undoState;
  bool _isBusy = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;
  List<TenThousandPlayer> get winners => state.winners;

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

  Future<void> _mutate(TenThousandGameState Function() mutation) async {
    if (_isBusy) return;
    final before = state.copy();
    final previousUndo = _undoState;
    _isBusy = true;
    notifyListeners();
    try {
      state = mutation();
      notifyListeners();
      await repository.save(state);
      _undoState = before;
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

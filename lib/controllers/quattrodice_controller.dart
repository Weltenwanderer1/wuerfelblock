import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/quattrodice_models.dart';
import '../models/game_models.dart';
import '../controllers/controller_transactions.dart';
import '../services/game_repository.dart';
import '../services/persistence_messages.dart';

class QuattroController extends ChangeNotifier {
  QuattroController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? _secureRoller() {
    _tx = ControllerTransactions<QuattroGameState, QuattroGameState>(
      capture: () => _copy(state),
      restore: (s) => state = _copy(s),
      save: () => repository.save(state),
      clear: repository.clear,
      notifyListeners: notifyListeners,
    );
  }
  static int Function() _secureRoller() {
    final r = Random.secure();
    return () => r.nextInt(6) + 1;
  }

  factory QuattroController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    QuattroSide side = QuattroSide.a,
    int Function()? roller,
  }) => QuattroController(
    state: QuattroGameState.newGame(names, mode: mode, side: side),
    repository: repository,
    roller: roller,
  );

  QuattroGameState state;
  final GameRepository repository;
  final int Function() _roller;
  late final ControllerTransactions<QuattroGameState, QuattroGameState> _tx;

  bool get canUndo => _tx.canUndo;
  bool get isBusy => _tx.isBusy;

  Future<void> writeCorner(int pIdx, String sqId, QuattroCorner c, int v) =>
      _mutate(() => state.writeCorner(pIdx, sqId, c, v));
  Future<void> clearCorner(int pIdx, String sqId, QuattroCorner c) =>
      _mutate(() => state.clearCorner(pIdx, sqId, c));
  Future<void> markCross(int pIdx, String sqId) =>
      _mutate(() => state.markCross(pIdx, sqId));
  Future<void> writeJoker(int pIdx, int v) =>
      _mutate(() => state.writeJoker(pIdx, v));
  Future<void> clearJoker(int pIdx, int idx) =>
      _mutate(() => state.clearJoker(pIdx, idx));
  Future<void> toggleBridge(int pIdx, String a, String b) =>
      _mutate(() => state.toggleBridge(pIdx, a, b));
  Future<void> nextPlayer() => _mutate(() => state.nextPlayer());
  Future<void> finishGame() => _mutate(() => state.isComplete = true);
  Future<void> roll() =>
      _mutateTransient(() => state.roll(List.generate(5, (_) => _roller())));

  Future<void> _mutate(void Function() m) => _tx.mutate(
    change: m,
    undoFromSnapshot: (s) => s,
    pendingSaveMessage: PersistenceMessages.pendingColordiceRollSave,
  );
  Future<void> _mutateTransient(void Function() m) => _tx.mutateTransient(
    change: m,
    undoFromSnapshot: (s) => s,
    pendingSaveMessage: PersistenceMessages.pendingColordiceRollSave,
  );
  Future<void> undo() => _tx.undo(restoreUndo: (p) => state = _copy(p));
  Future<void> abandon() => _tx.abandon();
  QuattroGameState _copy(QuattroGameState v) =>
      QuattroGameState.fromJson(v.toJson());
}

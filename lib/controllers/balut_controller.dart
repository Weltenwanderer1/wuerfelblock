import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/balut_models.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';

class BalutController extends ChangeNotifier {
  BalutController({
    required this.state,
    required this.repository,
    int Function()? roller,
  }) : _roller = roller ?? (() => Random().nextInt(6) + 1);

  factory BalutController.newGame({
    required List<String> names,
    required GameRepository repository,
    GameMode mode = GameMode.block,
    int Function()? roller,
  }) => BalutController(
    state: BalutGameState.newGame(names, mode: mode),
    repository: repository,
    roller: roller,
  );

  BalutGameState state;
  final GameRepository repository;
  final int Function() _roller;
  BalutGameState? _undoState;
  bool _isBusy = false;
  bool _needsDigitalSaveRetry = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;
  bool get needsDigitalSaveRetry => _needsDigitalSaveRetry;
  List<BalutPlayer> get winners => state.winners;

  Future<void> scoreBlock(
    BalutCategory category,
    int index,
    int score, {
    int? playerIndex,
  }) {
    if (_isBusy) return Future<void>.value();
    return _mutate(
      () => state.withBlockScore(
        category,
        index,
        score,
        playerIndex: playerIndex,
      ),
    );
  }

  Future<void> rollDigital() {
    _ensureDigitalSaveReady();
    if (_isBusy) return Future<void>.value();
    final diceToRoll = state.rollCount == 0
        ? 5
        : state.held.where((isHeld) => !isHeld).length;
    return _mutateTransient(
      () => state.withDigitalRoll(
        List<int>.generate(diceToRoll, (_) => _roller()),
      ),
    );
  }

  Future<void> toggleHold(int index) {
    _ensureDigitalSaveReady();
    if (_isBusy) return Future<void>.value();
    return _mutateTransient(() => state.withToggledHold(index));
  }

  Future<void> scoreDigital(BalutCategory category) {
    _ensureDigitalSaveReady();
    if (_isBusy) return Future<void>.value();
    return _mutate(() => state.withDigitalScore(category));
  }

  Future<void> _mutate(BalutGameState Function() mutation) async {
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

  Future<void> _mutateTransient(BalutGameState Function() mutation) async {
    if (_isBusy) return;
    final changed = mutation();
    _isBusy = true;
    notifyListeners();
    try {
      state = changed;
      notifyListeners();
      await repository.save(state);
      _needsDigitalSaveRetry = false;
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

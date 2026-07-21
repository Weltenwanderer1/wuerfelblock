import '../services/persistence_messages.dart';

typedef StateCapture<StateSnapshot> = StateSnapshot Function();
typedef StateRestore<StateSnapshot> = void Function(StateSnapshot snapshot);
typedef PersistenceOperation = Future<void> Function();

/// Coordinates persistence mechanics without knowing any game's state machine.
///
/// Controllers provide typed snapshot/restore callbacks and keep all domain
/// mutations in their own classes. This helper owns only the shared busy,
/// rollback, undo, and transient-save-retry lifecycle.
class ControllerTransactions<
  StateSnapshot extends Object,
  UndoState extends Object
> {
  ControllerTransactions({
    required StateCapture<StateSnapshot> capture,
    required StateRestore<StateSnapshot> restore,
    required PersistenceOperation save,
    required PersistenceOperation clear,
    required void Function() notifyListeners,
  }) : _capture = capture,
       _restore = restore,
       _save = save,
       _clear = clear,
       _notifyListeners = notifyListeners;

  final StateCapture<StateSnapshot> _capture;
  final StateRestore<StateSnapshot> _restore;
  final PersistenceOperation _save;
  final PersistenceOperation _clear;
  final void Function() _notifyListeners;

  UndoState? _undoState;
  _PendingTransient<StateSnapshot, UndoState>? _pendingTransient;
  bool _isBusy = false;
  bool _needsDigitalSaveRetry = false;

  bool get canUndo => _undoState != null;
  bool get isBusy => _isBusy;
  bool get needsDigitalSaveRetry => _needsDigitalSaveRetry;

  void ensureDigitalSaveReady([
    String message = PersistenceMessages.pendingDigitalDiceSave,
  ]) {
    if (_needsDigitalSaveRetry) throw StateError(message);
  }

  Future<void> mutate({
    required void Function() change,
    UndoState Function(StateSnapshot snapshot)? undoFromSnapshot,
    bool setUndoBeforeSave = false,
    String? pendingSaveMessage,
  }) => transaction((snapshot) async {
    final nextUndo = undoFromSnapshot?.call(snapshot);
    change();
    if (setUndoBeforeSave && nextUndo != null) {
      _undoState = nextUndo;
    }
    _notifyListeners();
    await _save();
    if (!setUndoBeforeSave && nextUndo != null) {
      _undoState = nextUndo;
    }
  }, pendingSaveMessage: pendingSaveMessage);

  Future<void> transaction(
    Future<void> Function(StateSnapshot snapshot) operation, {
    String? pendingSaveMessage,
  }) async {
    if (_isBusy) return;
    if (pendingSaveMessage != null) {
      ensureDigitalSaveReady(pendingSaveMessage);
    }
    final snapshot = _capture();
    final previousUndo = _undoState;
    _isBusy = true;
    _notifyListeners();
    try {
      await operation(snapshot);
    } catch (_) {
      _restore(snapshot);
      _undoState = previousUndo;
      _notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      _notifyListeners();
    }
  }

  Future<void> mutateTransient({
    required void Function() change,
    UndoState Function(StateSnapshot snapshot)? undoFromSnapshot,
    bool clearUndoAfterSave = false,
    String pendingSaveMessage = PersistenceMessages.pendingDigitalDiceSave,
  }) async {
    assert(undoFromSnapshot == null || !clearUndoAfterSave);
    if (_isBusy) return;
    ensureDigitalSaveReady(pendingSaveMessage);
    final snapshot = _capture();
    final pending = _PendingTransient(
      snapshot: snapshot,
      undoFromSnapshot: undoFromSnapshot,
      clearUndoAfterSave: clearUndoAfterSave,
    );
    _isBusy = true;
    _notifyListeners();
    try {
      change();
      _notifyListeners();
      await _save();
      _applyTransientUndo(pending);
      _pendingTransient = null;
      _needsDigitalSaveRetry = false;
    } catch (_) {
      _pendingTransient = pending;
      _needsDigitalSaveRetry = true;
      _notifyListeners();
      rethrow;
    } finally {
      _isBusy = false;
      _notifyListeners();
    }
  }

  Future<void> retryDigitalSave() async {
    if (_isBusy || !_needsDigitalSaveRetry) return;
    final pending = _pendingTransient;
    if (pending == null) return;
    _isBusy = true;
    _notifyListeners();
    try {
      await _save();
      _applyTransientUndo(pending);
      _pendingTransient = null;
      _needsDigitalSaveRetry = false;
    } finally {
      _isBusy = false;
      _notifyListeners();
    }
  }

  Future<void> undo({
    required void Function(UndoState undo) restoreUndo,
    bool clearUndoBeforeSave = false,
  }) async {
    if (_isBusy) return;
    final undo = _undoState;
    if (undo == null) return;
    await transaction((_) async {
      restoreUndo(undo);
      if (clearUndoBeforeSave) _undoState = null;
      _notifyListeners();
      await _save();
      _undoState = null;
    });
  }

  Future<void> abandon() async {
    if (_isBusy) return;
    _isBusy = true;
    _notifyListeners();
    try {
      await _clear();
    } finally {
      _isBusy = false;
      _notifyListeners();
    }
  }

  void _applyTransientUndo(
    _PendingTransient<StateSnapshot, UndoState> pending,
  ) {
    if (pending.clearUndoAfterSave) {
      _undoState = null;
    } else {
      final undoFromSnapshot = pending.undoFromSnapshot;
      if (undoFromSnapshot != null) {
        _undoState = undoFromSnapshot(pending.snapshot);
      }
    }
  }
}

class _PendingTransient<
  StateSnapshot extends Object,
  UndoState extends Object
> {
  const _PendingTransient({
    required this.snapshot,
    required this.undoFromSnapshot,
    required this.clearUndoAfterSave,
  });

  final StateSnapshot snapshot;
  final UndoState Function(StateSnapshot snapshot)? undoFromSnapshot;
  final bool clearUndoAfterSave;
}

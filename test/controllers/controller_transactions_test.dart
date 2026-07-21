import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/controller_transactions.dart';

void main() {
  test(
    'transaction rolls state and prior undo back when saving fails',
    () async {
      var state = 0;
      var persisted = 0;
      var failSave = false;
      final transactions = ControllerTransactions<int, int>(
        capture: () => state,
        restore: (snapshot) => state = snapshot,
        save: () async {
          if (failSave) throw StateError('save failed');
          persisted = state;
        },
        clear: () async => persisted = -1,
        notifyListeners: () {},
      );

      await transactions.mutate(
        change: () => state = 1,
        undoFromSnapshot: (snapshot) => snapshot,
      );
      expect((state, persisted, transactions.canUndo), (1, 1, true));

      failSave = true;
      await expectLater(
        transactions.mutate(
          change: () => state = 2,
          undoFromSnapshot: (snapshot) => snapshot,
        ),
        throwsStateError,
      );
      expect((state, persisted, transactions.canUndo), (1, 1, true));

      await expectLater(
        transactions.undo(restoreUndo: (undo) => state = undo),
        throwsStateError,
      );
      expect((state, persisted, transactions.canUndo), (1, 1, true));

      failSave = false;
      await transactions.undo(restoreUndo: (undo) => state = undo);
      expect((state, persisted, transactions.canUndo), (0, 0, false));
    },
  );

  test('busy guard ignores overlapping mutations and undo', () async {
    var state = 0;
    var saveCalls = 0;
    final saveGate = Completer<void>();
    final transactions = ControllerTransactions<int, int>(
      capture: () => state,
      restore: (snapshot) => state = snapshot,
      save: () async {
        saveCalls++;
        await saveGate.future;
      },
      clear: () async {},
      notifyListeners: () {},
    );

    final first = transactions.mutate(
      change: () => state = 1,
      undoFromSnapshot: (snapshot) => snapshot,
    );
    expect(transactions.isBusy, isTrue);

    await transactions.mutate(change: () => state = 2);
    await transactions.undo(restoreUndo: (undo) => state = undo);
    expect((state, saveCalls), (1, 1));

    saveGate.complete();
    await first;
    expect(transactions.isBusy, isFalse);
  });

  test(
    'transient failure keeps state until the exact state is retried',
    () async {
      var state = 0;
      var persisted = 0;
      var failSave = false;
      final transactions = ControllerTransactions<int, int>(
        capture: () => state,
        restore: (snapshot) => state = snapshot,
        save: () async {
          if (failSave) throw StateError('save failed');
          persisted = state;
        },
        clear: () async {},
        notifyListeners: () {},
      );
      await transactions.mutate(
        change: () => state = 1,
        undoFromSnapshot: (snapshot) => snapshot,
      );

      failSave = true;
      await expectLater(
        transactions.mutateTransient(
          change: () => state = 2,
          clearUndoAfterSave: true,
        ),
        throwsStateError,
      );
      expect(state, 2);
      expect(persisted, 1);
      expect(transactions.needsDigitalSaveRetry, isTrue);
      expect(transactions.canUndo, isTrue);

      await expectLater(
        transactions.mutateTransient(change: () => state = 3),
        throwsStateError,
      );
      expect(state, 2);

      failSave = false;
      await transactions.retryDigitalSave();
      expect(persisted, 2);
      expect(transactions.needsDigitalSaveRetry, isFalse);
      expect(transactions.canUndo, isFalse);
    },
  );

  test('retry can commit the pre-transient snapshot as undo', () async {
    var state = 3;
    var failSave = true;
    final transactions = ControllerTransactions<int, int>(
      capture: () => state,
      restore: (snapshot) => state = snapshot,
      save: () async {
        if (failSave) throw StateError('save failed');
      },
      clear: () async {},
      notifyListeners: () {},
    );

    await expectLater(
      transactions.mutateTransient(
        change: () => state = 4,
        undoFromSnapshot: (snapshot) => snapshot,
      ),
      throwsStateError,
    );
    expect(transactions.canUndo, isFalse);

    failSave = false;
    await transactions.retryDigitalSave();
    expect(transactions.canUndo, isTrue);
    await transactions.undo(restoreUndo: (undo) => state = undo);
    expect(state, 3);
  });
}

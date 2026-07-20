import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/controllers/balut_controller.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/balut_game_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';

class _ControlledRepository extends MemoryGameRepository {
  bool failSave = false;
  Completer<void>? saveGate;
  int saveCalls = 0;
  // Store the last JSON that was attempted to save, so the test can verify
  // that no fresh random dice were generated on retry.
  String? lastPayload;

  @override
  Future<void> save(SavedGameState state) async {
    saveCalls++;
    final gate = saveGate;
    if (gate != null) await gate.future;
    if (failSave) throw StateError('save failed');
    await super.save(state);
  }
}

void main() {
  testWidgets(
    'failed digital roll keeps the dice and exposes a working retry button',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final values = <int>[1, 2, 3, 4, 5];
      final repository = _ControlledRepository()..failSave = true;
      final controller = BalutController.newGame(
        names: const ['Ada', 'Bea'],
        mode: GameMode.digital,
        repository: repository,
        roller: () => values.removeAt(0),
      );

      await tester.pumpWidget(
        MaterialApp(home: BalutGameScreen(game: controller)),
      );

      // Roll and let the save fail.
      // rollDigital throws because the save fails; ignore the exception.
      try {
        await tester.tap(find.byKey(const Key('balut-roll')));
        await tester.pumpAndSettle();
      } catch (_) {
        // Expected: the controller throws on save failure.
      }

      // Dice are still visible after the failed save.
      expect(controller.state.dice, [1, 2, 3, 4, 5]);
      expect(controller.state.rollCount, 1);
      expect(controller.needsDigitalSaveRetry, isTrue);

      // The retry button is enabled even while needsDigitalSaveRetry is true.
      final retryButton = find.byKey(const Key('balut-retry-save'));
      expect(retryButton, findsOneWidget);
      final retryWidget = tester.widget<FilledButton>(retryButton);
      expect(retryWidget.onPressed, isNotNull);

      // Retry with a working repository uses the same dice, no fresh roll.
      repository.failSave = false;
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(controller.needsDigitalSaveRetry, isFalse);
      expect(controller.state.dice, [1, 2, 3, 4, 5]);
      // The roll button returns because the save succeeded.
      expect(find.byKey(const Key('balut-roll')), findsOneWidget);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';

import 'package:wuerfelblock/models/backgammon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/backgammon_game_screen.dart';
import 'package:wuerfelblock/screens/backgammon_rules_screen.dart';

import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/services/locale_controller.dart';

Future<void> tapVisible(WidgetTester t, Finder f) async {
  for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
    await t.drag(find.byType(ListView).first, const Offset(0, -240));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  for (final lang in ['de', 'en']) {
    for (final size in [const Size(360, 800), const Size(800, 360)]) {
      testWidgets('setup at 200 percent $lang $size', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          WuerfelblockApp(
            repository: MemoryGameRepository(),
            localeController: LocaleController.ephemeral()
              ..locale = Locale(lang),
          ),
        );
        await t.pumpAndSettle();
        await tapVisible(
          t,
          find.text(lang == 'de' ? 'Neue Partie' : 'New game'),
        );
        await tapVisible(t, find.byKey(const Key('game-kind-backgammon')));
        await tapVisible(t, find.byKey(const Key('game-mode-digital')));
        await tapVisible(t, find.byKey(const Key('start-game')));
        expect(find.byType(BackgammonGameScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
  test(
    'repository roundtrip persisted undo and unknown discriminator',
    () async {
      final repo = MemoryGameRepository();
      var s = BackgammonGameState.newGame(['Anna', 'Ben']).roll(6, 2);
      s = s.move(s.legalMoves.first);
      await repo.save(s);
      final loaded = (await repo.load()).state as BackgammonGameState;
      expect(loaded.toJson(), s.toJson());
      expect(loaded.undo().remaining, [6, 2]);
      expect(
        () => decodeSavedGameState({...s.toJson(), 'type': 'Backgammon'}),
        throwsFormatException,
      );
      expect(
        () => decodeSavedGameState({
          ...s.toJson(),
          'bar': [15, 15],
        }),
        throwsFormatException,
      );
    },
  );
  for (final lang in ['de', 'en']) {
    for (final mode in GameMode.values) {
      testWidgets('app setup movement persistence resume $lang ${mode.name}', (
        t,
      ) async {
        t.view.physicalSize = const Size(360, 800);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = MemoryGameRepository();
        await t.pumpWidget(
          WuerfelblockApp(
            repository: repo,
            localeController: LocaleController.ephemeral()
              ..locale = Locale(lang),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text(lang == 'de' ? 'Neue Partie' : 'New game'));
        await t.pumpAndSettle();
        await tapVisible(t, find.byKey(const Key('game-kind-backgammon')));
        expect(find.byKey(const Key('add-player')), findsNothing);
        await tapVisible(t, find.byKey(Key('game-mode-${mode.name}')));
        await tapVisible(t, find.byType(TextFormField).first);
        await t.enterText(find.byType(TextFormField).first, 'Anna');
        await t.enterText(find.byType(TextFormField).last, 'Ben');
        await t.tap(find.byKey(const Key('start-game')));
        await t.pumpAndSettle();
        final screen = t.widget<BackgammonGameScreen>(
          find.byType(BackgammonGameScreen),
        );
        expect(screen.game.state.names, ['Anna', 'Ben']);
        expect(screen.game.state.mode, mode);
        expect(repo.saved, isA<BackgammonGameState>());
        if (mode == GameMode.block) {
          await tapVisible(
            t,
            find.text(lang == 'de' ? 'Wurf eingeben' : 'Enter roll'),
          );
          await tapVisible(t, find.byKey(const ValueKey('die-0-6')));
          await tapVisible(t, find.byKey(const ValueKey('die-1-2')));
          await tapVisible(
            t,
            find.text(lang == 'de' ? 'Wurf übernehmen' : 'Use roll'),
          );
        } else {
          await tapVisible(
            t,
            find.text(
              lang == 'de' ? 'Eröffnungswurf würfeln' : 'Roll opening dice',
            ),
          );
          for (var i = 0; i < 100 && screen.game.state.opening; i++) {
            await tapVisible(
              t,
              find.text(
                lang == 'de' ? 'Eröffnungswurf würfeln' : 'Roll opening dice',
              ),
            );
          }
        }
        expect(screen.game.state.opening, false);
        final move = screen.game.state.legalMoves.first;
        await tapVisible(t, find.byKey(ValueKey('source-${move.from}')));
        await tapVisible(
          t,
          find.byKey(ValueKey('move-${move.from}-${move.to}-${move.die}')),
        );
        final saved = screen.game.state.toJson();
        Navigator.of(t.element(find.byType(BackgammonGameScreen))).pop();
        await t.pumpAndSettle();
        await tapVisible(
          t,
          find.text(lang == 'de' ? 'Partie fortsetzen' : 'Continue game'),
        );
        expect(
          t
              .widget<BackgammonGameScreen>(find.byType(BackgammonGameScreen))
              .game
              .state
              .toJson(),
          saved,
        );
        await t.tap(find.byIcon(Icons.help_outline));
        await t.pumpAndSettle();
        expect(find.byType(BackgammonRulesScreen), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets('finished save resumes result rather than new game', (t) async {
    var s = BackgammonGameState(
      names: ['Anna', 'Ben'],
      mode: GameMode.block,
      points: [1, ...List.filled(22, 0), -15],
      off: const [14, 0],
    ).roll(1, 2);
    s = s.move(s.legalMoves.first);
    final repo = MemoryGameRepository();
    await repo.save(s);
    await t.pumpWidget(WuerfelblockApp(repository: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Partie fortsetzen'));
    await t.pumpAndSettle();
    expect(find.text('Anna · Gewonnen'), findsOneWidget);
    expect(find.text('Gammon · 2 Punkte'), findsOneWidget);
  });
}

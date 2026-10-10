import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/models/backgammon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/screens/backgammon_rules_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/services/locale_controller.dart';
import 'backgammon_integration_test.dart' show tapVisible;

void main() {
  test(
    'real preferences retain original save key and legacy classic identity',
    () async {
      final legacy = GameState(
        ruleSet: RuleSet.kniffel,
        mode: GameMode.block,
        players: [
          Player(name: 'Ada'),
          Player(name: 'Ben'),
        ],
      ).toJson()..remove('type');
      SharedPreferences.setMockInitialValues({
        'active_game_v1': jsonEncode(legacy),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesGameRepository(prefs);
      expect((await repo.load()).state, isA<GameState>());
      var state = BackgammonGameState.newGame(['Ada', 'Ben']).roll(6, 2);
      state = state.move(state.legalMoves.first);
      await repo.save(state);
      final resumed =
          (await SharedPreferencesGameRepository(prefs).load()).state
              as BackgammonGameState;
      expect(resumed.toJson(), state.toJson());
      expect(resumed.undo().remaining, [6, 2]);
      expect(prefs.getKeys(), {'active_game_v1'});
    },
  );

  for (final lang in ['de', 'en']) {
    for (final type in BackgammonWinType.values) {
      testWidgets(
        'persisted $type result, both rule routes, large text $lang',
        (t) async {
          t.view.physicalSize = const Size(360, 800);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final p = List<int>.filled(24, 0)..[0] = 1;
          p[type == BackgammonWinType.backgammon ? 1 : 23] =
              type == BackgammonWinType.normal ? -14 : -15;
          var s = BackgammonGameState(
            names: ['Ada', 'Ben'],
            mode: GameMode.block,
            points: p,
            off: [14, type == BackgammonWinType.normal ? 1 : 0],
          ).roll(1, 2);
          s = s.move(s.legalMoves.first);
          final repo = MemoryGameRepository();
          await repo.save(s);
          await t.pumpWidget(
            WuerfelblockApp(
              repository: repo,
              localeController: LocaleController.ephemeral()
                ..locale = Locale(lang),
            ),
          );
          await t.pumpAndSettle();
          await tapVisible(
            t,
            find.text(lang == 'de' ? 'Partie fortsetzen' : 'Continue game'),
          );
          expect(
            find.text(lang == 'de' ? 'Ada · Gewonnen' : 'Ada · Won'),
            findsOneWidget,
          );
          final label = switch (type) {
            BackgammonWinType.normal =>
              lang == 'de' ? 'Normaler Sieg · 1 Punkt' : 'Normal win · 1 point',
            BackgammonWinType.gammon =>
              lang == 'de' ? 'Gammon · 2 Punkte' : 'Gammon · 2 points',
            BackgammonWinType.backgammon =>
              lang == 'de' ? 'Backgammon · 3 Punkte' : 'Backgammon · 3 points',
          };
          expect(find.text(label), findsOneWidget);
          await t.tap(find.byIcon(Icons.help_outline));
          await t.pumpAndSettle();
          expect(find.byType(BackgammonRulesScreen), findsOneWidget);
          expect(
            find.text(
              lang == 'de' ? 'Backgammon · Regeln' : 'Backgammon · Rules',
            ),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
          Navigator.of(t.element(find.byType(BackgammonRulesScreen))).pop();
          await t.pumpAndSettle();
          await tapVisible(
            t,
            find.text(lang == 'de' ? 'Zur Startseite' : 'Home'),
          );
          await tapVisible(
            t,
            find.text(lang == 'de' ? 'Spielregeln' : 'Game rules'),
          );
          await tapVisible(t, find.byKey(const Key('rules-link-backgammon')));
          expect(find.byType(BackgammonRulesScreen), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}

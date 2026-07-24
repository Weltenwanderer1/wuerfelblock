import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/core/app_theme.dart';
import 'package:wuerfelblock/screens/card_games_rules_screen.dart';
import 'package:wuerfelblock/screens/rules_selection_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('home Spielregeln action opens the rules selection screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      WuerfelblockApp(repository: MemoryGameRepository()),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('rules-action'));
    expect(action, findsOneWidget);
    expect(find.text('Spielregeln'), findsOneWidget);

    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(RulesSelectionScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Spielregeln'), findsOneWidget);
  });

  testWidgets('rules selection exposes every instruction separately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const RulesSelectionScreen()),
    );
    await tester.pumpAndSettle();

    for (final title in <String>[
      'Yahtzee/Kniffel',
      'Colordice',
      '10.000',
      'Balut',
      'Crisps!',
      'Regicide',
      'Haggis',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(find.byKey(const Key('rules-link-crisps')), findsOneWidget);
    expect(find.byKey(const Key('rules-link-regicide')), findsOneWidget);
    expect(find.byKey(const Key('rules-link-haggis')), findsOneWidget);

    await tester.tap(find.byKey(const Key('rules-link-crisps')));
    await tester.pumpAndSettle();

    expect(find.byType(CardGameRulesScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Crisps!-Regeln'), findsOneWidget);
    expect(find.byKey(const Key('card-game-rules-crisps')), findsOneWidget);
    expect(find.byKey(const Key('card-game-rules-regicide')), findsNothing);
    expect(find.byKey(const Key('card-game-rules-haggis')), findsNothing);
  });

  testWidgets('each card game page keeps its own rules', (tester) async {
    for (final entry in <(CardGame, String, String)>[
      (CardGame.crisps, 'Crisps!', 'Buben und Könige entfernen'),
      (CardGame.regicide, 'Regicide', 'Herz vor Karo'),
      (CardGame.haggis, 'Haggis', '13 statt 14 Karten'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: CardGameRulesScreen(game: entry.$1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, '${entry.$2}-Regeln'), findsOneWidget);
      expect(find.textContaining(entry.$3), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.byType(Scrollable), findsOneWidget);
    }
  });

  testWidgets('card game rules fit a small portrait viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const CardGameRulesScreen(game: CardGame.crisps),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card game rules remain usable with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: MaterialApp(
          theme: buildTheme(),
          home: const CardGameRulesScreen(game: CardGame.regicide),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

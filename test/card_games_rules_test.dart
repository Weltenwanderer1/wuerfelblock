import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/core/app_theme.dart';
import 'package:wuerfelblock/screens/card_games_rules_screen.dart';
import 'package:wuerfelblock/services/game_repository.dart';

void main() {
  testWidgets('home Spielregeln action opens the card-game rules screen', (
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

    final action = find.byKey(const Key('card-games-rules-action'));
    expect(action, findsOneWidget);
    expect(find.text('Spielregeln'), findsOneWidget);

    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byType(CardGamesRulesScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Spielregeln'), findsOneWidget);
  });

  testWidgets('screen exposes all three games in distinct rule cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const CardGamesRulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.byKey(const Key('card-game-rules-crisps')), findsOneWidget);
    expect(find.byKey(const Key('card-game-rules-regicide')), findsOneWidget);
    expect(find.byKey(const Key('card-game-rules-haggis')), findsOneWidget);
    expect(find.text('Crisps!'), findsOneWidget);
    expect(find.text('Regicide'), findsOneWidget);
    expect(find.text('Haggis'), findsOneWidget);
  });

  testWidgets('rules include standard-deck adaptations and end conditions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const CardGamesRulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Buben und Könige entfernen'), findsOneWidget);
    expect(find.textContaining('vier Damen'), findsOneWidget);
    expect(find.textContaining('hungrigere Person'), findsOneWidget);
    expect(find.textContaining('wer zuerst 3 Punkte erreicht'), findsOneWidget);

    expect(find.textContaining('52er-Deck plus 2 Joker'), findsOneWidget);
    expect(find.textContaining('Herz vor Karo'), findsOneWidget);
    expect(
      find.textContaining('Sieg: den letzten König besiegen'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Niederlage: einen Gegenangriff nicht bezahlen'),
      findsOneWidget,
    );

    expect(find.textContaining('13 statt 14 Karten'), findsOneWidget);
    expect(find.textContaining('später wieder mitspielen'), findsOneWidget);
    expect(
      find.textContaining('sobald die zweite Person leer ist'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Bei Gleichstand beginnt die Person links von der Geberin',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('250 Punkte (kurz) oder 350 Punkte (lang)'),
      findsOneWidget,
    );
  });

  testWidgets('rules fit a small portrait viewport without layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const CardGamesRulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rules remain usable with large text', (tester) async {
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
          home: const CardGamesRulesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

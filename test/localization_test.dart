import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuerfelblock/app.dart';
import 'package:wuerfelblock/l10n/app_localizations.dart';
import 'package:wuerfelblock/l10n/localized_text.dart';
import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/services/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit locale choice is persisted and wins on restart', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = LocaleController(preferences);

    expect(first.locale, isNull);
    await first.select(const Locale('en'));

    final restarted = LocaleController(preferences);
    expect(restarted.locale, const Locale('en'));
  });

  testWidgets('German default and English choice localize the whole app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final localeController = LocaleController(preferences);
    await localeController.select(const Locale('de'));
    await tester.pumpWidget(
      WuerfelblockApp(
        repository: MemoryGameRepository(),
        localeController: localeController,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Neue Partie'), findsOneWidget);

    await localeController.select(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Neue Partie'), findsNothing);
  });

  testWidgets('first launch follows an English system locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      WuerfelblockApp(
        repository: MemoryGameRepository(),
        localeController: LocaleController(preferences),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Neue Partie'), findsNothing);

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    final enteredNames = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(enteredNames, containsAll(<String>['Player 1', 'Player 2']));
    expect(enteredNames, isNot(contains('Spieler 1')));
  });

  testWidgets('unsupported system locale falls back to German', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      WuerfelblockApp(
        repository: MemoryGameRepository(),
        localeController: LocaleController(preferences),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neue Partie'), findsOneWidget);
    expect(find.text('New game'), findsNothing);
  });

  testWidgets('invalid stored locale safely forces German', (tester) async {
    SharedPreferences.setMockInitialValues({
      LocaleController.preferenceKey: 'xx',
    });
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final preferences = await SharedPreferences.getInstance();
    final localeController = LocaleController(preferences);

    expect(localeController.locale, const Locale('de'));
    await tester.pumpWidget(
      WuerfelblockApp(
        repository: MemoryGameRepository(),
        localeController: localeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neue Partie'), findsOneWidget);
    expect(find.text('New game'), findsNothing);
  });

  testWidgets('language switch never rewrites an edited player name', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final localeController = LocaleController(preferences);
    await localeController.select(const Locale('de'));
    await tester.pumpWidget(
      WuerfelblockApp(
        repository: MemoryGameRepository(),
        localeController: localeController,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Partie'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Spieler 99');
    await localeController.select(const Locale('en'));
    await tester.pumpAndSettle();

    final enteredNames = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(enteredNames, containsAll(<String>['Spieler 99', 'Player 2']));
  });

  testWidgets('dynamic names and numbers survive English templates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Column(
            children: [
              LocalizedText('Aktive Person: Alex'),
              LocalizedText('Name Spieler 2'),
              LocalizedText('Einser: 3 Punkte'),
              LocalizedText('Aktive Person: Rot'),
              LocalizedText('Sieger: Ada, Bea'),
              LocalizedText('Gewonnen: Ada, Bea'),
              LocalizedText('Erlaubte Werte: 0, 5, 10'),
              LocalizedText('Einstellungen & Info'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Active player: Alex'), findsOneWidget);
    expect(find.text('Player 2 name'), findsOneWidget);
    expect(find.text('Ones: 3 points'), findsOneWidget);
    expect(find.text('Active player: Rot'), findsOneWidget);
    expect(find.text('Winners: Ada, Bea'), findsNWidgets(2));
    expect(find.text('Allowed values: 0, 5, 10'), findsOneWidget);
    expect(find.text('Settings & info'), findsOneWidget);
  });

  testWidgets('About/privacy and language switch fit 360x800 at 200 percent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final localeController = LocaleController(preferences);
    await localeController.select(const Locale('de'));
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: WuerfelblockApp(
          repository: MemoryGameRepository(),
          localeController: localeController,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final settingsAction = find.byKey(const Key('settings-about-action'));
    await tester.ensureVisible(settingsAction);
    await tester.pumpAndSettle();
    await tester.tap(settingsAction);
    await tester.pumpAndSettle();

    expect(find.text('Über Würfelblock'), findsOneWidget);
    expect(find.text('Günther Schuch'), findsOneWidget);

    final englishAction = find.byKey(const Key('language-en'));
    await tester.tap(englishAction);
    await tester.pumpAndSettle();
    expect(find.text('About Würfelblock'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('privacy-summary')),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('no accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

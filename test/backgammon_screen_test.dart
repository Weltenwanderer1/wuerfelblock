import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/core/app_theme.dart';
import 'package:wuerfelblock/controllers/backgammon_controller.dart';
import 'package:wuerfelblock/models/backgammon_models.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/saved_game_state.dart';
import 'package:wuerfelblock/services/game_repository.dart';
import 'package:wuerfelblock/screens/backgammon_game_screen.dart';
import 'package:wuerfelblock/widgets/backgammon_board.dart';

class Repo implements GameRepository {
  bool fail = false;
  BackgammonGameState? saved;
  @override
  Future<void> save(SavedGameState s) async {
    if (fail) throw StateError('disk');
    saved = BackgammonGameState.fromJson(s.toJson());
  }

  @override
  Future<LoadResult> load() async => LoadResult(state: saved);
  @override
  Future<void> clear() async {
    saved = null;
  }
}

const shot = ValueKey('screenshot');
Future<void> mount(
  WidgetTester tester,
  BackgammonController c, {
  String lang = 'en',
  double scale = 1,
  Size size = const Size(360, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme().copyWith(
        textTheme: buildTheme().textTheme.apply(fontFamily: 'Roboto'),
        filledButtonTheme: FilledButtonThemeData(
          style: buildTheme().filledButtonTheme.style!.copyWith(
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Roboto',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      locale: Locale(lang),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: shot,
        child: BackgammonGameScreen(key: ObjectKey(c), game: c),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shot));
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/backgammon-screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> tapVisible(WidgetTester t, Finder f) async {
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    await t.drag(find.byType(ListView).first, const Offset(0, -200));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

BackgammonGameState position({
  bool win = false,
  bool bar = false,
  bool doubles = false,
}) {
  final p = List.filled(24, 0);
  p[0] = win ? 1 : 6;
  p[5] = win ? 0 : 9;
  p[18] = -15;
  return BackgammonGameState(
    names: const ['Ada', 'Ben'],
    mode: GameMode.digital,
    points: p,
    bar: bar ? [0, 1] : [0, 0],
    off: win ? [14, 0] : [0, 0],
    dice: doubles ? [4, 4] : [1, 2],
    remaining: doubles ? [4, 4, 4, 4] : [1, 2],
  );
}

void main() {
  setUpAll(() async {
    var sdk = File(Platform.resolvedExecutable).parent;
    while (!File(
          '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).existsSync() &&
        sdk.parent.path != sdk.path) {
      sdk = sdk.parent;
    }
    final root = Platform.environment['FLUTTER_ROOT'] ?? sdk.path;
    final file = File(
      '$root/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    );
    final fallback = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    final bytes = await (await fallback.exists() ? fallback : file)
        .readAsBytes();
    final icons = await File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    for (final family in ['Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(
            Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
          ))
          .load();
    }
  });
  testWidgets('physical explicit input, tie, moves undo save resume', (
    tester,
  ) async {
    final repo = Repo();
    final c = BackgammonController.newGame(
      names: ['Ada', 'Ben'],
      repository: repo,
      roller: () => throw StateError('RNG forbidden'),
    );
    await mount(tester, c, scale: 2);
    await tapVisible(tester, find.text('Enter roll'));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Use roll'))
          .onPressed,
      isNull,
    );
    await tapVisible(tester, find.byKey(const ValueKey('die-0-3')));
    await tapVisible(tester, find.byKey(const ValueKey('die-1-3')));
    await tapVisible(tester, find.text('Use roll'));
    expect(c.state.opening, true);
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text('Tie — both roll again'), findsOneWidget);
    await tapVisible(tester, find.text('Enter roll'));
    await tapVisible(tester, find.byKey(const ValueKey('die-0-6')));
    await tapVisible(tester, find.byKey(const ValueKey('die-1-2')));
    await tapVisible(tester, find.text('Use roll'));
    final before = c.state;
    final m = before.legalMoves.first;
    await tapVisible(tester, find.byKey(ValueKey('source-${m.from}')));
    await tapVisible(
      tester,
      find.byKey(ValueKey('move-${m.from}-${m.to}-${m.die}')),
    );
    expect(c.state.remaining.length, 1);
    await tapVisible(tester, find.text('Undo last move'));
    expect(c.state.points, before.points);
    expect(repo.saved!.remaining, [6, 2]);
    final resumed = BackgammonController(state: repo.saved!, repository: repo);
    await mount(tester, resumed);
    expect(resumed.state.toJson(), c.state.toJson());
  });
  testWidgets(
    'digital failed save blocks movement, retry preserves roll, win persisted',
    (tester) async {
      final repo = Repo()..fail = true;
      var calls = 0;
      final c = BackgammonController.newGame(
        names: ['Ada', 'Ben'],
        repository: repo,
        mode: GameMode.digital,
        roller: () => ++calls == 1 ? 6 : 2,
      );
      await mount(tester, c, scale: 2);
      await tapVisible(tester, find.text('Roll opening dice'));
      expect(c.needsSaveRetry, true);
      final pending = c.state;
      await capture(tester, 'error');
      repo.fail = false;
      await tapVisible(tester, find.text('Retry save'));
      expect(calls, 2);
      expect(c.state, same(pending));
      final winner = BackgammonController(
        state: position(win: true),
        repository: repo,
      );
      await mount(tester, winner, scale: 2);
      await tapVisible(tester, find.byKey(const ValueKey('source-1')));
      await tapVisible(tester, find.byKey(const ValueKey('move-1-25-2')));
      expect(winner.state.isComplete, true);
      expect(repo.saved!.isComplete, true);
      await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(find.text('Ada · Won'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await capture(tester, 'win');
    },
  );
  testWidgets('failed winning save does not expose completed result or home', (
    tester,
  ) async {
    final repo = Repo()..fail = true;
    final c = BackgammonController(
      state: position(win: true),
      repository: repo,
    );
    await mount(tester, c, scale: 2);
    await tapVisible(tester, find.byKey(const ValueKey('source-1')));
    await tapVisible(tester, find.byKey(const ValueKey('move-1-25-2')));
    expect(c.state.isComplete, true);
    expect(c.needsSaveRetry, true);
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Ada · Won'), findsNothing);
    repo.fail = false;
    await tapVisible(tester, find.text('Retry save'));
    await tester.drag(find.byType(ListView).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('Ada · Won'), findsOneWidget);
    expect(repo.saved!.isComplete, true);
  });
  testWidgets('native board semantics and complete doubles turn', (
    tester,
  ) async {
    final repo = Repo();
    final c = BackgammonController(
      state: position(doubles: true),
      repository: repo,
    );
    await mount(tester, c, scale: 2);
    for (var i = 0; i < 4; i++) {
      final m = c.state.legalMoves.first;
      await tapVisible(tester, find.byKey(ValueKey('source-${m.from}')));
      await tapVisible(
        tester,
        find.byKey(ValueKey('move-${m.from}-${m.to}-${m.die}')),
      );
    }
    expect(c.state.remaining, isEmpty);
    await tapVisible(tester, find.text('End turn'));
    expect(c.state.activePlayerIndex, 1);
    expect(repo.saved!.dice, isEmpty);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BackgammonBoard(state: c.state)),
      ),
    );
    await tester.pumpAndSettle();
    for (var p = 1; p <= 24; p++) {
      expect(find.bySemanticsLabel(RegExp('^Point $p,')), findsOneWidget);
    }
    handle.dispose();
  });
  for (final lang in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final size in [const Size(360, 800), const Size(800, 360)]) {
        testWidgets('production render $lang $scale $size', (tester) async {
          final c = BackgammonController.newGame(
            names: ['Ada', 'Ben'],
            repository: Repo(),
          );
          await mount(tester, c, lang: lang, scale: scale, size: size);
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            'start-$lang-${scale.toInt()}-${size.width.toInt()}',
          );
          if (scale == 2) {
            expect(find.byType(BackgammonBoard), findsNothing);
          }
          await tapVisible(tester, find.text(lang == 'de' ? 'Brett' : 'Board'));
          await tester.ensureVisible(find.byType(BackgammonBoard));
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.text(lang == 'de' ? 'Rechts' : 'Right'),
          );
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            'board-$lang-${scale.toInt()}-${size.width.toInt()}',
          );
        });
      }
    }
  }
  testWidgets('board production selection stacks bar doubles bearoff', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 500);
    for (final name in ['selection', 'bar9stack', 'doubles', 'bearoff']) {
      var state = position(doubles: name == 'doubles', win: name == 'bearoff');
      if (name == 'bar9stack') {
        final p = List<int>.of(state.points);
        p[18] = -14;
        state = BackgammonGameState(
          names: state.names,
          mode: state.mode,
          points: p,
          bar: const [0, 1],
          dice: state.dice,
          remaining: state.remaining,
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme().copyWith(
            textTheme: buildTheme().textTheme.apply(fontFamily: 'Roboto'),
            filledButtonTheme: FilledButtonThemeData(
              style: buildTheme().filledButtonTheme.style!.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: shot,
              child: BackgammonBoard(
                state: state,
                selected: 6,
                onPoint: (_) {},
                width: 800,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (name == 'doubles') {
        await mount(
          tester,
          BackgammonController(state: state, repository: Repo()),
          size: const Size(800, 360),
        );
        await tester.ensureVisible(find.text('Doubles — four moves of 4'));
        await tester.pumpAndSettle();
      }
      await capture(tester, name);
    }
  });
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
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
import 'package:wuerfelblock/widgets/backgammon_salon.dart';

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
      theme: buildTheme(),
      locale: Locale(lang),
      supportedLocales: const [Locale('de'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: shot,
        child: BackgammonGameScreen(key: ObjectKey(c), game: c),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(BackgammonGameScreen));
    for (final name in ['mahogany', 'emblem', 'roll', 'undo', 'rules']) {
      await precacheImage(
        AssetImage('assets/images/backgammon/$name.png'),
        context,
      );
    }
  });
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(shot));
  await tester.runAsync(() async {
    final image = await b.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/backgammon-screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> tapVisible(WidgetTester t, Finder f) async {
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
  p[18] = bar ? -14 : -15;
  return BackgammonGameState(
    names: const ['Ada', 'Ben'],
    mode: GameMode.digital,
    points: p,
    bar: bar ? [0, 1] : [0, 0],
    off: win ? [14, 0] : [0, 0],
    activePlayerIndex: bar ? 1 : 0,
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
    final icons = await File(
      '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    final bytes = await File(
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ).readAsBytes();
    for (final family in ['Roboto', 'Ahem', 'serif']) {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  testWidgets(
    'portrait no scroll, 24 measured native points, opening selection save error',
    (t) async {
      final repo = Repo();
      final c = BackgammonController.newGame(
        names: ['Ada', 'Ben'],
        repository: repo,
        mode: GameMode.digital,
        roller: () => 6,
      );
      await mount(t, c, lang: 'de');
      void measure() {
        expect(find.byType(Scrollable), findsNothing);
        final board = t.getRect(find.byType(BackgammonBoard));
        final action = t.getRect(find.byKey(const ValueKey('primary-action')));
        expect(board.top, greaterThanOrEqualTo(80));
        expect(board.bottom, lessThan(action.top));
        expect(action.bottom, lessThanOrEqualTo(776));
        expect(find.byType(IvoryDie), findsNWidgets(2));
        for (final finder in [
          find.byType(IvoryDie).first,
          find.byType(IvoryDie).last,
          find.byTooltip('Letzten Zug zurücknehmen'),
          find.byTooltip('Bedienansicht wechseln'),
        ]) {
          final rect = t.getRect(finder);
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.bottom, lessThanOrEqualTo(776));
        }
        for (var p = 1; p <= 24; p++) {
          final r = t.getRect(find.byKey(ValueKey('point-$p')));
          expect(board.contains(r.topLeft), true);
          expect(board.contains(r.bottomRight), true);
          expect(r.width, greaterThan(100));
          expect(r.height, greaterThan(25));
        }
        for (final key in ['bar-0', 'bar-1', 'off-0', 'off-1']) {
          final r = t.getRect(find.byKey(ValueKey(key)));
          expect(board.contains(r.center), true);
        }
        // ignore: avoid_print
        print(
          '360x800 safe bounds: board=$board primary=$action point1=${t.getRect(find.byKey(const ValueKey('point-1')))}; scrollables=0',
        );
        expect(t.takeException(), isNull);
      }

      measure();
      await capture(t, 'salon-opening');
      final selected = BackgammonController(
        state: BackgammonGameState.newGame(['Ada', 'Ben']).roll(6, 2),
        repository: repo,
      );
      await mount(t, selected, lang: 'de');
      final move = selected.state.legalMoves.first;
      await tapVisible(t, find.byKey(ValueKey('point-${move.from}')));
      measure();
      await capture(t, 'salon-selected');
      final before = selected.state;
      await tapVisible(t, find.byKey(ValueKey('point-${move.to}')));
      expect(selected.state.points, isNot(before.points));
      await t.tap(find.byTooltip('Letzten Zug zurücknehmen'));
      await t.pumpAndSettle();
      expect(selected.state.points, before.points);
      repo.fail = true;
      final error = BackgammonController.newGame(
        names: ['Ada', 'Ben'],
        repository: repo,
        mode: GameMode.digital,
        roller: () => 6,
      );
      await mount(t, error, lang: 'de');
      await tapVisible(t, find.byKey(const ValueKey('primary-action')));
      expect(error.needsSaveRetry, true);
      measure();
      await capture(t, 'salon-save-error');
      repo.fail = false;
      final pending = error.state;
      await tapVisible(t, find.text('Erneut speichern'));
      expect(error.state, same(pending));
      expect(error.needsSaveRetry, false);
    },
  );
  testWidgets('200 percent physical input tie moves undo resume', (t) async {
    final repo = Repo();
    final c = BackgammonController.newGame(
      names: ['Ada', 'Ben'],
      repository: repo,
      roller: () => throw StateError('RNG forbidden'),
    );
    await mount(t, c, scale: 2);
    expect(find.byType(BackgammonBoard), findsNothing);
    await tapVisible(t, find.text('Enter roll'));
    expect(
      t
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Use roll'))
          .onPressed,
      isNull,
    );
    await tapVisible(t, find.byKey(const ValueKey('die-0-3')));
    await tapVisible(t, find.byKey(const ValueKey('die-1-3')));
    await tapVisible(t, find.text('Use roll'));
    expect(c.state.opening, true);
    expect(find.text('Tie — both roll again'), findsOneWidget);
    await tapVisible(t, find.text('Enter roll'));
    await tapVisible(t, find.byKey(const ValueKey('die-0-6')));
    await tapVisible(t, find.byKey(const ValueKey('die-1-2')));
    await tapVisible(t, find.text('Use roll'));
    final before = c.state;
    final m = before.legalMoves.first;
    await tapVisible(t, find.byKey(ValueKey('source-${m.from}')));
    await tapVisible(
      t,
      find.byKey(ValueKey('move-${m.from}-${m.to}-${m.die}')),
    );
    expect(c.state.remaining.length, 1);
    await tapVisible(t, find.byTooltip('Undo last move'));
    expect(c.state.points, before.points);
    expect(repo.saved!.remaining, [6, 2]);
    final resumed = BackgammonController(state: repo.saved!, repository: repo);
    await mount(t, resumed, scale: 2);
    expect(resumed.state.toJson(), c.state.toJson());
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'native portrait bar reentry and borne off targets preserve IDs',
    (t) async {
      final repo = Repo();
      final c = BackgammonController(
        state: position(bar: true),
        repository: repo,
      );
      await mount(t, c);
      final m = c.state.legalMoves.first;
      expect(m.from, 0);
      await tapVisible(t, find.byKey(const ValueKey('bar-1')));
      await tapVisible(t, find.byKey(ValueKey('point-${m.to}')));
      expect(c.state.bar[1], 0);
      final win = BackgammonController(
        state: position(win: true),
        repository: repo,
      );
      await mount(t, win);
      await tapVisible(t, find.byKey(const ValueKey('point-1')));
      await tapVisible(t, find.byKey(const ValueKey('off-0')));
      if (find.text('Choose die').evaluate().isNotEmpty) {
        await tapVisible(t, find.text('With die 2'));
      }
      expect(win.state.isComplete, true);
      expect(repo.saved!.isComplete, true);
      expect(find.text('Ada · Won'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('failed winning save hides result and home until retry', (
    t,
  ) async {
    final repo = Repo()..fail = true;
    final c = BackgammonController(
      state: position(win: true),
      repository: repo,
    );
    await mount(t, c, scale: 2);
    await tapVisible(t, find.byKey(const ValueKey('source-1')));
    await tapVisible(t, find.byKey(const ValueKey('move-1-25-2')));
    expect(c.needsSaveRetry, true);
    expect(find.text('Ada · Won'), findsNothing);
    expect(find.text('Home'), findsNothing);
    repo.fail = false;
    await tapVisible(t, find.text('Retry save'));
    expect(find.text('Ada · Won'), findsOneWidget);
    expect(repo.saved!.isComplete, true);
  });
  testWidgets('doubles native accessible full turn and landscape geometry', (
    t,
  ) async {
    final repo = Repo();
    final c = BackgammonController(
      state: position(doubles: true),
      repository: repo,
    );
    await mount(t, c, scale: 2);
    for (var i = 0; i < 4; i++) {
      final m = c.state.legalMoves.first;
      await tapVisible(t, find.byKey(ValueKey('source-${m.from}')));
      await tapVisible(
        t,
        find.byKey(ValueKey('move-${m.from}-${m.to}-${m.die}')),
      );
    }
    expect(c.state.remaining, isEmpty);
    await tapVisible(t, find.text('End turn'));
    expect(c.state.activePlayerIndex, 1);
    expect(repo.saved!.dice, isEmpty);
    await mount(t, c, size: const Size(800, 360));
    expect(find.byType(Scrollable), findsNothing);
    expect(t.takeException(), isNull);
    final handle = t.ensureSemantics();
    await t.pump();
    for (var p = 1; p <= 24; p++) {
      expect(find.bySemanticsLabel(RegExp('^Point $p,')), findsOneWidget);
    }
    handle.dispose();
  });
}

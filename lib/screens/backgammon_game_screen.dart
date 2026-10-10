import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/backgammon_controller.dart';
import '../models/backgammon_models.dart';
import '../models/game_models.dart';
import '../widgets/backgammon_board.dart';
import '../widgets/backgammon_salon.dart';
import 'backgammon_rules_screen.dart';

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({super.key, required this.game});
  final BackgammonController game;
  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  int? selected;
  bool allowPop = false;
  bool? listPrimary;
  String? message;
  BackgammonController get game => widget.game;
  bool get locked => game.isBusy || game.needsSaveRetry;
  String t(String de, String en) => bgText(context, de, en);
  Future<T?> salonDialog<T>(WidgetBuilder builder) => showDialog<T>(
    context: context,
    builder: (c) => Theme(
      data: salonTheme(c),
      child: Builder(builder: builder),
    ),
  );
  Future<void> action(Future<void> Function() call) async {
    if (game.isBusy) return;
    try {
      await call();
      if (mounted) {
        setState(() {
          selected = null;
          message = t('Gespeichert', 'Saved');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = t('Aktion fehlgeschlagen.', 'Action failed.'));
      }
    }
  }

  Future<void> leave() async {
    if (game.isBusy) return;
    if (game.needsSaveRetry) {
      final exit = await salonDialog<bool>(
        (c) => AlertDialog(
          title: Text(t('Stand nicht gesichert', 'Position not saved')),
          content: Text(
            t(
              'Beim Verlassen kann dieser Stand verloren gehen.',
              'Leaving may lose this position.',
            ),
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(c, false),
              child: Text(t('Hier bleiben', 'Stay here')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(t('Trotzdem verlassen', 'Leave anyway')),
            ),
          ],
        ),
      );
      if (exit != true) return;
    }
    if (!mounted) return;
    setState(() => allowPop = true);
    Navigator.of(context).pop();
  }

  Future<void> manualRoll() async {
    int? first, second;
    final opening = game.state.opening;
    final values = await salonDialog<List<int>>(
      (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: Text(
            t(
              opening ? 'Eröffnungswurf' : 'Wurf eingeben',
              opening ? 'Opening roll' : 'Enter roll',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var group = 0; group < 2; group++) ...[
                  Text(
                    opening
                        ? '${game.state.names[group]} · ${group == 0 ? t('Hell', 'Light') : t('Dunkel', 'Dark')}'
                        : '${t('Würfel', 'Die')} ${group + 1}',
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var n = 1; n <= 6; n++)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: OutlinedButton(
                            key: ValueKey('die-$group-$n'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  (group == 0 ? first : second) == n
                                  ? const Color(0xFF76502A)
                                  : null,
                            ),
                            onPressed: () => update(() {
                              if (group == 0) {
                                first = n;
                              } else {
                                second = n;
                              }
                            }),
                            child: Semantics(
                              selected: (group == 0 ? first : second) == n,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  IvoryDie(n),
                                  if ((group == 0 ? first : second) == n)
                                    const Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: salonWood,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(t('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: first == null || second == null
                  ? null
                  : () => Navigator.pop(c, [first!, second!]),
              child: Text(t('Wurf übernehmen', 'Use roll')),
            ),
          ],
        ),
      ),
    );
    if (values != null && !locked) {
      await action(() => game.enterRoll(values[0], values[1]));
    }
  }

  String point(int p) => p == 0
      ? 'Bar'
      : p == 25
      ? t('Ausspielen', 'Bear off')
      : '${t('Punkt', 'Point')} $p';
  int pipCount(BackgammonGameState s, int player) =>
      25 * s.bar[player] +
      [
        for (var p = 1; p <= 24; p++)
          if (s.points[p - 1] * (player == 0 ? 1 : -1) > 0)
            s.points[p - 1].abs() * (player == 0 ? p : 25 - p),
      ].fold(0, (a, b) => a + b);
  Future<void> choose(int p) async {
    if (locked || game.state.isComplete) return;
    final source = game.state.bar[game.state.activePlayerIndex] > 0
        ? 0
        : selected;
    final moves = game.state.legalMoves
        .where((m) => m.from == source && m.to == p)
        .toList();
    if (moves.isNotEmpty) {
      BackgammonMove? move = moves.first;
      if (moves.length > 1) {
        move = await salonDialog<BackgammonMove>(
          (c) => SimpleDialog(
            title: Text(t('Würfel auswählen', 'Choose die')),
            children: [
              for (final m in moves)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(c, m),
                  child: Text('${t('Mit Würfel', 'With die')} ${m.die}'),
                ),
            ],
          ),
        );
      }
      if (move != null) await action(() => game.move(move!));
    } else if (game.state.legalMoves.any((m) => m.from == p)) {
      setState(() => selected = selected == p ? null : p);
    }
  }

  Widget button(String label, VoidCallback? callback, {Key? key}) =>
      OutlinedButton(key: key, onPressed: callback, child: Text(label));
  Future<void> details() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF351914),
      builder: (c) => Theme(
        data: salonTheme(c),
        child: SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(c).height * .8,
            child: AnimatedBuilder(
              animation: game,
              builder: (c, _) => StatefulBuilder(
                builder: (c, update) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      t('Salon · Partieübersicht', 'Salon · Game details'),
                      style: Theme.of(c).textTheme.titleLarge,
                    ),
                    for (var i = 0; i < 2; i++)
                      Text(
                        '${game.state.names[i]}: ${game.state.off[i]} ${t('ausgespielt', 'borne off')} · Bar ${game.state.bar[i]} · ${pipCount(game.state, i)} Pips',
                      ),
                    Text(
                      t(
                        'Hell: 24 → 1 → Ausspielen · Dunkel: 1 → 24 → Ausspielen',
                        'Light: 24 → 1 → bear off · Dark: 1 → 24 → bear off',
                      ),
                    ),
                    _nativeMoves(update),
                    for (var p = 1; p <= 24; p++)
                      Text(
                        '${point(p)}: ${game.state.points[p - 1].abs()} ${game.state.points[p - 1] >= 0 ? t('helle Steine', 'light checkers') : t('dunkle Steine', 'dark checkers')}',
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text(t('Schließen', 'Close')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nativeMoves([StateSetter? update]) {
    final s = game.state, legal = s.legalMoves;
    final source = s.bar[s.activePlayerIndex] > 0 ? 0 : selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t('Zugliste', 'Move list')),
        if (s.bar[s.activePlayerIndex] > 0)
          Text(
            t(
              'Zuerst ${s.bar[s.activePlayerIndex]} Steine von der Bar einsetzen',
              'First re-enter ${s.bar[s.activePlayerIndex]} checkers from the bar',
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in legal.map((m) => m.from).toSet())
              button(
                '${point(p)}${source == p ? ' ✓' : ''}',
                locked
                    ? null
                    : () {
                        setState(() => selected = selected == p ? null : p);
                        update?.call(() {});
                      },
                key: ValueKey('source-$p'),
              ),
          ],
        ),
        if (source != null)
          for (final m in legal.where((m) => m.from == source))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: button(
                '${point(m.from)} → ${point(m.to)} · ${t('Würfel', 'Die')} ${m.die}',
                locked
                    ? null
                    : () async {
                        await action(() => game.move(m));
                        update?.call(() {});
                      },
                key: ValueKey('move-${m.from}-${m.to}-${m.die}'),
              ),
            ),
        if (s.dice.length == 2) _consumption(s),
      ],
    );
  }

  String result(BackgammonGameState s) => switch (s.winType) {
    BackgammonWinType.normal => t(
      'Normaler Sieg · 1 Punkt',
      'Normal win · 1 point',
    ),
    BackgammonWinType.gammon => t('Gammon · 2 Punkte', 'Gammon · 2 points'),
    _ => t('Backgammon · 3 Punkte', 'Backgammon · 3 points'),
  };
  Widget _status(BackgammonGameState s) => Semantics(
    liveRegion: true,
    child: Text(
      game.needsSaveRetry
          ? t('⚠ Stand nicht gesichert', '⚠ Position not saved')
          : game.isBusy
          ? t('Wird gespeichert …', 'Saving …')
          : s.isComplete
          ? '${s.names[s.winnerIndex!]} · ${t('Gewonnen', 'Won')}'
          : s.opening
          ? (s.dice.isNotEmpty
                ? t(
                    'Gleichstand – beide würfeln noch einmal',
                    'Tie — both roll again',
                  )
                : t('Eröffnungswurf', 'Opening roll'))
          : '${s.names[s.activePlayerIndex]} · ${t('Am Zug', 'To move')}',
      maxLines: MediaQuery.textScalerOf(context).scale(16) >= 24 ? null : 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: salonIvory,
        backgroundColor: salonWood,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  Widget _primary(BackgammonGameState s) => FilledButton(
    key: const ValueKey('primary-action'),
    onPressed: game.isBusy
        ? null
        : game.needsSaveRetry
        ? () => action(game.retrySave)
        : s.isComplete
        ? leave
        : s.canRoll
        ? (s.mode == GameMode.digital
              ? () => action(game.rollDigital)
              : manualRoll)
        : s.canEndTurn
        ? () => action(game.endTurn)
        : null,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: salonWood,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(2),
          child: SalonSymbol(s.canRoll ? 'roll' : 'emblem', size: 22),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            game.needsSaveRetry
                ? t('Erneut speichern', 'Retry save')
                : s.isComplete
                ? t('Zur Startseite', 'Home')
                : s.canRoll
                ? (s.mode == GameMode.digital
                      ? t(
                          s.opening ? 'Eröffnungswurf würfeln' : 'Würfeln',
                          s.opening ? 'Roll opening dice' : 'Roll dice',
                        )
                      : t('Wurf eingeben', 'Enter roll'))
                : t('Zug abschließen', 'End turn'),
          ),
        ),
      ],
    ),
  );
  Widget _tools() => Row(
    children: [
      Expanded(child: button(t('Zugliste', 'Move list'), details)),
      const SizedBox(width: 8),
      IconButton(
        tooltip: t('Letzten Zug zurücknehmen', 'Undo last move'),
        onPressed: !locked && game.canUndo ? () => action(game.undo) : null,
        icon: const SalonSymbol('undo'),
      ),
      IconButton(
        tooltip: t('Bedienansicht wechseln', 'Switch accessible view'),
        onPressed: () {
          if (MediaQuery.textScalerOf(context).scale(16) >= 24 ||
              MediaQuery.of(context).accessibleNavigation) {
            details();
          } else {
            setState(() => listPrimary = !(listPrimary ?? false));
          }
        },
        icon: const Icon(Icons.accessibility_new),
      ),
    ],
  );
  Widget _tray(BackgammonGameState s) => Row(
    children: [
      const SalonSymbol('emblem', size: 42),
      const SizedBox(width: 8),
      for (var i = 0; i < 2; i++)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IvoryDie(s.dice.length > i ? s.dice[i] : null),
        ),
      Expanded(
        child: Text(
          s.opening
              ? t('Ein Würfel\npro Person', 'One die\nper player')
              : s.dice.isEmpty
              ? t('Noch kein Wurf', 'No roll yet')
              : '${s.remaining.length} ${t('Züge offen', 'moves left')}',
          style: const TextStyle(fontSize: 12, color: salonIvory),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: salonTheme(context),
    child: Builder(
      builder: (context) => AnimatedBuilder(
        animation: game,
        builder: (context, _) {
          final s = game.state;
          final native =
              listPrimary == true ||
              MediaQuery.textScalerOf(context).scale(16) >= 24 ||
              MediaQuery.of(context).accessibleNavigation;
          final source =
              s.bar[s.activePlayerIndex] > 0 && s.legalMoves.isNotEmpty
              ? 0
              : selected;
          return PopScope(
            canPop: allowPop || (!game.needsSaveRetry && !game.isBusy),
            onPopInvokedWithResult: (popped, _) {
              if (!popped) leave();
            },
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
              },
              child: Actions(
                actions: {
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (_) {
                      setState(() => selected = null);
                      return null;
                    },
                  ),
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'Backgammon',
                      style: TextStyle(fontFamily: 'serif', letterSpacing: 1.5),
                    ),
                    leading: IconButton(
                      tooltip: t('Partie pausieren', 'Pause game'),
                      onPressed: leave,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    actions: [
                      IconButton(
                        tooltip: t('Regeln', 'Rules'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const BackgammonRulesScreen(),
                          ),
                        ),
                        icon: const SalonSymbol('rules'),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    child: SalonSurface(
                      child: LayoutBuilder(
                        builder: (context, bounds) {
                          final controls = Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _status(s),
                              if (s.isComplete && !locked) Text(result(s)),
                              const SizedBox(height: 8),
                              _tray(s),
                              const SizedBox(height: 8),
                              _primary(s),
                              _tools(),
                            ],
                          );
                          if (native) {
                            return ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                controls,
                                _nativeMoves(),
                                if (message != null && !game.needsSaveRetry)
                                  Text(message!),
                                Text(
                                  t(
                                    'Hell: 24 → 1 · Dunkel: 1 → 24',
                                    'Light: 24 → 1 · Dark: 1 → 24',
                                  ),
                                ),
                              ],
                            );
                          }
                          final board = LayoutBuilder(
                            builder: (context, b) => Center(
                              child: BackgammonBoard(
                                state: s,
                                selected: source,
                                onPoint: locked || s.isComplete ? null : choose,
                                width: b.maxWidth,
                                height: b.maxHeight,
                              ),
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: bounds.maxWidth > bounds.maxHeight
                                ? Row(
                                    children: [
                                      Expanded(child: board),
                                      const SizedBox(width: 12),
                                      SizedBox(width: 250, child: controls),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _status(s),
                                      Row(
                                        children: [
                                          for (var i = 0; i < 2; i++)
                                            Expanded(
                                              child: Text(
                                                '${i == 0 ? '○' : '●'} ${s.names[i]}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: salonIvory,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (s.isComplete && !locked)
                                        Text(
                                          result(s),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      const SizedBox(height: 8),
                                      Expanded(child: board),
                                      const SizedBox(height: 8),
                                      _tray(s),
                                      const SizedBox(height: 10),
                                      _primary(s),
                                      _tools(),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  Widget _consumption(BackgammonGameState s) {
    final pool = s.dice[0] == s.dice[1] ? List.filled(4, s.dice[0]) : s.dice;
    final remaining = List<int>.of(s.remaining);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pool.length == 4)
          Text(
            t(
              'Pasch – vier Züge mit ${pool.first}',
              'Doubles — four moves of ${pool.first}',
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            for (final d in pool)
              Chip(
                label: Text(
                  '$d · ${remaining.remove(d) ? t('offen', 'available') : t('verwendet ✓', 'used ✓')}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

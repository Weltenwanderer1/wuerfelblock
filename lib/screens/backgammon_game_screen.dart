import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/backgammon_controller.dart';
import '../models/backgammon_models.dart';
import '../models/game_models.dart';
import '../widgets/backgammon_board.dart';
import 'backgammon_rules_screen.dart';

class BackgammonGameScreen extends StatefulWidget {
  const BackgammonGameScreen({super.key, required this.game});
  final BackgammonController game;
  @override
  State<BackgammonGameScreen> createState() => _BackgammonGameScreenState();
}

class _BackgammonGameScreenState extends State<BackgammonGameScreen> {
  int? selected;
  bool? listPrimary;
  bool allowPop = false;
  String? message;
  bool boardPositioned = false;
  late final boardScroll = ScrollController(
    onAttach: (position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && position.hasContentDimensions && !boardPositioned) {
          position.jumpTo(position.maxScrollExtent);
          boardPositioned = true;
        }
      });
    },
  );
  BackgammonController get game => widget.game;
  String t(String de, String en) => bgText(context, de, en);
  bool get locked => game.isBusy || game.needsSaveRetry;
  @override
  void dispose() {
    boardScroll.dispose();
    super.dispose();
  }

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
        setState(() {
          message = t('Aktion fehlgeschlagen.', 'Action failed.');
        });
      }
    }
  }

  Future<void> leave() async {
    if (game.isBusy) return;
    if (game.needsSaveRetry) {
      final exit = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
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
    final values = await showDialog<List<int>>(
      context: context,
      builder: (c) => StatefulBuilder(
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
                                  ? Theme.of(c).colorScheme.primaryContainer
                                  : null,
                            ),
                            onPressed: () => update(() {
                              if (group == 0) {
                                first = n;
                              } else {
                                second = n;
                              }
                            }),
                            child: Text('$n'),
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
    final currentSource = game.state.bar[game.state.activePlayerIndex] > 0
        ? 0
        : selected;
    final moves = game.state.legalMoves
        .where((m) => m.from == currentSource && m.to == p)
        .toList();
    if (moves.isNotEmpty) {
      BackgammonMove? move = moves.first;
      if (moves.length > 1) {
        move = await showDialog<BackgammonMove>(
          context: context,
          builder: (c) => SimpleDialog(
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
      setState(() {
        selected = selected == p ? null : p;
      });
    }
  }

  Widget button(String label, VoidCallback? callback, {Key? key}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
      ),
      onPressed: callback,
      child: Text(label),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: game,
    builder: (context, _) {
      final s = game.state;
      final legal = s.legalMoves;
      final source = s.bar[s.activePlayerIndex] > 0 && legal.isNotEmpty
          ? 0
          : selected;
      final primary =
          listPrimary ??
          (MediaQuery.textScalerOf(context).scale(16) >= 24 ||
              MediaQuery.of(context).accessibleNavigation);
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
                title: const Text('Backgammon'),
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
                    icon: const Icon(Icons.help_outline),
                  ),
                ],
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        t(
                          'Einzelpartie ohne Verdopplung',
                          'Single game without doubling',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (s.isComplete && !locked) ...[
                        Text(
                          '${s.names[s.winnerIndex!]} · ${t('Gewonnen', 'Won')}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          s.winType == BackgammonWinType.normal
                              ? t(
                                  'Normaler Sieg · 1 Punkt',
                                  'Normal win · 1 point',
                                )
                              : s.winType == BackgammonWinType.gammon
                              ? t('Gammon · 2 Punkte', 'Gammon · 2 points')
                              : t(
                                  'Backgammon · 3 Punkte',
                                  'Backgammon · 3 points',
                                ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          s.winType == BackgammonWinType.normal
                              ? t(
                                  'Die andere Person hat bereits Steine ausgespielt.',
                                  'The other player has already borne off checkers.',
                                )
                              : s.winType == BackgammonWinType.gammon
                              ? t(
                                  'Die andere Person hat keinen Stein ausgespielt.',
                                  'The other player has borne off no checkers.',
                                )
                              : t(
                                  'Kein Stein ausgespielt und noch Steine auf der Bar oder im Heimfeld des Siegers.',
                                  'No checkers borne off, and checkers remain on the bar or in the winner’s home board.',
                                ),
                        ),
                      ] else ...[
                        for (var i = 0; i < 2; i++)
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: !s.opening && s.activePlayerIndex == i
                                  ? BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                '${i == 0 ? '○' : '●'} ${s.names[i]} · ${i == 0 ? t('Hell', 'Light') : t('Dunkel', 'Dark')}${!s.opening && s.activePlayerIndex == i ? ' · ${t('Am Zug', 'To move')}' : ''}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        Text(
                          t(
                            s.opening ? 'Eröffnungswurf' : 'Wurf',
                            s.opening ? 'Opening roll' : 'Roll',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (s.opening && s.dice.isNotEmpty)
                          Text(
                            t(
                              'Gleichstand – beide würfeln noch einmal',
                              'Tie — both roll again',
                            ),
                          ),
                        if (s.dice.isEmpty)
                          Text(t('Noch kein Wurf', 'No roll yet'))
                        else ...[
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final d in s.dice)
                                Chip(label: Text('${t('Würfel', 'Die')} $d')),
                            ],
                          ),
                          if (!s.opening) _consumption(s),
                        ],
                        if (s.canRoll)
                          FilledButton(
                            onPressed: locked
                                ? null
                                : s.mode == GameMode.digital
                                ? () => action(game.rollDigital)
                                : manualRoll,
                            child: Text(
                              s.mode == GameMode.digital
                                  ? t(
                                      s.opening
                                          ? 'Eröffnungswurf würfeln'
                                          : 'Würfeln',
                                      s.opening
                                          ? 'Roll opening dice'
                                          : 'Roll dice',
                                    )
                                  : t('Wurf eingeben', 'Enter roll'),
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      if (game.isBusy)
                        Semantics(
                          liveRegion: true,
                          child: Text(t('Wird gespeichert …', 'Saving …')),
                        ),
                      if (game.needsSaveRetry)
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    '⚠ ${t('Speichern fehlgeschlagen. Dieser Stand ist noch nicht gesichert.', 'Save failed. This position has not been saved yet.')}',
                                  ),
                                ),
                                button(
                                  t('Erneut speichern', 'Retry save'),
                                  game.isBusy
                                      ? null
                                      : () => action(game.retrySave),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (message != null && !game.needsSaveRetry)
                        Semantics(liveRegion: true, child: Text(message!)),
                      Wrap(
                        spacing: 8,
                        children: [
                          button(
                            t('Brett', 'Board'),
                            () => setState(() => listPrimary = false),
                          ),
                          button(
                            t('Zugliste', 'Move list'),
                            () => setState(() => listPrimary = true),
                          ),
                        ],
                      ),
                      if (!primary) ...[
                        Text(
                          t(
                            'Brett seitlich verschieben · Im Querformat siehst du mehr.',
                            'Scroll board sideways · Landscape shows more.',
                          ),
                        ),
                        Scrollbar(
                          controller: boardScroll,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: boardScroll,
                            scrollDirection: Axis.horizontal,
                            child: BackgammonBoard(
                              state: s,
                              selected: source,
                              onPoint: locked || s.isComplete ? null : choose,
                              width: math.max(720, constraints.maxWidth - 32),
                              height: constraints.maxHeight < 400 ? 288 : 400,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            button(
                              t('Links', 'Left'),
                              () => boardScroll.animateTo(
                                0,
                                duration:
                                    MediaQuery.of(context).disableAnimations
                                    ? Duration.zero
                                    : const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                              ),
                            ),
                            button(
                              t('Rechts', 'Right'),
                              () => boardScroll.animateTo(
                                boardScroll.position.maxScrollExtent,
                                duration:
                                    MediaQuery.of(context).disableAnimations
                                    ? Duration.zero
                                    : const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                              ),
                            ),
                          ],
                        ),
                      ],
                      Text(
                        t(
                          'Hell: 24 → 1 → Ausspielen · Dunkel: 1 → 24 → Ausspielen',
                          'Light: 24 → 1 → bear off · Dark: 1 → 24 → bear off',
                        ),
                      ),
                      for (var i = 0; i < 2; i++)
                        Text(
                          '${s.names[i]}: ${s.off[i]} ${t('ausgespielt', 'borne off')} · Bar ${s.bar[i]} · ${t('Noch', 'Remaining')} ${pipCount(s, i)} ${t('Augen bis zum Ausspielen', 'pips to bear off')}',
                        ),
                      if (!s.isComplete) ...[
                        Text(
                          t('Zugliste', 'Move list'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (s.bar[s.activePlayerIndex] > 0)
                          Text(
                            t(
                              'Zuerst ${s.bar[s.activePlayerIndex]} Steine von der Bar einsetzen',
                              'First re-enter ${s.bar[s.activePlayerIndex]} checkers from the bar',
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final p in legal.map((m) => m.from).toSet())
                              button(
                                '${point(p)}${source == p ? ' ✓' : ''}',
                                locked
                                    ? null
                                    : () => setState(
                                        () =>
                                            selected = selected == p ? null : p,
                                      ),
                                key: ValueKey('source-$p'),
                              ),
                          ],
                        ),
                        if (source != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${point(source)} · ${t('Ziel auswählen', 'Choose destination')}',
                            ),
                          ),
                          for (final m in legal.where((m) => m.from == source))
                            button(
                              '${point(m.from)} → ${point(m.to)} · ${t('Würfel', 'Die')} ${m.die}${m.to < 25 && s.points[m.to - 1] * (s.activePlayerIndex == 0 ? 1 : -1) == -1 ? ' · ${t('schlagen', 'hit')}' : ''}',
                              locked ? null : () => action(() => game.move(m)),
                              key: ValueKey('move-${m.from}-${m.to}-${m.die}'),
                            ),
                          button(
                            t('Auswahl aufheben', 'Clear selection'),
                            () => setState(() => selected = null),
                          ),
                        ],
                        if (s.canEndTurn)
                          Text(
                            t(
                              'Keine weiteren legalen Züge. ${s.remaining.length} Würfel nicht spielbar.',
                              'No further legal moves. ${s.remaining.length} dice cannot be played.',
                            ),
                          ),
                        button(
                          t('Letzten Zug zurücknehmen', 'Undo last move'),
                          game.canUndo ? () => action(game.undo) : null,
                        ),
                        FilledButton(
                          onPressed: !locked && s.canEndTurn
                              ? () => action(game.endTurn)
                              : null,
                          child: Text(t('Zug abschließen', 'End turn')),
                        ),
                      ],
                      ExpansionTile(
                        title: Text(
                          t(
                            'Vollständige Brettübersicht',
                            'Full board overview',
                          ),
                        ),
                        children: [
                          for (var p = 1; p <= 24; p++)
                            ListTile(
                              title: Text(
                                '${point(p)}: ${s.points[p - 1].abs()} ${s.points[p - 1] >= 0 ? t('helle Steine', 'light checkers') : t('dunkle Steine', 'dark checkers')}',
                              ),
                            ),
                        ],
                      ),
                      if (s.isComplete)
                        FilledButton(
                          onPressed: locked ? null : leave,
                          child: Text(t('Zur Startseite', 'Home')),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
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

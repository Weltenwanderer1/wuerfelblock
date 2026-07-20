import 'package:flutter/material.dart';

import '../controllers/qwixx_controller.dart';
import '../models/game_models.dart';
import '../models/qwixx_models.dart';
import '../services/qwixx_orientation.dart';
import 'qwixx_result_screen.dart';
import 'qwixx_rules_screen.dart';

class QwixxGameScreen extends StatefulWidget {
  const QwixxGameScreen({required this.game, super.key});
  final QwixxController game;

  @override
  State<QwixxGameScreen> createState() => _QwixxGameScreenState();
}

class _QwixxGameScreenState extends State<QwixxGameScreen> {
  int displayedPlayerIndex = 0;

  QwixxController get game => widget.game;

  @override
  void initState() {
    super.initState();
    displayedPlayerIndex = game.state.activePlayerIndex;
    game.addListener(_changed);
    QwixxOrientation.acquire();
  }

  @override
  void dispose() {
    game.removeListener(_changed);
    QwixxOrientation.release();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted && game.state.isComplete) {
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(builder: (_) => QwixxResultScreen(game: game)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speichern fehlgeschlagen')),
        );
      }
    }
  }

  List<QwixxDigitalAction> _digitalActions(QwixxColor color, int value) => [
    for (final action in QwixxDigitalAction.values)
      if (game.state.canMarkDigital(displayedPlayerIndex, color, value, action))
        action,
  ];

  Future<void> _confirmMark(QwixxColor color, int value) async {
    final state = game.state;
    if (state.mode == GameMode.digital) {
      final actions = _digitalActions(color, value);
      if (actions.isEmpty) return;
      final action = actions.length == 1
          ? actions.single
          : await showDialog<QwixxDigitalAction>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Welche Würfelaktion?'),
                content: Text(
                  '$value passt sowohl zur weißen Summe als auch zu Weiß + ${color.label}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        Navigator.pop(context, QwixxDigitalAction.white),
                    child: const Text('Weiße Summe'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, QwixxDigitalAction.color),
                    child: const Text('Weiß + Farbe'),
                  ),
                ],
              ),
            );
      if (action != null && mounted) {
        await _run(
          () => game.markDigital(
            color,
            value,
            action,
            playerIndex: displayedPlayerIndex,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feld ankreuzen?'),
        content: Text(
          '${color.label} $value für ${state.players[displayedPlayerIndex].name}. Übersprungene Zahlen bleiben danach gesperrt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ankreuzen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        () => game.mark(color, value, playerIndex: displayedPlayerIndex),
      );
    }
  }

  Future<void> _confirmMiss() async {
    final active = game.state.activePlayer.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fehlwurf eintragen?'),
        content: Text(
          'Der Fehlwurf zählt für die aktive Person $active (−5 Punkte).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fehlwurf eintragen'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _run(game.markMiss);
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partie beenden?'),
        content: const Text('Der gespeicherte Spielstand wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Partie beenden'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await game.abandon();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speichern fehlgeschlagen')),
          );
        }
        return;
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (displayedPlayerIndex >= state.players.length) {
      displayedPlayerIndex = state.activePlayerIndex;
    }
    final player = state.players[displayedPlayerIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EC),
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text('Qwixx · Aktiv: ${state.activePlayer.name}'),
        actions: [
          IconButton(
            tooltip: 'Qwixx-Regeln',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const QwixxRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: 'Letzte Änderung rückgängig',
            onPressed:
                game.canUndo && !game.isBusy && !game.needsDigitalSaveRetry
                ? () => _run(game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _abandon(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'abandon', child: Text('Partie beenden')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1,
          maxScaleFactor: 1.15,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 176,
                  child: _ControlPanel(
                    game: game,
                    displayedPlayerIndex: displayedPlayerIndex,
                    onSelectPlayer: (index) =>
                        setState(() => displayedPlayerIndex = index),
                    onRun: _run,
                    onMiss: _confirmMiss,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 34,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Block von ${player.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _CompactMisses(player: player),
                            const SizedBox(width: 8),
                            Text(
                              'Gesamt ${player.total}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final color in QwixxColor.values)
                        Expanded(
                          child: _QwixxRow(
                            color: color,
                            player: player,
                            globallyClosed: state.closedColors.contains(color),
                            pendingSharedClosure: state.pendingClosedColors
                                .contains(color),
                            canMark: (value) => state.mode == GameMode.digital
                                ? !game.needsDigitalSaveRetry &&
                                      _digitalActions(color, value).isNotEmpty
                                : state.canMark(
                                    displayedPlayerIndex,
                                    color,
                                    value,
                                  ),
                            onMark: (value) => _confirmMark(color, value),
                          ),
                        ),
                      SizedBox(
                        height: 34,
                        child: _ScoreSummary(player: player),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.game,
    required this.displayedPlayerIndex,
    required this.onSelectPlayer,
    required this.onRun,
    required this.onMiss,
  });

  final QwixxController game;
  final int displayedPlayerIndex;
  final ValueChanged<int> onSelectPlayer;
  final Future<void> Function(Future<void> Function()) onRun;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aktiv: ${state.activePlayer.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            DropdownButtonFormField<int>(
              key: const Key('display-player-picker'),
              initialValue: displayedPlayerIndex,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Block anzeigen',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: [
                for (var index = 0; index < state.players.length; index++)
                  DropdownMenuItem<int>(
                    key: Key('display-player-$index'),
                    value: index,
                    child: Text(
                      state.players[index].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: game.isBusy
                  ? null
                  : (index) {
                      if (index != null) onSelectPlayer(index);
                    },
            ),
            const Spacer(),
            if (state.mode == GameMode.digital)
              _DigitalDicePanel(game: game, onRun: onRun)
            else ...[
              FilledButton.icon(
                key: const Key('next-player'),
                onPressed: game.isBusy ? null : () => onRun(game.nextPlayer),
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Nächste Person'),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const Key('mark-miss'),
                onPressed: game.isBusy ? null : onMiss,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Fehlwurf'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DigitalDicePanel extends StatelessWidget {
  const _DigitalDicePanel({required this.game, required this.onRun});

  final QwixxController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (game.needsDigitalSaveRetry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Wurf noch nicht gespeichert',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          FilledButton.icon(
            key: const Key('qwixx-retry-save'),
            onPressed: game.isBusy ? null : () => onRun(game.retryDigitalSave),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Speichern'),
          ),
        ],
      );
    }
    if (!state.hasRolled) {
      return FilledButton.icon(
        key: const Key('qwixx-roll'),
        onPressed: game.isBusy ? null : () => onRun(game.rollDigital),
        icon: const Icon(Icons.casino, size: 18),
        label: const Text('Würfeln'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var index = 0; index < state.dice.length; index++)
              _QwixxDie(
                key: Key('qwixx-die-$index'),
                value: state.dice[index],
                color: index < 2 ? null : QwixxColor.values[index - 2],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Weiß: ${state.whiteSum}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          key: const Key('qwixx-finish-turn'),
          onPressed: game.isBusy ? null : () => onRun(game.finishDigitalTurn),
          icon: const Icon(Icons.skip_next, size: 18),
          label: const Text('Zug beenden'),
        ),
      ],
    );
  }
}

class _QwixxDie extends StatelessWidget {
  const _QwixxDie({required this.value, required this.color, super.key});

  final int value;
  final QwixxColor? color;

  Color get background => switch (color) {
    QwixxColor.red => const Color(0xFFD72C2C),
    QwixxColor.yellow => const Color(0xFFF2B705),
    QwixxColor.green => const Color(0xFF168447),
    QwixxColor.blue => const Color(0xFF1967C9),
    null => Colors.white,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${color?.label ?? "Weiß"}er Würfel: $value',
    child: Container(
      width: 46,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: color == null || color == QwixxColor.yellow
              ? Colors.black
              : Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _QwixxRow extends StatelessWidget {
  const _QwixxRow({
    required this.color,
    required this.player,
    required this.globallyClosed,
    required this.pendingSharedClosure,
    required this.canMark,
    required this.onMark,
  });

  final QwixxColor color;
  final QwixxPlayer player;
  final bool globallyClosed;
  final bool pendingSharedClosure;
  final bool Function(int value) canMark;
  final ValueChanged<int> onMark;

  Color get bandColor => switch (color) {
    QwixxColor.red => const Color(0xFFD72C2C),
    QwixxColor.yellow => const Color(0xFFF2B705),
    QwixxColor.green => const Color(0xFF168447),
    QwixxColor.blue => const Color(0xFF1967C9),
  };

  String get lockStatus => globallyClosed
      ? 'geschlossen'
      : pendingSharedClosure
      ? 'Schließung ausstehend'
      : 'offen';

  IconData get lockIcon => globallyClosed
      ? Icons.lock
      : pendingSharedClosure
      ? Icons.hourglass_top
      : Icons.lock_outline;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: bandColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 34,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              color.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color == QwixxColor.yellow ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        for (final value in color.numbers)
          Expanded(
            child: _NumberCell(
              key: Key('qwixx-${color.name}-$value'),
              color: color,
              value: value,
              crossed: player.crossed[color]!.contains(value),
              enabled: canMark(value),
              onTap: () => onMark(value),
            ),
          ),
        Semantics(
          label: '${color.label} Schloss: $lockStatus',
          excludeSemantics: true,
          child: SizedBox(
            width: 38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(lockIcon, color: Colors.white, size: 17),
                if (globallyClosed || pendingSharedClosure)
                  FittedBox(
                    child: Text(
                      globallyClosed ? 'geschlossen' : 'ausstehend',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.color,
    required this.value,
    required this.crossed,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final QwixxColor color;
  final int value;
  final bool crossed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled,
    enabled: enabled,
    label:
        '${color.label} $value: ${crossed
            ? "angekreuzt"
            : enabled
            ? "verfügbar"
            : "nicht verfügbar"}',
    child: Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Material(
        color: crossed
            ? const Color(0xFFE7E7E7)
            : enabled
            ? Colors.white
            : const Color(0xFFCBCBCB),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              crossed ? '×' : '$value',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CompactMisses extends StatelessWidget {
  const _CompactMisses({required this.player});
  final QwixxPlayer player;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Text('Fehl: ', style: TextStyle(fontWeight: FontWeight.w700)),
      for (var index = 0; index < 4; index++)
        Semantics(
          label:
              'Fehlwurf ${index + 1}: ${index < player.misses ? "markiert" : "frei"}',
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D5D5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              index < player.misses ? '×' : '',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
    ],
  );
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.player});
  final QwixxPlayer player;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final color in QwixxColor.values)
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${color.label}: ${player.rowScore(color)}'),
          ),
        ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Fehl: ${player.missPenalty}'),
        ),
      ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Gesamt: ${player.total}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/colordice_controller.dart';
import '../models/game_models.dart';
import '../models/colordice_models.dart';
import '../services/persistence_messages.dart';
import '../services/colordice_orientation.dart';
import 'colordice_result_screen.dart';
import 'colordice_rules_screen.dart';

class ColordiceGameScreen extends StatefulWidget {
  const ColordiceGameScreen({required this.game, super.key});
  final ColordiceController game;

  @override
  State<ColordiceGameScreen> createState() => _ColordiceGameScreenState();
}

class _ColordiceGameScreenState extends State<ColordiceGameScreen> {
  int displayedPlayerIndex = 0;

  ColordiceController get game => widget.game;

  @override
  void initState() {
    super.initState();
    displayedPlayerIndex = game.state.activePlayerIndex;
    game.addListener(_changed);
    ColordiceOrientation.acquire();
  }

  @override
  void dispose() {
    game.removeListener(_changed);
    ColordiceOrientation.release();
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
          MaterialPageRoute(builder: (_) => ColordiceResultScreen(game: game)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText(PersistenceMessages.saveFailed),
          ),
        );
      }
    }
  }

  List<ColordiceDigitalAction> _digitalActions(
    ColordiceColor color,
    int value,
  ) => [
    for (final action in ColordiceDigitalAction.values)
      if (game.state.canMarkDigital(displayedPlayerIndex, color, value, action))
        action,
  ];

  Future<void> _confirmMark(ColordiceColor color, int value) async {
    final state = game.state;
    if (state.mode == GameMode.digital) {
      final actions = _digitalActions(color, value);
      if (actions.isEmpty) return;
      final action = actions.length == 1
          ? actions.single
          : await showDialog<ColordiceDigitalAction>(
              context: context,
              builder: (context) => AlertDialog(
                title: const LocalizedText('Welche Würfelaktion?'),
                content: LocalizedText(
                  '$value passt sowohl zur weißen Summe als auch zu Weiß + ${color.label}.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const LocalizedText('Abbrechen'),
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        Navigator.pop(context, ColordiceDigitalAction.white),
                    child: const LocalizedText('Weiße Summe'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, ColordiceDigitalAction.color),
                    child: const LocalizedText('Weiß + Farbe'),
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
        title: const LocalizedText('Feld ankreuzen?'),
        content: LocalizedText(
          '${color.label} $value für ${state.players[displayedPlayerIndex].name}. Übersprungene Zahlen bleiben danach gesperrt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Ankreuzen'),
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
        title: const LocalizedText('Fehlwurf eintragen?'),
        content: Text(
          '${localizeText(context, 'Der Fehlwurf zählt für die aktive Person')} '
          '$active ${localizeText(context, '(−5 Punkte).')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Fehlwurf eintragen'),
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
        title: const LocalizedText('Partie beenden?'),
        content: const LocalizedText(
          'Der gespeicherte Spielstand wird gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Partie beenden'),
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
            const SnackBar(
              content: LocalizedText(PersistenceMessages.saveFailed),
            ),
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
        title: LocalizedText('Colordice · Aktiv: ${state.activePlayer.name}'),
        actions: [
          IconButton(
            tooltip: localizeText(context, 'Colordice-Regeln'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const ColordiceRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: localizeText(context, 'Letzte Änderung rückgängig'),
            onPressed:
                game.canUndo && !game.isBusy && !game.needsDigitalSaveRetry
                ? () => _run(game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => _abandon(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'abandon',
                child: LocalizedText('Partie beenden'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _ColordiceTextScaleLayout(
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
                              child: LocalizedText(
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
                            LocalizedText(
                              'Gesamt ${player.total}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final color in ColordiceColor.values)
                        Expanded(
                          child: _ColordiceRow(
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

class _ColordiceTextScaleLayout extends StatelessWidget {
  const _ColordiceTextScaleLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const referenceFontSize = 16.0;
      final scaledFontSize = MediaQuery.textScalerOf(
        context,
      ).scale(referenceFontSize);
      if (scaledFontSize <= referenceFontSize) return child;
      return SingleChildScrollView(
        key: const Key('colordice-game-scroll'),
        child: SizedBox(
          height: constraints.maxHeight * scaledFontSize / referenceFontSize,
          child: child,
        ),
      );
    },
  );
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.game,
    required this.displayedPlayerIndex,
    required this.onSelectPlayer,
    required this.onRun,
    required this.onMiss,
  });

  final ColordiceController game;
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
            LocalizedText(
              'Aktiv: ${state.activePlayer.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            DropdownButtonFormField<int>(
              key: const Key('display-player-picker'),
              initialValue: displayedPlayerIndex,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: localizeText(context, 'Block anzeigen'),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
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
                label: const LocalizedText('Nächste Person'),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                key: const Key('mark-miss'),
                onPressed: game.isBusy ? null : onMiss,
                icon: const Icon(Icons.close, size: 18),
                label: const LocalizedText('Fehlwurf'),
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

  final ColordiceController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (game.needsDigitalSaveRetry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LocalizedText(
            'Wurf noch nicht gespeichert',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          FilledButton.icon(
            key: const Key('colordice-retry-save'),
            onPressed: game.isBusy ? null : () => onRun(game.retryDigitalSave),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const LocalizedText('Speichern'),
          ),
        ],
      );
    }
    if (!state.hasRolled) {
      return FilledButton.icon(
        key: const Key('colordice-roll'),
        onPressed: game.isBusy ? null : () => onRun(game.rollDigital),
        icon: const Icon(Icons.casino, size: 18),
        label: const LocalizedText('Würfeln'),
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
              _ColordiceDie(
                key: Key('colordice-die-$index'),
                value: state.dice[index],
                color: index < 2 ? null : ColordiceColor.values[index - 2],
              ),
          ],
        ),
        const SizedBox(height: 4),
        LocalizedText(
          'Weiß: ${state.whiteSum}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        FilledButton.icon(
          key: const Key('colordice-finish-turn'),
          onPressed: game.isBusy ? null : () => onRun(game.finishDigitalTurn),
          icon: const Icon(Icons.skip_next, size: 18),
          label: const LocalizedText('Zug beenden'),
        ),
      ],
    );
  }
}

class _ColordiceDie extends StatelessWidget {
  const _ColordiceDie({required this.value, required this.color, super.key});

  final int value;
  final ColordiceColor? color;

  Color get background => switch (color) {
    ColordiceColor.red => const Color(0xFFD72C2C),
    ColordiceColor.yellow => const Color(0xFFF2B705),
    ColordiceColor.green => const Color(0xFF168447),
    ColordiceColor.blue => const Color(0xFF1967C9),
    null => Colors.white,
  };

  @override
  Widget build(BuildContext context) {
    final colorName = localizeText(context, color?.label ?? 'Weiß');
    return Semantics(
      label:
          '$colorName ${localizeText(context, 'Würfel').toLowerCase()}: $value',
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
            color: color == null || color == ColordiceColor.yellow
                ? Colors.black
                : Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ColordiceRow extends StatelessWidget {
  const _ColordiceRow({
    required this.color,
    required this.player,
    required this.globallyClosed,
    required this.pendingSharedClosure,
    required this.canMark,
    required this.onMark,
  });

  final ColordiceColor color;
  final ColordicePlayer player;
  final bool globallyClosed;
  final bool pendingSharedClosure;
  final bool Function(int value) canMark;
  final ValueChanged<int> onMark;

  Color get bandColor => switch (color) {
    ColordiceColor.red => const Color(0xFFD72C2C),
    ColordiceColor.yellow => const Color(0xFFF2B705),
    ColordiceColor.green => const Color(0xFF168447),
    ColordiceColor.blue => const Color(0xFF1967C9),
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
            child: LocalizedText(
              color.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color == ColordiceColor.yellow
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        for (final value in color.numbers)
          Expanded(
            child: _NumberCell(
              key: Key('colordice-${color.name}-$value'),
              color: color,
              value: value,
              crossed: player.crossed[color]!.contains(value),
              enabled: canMark(value),
              onTap: () => onMark(value),
            ),
          ),
        Semantics(
          label: localizeText(context, '${color.label} Schloss: $lockStatus'),
          excludeSemantics: true,
          child: SizedBox(
            width: 38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(lockIcon, color: Colors.white, size: 17),
                if (globallyClosed || pendingSharedClosure)
                  FittedBox(
                    child: LocalizedText(
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

  final ColordiceColor color;
  final int value;
  final bool crossed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorName = localizeText(context, color.label);
    final status = localizeText(
      context,
      crossed
          ? 'angekreuzt'
          : enabled
          ? 'verfügbar'
          : 'nicht verfügbar',
    );
    return Semantics(
      button: enabled,
      enabled: enabled,
      excludeSemantics: true,
      label: '$colorName $value: $status',
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
              child: LocalizedText(
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
}

class _CompactMisses extends StatelessWidget {
  const _CompactMisses({required this.player});
  final ColordicePlayer player;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const LocalizedText(
        'Fehl: ',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      for (var index = 0; index < 4; index++)
        Semantics(
          label:
              '${localizeText(context, 'Fehlwurf')} ${index + 1}: '
              '${localizeText(context, index < player.misses ? 'markiert' : 'frei')}',
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD5D5D5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LocalizedText(
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
  final ColordicePlayer player;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final color in ColordiceColor.values)
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: LocalizedText('${color.label}: ${player.rowScore(color)}'),
          ),
        ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: LocalizedText('Fehl: ${player.missPenalty}'),
        ),
      ),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: LocalizedText(
            'Gesamt: ${player.total}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    ],
  );
}

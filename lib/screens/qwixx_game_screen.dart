import 'package:flutter/material.dart';

import '../controllers/qwixx_controller.dart';
import '../models/qwixx_models.dart';
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
  }

  @override
  void dispose() {
    game.removeListener(_changed);
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

  Future<void> _confirmMark(QwixxColor color, int value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feld ankreuzen?'),
        content: Text(
          '${color.label} $value für ${game.state.players[displayedPlayerIndex].name}. Übersprungene Zahlen bleiben danach gesperrt.',
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
    final player = state.players[displayedPlayerIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EC),
      appBar: AppBar(
        title: const Text('Qwixx-Block'),
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
            onPressed: game.canUndo && !game.isBusy
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Aktiv: ${state.activePlayer.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('next-player'),
                    onPressed: game.isBusy ? null : () => _run(game.nextPlayer),
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Nächste Person'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Angezeigten Block wählen (alle dürfen gleichzeitig eintragen):',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (var index = 0; index < state.players.length; index++)
                ChoiceChip(
                  key: Key('display-player-$index'),
                  label: Text(state.players[index].name),
                  selected: displayedPlayerIndex == index,
                  onSelected: (_) =>
                      setState(() => displayedPlayerIndex = index),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Block von ${player.name}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _Misses(player: player),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            key: const Key('mark-miss'),
            onPressed: game.isBusy ? null : _confirmMiss,
            icon: const Icon(Icons.close),
            label: Text('Fehlwurf für ${state.activePlayer.name}'),
          ),
          const SizedBox(height: 10),
          for (final color in QwixxColor.values)
            _QwixxRow(
              color: color,
              player: player,
              globallyClosed: state.closedColors.contains(color),
              pendingSharedClosure: state.pendingClosedColors.contains(color),
              canMark: (value) =>
                  state.canMark(displayedPlayerIndex, color, value),
              onMark: (value) => _confirmMark(color, value),
            ),
          const SizedBox(height: 12),
          _ScoreSummary(player: player),
        ],
      ),
    );
  }
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

  String get lockText => pendingSharedClosure ? 'ausstehend' : lockStatus;

  IconData get lockIcon => globallyClosed
      ? Icons.lock
      : pendingSharedClosure
      ? Icons.hourglass_top
      : Icons.lock_outline;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: bandColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              color.label,
              style: TextStyle(
                color: color == QwixxColor.yellow ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final value in color.numbers)
            _NumberCell(
              key: Key('qwixx-${color.name}-$value'),
              color: color,
              value: value,
              crossed: player.crossed[color]!.contains(value),
              enabled: canMark(value),
              onTap: () => onMark(value),
            ),
          Semantics(
            label: '${color.label} Schloss: $lockStatus',
            excludeSemantics: true,
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(lockIcon, color: bandColor, size: 22),
                  Text(
                    lockText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    child: SizedBox(
      width: 54,
      height: 52,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Material(
          color: crossed
              ? const Color(0xFFE7E7E7)
              : enabled
              ? Colors.white
              : const Color(0xFFCBCBCB),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                crossed ? '×' : '$value',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Misses extends StatelessWidget {
  const _Misses({required this.player});
  final QwixxPlayer player;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Fehlwürfe', style: TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Row(
        children: [
          for (var index = 0; index < 4; index++)
            Semantics(
              label:
                  'Fehlwurf ${index + 1}: ${index < player.misses ? "markiert" : "frei"}',
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.all(3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D5D5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  index < player.misses ? '×' : '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({required this.player});
  final QwixxPlayer player;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 18,
        runSpacing: 6,
        children: [
          for (final color in QwixxColor.values)
            Text('${color.label}: ${player.rowScore(color)}'),
          Text('Fehlwürfe: ${player.missPenalty}'),
          Text(
            'Gesamt: ${player.total}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}

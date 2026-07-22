import 'package:flutter/material.dart';

import '../controllers/escalero_controller.dart';
import 'escalero_rules_screen.dart';

class EscaleroResultScreen extends StatefulWidget {
  const EscaleroResultScreen({required this.game, super.key});
  final EscaleroController game;
  @override
  State<EscaleroResultScreen> createState() => _EscaleroResultScreenState();
}

class _EscaleroResultScreenState extends State<EscaleroResultScreen> {
  bool busy = false;
  String? error;
  Future<void> _finish() async {
    setState(() => busy = true);
    try {
      await widget.game.abandon();
      if (mounted) Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Partie konnte nicht beendet werden.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.state;
    final ranking = state.ranking;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E8),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Escalero · Ergebnis'),
          actions: [
            IconButton(
              key: const Key('escalero-result-rules'),
              tooltip: 'Escalero-Regeln',
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const EscaleroRulesScreen()),
              ),
              icon: const Icon(Icons.menu_book_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            children: [
              Card(
                color: const Color(0xFFFFE0A8),
                child: ListTile(
                  leading: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFF8A4B08),
                  ),
                  title: Text(
                    'Gewonnen: ${state.winners.map((p) => p.name).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Abrechnung ausschließlich nach den Spielpunkten.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < ranking.length; index++)
                _PlayerResult(
                  itemIndex: index,
                  rank:
                      1 +
                      ranking.where((player) {
                        final playerIndex = state.players.indexOf(player);
                        final currentIndex = state.players.indexOf(
                          ranking[index],
                        );
                        return state.gamePointsFor(playerIndex) >
                            state.gamePointsFor(currentIndex);
                      }).length,
                  name: ranking[index].name,
                  columns: [
                    for (var c = 0; c < 3; c++) ranking[index].columnTotal(c),
                  ],
                  raw: ranking[index].rawTotal,
                  gamePoints: state.gamePointsFor(
                    state.players.indexOf(ranking[index]),
                  ),
                ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Kolonnenwert: 1 · 2 · 4 Spielpunkte. Pro Kolonne kassiert die Person mit der höchsten Summe den Kolonnenwert von jedem Gegner. Ein Gewinn aller drei Kolonnen bringt zusätzlich 2 Punkte pro Gegner. Bei Gleichstand an der Spitze erhält niemand Punkte.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton.icon(
                key: const Key('escalero-finish'),
                onPressed: busy ? null : _finish,
                icon: const Icon(Icons.home),
                label: const Text('Zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerResult extends StatelessWidget {
  const _PlayerResult({
    required this.itemIndex,
    required this.rank,
    required this.name,
    required this.columns,
    required this.raw,
    required this.gamePoints,
  });
  final int itemIndex;
  final int rank;
  final String name;
  final List<int> columns;
  final int raw;
  final int gamePoints;
  @override
  Widget build(BuildContext context) => Card(
    key: Key('escalero-result-player-$itemIndex'),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF5B2A1D),
                foregroundColor: Colors.white,
                child: Text('$rank'),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                '${gamePoints >= 0 ? '+' : ''}$gamePoints SP',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF8A4B08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < 3; i++)
                Text(
                  'K${i + 1}: ${columns[i]}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              Text(
                'Roh: $raw',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

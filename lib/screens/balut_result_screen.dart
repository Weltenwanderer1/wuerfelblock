import 'package:flutter/material.dart';

import '../controllers/balut_controller.dart';
import '../models/balut_models.dart';
import 'balut_rules_screen.dart';

const _balutPaper = Color(0xFFFFF3D6);
const _balutInk = Color(0xFF2D2923);
const _balutAccent = Color(0xFF166534);

class BalutResultScreen extends StatefulWidget {
  const BalutResultScreen({required this.game, super.key});
  final BalutController game;

  @override
  State<BalutResultScreen> createState() => _BalutResultScreenState();
}

class _BalutResultScreenState extends State<BalutResultScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _close() async {
    if (_busy) return;
    _busy = true;
    setState(() {});
    try {
      await widget.game.abandon();
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Partie konnte nicht beendet werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.state;
    final winners = state.winners;
    final sorted = [...state.players]
      ..sort(
        (a, b) => (b.rawTotal + b.incentivePoints).compareTo(
          a.rawTotal + a.incentivePoints,
        ),
      );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E8),
        appBar: AppBar(
          title: const Text('Balut · Ergebnis'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              key: const Key('balut-result-rules'),
              tooltip: 'Balut-Regeln',
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const BalutRulesScreen()),
              ),
              icon: const Icon(Icons.menu_book_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                color: const Color(0xFFE7F6E7),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: _balutAccent),
                  title: Text(
                    'Sieger: ${winners.map((player) => player.name).join(', ')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _balutInk,
                    ),
                  ),
                  subtitle: Text(
                    '28 Wertungen pro Person · Gesamtpunkte aus Roh- und Incentive-Punkten.',
                    style: const TextStyle(color: _balutInk),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final player in sorted) _ResultRow(player: player),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                key: const Key('balut-finish'),
                onPressed: _busy ? null : _close,
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.player});
  final BalutPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _balutPaper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD2B98C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                color: _balutInk,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Roh ${player.rawTotal}'),
              Text('Bonus ${player.incentivePoints}'),
            ],
          ),
          const SizedBox(width: 14),
          Text(
            '${player.rawTotal + player.incentivePoints}',
            style: const TextStyle(
              color: _balutAccent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

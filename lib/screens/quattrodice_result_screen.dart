import 'package:flutter/material.dart';
import '../controllers/quattrodice_controller.dart';
import '../l10n/localized_text.dart';

class QuattroResultScreen extends StatelessWidget {
  const QuattroResultScreen({required this.game, super.key});
  final QuattroController game;
  @override
  Widget build(BuildContext context) {
    final st = game.state;
    final sorted = List.of(st.players)
      ..sort((a, b) => b.total.compareTo(a.total));
    final best = sorted.first.total;
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('QuattroDice · Ergebnis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in sorted)
            Card(
              color: p.total == best ? Colors.green.shade50 : null,
              child: ListTile(
                title: Text(
                  '${p.name}  ${p.total} Pkt',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Gekreist ${p.circledSum} + Brücken ${p.bridgePoints} + Lila ${p.lilaExtra}  –  Schraffiert ${p.shadedCount}×10 – Joker ${p.jokerSum}\nBrücken: ${p.bridges.join(", ")}',
                ),
                trailing: p.total == best
                    ? const Icon(Icons.emoji_events, color: Colors.amber)
                    : null,
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await game.abandon();
              if (context.mounted) {
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            },
            child: const LocalizedText('Fertig · Zurück zum Start'),
          ),
        ],
      ),
    );
  }
}

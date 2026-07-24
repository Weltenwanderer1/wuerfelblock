import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/colordice_controller.dart';
import '../models/colordice_models.dart';
import '../services/persistence_messages.dart';
import '../services/colordice_orientation.dart';
import 'colordice_game_screen.dart';

class ColordiceResultScreen extends StatefulWidget {
  const ColordiceResultScreen({required this.game, super.key});
  final ColordiceController game;

  @override
  State<ColordiceResultScreen> createState() => _ColordiceResultScreenState();
}

class _ColordiceResultScreenState extends State<ColordiceResultScreen> {
  ColordiceController get game => widget.game;

  @override
  void initState() {
    super.initState();
    ColordiceOrientation.acquire();
  }

  @override
  void dispose() {
    ColordiceOrientation.release();
    super.dispose();
  }

  Future<void> _undo() async {
    try {
      await game.undo();
      if (mounted) {
        await Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(builder: (_) => ColordiceGameScreen(game: game)),
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

  Future<void> _finish() async {
    try {
      await game.abandon();
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    final winners = game.winners;
    final title = winners.length == 1
        ? '${winners.single.name} gewinnt!'
        : 'Gleichstand: ${winners.map((player) => player.name).join(', ')}';
    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const LocalizedText('Colordice-Ergebnis'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.emoji_events, size: 72, color: Color(0xFFF2B705)),
            LocalizedText(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            for (final player in [
              ...game.state.players,
            ]..sort((a, b) => b.total.compareTo(a.total)))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        children: [
                          for (final color in ColordiceColor.values)
                            LocalizedText(
                              '${color.label}: ${player.rowScore(color)}',
                            ),
                          LocalizedText('Fehlwürfe: ${player.missPenalty}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const LocalizedText(
                            'Gesamt',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          LocalizedText(
                            '${player.total}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: game.canUndo ? _undo : null,
              icon: const Icon(Icons.undo),
              label: const LocalizedText('Letzte Änderung rückgängig'),
            ),
            FilledButton(
              onPressed: _finish,
              child: const LocalizedText('Zur Startseite'),
            ),
          ],
        ),
      ),
    );
  }
}

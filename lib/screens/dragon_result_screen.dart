import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';
import '../controllers/dragon_controller.dart';
import '../models/dragon_models.dart';

const _paper = Color(0xFFFFF8E8);
const _ink = Color(0xFF2D2923);
const _gold = Color(0xFFB8860B);

class DragonResultScreen extends StatefulWidget {
  const DragonResultScreen({required this.game, super.key});
  final DragonController game;

  @override
  State<DragonResultScreen> createState() => _DragonResultScreenState();
}

class _DragonResultScreenState extends State<DragonResultScreen> {
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
    final ranking = state.ranking;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(
          title: const LocalizedText('Drachengold · Ergebnis'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                color: const Color(0xFFFDF6E3),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: _gold),
                  title: LocalizedText(
                    'Sieger: ${state.winners.map((p) => p.name).join(', ')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                  subtitle: state.bonusWinnerIndex != null
                      ? LocalizedText(
                          'Drachenbonus (+20 🪙): '
                          '${state.players[state.bonusWinnerIndex!].name}',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              for (final player in ranking)
                _ResultRow(
                  player: player,
                  isBonusWinner: state.bonusWinnerIndex != null &&
                      state.players[state.bonusWinnerIndex!] == player,
                ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                LocalizedText(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                key: const Key('dragon-finish'),
                onPressed: _busy ? null : _close,
                icon: const Icon(Icons.home),
                label: const LocalizedText('Zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.player, required this.isBonusWinner});
  final DragonPlayer player;
  final bool isBonusWinner;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF6E3),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD2B98C)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              LocalizedText('🐉 ${player.tamedCount} Drachen gezähmt'),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LocalizedText('Gold ${player.gold}'),
            if (player.bonusGold > 0)
              LocalizedText('Bonus +${player.bonusGold}'),
          ],
        ),
        const SizedBox(width: 14),
        LocalizedText(
          '${player.totalGold}',
          style: const TextStyle(
            color: _gold,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

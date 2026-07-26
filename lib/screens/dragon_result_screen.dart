import 'package:flutter/material.dart';

import '../controllers/dragon_controller.dart';
import '../l10n/localized_text.dart';
import '../models/dragon_models.dart';
import 'schuppenschatz_rules_screen.dart';

const _page = Color(0xFFF7F1E5);
const _ink = Color(0xFF241C2B);
const _muted = Color(0xFF766C78);
const _gold = Color(0xFFC98915);
const _deepGold = Color(0xFF7A4B00);
const _panel = Color(0xFFFFFBF3);

class DragonResultScreen extends StatefulWidget {
  const DragonResultScreen({required this.game, super.key});
  final DragonController game;

  @override
  State<DragonResultScreen> createState() => _DragonResultScreenState();
}

class _DragonResultScreenState extends State<DragonResultScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _openRules() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => const SchuppenschatzRulesScreen()),
  );

  Future<void> _close() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.game.abandon();
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } catch (_) {
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
        backgroundColor: _page,
        appBar: AppBar(
          title: const LocalizedText('Schuppenschatz · Ergebnis'),
          automaticallyImplyLeading: false,
          backgroundColor: _page,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              key: const Key('dragon-result-rules'),
              tooltip: localizeText(context, 'Spielregeln'),
              onPressed: _openRules,
              icon: const Icon(Icons.menu_book_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _WinnerSummary(state: state),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: LocalizedText(
                  'Rangliste',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < ranking.length; i++)
                _ResultRow(
                  key: Key('dragon-result-row-$i'),
                  rank: i + 1,
                  player: ranking[i],
                  isBonusWinner:
                      state.bonusWinnerIndex != null &&
                      state.players[state.bonusWinnerIndex!] == ranking[i],
                  isWinner: state.winners.contains(ranking[i]),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE1DE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB84C43)),
                  ),
                  child: LocalizedText(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF8A2F29),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('dragon-finish'),
                onPressed: _busy ? null : _close,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.home_rounded),
                label: const LocalizedText('Zur Startseite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerSummary extends StatelessWidget {
  const _WinnerSummary({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) {
    final winnerNames = state.winners.map((player) => player.name).join(', ');
    final bonusWinner = state.bonusWinnerIndex == null
        ? null
        : state.players[state.bonusWinnerIndex!].name;
    return Container(
      key: const Key('dragon-result-summary'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2133), Color(0xFF5D3D52)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD77B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: _deepGold,
              size: 38,
            ),
          ),
          const SizedBox(height: 10),
          const LocalizedText(
            'Schatzmeister',
            style: TextStyle(
              color: Color(0xFFD9CCD8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            winnerNames,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (bonusWinner != null)
            Text(
              '$bonusWinner ${localizeText(context, 'erhält 20 Bonusgold für die meisten Drachen.')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD77B),
                fontWeight: FontWeight.w800,
              ),
            )
          else
            const LocalizedText(
              'Gleichstand bei den Drachen: Das Bonusgold bleibt liegen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD9CCD8)),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.rank,
    required this.player,
    required this.isBonusWinner,
    required this.isWinner,
    super.key,
  });
  final int rank;
  final DragonPlayer player;
  final bool isBonusWinner;
  final bool isWinner;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isWinner ? const Color(0xFFFFE7B3) : _panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isWinner ? _gold : const Color(0xFFE3D7C4)),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isWinner ? _gold : const Color(0xFFEAE0E9),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: isWinner ? Colors.white : _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              LocalizedText(
                _scoreLine(player, isBonusWinner),
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${player.totalGold}',
              style: const TextStyle(
                color: _deepGold,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const LocalizedText(
              'Gesamt',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
      ],
    ),
  );
}

String _scoreLine(DragonPlayer player, bool isBonusWinner) {
  if (player.tamedCount == 1) {
    return isBonusWinner
        ? '1 Drache · ${player.gold} Gold · +20 Bonus'
        : '1 Drache · ${player.gold} Gold';
  }
  return isBonusWinner
      ? '${player.tamedCount} Drachen · ${player.gold} Gold · +20 Bonus'
      : '${player.tamedCount} Drachen · ${player.gold} Gold';
}

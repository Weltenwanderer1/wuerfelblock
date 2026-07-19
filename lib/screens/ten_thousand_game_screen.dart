import 'package:flutter/material.dart';

import '../controllers/ten_thousand_controller.dart';
import '../widgets/ten_thousand_score_sheet.dart';
import 'ten_thousand_result_screen.dart';
import 'ten_thousand_rules_screen.dart';

class TenThousandGameScreen extends StatefulWidget {
  const TenThousandGameScreen({required this.game, super.key});

  final TenThousandController game;

  @override
  State<TenThousandGameScreen> createState() => _TenThousandGameScreenState();
}

class _TenThousandGameScreenState extends State<TenThousandGameScreen> {
  TenThousandController get game => widget.game;

  @override
  void initState() {
    super.initState();
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

  void _showSaveError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Speichern fehlgeschlagen')));
  }

  Future<void> _afterOperation() async {
    if (!mounted || !game.state.isComplete) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(builder: (_) => TenThousandResultScreen(game: game)),
    );
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      await _afterOperation();
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  Future<void> _enterPoints() async {
    final player = game.state.activePlayer;
    if (player == null) return;
    final points = await showTenThousandPointsDialog(
      context,
      playerName: player.name,
    );
    if (points != null && mounted) await _run(() => game.enterTurn(points));
  }

  Future<void> _enterBust() async {
    final player = game.state.activePlayer;
    if (player == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fehlwurf (0) eintragen?'),
        content: Text(
          'Für ${player.name} werden 0 Punkte eingetragen. Der Zug geht danach an die nächste Person.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-bust'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Fehlwurf eintragen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _run(() => game.enterTurn(0));
  }

  Future<void> _editTurn(int ordinal) async {
    final turn = game.state.turns[ordinal];
    final owner =
        game.state.players[game.state.playerIndexForTurn(ordinal)].name;
    final points = await showTenThousandPointsDialog(
      context,
      playerName: owner,
      initialPoints: turn.points,
      restoring: turn.isDeleted,
    );
    if (points == null || !mounted) return;
    await _correct(
      operation: (confirm) =>
          game.editTurn(ordinal, points, confirmTruncation: confirm),
    );
  }

  Future<void> _deleteTurn(int ordinal) async {
    final confirmed = await confirmTenThousandDeletion(
      context,
      turnNumber: ordinal + 1,
    );
    if (!confirmed || !mounted) return;
    await _correct(
      operation: (confirm) =>
          game.deleteTurn(ordinal, confirmTruncation: confirm),
    );
  }

  Future<void> _correct({
    required Future<void> Function(bool confirmTruncation) operation,
  }) async {
    try {
      await operation(false);
      await _afterOperation();
    } on TenThousandCorrectionImpact catch (impact) {
      if (!mounted) return;
      final confirmed = await confirmTenThousandTruncation(
        context,
        count: impact.illegalTrailingTurnCount,
      );
      if (!confirmed || !mounted) return;
      try {
        await operation(true);
        await _afterOperation();
      } catch (_) {
        if (mounted) _showSaveError();
      }
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partie beenden?'),
        content: const Text('Der gespeicherte 10.000-Block wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-abandon'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Partie beenden'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await game.abandon();
    } catch (_) {
      if (mounted) _showSaveError();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final active = state.activePlayer;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: const Text('10.000-Block'),
        actions: [
          IconButton(
            tooltip: '10.000-Regeln',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const TenThousandRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: 'Letzte Änderung rückgängig',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: game.canUndo && !game.isBusy
                ? () => _run(game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            key: const Key('abandon-game'),
            tooltip: 'Partie beenden',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: game.isBusy ? null : _abandon,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (active != null)
            Semantics(
              label: 'Aktive Person: ${active.name}',
              container: true,
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tenThousandAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JETZT AM ZUG',
                            style: TextStyle(
                              color: tenThousandAccentSoft,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            active.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          _RoundBanner(game: game),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Punkte für aktive Person eintragen',
                  child: FilledButton.icon(
                    key: const Key('enter-points'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: tenThousandAccent,
                    ),
                    onPressed: game.isBusy ? null : _enterPoints,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Punkte'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Fehlwurf mit 0 Punkten eintragen',
                  child: OutlinedButton.icon(
                    key: const Key('bust-turn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: tenThousandAccent,
                      side: const BorderSide(
                        color: tenThousandAccent,
                        width: 2,
                      ),
                    ),
                    onPressed: game.isBusy ? null : _enterBust,
                    icon: const Icon(Icons.block),
                    label: const Text('Fehlwurf (0)'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TenThousandScoreSheet(
            state: state,
            onEdit: game.isBusy ? (_) {} : _editTurn,
            onDelete: game.isBusy ? (_) {} : _deleteTurn,
          ),
        ],
      ),
    );
  }
}

class _RoundBanner extends StatelessWidget {
  const _RoundBanner({required this.game});

  final TenThousandController game;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (state.isInFinalRound) {
      final names = state.finalRoundRemainingPlayerIndices
          .map((index) => state.players[index].name)
          .join(', ');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tenThousandAccentSoft,
          border: Border.all(color: tenThousandAccent, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Letzte Runde',
              style: TextStyle(
                color: tenThousandAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text('Noch am Zug: $names'),
          ],
        ),
      );
    }
    return const Row(
      children: [
        Icon(Icons.flag_outlined, size: 20, color: tenThousandAccent),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Normale Runde · ab 10.000 beginnt die letzte Runde.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

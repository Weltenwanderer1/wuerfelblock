import 'package:flutter/material.dart';

import '../controllers/ten_thousand_controller.dart';
import '../models/game_models.dart';
import '../services/persistence_messages.dart';
import '../widgets/ten_thousand_score_sheet.dart';
import 'ten_thousand_digital_game_screen.dart';
import 'ten_thousand_game_screen.dart';

class TenThousandResultScreen extends StatefulWidget {
  const TenThousandResultScreen({required this.game, super.key});

  final TenThousandController game;

  @override
  State<TenThousandResultScreen> createState() =>
      _TenThousandResultScreenState();
}

class _TenThousandResultScreenState extends State<TenThousandResultScreen> {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(PersistenceMessages.saveFailed)),
    );
  }

  Future<void> _routeIfReopened() async {
    if (!mounted || game.state.isComplete) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => game.state.mode == GameMode.digital
            ? TenThousandDigitalGameScreen(game: game)
            : TenThousandGameScreen(game: game),
      ),
    );
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
      await _routeIfReopened();
    } on TenThousandCorrectionImpact catch (impact) {
      if (!mounted) return;
      final confirmed = await confirmTenThousandTruncation(
        context,
        count: impact.illegalTrailingTurnCount,
      );
      if (!confirmed || !mounted) return;
      try {
        await operation(true);
        await _routeIfReopened();
      } catch (_) {
        if (mounted) _showSaveError();
      }
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  Future<void> _undo() async {
    try {
      await game.undo();
      await _routeIfReopened();
    } catch (_) {
      if (mounted) _showSaveError();
    }
  }

  Future<void> _finish() async {
    try {
      await game.abandon();
    } catch (_) {
      if (mounted) _showSaveError();
      return;
    }
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final winners = game.winners;
    final title = winners.length == 1
        ? '${winners.single.name} gewinnt!'
        : 'Gleichstand: ${winners.map((player) => player.name).join(', ')}';
    final ranking = List<int>.generate(state.players.length, (index) => index)
      ..sort((a, b) {
        final byScore = state.totals[b].compareTo(state.totals[a]);
        return byScore != 0 ? byScore : a.compareTo(b);
      });

    return PopScope<void>(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E8),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('10.000-Ergebnis'),
        ),
        body: CustomScrollView(
          key: const Key('ten-thousand-result-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: const Icon(
                            Icons.emoji_events,
                            size: 70,
                            color: tenThousandAccent,
                          ),
                        ),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: tenThousandInk,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Endstand',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tenThousandAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: tenThousandPaper,
                            border: Border.all(color: tenThousandInk, width: 2),
                          ),
                          child: Column(
                            children: [
                              for (var rank = 0; rank < ranking.length; rank++)
                                _RankRow(
                                  key: Key('result-rank-$rank'),
                                  rank: rank + 1,
                                  name: state.players[ranking[rank]].name,
                                  total: state.totals[ranking[rank]],
                                  winner: state.winnerIndices.contains(
                                    ranking[rank],
                                  ),
                                  last: rank == ranking.length - 1,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  TenThousandScoreSheet(
                    state: state,
                    showSummary: false,
                    onEdit: game.isBusy ? (_) {} : _editTurn,
                    onDelete: game.isBusy ? (_) {} : _deleteTurn,
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('undo-result'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: tenThousandAccent,
                          ),
                          onPressed: game.canUndo && !game.isBusy
                              ? _undo
                              : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Letzte Änderung rückgängig'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('finish-result'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: tenThousandAccent,
                          ),
                          onPressed: game.isBusy ? null : _finish,
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Zur Startseite'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.name,
    required this.total,
    required this.winner,
    required this.last,
    super.key,
  });

  final int rank;
  final String name;
  final int total;
  final bool winner;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 60),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: winner ? tenThousandAccentSoft.withValues(alpha: 0.65) : null,
      border: last
          ? null
          : const Border(bottom: BorderSide(color: tenThousandInk, width: 1)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '$rank.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (winner) ...[
          const Icon(Icons.emoji_events, size: 19, color: tenThousandAccent),
          const SizedBox(width: 6),
        ],
        Text(
          '$total',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/ten_thousand_controller.dart';
import '../models/ten_thousand_rules.dart';
import '../services/persistence_messages.dart';
import '../widgets/die_widget.dart';
import '../widgets/ten_thousand_score_sheet.dart';
import 'ten_thousand_result_screen.dart';
import 'ten_thousand_rules_screen.dart';

class TenThousandDigitalGameScreen extends StatefulWidget {
  const TenThousandDigitalGameScreen({required this.game, super.key});

  final TenThousandController game;

  @override
  State<TenThousandDigitalGameScreen> createState() =>
      _TenThousandDigitalGameScreenState();
}

class _TenThousandDigitalGameScreenState
    extends State<TenThousandDigitalGameScreen> {
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

  void _error() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: LocalizedText(PersistenceMessages.saveFailed)),
    );
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      await _routeIfComplete();
    } catch (_) {
      if (mounted) _error();
    }
  }

  Future<void> _routeIfComplete() async {
    if (!mounted || !game.state.isComplete) return;
    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(builder: (_) => TenThousandResultScreen(game: game)),
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
      (confirm) => game.editTurn(ordinal, points, confirmTruncation: confirm),
    );
  }

  Future<void> _deleteTurn(int ordinal) async {
    final confirmed = await confirmTenThousandDeletion(
      context,
      turnNumber: ordinal + 1,
    );
    if (!confirmed || !mounted) return;
    await _correct(
      (confirm) => game.deleteTurn(ordinal, confirmTruncation: confirm),
    );
  }

  Future<void> _correct(
    Future<void> Function(bool confirmTruncation) operation,
  ) async {
    try {
      await operation(false);
      await _routeIfComplete();
    } on TenThousandCorrectionImpact catch (impact) {
      if (!mounted) return;
      final confirmed = await confirmTenThousandTruncation(
        context,
        count: impact.illegalTrailingTurnCount,
      );
      if (!confirmed || !mounted) return;
      try {
        await operation(true);
        await _routeIfComplete();
      } catch (_) {
        if (mounted) _error();
      }
    } catch (_) {
      if (mounted) _error();
    }
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Partie beenden?'),
        content: const LocalizedText(
          'Der gespeicherte 10.000-Spielstand wird gelöscht.',
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
    if (confirmed != true || !mounted) return;
    try {
      await game.abandon();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final turn = state.digitalTurn!;
    final active = state.activePlayer;
    final blocked = game.isBusy || game.needsDigitalSaveRetry;
    final historyBlocked = blocked || !turn.isFresh;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: const LocalizedText('10.000 · Digital'),
        actions: [
          IconButton(
            tooltip: localizeText(context, '10.000-Regeln'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const TenThousandRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: localizeText(context, 'Letzte Runde rückgängig'),
            onPressed: game.canUndo && !blocked ? () => _run(game.undo) : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: localizeText(context, 'Partie beenden'),
            onPressed: game.isBusy ? null : _abandon,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: CustomScrollView(
        key: const Key('ten-thousand-digital-game-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (game.needsDigitalSaveRetry) ...[
                        Card(
                          color: const Color(0xFFFFD6A5),
                          child: ListTile(
                            leading: const Icon(Icons.save_outlined),
                            title: const LocalizedText(
                              'Würfelstand noch nicht gespeichert',
                            ),
                            subtitle: const LocalizedText(
                              'Der Wurf bleibt stehen. Erst speichern, dann weiterspielen.',
                            ),
                            trailing: FilledButton(
                              key: const Key('tenk-retry-save'),
                              onPressed: game.isBusy
                                  ? null
                                  : () => _run(game.retryDigitalSave),
                              child: const LocalizedText('Erneut'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: LocalizedText(
                              active == null
                                  ? 'Partie beendet'
                                  : '${active.name} ist am Zug',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tenThousandAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: LocalizedText(
                              '${turn.roundPoints} Punkte',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.isInFinalRound) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: const Color(0xFFFFE1B8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: LocalizedText(
                              'Letzte Runde · Noch dran: ${state.finalRoundRemainingPlayerIndices.map((index) => state.players[index].name).join(', ')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (turn.mustRoll)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LocalizedText(
                            'Alle 6 Würfel gewertet – der Bestätigungswurf ist Pflicht.',
                            style: TextStyle(
                              color: tenThousandAccent,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (turn.hasRolled)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (
                              var index = 0;
                              index < turn.dice.length;
                              index++
                            )
                              DieWidget(
                                key: Key('tenk-die-$index'),
                                value: turn.dice[index],
                                held: turn.selected[index],
                                selectedSemantic: 'zur Wertung ausgewählt',
                                unselectedSemantic:
                                    'nicht zur Wertung ausgewählt',
                                index: 100 + index,
                                onTap: !blocked
                                    ? () => _run(
                                        () => game.toggleDigitalDie(index),
                                      )
                                    : null,
                              ),
                          ],
                        )
                      else
                        LocalizedText(
                          '${turn.activeDiceCount} Würfel bereit',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 10),
                      if (!turn.hasRolled)
                        FilledButton.icon(
                          key: const Key('tenk-roll'),
                          onPressed: blocked
                              ? null
                              : () => _run(game.rollDigital),
                          icon: const Icon(Icons.casino),
                          label: LocalizedText(
                            turn.activeDiceCount == 6
                                ? 'Mit 6 Würfeln würfeln'
                                : 'Mit ${turn.activeDiceCount} Würfeln weiterwürfeln',
                          ),
                        )
                      else if (turn.isMacke)
                        FilledButton.icon(
                          key: const Key('tenk-confirm-macke'),
                          onPressed: blocked
                              ? null
                              : () => _run(game.confirmDigitalMacke),
                          icon: const Icon(Icons.block),
                          label: const LocalizedText(
                            'Macke bestätigen · Runde 0',
                          ),
                        )
                      else ...[
                        LocalizedText(
                          turn.selectedValues.isEmpty
                              ? 'Tippe alle Würfel an, die du werten möchtest.'
                              : turn.selectedScore == null
                              ? 'Diese Auswahl ist keine gültige Kombination.'
                              : 'Auswahl: ${turn.selectedScore} Punkte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                turn.selectedValues.isNotEmpty &&
                                    turn.selectedScore == null
                                ? Colors.redAccent
                                : tenThousandInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FilledButton.tonalIcon(
                          key: const Key('tenk-bank'),
                          onPressed: turn.canBank && !blocked
                              ? () => _run(game.bankDigitalSelection)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const LocalizedText('Auswahl werten'),
                        ),
                      ],
                      if (turn.canSecure) ...[
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('tenk-secure'),
                          style: FilledButton.styleFrom(
                            backgroundColor: tenThousandAccent,
                          ),
                          onPressed: blocked
                              ? null
                              : () => _run(game.secureDigitalTurn),
                          icon: const Icon(Icons.savings_outlined),
                          label: LocalizedText(
                            '${turn.roundPoints} Punkte sichern',
                          ),
                        ),
                      ],
                      if (!turn.isFresh &&
                          turn.roundPoints <
                              TenThousandRules.minimumBankScore &&
                          !turn.isMacke) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('tenk-forfeit'),
                          onPressed: blocked
                              ? null
                              : () => _run(game.forfeitDigitalTurn),
                          icon: const Icon(Icons.skip_next),
                          label: const LocalizedText(
                            'Durchgang beenden · 0 Punkte',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                TenThousandScoreSheet(
                  state: state,
                  onEdit: historyBlocked ? null : _editTurn,
                  onDelete: historyBlocked ? null : _deleteTurn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

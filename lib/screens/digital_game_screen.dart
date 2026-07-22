import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/dice_controller.dart';
import '../controllers/game_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../models/rules_content.dart';
import '../services/persistence_messages.dart';
import '../widgets/die_widget.dart';
import '../widgets/rules_widgets.dart';
import '../widgets/totals_card.dart';
import 'result_screen.dart';

class DigitalGameScreen extends StatefulWidget {
  const DigitalGameScreen({required this.game, super.key});
  final GameController game;
  @override
  State<DigitalGameScreen> createState() => _DigitalGameScreenState();
}

class _DigitalGameScreenState extends State<DigitalGameScreen> {
  late final DiceController dice;
  @override
  void initState() {
    super.initState();
    dice = DiceController(game: widget.game)..addListener(_changed);
    widget.game.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    dice.removeListener(_changed);
    dice.dispose();
    widget.game.removeListener(_changed);
    super.dispose();
  }

  Future<void> _score(ScoreCategory category) async {
    if (widget.game.isBusy) return;
    try {
      await dice.score(category);
    } catch (_) {
      _saveFailed();
      return;
    }
    if (!mounted) return;
    if (widget.game.state.isComplete) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(game: widget.game)),
      );
    }
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Partie verwerfen?'),
        content: const LocalizedText(
          'Der gespeicherte Spielstand wird gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Verwerfen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.game.abandon();
    } catch (_) {
      _saveFailed();
      return;
    }
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _roll() async {
    try {
      await dice.roll();
    } catch (_) {
      _saveFailed();
      return;
    }
    if (!mounted || !dice.isExtraKniffel) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Zusatz-Kniffel!'),
        content: const LocalizedText(
          '+50 Punkte. Wähle ein freies Feld für die Höchstpunktzahl.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const LocalizedText('Feld wählen'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleHold(int index) async {
    try {
      await dice.toggleHold(index);
    } catch (_) {
      _saveFailed();
    }
  }

  Future<void> _undo() async {
    try {
      await dice.undo();
    } catch (_) {
      _saveFailed();
    }
  }

  void _saveFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: LocalizedText(PersistenceMessages.saveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.state;
    final player = state.currentPlayer;
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText(state.ruleSet.label),
        actions: [
          ActiveRulesButton(ruleSet: state.ruleSet),
          IconButton(
            onPressed: widget.game.canUndo && !widget.game.isBusy
                ? _undo
                : null,
            tooltip: localizeText(context, 'Letzten Eintrag rückgängig'),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: widget.game.isBusy ? null : _discard,
            tooltip: localizeText(context, 'Partie verwerfen'),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.plum,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocalizedText(
                          'Am Zug',
                          style: TextStyle(fontSize: 13),
                        ),
                        LocalizedText(
                          player.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  LocalizedText(
                    '${state.totalFor(player)} P.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.plum,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LocalizedText(
              dice.hasRolled
                  ? 'Wurf ${dice.rollCount} von 3'
                  : 'Bereit zum Würfeln',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 9,
              children: [
                for (var index = 0; index < 5; index++)
                  DieWidget(
                    value: dice.dice[index],
                    held: dice.held[index],
                    index: index,
                    onTap: widget.game.isBusy ? null : () => _toggleHold(index),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: dice.canRoll && !widget.game.isBusy ? _roll : null,
              icon: const Icon(Icons.casino),
              label: LocalizedText(
                dice.hasRolled ? 'Noch einmal würfeln' : 'Würfeln',
              ),
            ),
            if (dice.hasRolled) ...[
              const SizedBox(height: 24),
              LocalizedText(
                'Wertung wählen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const LocalizedText(
                'Auch 0 Punkte können zum Streichen gewählt werden.',
              ),
              const SizedBox(height: 10),
              for (final category in state.ruleSet.categories.where(
                (category) => !player.scores.containsKey(category),
              ))
                Card(
                  color: category.isUpper ? AppColors.rose : AppColors.lavender,
                  child: ListTile(
                    minTileHeight: 56,
                    title: Row(
                      children: [
                        Expanded(
                          child: LocalizedText(
                            category.displayLabel(state.ruleSet),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        CategoryInfoButton(
                          ruleSet: state.ruleSet,
                          category: category,
                        ),
                      ],
                    ),
                    trailing: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: LocalizedText(
                        '${dice.suggestion(category)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                    onTap: widget.game.isBusy ? null : () => _score(category),
                  ),
                ),
            ],
            if (player.scores.isNotEmpty) ...[
              const SizedBox(height: 18),
              LocalizedText(
                'Bereits gewertet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in state.ruleSet.categories)
                    if (player.scores[category] case final score?)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LocalizedText(
                              '${category.displayLabel(state.ruleSet)}: $score',
                            ),
                            CategoryInfoButton(
                              ruleSet: state.ruleSet,
                              category: category,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            TotalsCard(state: state),
          ],
        ),
      ),
    );
  }
}

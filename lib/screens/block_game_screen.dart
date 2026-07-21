import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../models/rules_content.dart';
import '../services/persistence_messages.dart';
import '../services/scoring_engine.dart';
import '../widgets/classic_score_sheet.dart';
import '../widgets/rules_widgets.dart';
import 'result_screen.dart';

class BlockGameScreen extends StatefulWidget {
  const BlockGameScreen({required this.game, super.key});
  final GameController game;
  @override
  State<BlockGameScreen> createState() => _BlockGameScreenState();
}

class _BlockGameScreenState extends State<BlockGameScreen> {
  @override
  void initState() {
    super.initState();
    widget.game.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    widget.game.removeListener(_changed);
    super.dispose();
  }

  Future<void> _enter(ScoreCategory category, int playerIndex) async {
    if (widget.game.isBusy) return;
    final result = await showDialog<_ScoreEntryResult>(
      context: context,
      builder: (context) => _ScoreEntryDialog(
        playerName: widget.game.state.players[playerIndex].name,
        category: category,
        ruleSet: widget.game.state.ruleSet,
        allowedScores: ScoringEngine.allowedScores(
          widget.game.state.ruleSet,
          category,
        ),
      ),
    );
    if (result == null) return;
    try {
      await widget.game.enterScore(
        category,
        result.value!,
        playerIndex: playerIndex,
      );
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

  Future<void> _edit(ScoreCategory category, int playerIndex) async {
    if (widget.game.isBusy) return;
    final player = widget.game.state.players[playerIndex];
    final result = await showDialog<_ScoreEntryResult>(
      context: context,
      builder: (context) => _ScoreEntryDialog(
        playerName: player.name,
        category: category,
        ruleSet: widget.game.state.ruleSet,
        allowedScores: ScoringEngine.allowedScores(
          widget.game.state.ruleSet,
          category,
        ),
        initialValue: player.scores[category],
      ),
    );
    if (result == null) return;
    try {
      await widget.game.editBlockScore(
        category,
        result.value,
        playerIndex: playerIndex,
      );
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
        title: const Text('Partie verwerfen?'),
        content: const Text('Der gespeicherte Spielstand wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwerfen'),
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

  Future<void> _undo() async {
    try {
      await widget.game.undo();
    } catch (_) {
      _saveFailed();
    }
  }

  Future<void> _enterExtraKniffel() async {
    if (widget.game.isBusy) return;
    final selection = await showDialog<_ExtraKniffelSelection>(
      context: context,
      builder: (context) => _ExtraKniffelDialog(state: widget.game.state),
    );
    if (selection == null) return;
    try {
      await widget.game.enterBlockExtraKniffelScore(
        selection.category,
        playerIndex: selection.playerIndex,
      );
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

  void _saveFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(PersistenceMessages.saveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.state;
    return Scaffold(
      appBar: AppBar(
        title: Text('${state.ruleSet.label} · Scoreblock'),
        actions: [
          ActiveRulesButton(ruleSet: state.ruleSet),
          IconButton(
            onPressed: widget.game.canUndo && !widget.game.isBusy
                ? _undo
                : null,
            tooltip: 'Letzten Eintrag rückgängig',
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            onPressed: widget.game.isBusy ? null : _discard,
            tooltip: 'Partie verwerfen',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: widget.game.progress,
            minHeight: 7,
            color: AppColors.plum,
            backgroundColor: AppColors.rose,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${state.completedEntries} von ${state.totalEntries} Wertungen',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (state.ruleSet == RuleSet.kniffel)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Semantics(
                button: true,
                label: 'Zusatz-Kniffel im Scoreblock eintragen',
                child: OutlinedButton.icon(
                  key: const Key('block-extra-kniffel'),
                  onPressed: widget.game.isBusy ? null : _enterExtraKniffel,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Zusatz-Kniffel'),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('score-sheet-horizontal-scroll'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: ClassicScoreSheet(
                state: state,
                busy: widget.game.isBusy,
                onEnterScore: _enter,
                onEditScore: _edit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraKniffelSelection {
  const _ExtraKniffelSelection(this.playerIndex, this.category);

  final int playerIndex;
  final ScoreCategory category;
}

class _ExtraKniffelDialog extends StatefulWidget {
  const _ExtraKniffelDialog({required this.state});

  final GameState state;

  @override
  State<_ExtraKniffelDialog> createState() => _ExtraKniffelDialogState();
}

class _ExtraKniffelDialogState extends State<_ExtraKniffelDialog> {
  late final List<int> eligiblePlayers;
  int? playerIndex;
  ScoreCategory? category;

  List<ScoreCategory> get freeCategories => playerIndex == null
      ? const []
      : widget.state.ruleSet.categories
            .where(
              (item) =>
                  !widget.state.players[playerIndex!].scores.containsKey(item),
            )
            .toList();

  @override
  void initState() {
    super.initState();
    eligiblePlayers = [
      for (var index = 0; index < widget.state.players.length; index++)
        if (widget.state.players[index].scores[ScoreCategory.yatzy] == 50 &&
            widget.state.players[index].scores.length <
                widget.state.ruleSet.categories.length)
          index,
    ];
    playerIndex = eligiblePlayers.firstOrNull;
    category = freeCategories.firstOrNull;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Zusatz-Kniffel bestätigen'),
    content: eligiblePlayers.isEmpty
        ? const Text(
            'Kein Spieler hat bereits 50 Punkte im Kniffel-Feld und ein freies Feld.',
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nach ausdrücklicher Bestätigung gibt es +50 Zusatzpunkte und die Höchstpunktzahl im gewählten freien Feld.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const Key('extra-kniffel-player'),
                initialValue: playerIndex,
                decoration: const InputDecoration(labelText: 'Spieler'),
                items: [
                  for (final index in eligiblePlayers)
                    DropdownMenuItem(
                      value: index,
                      child: Text(widget.state.players[index].name),
                    ),
                ],
                onChanged: (value) => setState(() {
                  playerIndex = value;
                  category = freeCategories.firstOrNull;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ScoreCategory>(
                key: const Key('extra-kniffel-category'),
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Freies Feld'),
                items: [
                  for (final item in freeCategories)
                    DropdownMenuItem(
                      value: item,
                      child: Text(
                        '${item.displayLabel(widget.state.ruleSet)} (${item.maxScore(widget.state.ruleSet)})',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => category = value),
              ),
            ],
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: playerIndex != null && category != null
            ? () => Navigator.pop(
                context,
                _ExtraKniffelSelection(playerIndex!, category!),
              )
            : null,
        child: const Text('Eintragen'),
      ),
    ],
  );
}

class _ScoreEntryResult {
  const _ScoreEntryResult(this.value);

  final int? value;
}

class _ScoreEntryDialog extends StatefulWidget {
  const _ScoreEntryDialog({
    required this.playerName,
    required this.category,
    required this.ruleSet,
    required this.allowedScores,
    this.initialValue,
  });

  final String playerName;
  final ScoreCategory category;
  final RuleSet ruleSet;
  final Set<int> allowedScores;
  final int? initialValue;

  @override
  State<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<_ScoreEntryDialog> {
  late final TextEditingController _controller;
  String? _error;

  bool get _isEditing => widget.initialValue != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue?.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || !widget.allowedScores.contains(value)) {
      setState(() => _error = 'Ungültige Punktzahl für diese Kategorie.');
      return;
    }
    Navigator.pop(context, _ScoreEntryResult(value));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(_isEditing ? 'Punkte ändern' : 'Punkte eintragen'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.category.displayLabel(widget.ruleSet)} · ${widget.playerName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Erlaubte Werte: ${(widget.allowedScores.toList()..sort()).join(', ')}',
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('score-input'),
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Punkte',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      if (_isEditing)
        TextButton.icon(
          onPressed: () =>
              Navigator.pop(context, const _ScoreEntryResult(null)),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eintrag löschen'),
        )
      else
        TextButton(
          onPressed: () => Navigator.pop(context, const _ScoreEntryResult(0)),
          child: const Text('Streichen (0)'),
        ),
      FilledButton(onPressed: _save, child: const Text('Speichern')),
    ],
  );
}

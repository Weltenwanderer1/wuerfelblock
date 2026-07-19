import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../services/scoring_engine.dart';
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
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _ScoreEntryDialog(
        playerName: widget.game.state.players[playerIndex].name,
        category: category,
        allowedScores: ScoringEngine.allowedScores(
          widget.game.state.ruleSet,
          category,
        ),
      ),
    );
    if (value == null) return;
    try {
      await widget.game.enterScore(category, value, playerIndex: playerIndex);
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

  void _saveFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Speichern fehlgeschlagen')));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.state;
    const labelWidth = 150.0;
    const cellWidth = 92.0;
    return Scaffold(
      appBar: AppBar(
        title: Text('${state.ruleSet.label} · Scoreblock'),
        actions: [
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
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: Column(
                  children: [
                    _row(
                      color: AppColors.apricot,
                      labelWidth: labelWidth,
                      cellWidth: cellWidth,
                      label: 'Kategorie',
                      cells: [
                        for (final player in state.players)
                          Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                    for (final category in state.ruleSet.categories)
                      _row(
                        color: category.isUpper
                            ? AppColors.rose
                            : AppColors.lavender,
                        labelWidth: labelWidth,
                        cellWidth: cellWidth,
                        label: category.label,
                        cells: [
                          for (
                            var playerIndex = 0;
                            playerIndex < state.players.length;
                            playerIndex++
                          )
                            if (state.players[playerIndex].scores[category]
                                case final score?)
                              Semantics(
                                label:
                                    '${category.label} für ${state.players[playerIndex].name}: $score Punkte',
                                child: Center(
                                  child: Text(
                                    '$score',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Semantics(
                                button: true,
                                label:
                                    '${category.label} für ${state.players[playerIndex].name} eintragen',
                                child: InkWell(
                                  key: Key(
                                    'score-${category.name}-$playerIndex',
                                  ),
                                  onTap: widget.game.isBusy
                                      ? null
                                      : () => _enter(category, playerIndex),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.plum,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    _summaryRow(
                      'Obere Summe',
                      [for (final player in state.players) player.upperTotal],
                      labelWidth,
                      cellWidth,
                    ),
                    _summaryRow(
                      'Bonus',
                      [
                        for (final player in state.players)
                          state.bonusFor(player),
                      ],
                      labelWidth,
                      cellWidth,
                      color: AppColors.apricot,
                    ),
                    _summaryRow(
                      'Gesamt',
                      [
                        for (final player in state.players)
                          state.totalFor(player),
                      ],
                      labelWidth,
                      cellWidth,
                      color: AppColors.plum,
                      light: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required Color color,
    required double labelWidth,
    required double cellWidth,
    required String label,
    required List<Widget> cells,
  }) => Container(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.plum.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: labelWidth,
          height: 54,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        for (final cell in cells)
          Container(
            width: cellWidth,
            height: 54,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.plum.withValues(alpha: 0.25)),
              ),
            ),
            child: cell,
          ),
      ],
    ),
  );

  Widget _summaryRow(
    String label,
    List<int> values,
    double labelWidth,
    double cellWidth, {
    Color color = Colors.white,
    bool light = false,
  }) => _row(
    color: color,
    labelWidth: labelWidth,
    cellWidth: cellWidth,
    label: label,
    cells: [
      for (final value in values)
        Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: light ? Colors.white : AppColors.ink,
            ),
          ),
        ),
    ],
  );
}

class _ScoreEntryDialog extends StatefulWidget {
  const _ScoreEntryDialog({
    required this.playerName,
    required this.category,
    required this.allowedScores,
  });

  final String playerName;
  final ScoreCategory category;
  final Set<int> allowedScores;

  @override
  State<_ScoreEntryDialog> createState() => _ScoreEntryDialogState();
}

class _ScoreEntryDialogState extends State<_ScoreEntryDialog> {
  final _controller = TextEditingController();
  String? _error;

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
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Punkte eintragen'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.category.label} · ${widget.playerName}',
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
      TextButton(
        onPressed: () => Navigator.pop(context, 0),
        child: const Text('Streichen (0)'),
      ),
      FilledButton(onPressed: _save, child: const Text('Speichern')),
    ],
  );
}

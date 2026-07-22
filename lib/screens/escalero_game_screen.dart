import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/escalero_controller.dart';
import '../models/escalero_models.dart';
import '../models/game_models.dart';
import '../widgets/escalero_score_sheet.dart';
import '../widgets/poker_die_widget.dart';
import 'escalero_result_screen.dart';
import 'escalero_rules_screen.dart';

class EscaleroGameScreen extends StatefulWidget {
  const EscaleroGameScreen({
    required this.game,
    this.correctionMode = false,
    super.key,
  });
  final EscaleroController game;
  final bool correctionMode;
  @override
  State<EscaleroGameScreen> createState() => _EscaleroGameScreenState();
}

class _EscaleroGameScreenState extends State<EscaleroGameScreen> {
  late int _playerIndex;
  bool _correctionModeFinished = false;
  EscaleroController get game => widget.game;

  @override
  void initState() {
    super.initState();
    _playerIndex = game.state.activePlayerIndex;
    game.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    if (widget.correctionMode && !game.state.isComplete) {
      _correctionModeFinished = true;
    }
    _playerIndex = game.state.activePlayerIndex;
    setState(() {});
  }

  @override
  void dispose() {
    game.removeListener(_changed);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: LocalizedText('Aktion konnte nicht gespeichert werden.'),
          ),
        );
      }
    }
  }

  Future<void> _cell(EscaleroCategory category, int column) async {
    final state = game.state;
    final current = state.players[_playerIndex].entries[category]![column];
    if (current != null) {
      final editedPlayerIndex = _playerIndex;
      final result = await showDialog<_ScoreDialogResult>(
        context: context,
        builder: (_) => _ScoreInputDialog(
          category: category,
          column: column,
          initialValue: current,
        ),
      );
      if (result != null) {
        await _run(
          () =>
              game.editScore(editedPlayerIndex, category, column, result.value),
        );
        if (mounted) setState(() => _playerIndex = editedPlayerIndex);
      }
      return;
    }
    if (_playerIndex != state.activePlayerIndex) return;
    if (state.mode == GameMode.block) {
      final result = await showDialog<_ScoreDialogResult>(
        context: context,
        builder: (_) => _ScoreInputDialog(category: category, column: column),
      );
      if (result != null) {
        await _run(() => game.scoreBlock(category, column, result.value!));
      }
      return;
    }
    if (state.digitalTurn.rollCount == 0) return;
    final score = EscaleroScoring.score(
      category,
      state.digitalTurn.dice,
      served: state.digitalTurn.lastRollWasAllFive,
    );
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: LocalizedText('${category.label}: $score Punkte'),
        content: LocalizedText(
          'In Kolonne ${column + 1} für ${state.activePlayer.name} eintragen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            key: const Key('escalero-confirm-score'),
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Werten'),
          ),
        ],
      ),
    );
    if (yes == true) await _run(() => game.scoreDigital(category, column));
  }

  Future<void> _showCategoryInfo(EscaleroCategory category) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: LocalizedText(category.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LocalizedText(
              'Bildung',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            LocalizedText(category.formation),
            const SizedBox(height: 14),
            LocalizedText('Grundwert: ${category.baseValue}'),
            const SizedBox(height: 6),
            LocalizedText('Servierungswert: ${category.servedValue}'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const LocalizedText('Schließen'),
        ),
      ],
    ),
  );

  Future<void> _abandon() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Partie beenden?'),
        content: const LocalizedText('Der aktuelle Spielstand wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Beenden'),
          ),
        ],
      ),
    );
    if (yes == true) {
      try {
        await game.abandon();
        if (mounted) Navigator.pop(context);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: LocalizedText(
                'Die Partie konnte nicht gelöscht werden.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final correctionMode = widget.correctionMode && !_correctionModeFinished;
    if (state.isComplete && !correctionMode) {
      return EscaleroResultScreen(game: game);
    }
    final correctingComplete = correctionMode && state.isComplete;
    final digital = state.mode == GameMode.digital;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: LocalizedText(
          correctingComplete
              ? 'Escalero · Wertungen korrigieren'
              : 'Escalero · ${state.activePlayer.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('escalero-game-rules'),
            tooltip: localizeText(context, 'Regeln'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const EscaleroRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            key: const Key('escalero-undo'),
            tooltip: localizeText(context, 'Rückgängig'),
            onPressed: game.canUndo && !game.isBusy
                ? () => _run(game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          if (!correctionMode)
            IconButton(
              tooltip: localizeText(context, 'Partie beenden'),
              onPressed: game.isBusy ? null : _abandon,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          child: Column(
            children: [
              if (correctingComplete)
                const _CorrectionHint()
              else if (digital)
                _DigitalPanel(game: game, onRun: _run)
              else
                const _BlockHint(),
              const SizedBox(height: 7),
              Row(
                children: [
                  const LocalizedText(
                    'Blatt: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Expanded(
                    child: DropdownButton<int>(
                      key: const Key('escalero-player-picker'),
                      value: _playerIndex,
                      isExpanded: true,
                      items: [
                        for (var i = 0; i < state.players.length; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                              state.players[i].name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _playerIndex = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (!correctingComplete &&
                  _playerIndex != state.activePlayerIndex) ...[
                LocalizedText(
                  'Nur ${state.activePlayer.name} ist am Zug. Leere Felder sind schreibgeschützt; belegte Wertungen können korrigiert werden.',
                  key: const Key('escalero-readonly-sheet'),
                  style: const TextStyle(
                    color: Color(0xFF7C2D12),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
              ],
              Expanded(
                child: EscaleroScoreSheet(
                  state: state,
                  playerIndex: _playerIndex,
                  onCellTap: !game.isBusy && !game.needsDigitalSaveRetry
                      ? _cell
                      : null,
                  canTapEmptyCells:
                      !correctingComplete &&
                      _playerIndex == state.activePlayerIndex &&
                      (!digital || state.digitalTurn.rollCount > 0),
                  onCategoryTap: _showCategoryInfo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockHint extends StatelessWidget {
  const _BlockHint();
  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: LocalizedText(
              'Echte Pokerwürfel: freie Zelle antippen und Wert eintragen.',
              maxLines: 2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CorrectionHint extends StatelessWidget {
  const _CorrectionHint();

  @override
  Widget build(BuildContext context) => const Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LocalizedText(
        'Belegte Wertung antippen, korrigieren oder löschen.',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _DigitalPanel extends StatelessWidget {
  const _DigitalPanel({required this.game, required this.onRun});
  final EscaleroController game;
  final Future<void> Function(Future<void> Function()) onRun;
  @override
  Widget build(BuildContext context) {
    final turn = game.state.digitalTurn;
    final blocked = game.isBusy || game.needsDigitalSaveRetry;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LocalizedText(
                  'Wurf ${turn.rollCount}/3',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Flexible(
                  child: LocalizedText(
                    turn.rollCount == 0
                        ? 'Zum Start würfeln'
                        : 'Würfel antippen = halten',
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < 5; i++)
                  PokerDieWidget(
                    key: Key('escalero-die-$i'),
                    value: turn.dice[i],
                    held: turn.held[i],
                    size: 48,
                    onTap: !blocked && turn.rollCount > 0 && turn.rollCount < 3
                        ? () => onRun(() => game.toggleHold(i))
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (game.needsDigitalSaveRetry)
              Card(
                color: const Color(0xFFFFE1C7),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LocalizedText(
                        'Wurf ist sichtbar, aber noch nicht gespeichert.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          key: const Key('escalero-retry-save'),
                          onPressed: game.isBusy
                              ? null
                              : () => onRun(game.retryDigitalSave),
                          child: const LocalizedText('Erneut speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('escalero-roll'),
                  onPressed:
                      !blocked &&
                          turn.rollCount < 3 &&
                          (turn.rollCount == 0 ||
                              turn.held.any((held) => !held))
                      ? () => onRun(game.rollDigital)
                      : null,
                  icon: const Icon(Icons.casino, size: 19),
                  label: LocalizedText(
                    turn.rollCount == 0
                        ? 'Pokerwürfel werfen'
                        : 'Weiterwürfeln',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDialogResult {
  const _ScoreDialogResult(this.value);
  final int? value;
}

class _ScoreInputDialog extends StatefulWidget {
  const _ScoreInputDialog({
    required this.category,
    required this.column,
    this.initialValue,
  });
  final EscaleroCategory category;
  final int column;
  final int? initialValue;
  @override
  State<_ScoreInputDialog> createState() => _ScoreInputDialogState();
}

class _ScoreInputDialogState extends State<_ScoreInputDialog> {
  late final TextEditingController controller;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue?.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final value = int.tryParse(controller.text.trim());
    if (value == null ||
        !EscaleroScoring.isValidEntry(widget.category, value)) {
      setState(() => error = 'Für diese Kategorie ungültiger Wert.');
      return;
    }
    Navigator.pop(context, _ScoreDialogResult(value));
  }

  List<int> get validScores {
    final picture = widget.category.pictureValue;
    if (picture != null) {
      return [for (var count = 1; count <= 5; count++) count * picture];
    }
    return switch (widget.category) {
      EscaleroCategory.straight => const [20, 25],
      EscaleroCategory.fullHouse => const [30, 35],
      EscaleroCategory.poker => const [40, 45],
      EscaleroCategory.grande => const [50, 80],
      _ => const [],
    };
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: LocalizedText(
      '${widget.category.label} · Kolonne ${widget.column + 1}',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('escalero-points-field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: localizeText(context, 'Punkte'),
              errorText: error == null ? null : localizeText(context, error!),
            ),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 12),
          const LocalizedText(
            'Schnellwahl',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final score in validScores)
                ActionChip(
                  key: Key('escalero-quick-score-$score'),
                  label: LocalizedText('$score'),
                  onPressed: () =>
                      Navigator.pop(context, _ScoreDialogResult(score)),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      if (widget.initialValue != null)
        TextButton(
          key: const Key('escalero-delete-points'),
          onPressed: () =>
              Navigator.pop(context, const _ScoreDialogResult(null)),
          child: const LocalizedText('Löschen'),
        )
      else
        TextButton(
          onPressed: () => Navigator.pop(context, const _ScoreDialogResult(0)),
          child: const LocalizedText('0 (streichen)'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const LocalizedText('Abbrechen'),
      ),
      FilledButton(
        key: const Key('escalero-save-points'),
        onPressed: submit,
        child: LocalizedText(
          widget.initialValue == null ? 'Eintragen' : 'Speichern',
        ),
      ),
    ],
  );
}

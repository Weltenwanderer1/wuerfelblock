import 'package:flutter/material.dart';

import '../controllers/escalero_controller.dart';
import '../models/escalero_models.dart';
import '../models/game_models.dart';
import '../widgets/escalero_score_sheet.dart';
import '../widgets/poker_die_widget.dart';
import 'escalero_result_screen.dart';
import 'escalero_rules_screen.dart';

class EscaleroGameScreen extends StatefulWidget {
  const EscaleroGameScreen({required this.game, super.key});
  final EscaleroController game;
  @override
  State<EscaleroGameScreen> createState() => _EscaleroGameScreenState();
}

class _EscaleroGameScreenState extends State<EscaleroGameScreen> {
  int _playerIndex = 0;
  EscaleroController get game => widget.game;

  @override
  void initState() {
    super.initState();
    _playerIndex = game.state.activePlayerIndex;
    game.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
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
            content: Text('Aktion konnte nicht gespeichert werden.'),
          ),
        );
      }
    }
  }

  Future<void> _cell(EscaleroCategory category, int column) async {
    final state = game.state;
    if (_playerIndex != state.activePlayerIndex) return;
    if (state.players[_playerIndex].entries[category]![column] != null) return;
    if (state.mode == GameMode.block) {
      final value = await showDialog<int>(
        context: context,
        builder: (_) => _ScoreInputDialog(category: category, column: column),
      );
      if (value != null) {
        await _run(() => game.scoreBlock(category, column, value));
      }
      return;
    }
    if (_playerIndex != state.activePlayerIndex ||
        state.digitalTurn.rollCount == 0) {
      return;
    }
    final score = EscaleroScoring.score(
      category,
      state.digitalTurn.dice,
      served: state.digitalTurn.lastRollWasAllFive,
    );
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.label}: $score Punkte'),
        content: Text(
          'In Kolonne ${column + 1} für ${state.activePlayer.name} eintragen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            key: const Key('escalero-confirm-score'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Werten'),
          ),
        ],
      ),
    );
    if (yes == true) await _run(() => game.scoreDigital(category, column));
  }

  Future<void> _abandon() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partie beenden?'),
        content: const Text('Der aktuelle Spielstand wird gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Beenden'),
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
              content: Text('Die Partie konnte nicht gelöscht werden.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (state.isComplete) {
      return EscaleroResultScreen(game: game);
    }
    final digital = state.mode == GameMode.digital;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text(
          'Escalero · ${state.activePlayer.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            key: const Key('escalero-game-rules'),
            tooltip: 'Regeln',
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const EscaleroRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            key: const Key('escalero-undo'),
            tooltip: 'Rückgängig',
            onPressed: game.canUndo && !game.isBusy
                ? () => _run(game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Partie beenden',
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
              if (digital)
                _DigitalPanel(game: game, onRun: _run)
              else
                const _BlockHint(),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Text(
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
              if (_playerIndex != state.activePlayerIndex) ...[
                Text(
                  'Nur ${state.activePlayer.name} ist am Zug – dieses Blatt ist schreibgeschützt.',
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
                  onCellTap:
                      _playerIndex == state.activePlayerIndex &&
                          !game.isBusy &&
                          (!digital ||
                              (state.digitalTurn.rollCount > 0 &&
                                  !game.needsDigitalSaveRetry))
                      ? _cell
                      : null,
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
            child: Text(
              'Echte Pokerwürfel: freie Zelle antippen und Wert eintragen.',
              maxLines: 2,
            ),
          ),
        ],
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
                Text(
                  'Wurf ${turn.rollCount}/3',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Flexible(
                  child: Text(
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
                      const Text(
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
                          child: const Text('Erneut speichern'),
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
                  label: Text(
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

class _ScoreInputDialog extends StatefulWidget {
  const _ScoreInputDialog({required this.category, required this.column});
  final EscaleroCategory category;
  final int column;
  @override
  State<_ScoreInputDialog> createState() => _ScoreInputDialogState();
}

class _ScoreInputDialogState extends State<_ScoreInputDialog> {
  final controller = TextEditingController();
  String? error;
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
    Navigator.pop(context, value);
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
    title: Text('${widget.category.label} · Kolonne ${widget.column + 1}'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('escalero-points-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Punkte', errorText: error),
          onSubmitted: (_) => submit(),
        ),
        const SizedBox(height: 12),
        const Text(
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
                label: Text('$score'),
                onPressed: () => Navigator.pop(context, score),
              ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, 0),
        child: const Text('0 (streichen)'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        key: const Key('escalero-save-points'),
        onPressed: submit,
        child: const Text('Eintragen'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/balut_controller.dart';
import '../models/balut_models.dart';
import '../models/game_models.dart';
import 'balut_result_screen.dart';
import 'balut_rules_screen.dart';
import '../widgets/die_widget.dart';

const _balutInk = Color(0xFF2D2923);
const _balutAccent = Color(0xFF166534);

class BalutGameScreen extends StatefulWidget {
  const BalutGameScreen({required this.game, super.key});
  final BalutController game;

  @override
  State<BalutGameScreen> createState() => _BalutGameScreenState();
}

class _BalutGameScreenState extends State<BalutGameScreen> {
  int _displayedPlayerIndex = 0;

  BalutController get _game => widget.game;
  BalutGameState get _state => _game.state;

  @override
  void initState() {
    super.initState();
    _displayedPlayerIndex = _state.activePlayerIndex;
    _game.addListener(_onGameChanged);
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    super.dispose();
  }

  void _onGameChanged() {
    if (!mounted) return;
    if (_state.activePlayerIndex < _state.players.length) {
      _displayedPlayerIndex = _state.activePlayerIndex;
    }
    setState(() {});
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Aktion fehlgeschlagen.')),
      );
    }
  }

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Partie beenden?'),
        content: const LocalizedText(
          'Die aktuelle Balut-Partie wird verworfen und das Spiel zurückgesetzt.',
        ),
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
    if (confirmed != true || !mounted) return;
    try {
      await _game.abandon();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Beenden fehlgeschlagen.')),
      );
    }
  }

  Future<void> _editBlock({
    required int playerIndex,
    required BalutCategory category,
    required int index,
  }) async {
    if (_state.mode != GameMode.block) return;
    final player = _state.players[playerIndex];
    final preview = BalutScoring.score(category, _state.dice);
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => _BalutScoreDialog(
        category: category,
        index: index,
        playerName: player.name,
        suggested: preview,
      ),
    );
    if (entered == null) return;
    await _run(
      () =>
          _game.scoreBlock(category, index, entered, playerIndex: playerIndex),
    );
  }

  Future<void> _scoreDigital(BalutCategory category) async {
    if (_state.mode != GameMode.digital) return;
    if (_state.rollCount == 0) return;
    final score = BalutScoring.score(category, _state.dice);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: LocalizedText('${category.label}: $score Punkte?'),
        content: LocalizedText(
          'Wertung wird in den nächsten freien Eintrag von '
          '${_state.activePlayer.name} übernommen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            key: const Key('confirm-score'),
            onPressed: () => Navigator.pop(context, true),
            child: const LocalizedText('Werten'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() => _game.scoreDigital(category));
  }

  Future<void> _showCategoryInfo(BalutCategory category) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: LocalizedText(category.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LocalizedText(
              'So wird gewertet',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            LocalizedText(category.scoringExplanation),
            const SizedBox(height: 14),
            LocalizedText(
              'Mögliche Werte: ${BalutScoring.validScores(category).join(', ')}',
            ),
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

  Future<void> _openResult() async {
    if (!_state.isComplete) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => BalutResultScreen(game: _game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final active = state.activePlayer;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: LocalizedText(
          state.isComplete
              ? 'Balut · Ergebnis'
              : 'Balut · ${active.name} ist dran',
        ),
        actions: [
          IconButton(
            tooltip: localizeText(context, 'Balut-Regeln'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const BalutRulesScreen()),
            ),
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            tooltip: localizeText(context, 'Letzte Wertung zurück'),
            onPressed: _game.canUndo && !_game.isBusy
                ? () => _run(_game.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: localizeText(context, 'Partie beenden'),
            onPressed: _game.isBusy ? null : _abandon,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: state.isComplete
          ? _buildCompleted(state)
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 540;
                    final dicePanel = _DicePanel(
                      game: _game,
                      compact: compact,
                      onRun: _run,
                    );
                    final sheet = _BalutSheet(
                      state: state,
                      canScoreDigital:
                          !_game.isBusy &&
                          !_game.needsDigitalSaveRetry &&
                          state.rollCount > 0,
                      displayedPlayerIndex: _displayedPlayerIndex,
                      onSelectPlayer: (index) =>
                          setState(() => _displayedPlayerIndex = index),
                      onEditBlock: (category, index) => _editBlock(
                        playerIndex: _displayedPlayerIndex,
                        category: category,
                        index: index,
                      ),
                      onScoreDigital: (category) => _scoreDigital(category),
                      onShowCategoryInfo: _showCategoryInfo,
                    );
                    if (compact) {
                      return Column(
                        children: [
                          dicePanel,
                          const SizedBox(height: 8),
                          Expanded(child: sheet),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: Column(
                            children: [dicePanel, const SizedBox(height: 8)],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: sheet),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildCompleted(BalutGameState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFE7F6E7),
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: _balutAccent),
              title: const LocalizedText(
                'Alle 28 Wertungen sind voll.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: LocalizedText(
                'Sieger: ${state.winners.map((player) => player.name).join(', ')}',
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('balut-open-result'),
            onPressed: _game.isBusy ? null : _openResult,
            icon: const Icon(Icons.bar_chart),
            label: const LocalizedText('Ergebnis anzeigen'),
          ),
        ],
      ),
    );
  }
}

class _DicePanel extends StatelessWidget {
  const _DicePanel({
    required this.game,
    required this.compact,
    required this.onRun,
  });
  final BalutController game;
  final bool compact;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final isDigital = state.mode == GameMode.digital;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDigital) ...[
              LocalizedText(
                'Wurf ${state.rollCount}/3',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _balutInk,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var index = 0; index < state.dice.length; index++)
                    DieWidget(
                      key: Key('balut-die-$index'),
                      value: state.dice[index],
                      held: state.held[index],
                      selectedSemantic: 'festgehalten',
                      unselectedSemantic: 'wird neu gewürfelt',
                      index: 200 + index,
                      onTap:
                          isDigital &&
                              state.rollCount > 0 &&
                              state.rollCount < 3 &&
                              !game.isBusy
                          ? () => onRun(() => game.toggleHold(index))
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LocalizedText(
                  'Blockmodus: Mit echten Würfeln spielen und Werte unten eintragen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _balutInk,
                  ),
                ),
              ),
            if (isDigital && game.needsDigitalSaveRetry)
              FilledButton.icon(
                key: const Key('balut-retry-save'),
                // Retry must remain clickable while needsDigitalSaveRetry is
                // true; only isBusy should disable it.
                onPressed: game.isBusy
                    ? null
                    : () => onRun(game.retryDigitalSave),
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const LocalizedText('Erneut speichern'),
              )
            else if (isDigital)
              FilledButton.icon(
                key: const Key('balut-roll'),
                onPressed: isDigital && !game.isBusy && state.rollCount < 3
                    ? () => onRun(game.rollDigital)
                    : null,
                icon: const Icon(Icons.casino, size: 18),
                label: LocalizedText(
                  state.rollCount == 0
                      ? 'Würfeln'
                      : 'Mit ${state.held.where((value) => !value).length} Würfeln weiter',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalutSheet extends StatelessWidget {
  const _BalutSheet({
    required this.state,
    required this.canScoreDigital,
    required this.displayedPlayerIndex,
    required this.onSelectPlayer,
    required this.onEditBlock,
    required this.onScoreDigital,
    required this.onShowCategoryInfo,
  });

  final BalutGameState state;
  final bool canScoreDigital;
  final int displayedPlayerIndex;
  final ValueChanged<int> onSelectPlayer;
  final void Function(BalutCategory category, int index) onEditBlock;
  final ValueChanged<BalutCategory> onScoreDigital;
  final ValueChanged<BalutCategory> onShowCategoryInfo;

  @override
  Widget build(BuildContext context) {
    final player = state.players[displayedPlayerIndex];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlayerPicker(
              state: state,
              displayedPlayerIndex: displayedPlayerIndex,
              onSelectPlayer: onSelectPlayer,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final category in BalutCategory.values)
                    _CategoryRow(
                      category: category,
                      player: player,
                      state: state,
                      canScoreDigital: canScoreDigital,
                      onEditBlock: (cat, idx) => onEditBlock(cat, idx),
                      onScoreDigital: (cat) => onScoreDigital(cat),
                      onShowCategoryInfo: onShowCategoryInfo,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _PlayerTotals(player: player),
          ],
        ),
      ),
    );
  }
}

class _PlayerPicker extends StatelessWidget {
  const _PlayerPicker({
    required this.state,
    required this.displayedPlayerIndex,
    required this.onSelectPlayer,
  });
  final BalutGameState state;
  final int displayedPlayerIndex;
  final ValueChanged<int> onSelectPlayer;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const Key('balut-player-picker'),
      initialValue: displayedPlayerIndex,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: localizeText(context, 'Block anzeigen'),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      items: [
        for (var index = 0; index < state.players.length; index++)
          DropdownMenuItem<int>(
            key: Key('balut-player-$index'),
            value: index,
            child: Text(
              state.players[index].name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onSelectPlayer(value);
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.player,
    required this.state,
    required this.canScoreDigital,
    required this.onEditBlock,
    required this.onScoreDigital,
    required this.onShowCategoryInfo,
  });
  final BalutCategory category;
  final BalutPlayer player;
  final BalutGameState state;
  final bool canScoreDigital;
  final void Function(BalutCategory category, int index) onEditBlock;
  final ValueChanged<BalutCategory> onScoreDigital;
  final ValueChanged<BalutCategory> onShowCategoryInfo;

  @override
  Widget build(BuildContext context) {
    final entries = player.entries[category]!;
    final categoryTotal = player.categoryTotal(category);
    final isDigital = state.mode == GameMode.digital;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  key: Key('balut-category-info-${_categoryKey(category)}'),
                  onPressed: () => onShowCategoryInfo(category),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 40),
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: LocalizedText(
                    '${category.label} (${category.bonusHint})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _balutInk,
                    ),
                  ),
                ),
              ),
              LocalizedText(
                'Σ $categoryTotal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _balutAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (
                var index = 0;
                index < BalutPlayer.entriesPerCategory;
                index++
              )
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _SlotCell(
                      key: ValueKey(
                        isDigital
                            ? 'balut-score-${_categoryKey(category)}-$index'
                            : 'balut-edit-${_categoryKey(category)}-$index',
                      ),
                      category: category,
                      index: index,
                      value: entries[index],
                      canTap: isDigital
                          ? canScoreDigital && entries[index] == null
                          : true,
                      onTap: () {
                        if (isDigital) {
                          if (entries[index] == null) {
                            onScoreDigital(category);
                          }
                        } else {
                          onEditBlock(category, index);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _categoryKey(BalutCategory category) => switch (category) {
  BalutCategory.fours => 'fours',
  BalutCategory.fives => 'fives',
  BalutCategory.sixes => 'sixes',
  BalutCategory.straights => 'straights',
  BalutCategory.fullHouse => 'fullHouse',
  BalutCategory.choice => 'choice',
  BalutCategory.balut => 'balut',
};

class _SlotCell extends StatelessWidget {
  const _SlotCell({
    super.key,
    required this.category,
    required this.index,
    required this.value,
    required this.canTap,
    required this.onTap,
  });
  final BalutCategory category;
  final int index;
  final int? value;
  final bool canTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = value != null;
    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFFE6BD) : const Color(0xFFFFFBEC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB59A6A)),
        ),
        child: LocalizedText(
          filled ? '$value' : '·',
          style: TextStyle(
            color: filled ? _balutInk : const Color(0xFF8A7A55),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _PlayerTotals extends StatelessWidget {
  const _PlayerTotals({required this.player});
  final BalutPlayer player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6E7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 2,
        children: [
          LocalizedText(
            'Roh ${player.rawTotal}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _balutInk,
              fontSize: 13,
            ),
          ),
          LocalizedText(
            'Bonus ${player.incentivePoints}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _balutAccent,
              fontSize: 13,
            ),
          ),
          LocalizedText(
            'Σ ${player.rawTotal + player.incentivePoints}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _balutAccent,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalutScoreDialog extends StatefulWidget {
  const _BalutScoreDialog({
    required this.category,
    required this.index,
    required this.playerName,
    required this.suggested,
  });
  final BalutCategory category;
  final int index;
  final String playerName;
  final int suggested;

  @override
  State<_BalutScoreDialog> createState() => _BalutScoreDialogState();
}

class _BalutScoreDialogState extends State<_BalutScoreDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.suggested == 0 ? '' : '${widget.suggested}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final value = int.tryParse(raw);
    if (value == null) {
      setState(() => _error = 'Bitte eine ganze Zahl eingeben.');
      return;
    }
    if (!BalutScoring.isValidEntry(widget.category, value)) {
      setState(() => _error = 'Wert ist für diese Kategorie nicht erlaubt.');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: LocalizedText('${widget.category.label} für ${widget.playerName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocalizedText(
              'Vorschlag aus aktuellem Wurf: ${widget.suggested}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            const LocalizedText(
              'Mögliche Werte – antippen zum Übernehmen:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final value in BalutScoring.validScores(widget.category))
                  ChoiceChip(
                    key: Key(
                      'balut-value-${_categoryKey(widget.category)}-$value',
                    ),
                    label: Text('$value'),
                    selected: _controller.text.trim() == '$value',
                    onSelected: (_) => setState(() {
                      _controller.text = '$value';
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('balut-points-field'),
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                labelText: localizeText(
                  context,
                  'Wert (${widget.index + 1}. Eintrag)',
                ),
                border: const OutlineInputBorder(),
                errorText: _error == null
                    ? null
                    : localizeText(context, _error!),
              ),
              onChanged: (_) => setState(() {
                _error = null;
              }),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const LocalizedText('0 (streichen)'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const LocalizedText('Abbrechen'),
        ),
        FilledButton(
          key: const Key('balut-save-points'),
          onPressed: _submit,
          child: const LocalizedText('Eintragen'),
        ),
      ],
    );
  }
}

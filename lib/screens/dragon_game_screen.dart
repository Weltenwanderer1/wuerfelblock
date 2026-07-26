import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';
import '../controllers/dragon_controller.dart';
import '../models/dragon_models.dart';
import '../models/game_models.dart';
import '../widgets/die_widget.dart';
import 'dragon_result_screen.dart';

const _paper = Color(0xFFFFF8E8);
const _ink = Color(0xFF2D2923);
const _gold = Color(0xFFB8860B);

Color _typeColor(DragonType type) => switch (type) {
  DragonType.water => const Color(0xFF1565C0),
  DragonType.fire => const Color(0xFFC62828),
  DragonType.luck => const Color(0xFF7B1FA2),
};

class DragonGameScreen extends StatefulWidget {
  const DragonGameScreen({required this.game, super.key});
  final DragonController game;

  @override
  State<DragonGameScreen> createState() => _DragonGameScreenState();
}

class _DragonGameScreenState extends State<DragonGameScreen> {
  DragonController get _game => widget.game;
  DragonGameState get _state => _game.state;

  @override
  void initState() {
    super.initState();
    _game.addListener(_onChanged);
  }

  @override
  void dispose() {
    _game.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
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
          'Die aktuelle Drachengold-Partie wird verworfen.',
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

  Future<void> _placeManual(int fieldIndex) async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => const _ManualValueDialog(),
    );
    if (value == null) return;
    await _run(() => _game.placeManualDie(fieldIndex, value));
  }

  Future<void> _openResult() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DragonResultScreen(game: _game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state.isComplete) return _buildCompleted();
    final active = state.activePlayer;
    final isDigital = state.mode == GameMode.digital;
    final selectedDie = isDigital &&
            state.selectedDieIndex != null &&
            state.selectedDieIndex! < state.dice.length
        ? state.dice[state.selectedDieIndex!]
        : null;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: LocalizedText('Drachengold · ${active.name} ist dran'),
        actions: [
          IconButton(
            tooltip: localizeText(context, 'Zurück'),
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_game.lastMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LocalizedText(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _gold,
                  ),
                ),
              ),
            _DragonCardView(
              key: const Key('dragon-card'),
              state: state,
              selectedDie: selectedDie,
              onFieldTap: (index) {
                if (_game.isBusy) return;
                if (isDigital && selectedDie != null) {
                  _run(() => _game.placeSelectedDie(index));
                } else if (!isDigital) {
                  _placeManual(index);
                }
              },
            ),
            const SizedBox(height: 12),
            if (isDigital)
              _DigitalDiceArea(game: _game, onRun: _run)
            else
              const _BlockDiceHint(),
            const SizedBox(height: 12),
            _ActionButtons(game: _game, onRun: _run),
            const SizedBox(height: 16),
            _PlayerInfo(state: state),
            const SizedBox(height: 12),
            _DeckInfo(state: state),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(title: const LocalizedText('Drachengold · Ergebnis')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: const Color(0xFFFDF6E3),
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: _gold),
              title: LocalizedText(
                'Sieger: ${_state.winners.map((p) => p.name).join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _game.isBusy ? null : _openResult,
            icon: const Icon(Icons.bar_chart),
            label: const LocalizedText('Ergebnis anzeigen'),
          ),
        ],
      ),
    ),
  );
}

class _DigitalDiceArea extends StatelessWidget {
  const _DigitalDiceArea({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (state.dice.isEmpty) {
      return FilledButton.icon(
        key: const Key('dragon-roll'),
        onPressed: game.isBusy ? null : () => onRun(game.rollDigital),
        icon: const Icon(Icons.casino),
        label: const LocalizedText('Würfeln'),
      );
    }
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < state.dice.length; i++)
              DieWidget(
                key: Key('dragon-die-$i'),
                value: state.dice[i],
                held: state.selectedDieIndex == i,
                onTap:
                    game.isBusy ? null : () => onRun(() => game.selectDie(i)),
                index: 300 + i,
                selectedSemantic: 'ausgewählt',
                unselectedSemantic: 'nicht ausgewählt',
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BlockDiceHint extends StatelessWidget {
  const _BlockDiceHint();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: LocalizedText(
      'Blockmodus: Mit echten Würfeln spielen und Werte auf die Felder tippen.',
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
    ),
  );
}

class _DragonCardView extends StatelessWidget {
  const _DragonCardView({
    required this.state,
    required this.selectedDie,
    required this.onFieldTap,
    super.key,
  });
  final DragonGameState state;
  final int? selectedDie;
  final ValueChanged<int> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final card = state.currentCard;
    final attempt = state.attempt;
    if (card == null || attempt == null) return const SizedBox.shrink();
    final color = _typeColor(card.type);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(card.type.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                LocalizedText(
                  card.type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                if (state.cardGold > 0)
                  LocalizedText(
                    '🪙 ${state.cardGold}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _gold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < card.fields.length; i++)
                  _FieldChip(
                    index: i,
                    field: card.fields[i],
                    placedValue: attempt.placedValues[i],
                    acceptsSelected: selectedDie != null &&
                        attempt.placedValues[i] == null &&
                        card.fields[i].accepts(selectedDie!, card: card),
                    onTap: attempt.placedValues[i] == null
                        ? () => onFieldTap(i)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  const _FieldChip({
    required this.index,
    required this.field,
    required this.placedValue,
    required this.acceptsSelected,
    required this.onTap,
  });
  final int index;
  final DragonField field;
  final int? placedValue;
  final bool acceptsSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label:
        'Feld ${index + 1}: ${field.symbol}'
        '${placedValue != null ? ', belegt mit $placedValue' : ', frei'}',
    child: InkWell(
      key: Key('dragon-field-$index'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: placedValue != null
              ? const Color(0xFFE8F5E9)
              : acceptsSelected
              ? const Color(0xFFE3F2FD)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: acceptsSelected
                ? const Color(0xFF1565C0)
                : const Color(0xFFD4C4CF),
            width: acceptsSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              field.symbol,
              style: const TextStyle(fontSize: 13, color: _ink),
            ),
            if (placedValue != null)
              Text(
                '$placedValue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _gold,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    if (game.needsDigitalSaveRetry) {
      return FilledButton.icon(
        key: const Key('dragon-retry-save'),
        onPressed: game.isBusy ? null : () => onRun(game.retryDigitalSave),
        icon: const Icon(Icons.save_outlined, size: 18),
        label: const LocalizedText('Erneut speichern'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.canContinue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.icon(
              key: const Key('dragon-continue'),
              onPressed:
                  game.isBusy ? null : () => onRun(game.continueRolling),
              icon: const Icon(Icons.casino, size: 18),
              label: const LocalizedText('Weiter würfeln'),
            ),
          ),
        if (game.canEndTurn)
          FilledButton.icon(
            key: const Key('dragon-end-turn'),
            onPressed: game.isBusy ? null : () => onRun(game.endTurn),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const LocalizedText('Zug beenden'),
          ),
      ],
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  const _PlayerInfo({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < state.players.length; i++) ...[
            if (i > 0) const Divider(height: 12),
            Row(
              children: [
                if (i == state.activePlayerIndex)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.arrow_right, color: _gold, size: 20),
                  ),
                Expanded(
                  child: LocalizedText(
                    state.players[i].name,
                    style: TextStyle(
                      fontWeight: i == state.activePlayerIndex
                          ? FontWeight.w900
                          : FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                ),
                LocalizedText('🪙 ${state.players[i].gold}'),
                const SizedBox(width: 12),
                LocalizedText('🐉 ${state.players[i].tamedCount}'),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _DeckInfo extends StatelessWidget {
  const _DeckInfo({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      LocalizedText(
        '${state.cardsInGame} Karten',
        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
      const SizedBox(width: 16),
      LocalizedText(
        'Goldtopf: ${state.goldPool}',
        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
    ],
  );
}

class _ManualValueDialog extends StatelessWidget {
  const _ManualValueDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const LocalizedText('Würfelwert wählen'),
    content: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var value = 1; value <= 6; value++)
          FilledButton(
            key: Key('dragon-manual-value-$value'),
            onPressed: () => Navigator.pop(context, value),
            style: FilledButton.styleFrom(minimumSize: const Size(52, 52)),
            child: Text('$value', style: const TextStyle(fontSize: 20)),
          ),
      ],
    ),
  );
}

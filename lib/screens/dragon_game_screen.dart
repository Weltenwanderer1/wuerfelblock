import 'package:flutter/material.dart';

import '../controllers/dragon_controller.dart';
import '../l10n/localized_text.dart';
import '../models/dragon_models.dart';
import '../models/game_models.dart';
import '../widgets/die_widget.dart';
import 'dragon_result_screen.dart';
import 'schuppenschatz_rules_screen.dart';

const _page = Color(0xFFF7F1E5);
const _ink = Color(0xFF241C2B);
const _muted = Color(0xFF766C78);
const _gold = Color(0xFFC98915);
const _deepGold = Color(0xFF7A4B00);
const _panel = Color(0xFFFFFBF3);
const _water = Color(0xFF176B87);
const _fire = Color(0xFFA93A2B);
const _luck = Color(0xFF7A4C9E);

Color _typeColor(DragonType type) => switch (type) {
  DragonType.water => _water,
  DragonType.fire => _fire,
  DragonType.luck => _luck,
};

Color _typeLight(DragonType type) => switch (type) {
  DragonType.water => const Color(0xFFD8F1F6),
  DragonType.fire => const Color(0xFFFFE0D6),
  DragonType.luck => const Color(0xFFEEDFF8),
};

IconData _typeIcon(DragonType type) => switch (type) {
  DragonType.water => Icons.water_drop_rounded,
  DragonType.fire => Icons.local_fire_department_rounded,
  DragonType.luck => Icons.auto_awesome_rounded,
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
    if (mounted) setState(() {});
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

  Future<void> _openRules() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => const SchuppenschatzRulesScreen()),
  );

  Future<void> _abandon() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const LocalizedText('Partie beenden?'),
        content: const LocalizedText(
          'Die aktuelle Schuppenschatz-Partie wird verworfen.',
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
    final card = _state.currentCard;
    if (card == null) return;
    final field = card.fields[fieldIndex];
    final validValues = [
      for (var value = 1; value <= 6; value++)
        if (field.accepts(value, card: card)) value,
    ];
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _ManualValueDialog(validValues: validValues),
    );
    if (value != null) {
      await _run(() => _game.placeManualDie(fieldIndex, value));
    }
  }

  Future<void> _openResult() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => DragonResultScreen(game: _game)),
  );

  @override
  Widget build(BuildContext context) {
    if (_state.isComplete) return _buildCompleted();
    final state = _state;
    final isDigital = state.mode == GameMode.digital;
    final selectedDie =
        isDigital &&
            state.selectedDieIndex != null &&
            state.selectedDieIndex! < state.dice.length
        ? state.dice[state.selectedDieIndex!]
        : null;
    final interactionEnabled = !_game.isBusy && !_game.needsDigitalSaveRetry;

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        title: const LocalizedText('Schuppenschatz'),
        backgroundColor: _page,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('dragon-rules'),
            tooltip: localizeText(context, 'Spielregeln'),
            onPressed: _openRules,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          IconButton(
            key: const Key('dragon-undo'),
            tooltip: localizeText(context, 'Zurück'),
            onPressed: _game.canUndo && interactionEnabled
                ? () => _run(_game.undo)
                : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: localizeText(context, 'Partie beenden'),
            onPressed: _game.isBusy ? null : _abandon,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          children: [
            _StatusPanel(state: state),
            if (_game.lastMessage case final message?) ...[
              const SizedBox(height: 8),
              _MessageBanner(message: message),
            ],
            const SizedBox(height: 10),
            _DragonChallengeCard(
              key: const Key('dragon-card'),
              state: state,
              selectedDie: selectedDie,
              manualMode: !isDigital,
              enabled: interactionEnabled,
              onFieldTap: (index) {
                if (!interactionEnabled) return;
                if (isDigital && selectedDie != null) {
                  _run(() => _game.placeSelectedDie(index));
                } else if (!isDigital) {
                  _placeManual(index);
                }
              },
            ),
            const SizedBox(height: 10),
            _RiskPanel(state: state),
            const SizedBox(height: 10),
            if (isDigital)
              _DigitalDiceArea(game: _game, onRun: _run)
            else
              const _BlockDiceHint(),
            const SizedBox(height: 10),
            _PlayerStrip(state: state),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(game: _game, onRun: _run),
    );
  }

  Widget _buildCompleted() => Scaffold(
    backgroundColor: _page,
    appBar: AppBar(
      title: const LocalizedText('Schuppenschatz · Geschafft'),
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events_rounded, color: _gold, size: 72),
              const SizedBox(height: 12),
              const LocalizedText(
                'Sieger',
                style: TextStyle(fontWeight: FontWeight.w700, color: _muted),
              ),
              const SizedBox(height: 4),
              Text(
                _state.winners.map((p) => p.name).join(', '),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _game.isBusy ? null : _openResult,
                icon: const Icon(Icons.leaderboard_rounded),
                label: const LocalizedText('Ergebnis ansehen'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('schuppenschatz-status'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _ink,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
          child: const Icon(Icons.person_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LocalizedText(
                'Am Zug',
                style: TextStyle(color: Color(0xFFD7CED9), fontSize: 12),
              ),
              Text(
                state.activePlayer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        _MiniStat(
          icon: Icons.style_rounded,
          label: '${state.cardsInGame}',
          semanticLabel: '${state.cardsInGame} Karten',
        ),
        const SizedBox(width: 8),
        _MiniStat(
          icon: Icons.monetization_on_rounded,
          label: '${state.activePlayer.totalGold}',
          semanticLabel: '${state.activePlayer.totalGold} Gold',
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.semanticLabel,
  });
  final IconData icon;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: localizeText(context, semanticLabel),
    excludeSemantics: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFFD77B)),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE7B3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2B557)),
    ),
    child: Row(
      children: [
        const Icon(Icons.campaign_rounded, size: 20, color: _deepGold),
        const SizedBox(width: 8),
        Expanded(
          child: LocalizedText(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _deepGold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DragonChallengeCard extends StatelessWidget {
  const _DragonChallengeCard({
    required this.state,
    required this.selectedDie,
    required this.manualMode,
    required this.enabled,
    required this.onFieldTap,
    super.key,
  });
  final DragonGameState state;
  final int? selectedDie;
  final bool manualMode;
  final bool enabled;
  final ValueChanged<int> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final card = state.currentCard;
    final attempt = state.attempt;
    if (card == null || attempt == null) return const SizedBox.shrink();
    final color = _typeColor(card.type);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_typeLight(card.type), _panel],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: .55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _typeIcon(card.type),
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        card.type.label,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      LocalizedText(
                        _typeHint(card.type),
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                if (state.cardGold > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD77B),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '+${state.cardGold}',
                      style: const TextStyle(
                        color: _deepGold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < card.fields.length; i++)
                    _FieldSocket(
                      index: i,
                      field: card.fields[i],
                      placedValue: attempt.placedValues[i],
                      accent: color,
                      acceptsSelected:
                          selectedDie != null &&
                          attempt.placedValues[i] == null &&
                          card.fields[i].accepts(selectedDie!, card: card),
                      onTap:
                          attempt.placedValues[i] == null &&
                              enabled &&
                              (manualMode ||
                                  (selectedDie != null &&
                                      card.fields[i].accepts(
                                        selectedDie!,
                                        card: card,
                                      )))
                          ? () => onFieldTap(i)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeHint(DragonType type) => switch (type) {
    DragonType.water => 'Jede passende Zahl oder Flamme zählt.',
    DragonType.fire => 'Feuerfest: Eine 6 passt hier nie.',
    DragonType.luck => 'Markierte Felder müssen zuerst voll sein.',
  };
}

class _FieldSocket extends StatelessWidget {
  const _FieldSocket({
    required this.index,
    required this.field,
    required this.placedValue,
    required this.accent,
    required this.acceptsSelected,
    required this.onTap,
  });
  final int index;
  final DragonField field;
  final int? placedValue;
  final Color accent;
  final bool acceptsSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isFilled = placedValue != null;
    return Semantics(
      button: onTap != null,
      label:
          'Feld ${index + 1}: ${field.symbol}${isFilled ? ', belegt mit $placedValue' : ', frei'}',
      child: InkWell(
        key: Key('dragon-field-$index'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? accent
                : acceptsSelected
                ? const Color(0xFFFFE49E)
                : Colors.white.withValues(alpha: .82),
            border: Border.all(
              color: acceptsSelected ? _gold : accent.withValues(alpha: .65),
              width: acceptsSelected ? 3 : 1.5,
            ),
            boxShadow: acceptsSelected
                ? [
                    BoxShadow(
                      color: _gold.withValues(alpha: .35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                isFilled ? _dieLabel(placedValue) : _fieldLabel(field),
                style: TextStyle(
                  color: isFilled ? Colors.white : _ink,
                  fontSize: isFilled ? 24 : 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (field.mandatory && !isFilled)
                const Positioned(
                  right: 3,
                  top: 2,
                  child: Icon(Icons.star_rounded, size: 17, color: _gold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dieLabel(int? value) => value == 6 ? '🔥' : '$value';
  String _fieldLabel(DragonField value) => switch (value.kind) {
    DragonFieldKind.number => '${value.number}',
    DragonFieldKind.flame => '🔥',
    DragonFieldKind.empty => '✦',
  };
}

class _RiskPanel extends StatelessWidget {
  const _RiskPanel({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) {
    final secured = state.attempt?.diceGold ?? 0;
    final filled = state.attempt?.placedCount ?? 0;
    final total = state.currentCard?.fields.length ?? 0;
    return Container(
      key: const Key('schuppenschatz-risk'),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3D7C4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: _gold, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Jetzt sicher: $secured Gold',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                LocalizedText(
                  '$filled von $total Feldern · ${state.cardGold} Gold auf der Karte',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalDiceArea extends StatelessWidget {
  const _DigitalDiceArea({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (state.dice.isEmpty) {
      return const LocalizedText(
        'Bereit? Würfle und wähle danach einen passenden Würfel.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
      );
    }
    return Column(
      children: [
        const LocalizedText(
          'Würfel wählen, dann auf ein leuchtendes Feld tippen',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 7),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var i = 0; i < state.dice.length; i++)
              DieWidget(
                key: Key('dragon-die-$i'),
                value: state.dice[i],
                held: state.selectedDieIndex == i,
                selectable: true,
                face: state.dice[i] == 6
                    ? const Icon(
                        Icons.local_fire_department_rounded,
                        color: _fire,
                        size: 32,
                      )
                    : null,
                semanticValue: state.dice[i] == 6 ? 'Flamme' : null,
                onTap: game.isBusy || game.needsDigitalSaveRetry
                    ? null
                    : () => onRun(() => game.selectDie(i)),
                index: 300 + i,
                selectedSemantic: 'ausgewählt',
                unselectedSemantic: 'nicht ausgewählt',
              ),
          ],
        ),
      ],
    );
  }
}

class _BlockDiceHint extends StatelessWidget {
  const _BlockDiceHint();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.touch_app_rounded, color: _deepGold),
      SizedBox(width: 8),
      Flexible(
        child: LocalizedText(
          'Passendes Feld antippen und den echten Würfelwert wählen.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
    ],
  );
}

class _PlayerStrip extends StatelessWidget {
  const _PlayerStrip({required this.state});
  final DragonGameState state;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 74 + (textScale - 1).clamp(0, 1) * 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.players.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final player = state.players[index];
          final active = index == state.activePlayerIndex;
          return Container(
            width: 142,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFE7B3) : _panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active ? _gold : const Color(0xFFE3D7C4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${player.gold} Gold  ·  ${player.tamedCount} 🐉',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stack = textScale > 1.35;
    final actions = <Widget>[];

    if (game.needsDigitalSaveRetry) {
      actions.add(
        FilledButton.icon(
          key: const Key('dragon-retry-save'),
          onPressed: game.isBusy ? null : () => onRun(game.retryDigitalSave),
          icon: const Icon(Icons.save_outlined),
          label: const LocalizedText('Erneut speichern'),
        ),
      );
    } else {
      if (state.mode == GameMode.digital &&
          state.dice.isEmpty &&
          state.placementsSinceRoll == 0) {
        actions.add(
          FilledButton.icon(
            key: const Key('dragon-roll'),
            onPressed: game.isBusy ? null : () => onRun(game.rollDigital),
            icon: const Icon(Icons.casino_rounded),
            label: const LocalizedText('Würfeln'),
          ),
        );
      }
      if (state.mode == GameMode.block && state.placementsSinceRoll == 0) {
        actions.add(
          OutlinedButton.icon(
            key: const Key('dragon-fail-attempt'),
            onPressed: game.isBusy ? null : () => onRun(game.failAttempt),
            icon: const Icon(Icons.block_rounded),
            label: const LocalizedText('Kein Würfel passt'),
          ),
        );
      }
      if (game.canContinue) {
        actions.add(
          FilledButton.icon(
            key: const Key('dragon-continue'),
            onPressed: game.isBusy ? null : () => onRun(game.continueRolling),
            icon: const Icon(Icons.casino_rounded),
            label: const LocalizedText('Weiter würfeln'),
          ),
        );
      }
      if (game.canEndTurn) {
        actions.add(
          OutlinedButton.icon(
            key: const Key('dragon-end-turn'),
            onPressed: game.isBusy ? null : () => onRun(game.endTurn),
            icon: const Icon(Icons.savings_outlined),
            label: LocalizedText(
              '${state.attempt?.diceGold ?? 0} Gold sichern',
            ),
          ),
        );
      }
    }

    return Material(
      key: const Key('dragon-action-bar'),
      color: _panel,
      elevation: 12,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        child: actions.isEmpty
            ? const LocalizedText(
                'Wähle mindestens einen passenden Würfel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
              )
            : stack
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    actions[i],
                  ],
                ],
              )
            : Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ManualValueDialog extends StatelessWidget {
  const _ManualValueDialog({required this.validValues});
  final List<int> validValues;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const LocalizedText('Passenden Würfel wählen'),
    content: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in validValues)
          FilledButton(
            key: Key('dragon-manual-value-$value'),
            onPressed: () => Navigator.pop(context, value),
            style: FilledButton.styleFrom(minimumSize: const Size(54, 54)),
            child: Text(
              value == 6 ? '🔥' : '$value',
              style: const TextStyle(fontSize: 20),
            ),
          ),
      ],
    ),
  );
}

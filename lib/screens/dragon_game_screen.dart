import 'package:flutter/material.dart';

import '../controllers/dragon_controller.dart';
import '../l10n/localized_text.dart';
import '../models/dragon_models.dart';
import '../models/game_models.dart';

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
const _ghost = Color(0xFF2C2C34);
const _boss = Color(0xFF8B0000);

Color _typeColor(DragonType type) => switch (type) {
  DragonType.water => _water,
  DragonType.fire => _fire,
  DragonType.luck => _luck,
  DragonType.ghost => _ghost,
  DragonType.boss => _boss,
};

Color _typeLight(DragonType type) => switch (type) {
  DragonType.water => const Color(0xFFD8F1F6),
  DragonType.fire => const Color(0xFFFFE0D6),
  DragonType.luck => const Color(0xFFEEDFF8),
  DragonType.ghost => const Color(0xFFE8E8EE),
  DragonType.boss => const Color(0xFFFFE0E0),
};

IconData _typeIcon(DragonType type) => switch (type) {
  DragonType.water => Icons.water_drop_rounded,
  DragonType.fire => Icons.local_fire_department_rounded,
  DragonType.luck => Icons.auto_awesome_rounded,
  DragonType.ghost => Icons.nights_stay_rounded,
  DragonType.boss => Icons.cruelty_free_rounded,
};

Color _dieColor(DieColor c) => switch (c) {
  DieColor.white => Colors.white,
  DieColor.blue => const Color(0xFF2196F3),
  DieColor.green => const Color(0xFF4CAF50),
  DieColor.black => const Color(0xFF212121),
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

    if (field.kind == DragonFieldKind.sum) {
      final result = await showDialog<List<int>>(
        context: context,
        builder: (context) => _SumInputDialog(field: field, card: card),
      );
      if (result != null) {
        final dice = result.map((v) => (v, DieColor.white)).toList();
        await _run(() => _game.placeManualSum(fieldIndex, dice));
      }
      return;
    }

    if (field.kind == DragonFieldKind.bossHp) {
      final hp = _state.bossRemainingHp[fieldIndex];
      final maxVal = hp < 6 ? hp : 6;
      final value = await showDialog<int>(
        context: context,
        builder: (context) => _ManualValueDialog(
          validValues: [for (var v = 1; v <= maxVal; v++) v],
        ),
      );
      if (value != null) {
        await _run(() => _game.placeManualDie(fieldIndex, value));
      }
      return;
    }

    // Farbwürfel-Felder: nur passender Würfel wählbar
    final validValues = [
      for (var value = 1; value <= 6; value++)
        if (field.acceptsDie(
          DieRoll(value, field.dieColor ?? DieColor.white),
          card: card,
        ))
          value,
    ];
    if (validValues.isEmpty) return;
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _ManualValueDialog(validValues: validValues),
    );
    if (value != null) {
      await _run(
        () => _game.placeManualDie(
          fieldIndex,
          value,
          color: field.dieColor ?? DieColor.white,
        ),
      );
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
            if (state.isBossCard)
              _BossCard(
                key: const Key('dragon-boss-card'),
                state: state,
                game: _game,
                onRun: _run,
              )
            else
              _DragonChallengeCard(
                key: const Key('dragon-card'),
                state: state,
                game: _game,
                manualMode: !isDigital,
                enabled: interactionEnabled,
                onFieldTap: (index) {
                  if (!interactionEnabled) return;
                  if (isDigital && state.selectedDieIndices.isNotEmpty) {
                    _run(() => _game.placeSelectedOnField(index));
                  } else if (!isDigital) {
                    _placeManual(index);
                  }
                },
              ),
            const SizedBox(height: 10),
            if (!state.isBossCard) _RiskPanel(state: state),
            const SizedBox(height: 10),
            if (isDigital)
              _DigitalDiceArea(game: _game, onRun: _run)
            else
              const _BlockDiceHint(),
            const SizedBox(height: 10),
            _AbilityBar(game: _game, onRun: _run),
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

// ─── Status Panel ─────────────────────────────────────────────────────────────

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
          label: '${state.cardsRemaining}',
          semanticLabel: '${state.cardsRemaining} Karten übrig',
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

// ─── Message Banner ───────────────────────────────────────────────────────────

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

// ─── Normale Drachenkarte ─────────────────────────────────────────────────────

class _DragonChallengeCard extends StatelessWidget {
  const _DragonChallengeCard({
    required this.state,
    required this.game,
    required this.manualMode,
    required this.enabled,
    required this.onFieldTap,
    super.key,
  });
  final DragonGameState state;
  final DragonController game;
  final bool manualMode;
  final bool enabled;
  final ValueChanged<int> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final card = state.currentCard;
    final attempt = state.attempt;
    if (card == null || attempt == null) return const SizedBox.shrink();
    final color = _typeColor(card.type);
    final hasSelection = state.selectedDieIndices.isNotEmpty;
    final selectedDice = [
      for (final i in state.selectedDieIndices) state.dice[i],
    ];

    bool fieldIsOpen(int i) {
      final pf = attempt.placed[i];
      if (pf == null) return true;
      return card.fields[i].kind == DragonFieldKind.sum &&
          !card.fields[i].isSumComplete(pf.sum, pf.values.length);
    }

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
                if (card.bonusPoints > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB39DDB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '+${card.bonusPoints}★',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                if (state.cardGold > 0) ...[
                  const SizedBox(width: 6),
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
                      placed: attempt.placed[i],
                      isOpen: fieldIsOpen(i),
                      accent: color,
                      reduction: state.fieldReductions.length > i
                          ? state.fieldReductions[i]
                          : 0,
                      acceptsSelected:
                          hasSelection &&
                          fieldIsOpen(i) &&
                          _fieldAcceptsSelection(
                            card.fields[i],
                            selectedDice,
                            card,
                            attempt.placed[i],
                          ),
                      onTap:
                          fieldIsOpen(i) &&
                              enabled &&
                              (manualMode ||
                                  (hasSelection &&
                                      _fieldAcceptsSelection(
                                        card.fields[i],
                                        selectedDice,
                                        card,
                                        attempt.placed[i],
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

  bool _fieldAcceptsSelection(
    DragonField field,
    List<DieRoll> dice,
    DragonCard card,
    PlacedField? existing,
  ) {
    if (dice.isEmpty) return false;
    if (field.kind == DragonFieldKind.sum) {
      final existingSum = existing?.sum ?? 0;
      final existingCount = existing?.values.length ?? 0;
      return field.acceptsSum(dice, card: card, existingSum: existingSum, existingCount: existingCount);
    }
    if (dice.length == 1) {
      return field.acceptsDie(dice.single, card: card);
    }
    return false;
  }

  String _typeHint(DragonType type) => switch (type) {
    DragonType.water => 'Blaues Feld braucht den blauen Würfel.',
    DragonType.fire => 'Feuerfest: Keine 6. Summenfeld mit 2–3 Würfeln.',
    DragonType.luck => '★ Pflichtfelder + grünes Würfelfeld.',
    DragonType.ghost => 'Schwarzes Feld + Summe aus 2–4 Würfeln.',
    DragonType.boss => '',
  };
}

// ─── Boss-Karte ───────────────────────────────────────────────────────────────

class _BossCard extends StatelessWidget {
  const _BossCard({required this.state, required this.game, required this.onRun, super.key});
  final DragonGameState state;
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final card = state.currentCard;
    if (card == null) return const SizedBox.shrink();
    final hasSelection = state.selectedDieIndices.isNotEmpty;
    final selectedValue = hasSelection && state.selectedDieIndices.length == 1
        ? state.dice[state.selectedDieIndices.single].value
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_typeLight(DragonType.boss), _panel],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _boss.withValues(alpha: .6), width: 2),
        boxShadow: [
          BoxShadow(
            color: _boss.withValues(alpha: .2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: _boss,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cruelty_free_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'Boss-Drache',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _boss,
                        ),
                      ),
                      LocalizedText(
                        'Reduziere die HP auf 0! Würfel werden weitergegeben.',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD77B),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '20 🪙',
                    style: TextStyle(
                      color: _deepGold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < state.bossRemainingHp.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _BossHpField(
                    index: i,
                    hp: state.bossRemainingHp[i],
                    maxHp: card.fields[i].bossHp ?? 0,
                    acceptsSelected:
                        selectedValue != null &&
                        selectedValue <= state.bossRemainingHp[i],
                    onTap:
                        selectedValue != null &&
                            selectedValue <= state.bossRemainingHp[i] &&
                            !game.isBusy
                        ? () => onRun(() async {
                            await game.placeSelectedOnField(i);
                          })
                        : null,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BossHpField extends StatelessWidget {
  const _BossHpField({
    required this.index,
    required this.hp,
    required this.maxHp,
    required this.acceptsSelected,
    required this.onTap,
  });
  final int index;
  final int hp;
  final int maxHp;
  final bool acceptsSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final defeated = hp <= 0;
    return Semantics(
      label: 'Boss-Feld ${index + 1}: $hp von $maxHp HP',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 90,
          decoration: BoxDecoration(
            color: defeated
                ? const Color(0xFFC8E6C9)
                : acceptsSelected
                ? const Color(0xFFFFE49E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: defeated
                  ? const Color(0xFF4CAF50)
                  : acceptsSelected
                  ? _gold
                  : _boss.withValues(alpha: .5),
              width: acceptsSelected ? 3 : 1.5,
            ),
            boxShadow: acceptsSelected
                ? [
                    BoxShadow(
                      color: _gold.withValues(alpha: .4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                defeated ? Icons.check_circle_rounded : Icons.favorite_rounded,
                color: defeated ? const Color(0xFF4CAF50) : _boss,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                defeated ? '✓' : '$hp',
                style: TextStyle(
                  fontSize: defeated ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: defeated ? const Color(0xFF4CAF50) : _boss,
                ),
              ),
              if (!defeated)
                Text(
                  '/$maxHp',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feld-Socket ──────────────────────────────────────────────────────────────

class _FieldSocket extends StatelessWidget {
  const _FieldSocket({
    required this.index,
    required this.field,
    required this.placed,
    required this.isOpen,
    required this.accent,
    required this.acceptsSelected,
    required this.onTap,
    this.reduction = 0,
  });
  final int index;
  final DragonField field;
  final PlacedField? placed;
  final bool isOpen;
  final Color accent;
  final bool acceptsSelected;
  final VoidCallback? onTap;
  final int reduction;

  @override
  Widget build(BuildContext context) {
    final isFilled = placed != null;
    final isPartial = isFilled && isOpen; // Summenfeld mit Zwischenstand
    final isComplete = isFilled && !isOpen; // alle anderen Felder oder vollständiges Summenfeld

    return Semantics(
      button: onTap != null,
      label: 'Feld ${index + 1}: $_label${isFilled ? ', belegt' : ', frei'}',
      child: InkWell(
        key: Key('dragon-field-$index'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 64,
          height: 64,
          decoration: ShapeDecoration(
            shape: field.mandatory && !isFilled
                ? StarBorder(
                    points: 5,
                    rotation: 0,
                    innerRadiusRatio: 0.45,
                    side: BorderSide(
                      color: acceptsSelected ? _gold : accent.withValues(alpha: .65),
                      width: acceptsSelected ? 3 : 1.5,
                    ),
                  )
                : CircleBorder(
                    side: BorderSide(
                      color: acceptsSelected ? _gold : accent.withValues(alpha: .65),
                      width: acceptsSelected ? 3 : 1.5,
                    ),
                  ),
            color: isComplete
                ? accent
                : isPartial
                ? accent.withValues(alpha: .5)
                : acceptsSelected
                ? const Color(0xFFFFE49E)
                : _fieldBgColor(field),
            shadows: acceptsSelected
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
                isFilled ? _placedLabel : _label,
                style: TextStyle(
                  color: isComplete ? Colors.white : _ink,
                  fontSize: isFilled ? 18 : 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _placedLabel {
    if (placed == null) return '';
    final p = placed!;
    if (p.values.length == 1) {
      return p.values.single == 6 && p.colors.single == DieColor.white
          ? '🔥'
          : '${p.values.single}';
    }
    return p.values.join('+');
  }

  String get _label {
    if (reduction > 0 &&
        (field.kind == DragonFieldKind.number ||
            field.kind == DragonFieldKind.coloredDie ||
            field.kind == DragonFieldKind.sum)) {
      final orig = field.kind == DragonFieldKind.sum
          ? (field.sumTarget ?? 0)
          : (field.number ?? 0);
      final effective = orig - reduction;
      final prefix = field.kind == DragonFieldKind.sum ? '↗' : '';
      return '$prefix$effective';
    }
    return switch (field.kind) {
      DragonFieldKind.number => '${field.number}',
      DragonFieldKind.flame => '🔥',
      DragonFieldKind.empty => '✦',
      DragonFieldKind.coloredDie => '${field.number}',
      DragonFieldKind.sum => '↗${field.sumTarget}',
      DragonFieldKind.bossHp => '♥${field.bossHp}',
    };
  }

  Color _fieldBgColor(DragonField field) {
    if (field.kind == DragonFieldKind.coloredDie && field.dieColor != null) {
      return _dieColor(field.dieColor!).withValues(alpha: .35);
    }
    return Colors.white.withValues(alpha: .82);
  }
}

// ─── Risk Panel ───────────────────────────────────────────────────────────────

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

// ─── Digital Dice Area ────────────────────────────────────────────────────────

class _DigitalDiceArea extends StatelessWidget {
  const _DigitalDiceArea({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final state = game.state;
    if (state.dice.isEmpty) {
      return const LocalizedText(
        'Bereit? Würfle und wähle danach passende Würfel.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
      );
    }
    return Column(
      children: [
        LocalizedText(
          state.isBossCard
              ? 'Würfel wählen → Boss-Feld antippen (reduziert HP)'
              : 'Würfel wählen → Feld antippen. Mehrere für Σ-Felder.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
        const SizedBox(height: 7),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var i = 0; i < state.dice.length; i++)
              _ColoredDieWidget(
                key: Key('dragon-die-$i'),
                die: state.dice[i],
                selected: state.selectedDieIndices.contains(i),
                onTap: game.isBusy || game.needsDigitalSaveRetry
                    ? null
                    : () => onRun(() => game.toggleDie(i)),
                index: i,
              ),
          ],
        ),
        if (state.handicapDice > 0)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LocalizedText(
              '🎯 Handicap aktiv: 2 Würfel weniger',
              style: TextStyle(
                fontSize: 11,
                color: _fire,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ColoredDieWidget extends StatelessWidget {
  const _ColoredDieWidget({
    required this.die,
    required this.selected,
    required this.onTap,
    required this.index,
    super.key,
  });
  final DieRoll die;
  final bool selected;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _dieColor(die.color);
    final isWhite = die.color == DieColor.white;
    return Semantics(
      label:
          '${die.color.label}er Würfel: ${die.value}${selected ? ', ausgewählt' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : color.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _gold
                  : isWhite
                  ? const Color(0xFF9E9E9E)
                  : color,
              width: selected ? 3 : 1.5,
            ),
            boxShadow: selected
                ? [BoxShadow(color: _gold.withValues(alpha: .4), blurRadius: 8)]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isWhite)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                die.value == 6 && isWhite ? '🔥' : '${die.value}',
                style: TextStyle(
                  fontSize: die.value == 6 && isWhite ? 22 : 24,
                  fontWeight: FontWeight.w900,
                  color: isWhite ? _ink : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Block Dice Hint ──────────────────────────────────────────────────────────

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

// ─── Ability Bar ──────────────────────────────────────────────────────────────

class _AbilityBar extends StatelessWidget {
  const _AbilityBar({required this.game, required this.onRun});
  final DragonController game;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context) {
    final player = game.state.activePlayer;
    final abilities = DragonAbility.values;
    final available = abilities.where(player.canUse).toList();
    if (available.isEmpty) {
      return const LocalizedText(
        'Alle Fähigkeiten verbraucht.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: _muted),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ability in available)
          ActionChip(
            key: Key('dragon-ability-${ability.name}'),
            label: LocalizedText(ability.label),
            avatar: const Icon(Icons.bolt_rounded, size: 16),
            onPressed: () => _showAbilityDialog(context, ability),
          ),
      ],
    );
  }

  Future<void> _showAbilityDialog(
    BuildContext context,
    DragonAbility ability,
  ) async {
    if (ability == DragonAbility.reduce) {
      final card = game.state.currentCard;
      if (card == null) return;
      final fieldIdx = await showDialog<int>(
        context: context,
        builder: (ctx) =>
            _ReduceDialog(card: card, reductions: game.state.fieldReductions),
      );
      if (fieldIdx == null || !context.mounted) return;
      final reduction = await showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const LocalizedText('Um wie viel senken?'),
          children: [
            for (final r in [1, 2, 3])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r),
                child: Text('−$r'),
              ),
          ],
        ),
      );
      if (reduction == null) return;
      onRun(
        () => game.useAbility(
          ability,
          fieldIndex: fieldIdx,
          reduction: reduction,
        ),
      );
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: LocalizedText(ability.label),
          content: LocalizedText(ability.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const LocalizedText('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const LocalizedText('Einsetzen'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        onRun(() => game.useAbility(ability));
      }
    }
  }
}

class _ReduceDialog extends StatelessWidget {
  const _ReduceDialog({required this.card, required this.reductions});
  final DragonCard card;
  final List<int> reductions;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const LocalizedText('Welches Feld senken?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < card.fields.length; i++)
          if (card.fields[i].kind == DragonFieldKind.number ||
              card.fields[i].kind == DragonFieldKind.coloredDie ||
              card.fields[i].kind == DragonFieldKind.sum)
            ListTile(
              dense: true,
              title: Text('Feld ${i + 1}: ${card.fields[i].symbol}'),
              subtitle: reductions[i] > 0
                  ? Text('Bereits −${reductions[i]}')
                  : null,
              onTap: () => Navigator.pop(context, i),
            ),
      ],
    ),
  );
}

// ─── Player Strip ─────────────────────────────────────────────────────────────

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

// ─── Action Bar ───────────────────────────────────────────────────────────────

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
      // Würfeln (digital, noch keine Würfel)
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
      // Block: Fehlversuch
      if (state.mode == GameMode.block && state.placementsSinceRoll == 0) {
        actions.add(
          OutlinedButton.icon(
            key: const Key('dragon-fail-attempt'),
            onPressed: game.isBusy ? null : () => onRun(game.failAttempt),
            icon: const Icon(Icons.block_rounded),
            label: LocalizedText(
              state.isBossCard ? 'Boss weitergeben' : 'Kein Würfel passt',
            ),
          ),
        );
      }
      // Weiter würfeln (nur normale Karten)
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
      // Gold sichern (normale Karten)
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
      // Boss: Zug beenden (weitergeben)
      if (game.canBossEndTurn) {
        actions.add(
          OutlinedButton.icon(
            key: const Key('dragon-boss-end'),
            onPressed: game.isBusy ? null : () => onRun(game.endTurn),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const LocalizedText('Boss weitergeben'),
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

// ─── Dialogs ──────────────────────────────────────────────────────────────────

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

class _SumInputDialog extends StatefulWidget {
  const _SumInputDialog({required this.field, required this.card});
  final DragonField field;
  final DragonCard card;

  @override
  State<_SumInputDialog> createState() => _SumInputDialogState();
}

class _SumInputDialogState extends State<_SumInputDialog> {
  final List<int> _values = [];

  int get _sum => _values.fold(0, (a, v) => a + v);
  bool get _isValid =>
      _values.length >= widget.field.sumMinDice &&
      _values.length <= widget.field.sumMaxDice &&
      _sum == (widget.field.sumTarget ?? 0);
  bool get _canAdd => _values.length < widget.field.sumMaxDice && _sum < (widget.field.sumTarget ?? 0);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: LocalizedText(
      'Summe = ${widget.field.sumTarget} (${widget.field.sumMinDice}–${widget.field.sumMaxDice} Würfel)',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aktuell: ${_values.isEmpty ? "–" : _values.join(" + ")} = $_sum',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var v = 1; v <= 6; v++)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: _canAdd && _sum + v <= (widget.field.sumTarget ?? 0)
                    ? () => setState(() => _values.add(v))
                    : null,
                child: Text(
                  v == 6 ? '🔥' : '$v',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_values.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _values.removeLast()),
            child: const LocalizedText('Letzten Würfel entfernen'),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const LocalizedText('Abbrechen'),
      ),
      FilledButton(
        onPressed: _isValid ? () => Navigator.pop(context, _values) : null,
        child: const LocalizedText('Bestätigen'),
      ),
    ],
  );
}

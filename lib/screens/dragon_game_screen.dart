import 'package:flutter/material.dart';

import '../controllers/dragon_controller.dart';
import '../l10n/localized_text.dart';
import '../models/dragon_models.dart';
import '../models/game_models.dart';

import 'dragon_result_screen.dart';
import 'schuppenschatz_rules_screen.dart';

const _page = Color(0xFF241209);
const _ink = Color(0xFF2D160B);
const _muted = Color(0xFF714224);
const _gold = Color(0xFFD79B2D);
const _deepGold = Color(0xFFF0C56A);
const _panel = Color(0xFFF1D7A1);
const _water = Color(0xFF006498);
const _fire = Color(0xFFFD8B00);
const _luck = Color(0xFF10B981);
const _ghost = Color(0xFF4D4732);
const _boss = Color(0xFF93000A);

Color _typeColor(DragonType type) => switch (type) {
  DragonType.water => _water,
  DragonType.fire => _fire,
  DragonType.luck => _luck,
  DragonType.ghost => _ghost,
  DragonType.boss => _boss,
};

Color _typeLight(DragonType type) => switch (type) {
  DragonType.water => const Color(0xFF001D31),
  DragonType.fire => const Color(0xFF2F1500),
  DragonType.luck => const Color(0xFF064E3B),
  DragonType.ghost => const Color(0xFF1A2B3C),
  DragonType.boss => const Color(0xFF690005),
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
      final placed = _state.attempt?.placed[fieldIndex];
      final reduction = _state.fieldReductions.length > fieldIndex
          ? _state.fieldReductions[fieldIndex]
          : 0;
      final remaining = field.remainingTarget(
        placed?.sum ?? 0,
        reduction: reduction,
      );
      final maxValue = remaining < 6 ? remaining : 6;
      final validValues = [
        for (var value = 1; value <= maxValue; value++) value,
      ];
      final value = await showDialog<int>(
        context: context,
        builder: (context) => _ManualValueDialog(validValues: validValues),
      );
      if (value != null) {
        await _run(
          () => _game.placeManualSum(fieldIndex, [(value, DieColor.white)]),
        );
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
    final reduction = _state.fieldReductions.length > fieldIndex
        ? _state.fieldReductions[fieldIndex]
        : 0;
    final validValues = [
      for (var value = 1; value <= 6; value++)
        if (field.acceptsDie(
          DieRoll(value, field.dieColor ?? DieColor.white),
          card: card,
          reduction: reduction,
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
        title: const Icon(Icons.auto_awesome_rounded, color: _gold, size: 24),
        backgroundColor: const Color(0xFF1B100A),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4B2A16), Color(0xFF1A0D08)],
            ),
            border: Border(
              top: BorderSide(color: Color(0xFFDDAE4B), width: 1.4),
              bottom: BorderSide(color: Color(0xFF080403), width: 3),
            ),
            boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 10)],
          ),
        ),
        iconTheme: const IconThemeData(color: _deepGold),
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
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/schuppenschatz/dragon_board.png',
              ),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
      ),
      bottomNavigationBar: _ActionBar(game: _game, onRun: _run),
    );
  }

  Widget _buildCompleted() => Scaffold(
    backgroundColor: _page,
    appBar: AppBar(
      title: const LocalizedText(
        'Schuppenschatz · Geschafft',
        style: TextStyle(color: _ink),
      ),
      automaticallyImplyLeading: false,
      iconTheme: const IconThemeData(color: _ink),
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
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('dragon-wood-status'),
    child: Container(
      key: const Key('schuppenschatz-status'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5B321C), Color(0xFF241209)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x660E0703),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF5C351B),
              border: Border.all(color: _gold, width: 1.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: _deepGold, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocalizedText(
                  'Am Zug',
                  style: TextStyle(color: _muted, fontSize: 12),
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
          const SizedBox(width: 8),
          _MiniStat(
            icon: Icons.casino_rounded,
            label: '${state.rollCount}',
            semanticLabel: '${state.rollCount}. Wurf in diesem Zug',
          ),
        ],
      ),
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
        Icon(icon, size: 18, color: _gold),
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
      color: const Color(0xFF2A3B4C),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _gold.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        const Icon(Icons.campaign_rounded, size: 20, color: _gold),
        const SizedBox(width: 8),
        Expanded(
          child: LocalizedText(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFF3D8),
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
      if (pf == null) {
        final field = card.fields[i];
        if (field.kind == DragonFieldKind.number ||
            field.kind == DragonFieldKind.coloredDie) {
          final reduction = state.fieldReductions.length > i
              ? state.fieldReductions[i]
              : 0;
          if (field.effectiveNumber(reduction) <= 0) return false;
        }
        return true;
      }
      return card.fields[i].kind == DragonFieldKind.sum &&
          !card.fields[i].isSumComplete(pf.sum, pf.values.length);
    }

    bool fieldCanUseThisRoll(int i) =>
        fieldIsOpen(i) &&
        !(card.fields[i].kind == DragonFieldKind.sum &&
            state.sumFieldsReducedThisRoll.contains(i));

    return Container(
      key: const Key('dragon-rune-card-frame'),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage(
                  'assets/images/schuppenschatz/rune_dragon_card.png',
                ),
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(.84),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 42, 38, 46),
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
                              style: const TextStyle(
                                fontSize: 21,
                                height: .95,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFF0CD),
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF0B0604),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            LocalizedText(
                              _typeHint(card.type),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFDFA6),
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF0B0604),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
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
                            color: _luck.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '+${card.bonusPoints}★',
                            style: const TextStyle(
                              color: _luck,
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
                            color: _gold.withValues(alpha: .25),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '+${state.cardGold}',
                            style: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
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
                                fieldCanUseThisRoll(i) &&
                                _fieldAcceptsSelection(
                                  card.fields[i],
                                  selectedDice,
                                  card,
                                  attempt.placed[i],
                                  state.fieldReductions.length > i
                                      ? state.fieldReductions[i]
                                      : 0,
                                ),
                            onTap:
                                fieldCanUseThisRoll(i) &&
                                    enabled &&
                                    (manualMode ||
                                        (hasSelection &&
                                            _fieldAcceptsSelection(
                                              card.fields[i],
                                              selectedDice,
                                              card,
                                              attempt.placed[i],
                                              state.fieldReductions.length > i
                                                  ? state.fieldReductions[i]
                                                  : 0,
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
    int reduction,
  ) {
    if (dice.isEmpty) return false;
    if (field.kind == DragonFieldKind.number ||
        field.kind == DragonFieldKind.coloredDie) {
      if (field.effectiveNumber(reduction) <= 0) return false;
    }
    if (field.kind == DragonFieldKind.sum) {
      if (dice.length != 1) return false;
      final existingSum = existing?.sum ?? 0;
      final existingCount = existing?.values.length ?? 0;
      return field.acceptsSum(
        dice,
        card: card,
        existingSum: existingSum,
        existingCount: existingCount,
        reduction: reduction,
      );
    }
    if (dice.length == 1) {
      return field.acceptsDie(dice.single, card: card, reduction: reduction);
    }
    return false;
  }

  String _typeHint(DragonType type) => switch (type) {
    DragonType.water => 'Blaues Feld braucht den blauen Würfel.',
    DragonType.fire => 'Summenfeld: ein Würfel pro Wurf, über 2–3 Würfe.',
    DragonType.luck => '★ Pflichtfelder + grünes Würfelfeld.',
    DragonType.ghost => 'Schwarzes Feld + Summe aus 2–4 Würfeln.',
    DragonType.boss => '',
  };
}

// ─── Boss-Karte ───────────────────────────────────────────────────────────────

class _BossCard extends StatelessWidget {
  const _BossCard({
    required this.state,
    required this.manualMode,
    required this.enabled,
    required this.onFieldTap,
    super.key,
  });
  final DragonGameState state;
  final bool manualMode;
  final bool enabled;
  final ValueChanged<int> onFieldTap;

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
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/schuppenschatz/rune_dragon_card.png',
          ),
          fit: BoxFit.cover,
          opacity: .9,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _typeLight(DragonType.boss).withValues(alpha: .75),
            _panel.withValues(alpha: .68),
          ],
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
                        'Jedes Feld 1× pro Wurf · Würfel weitergeben',
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
                    color: _gold.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    '20 🪙',
                    style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < state.bossRemainingHp.length; i++) ...{
                  if (i > 0) const SizedBox(width: 12),
                  _BossHpField(
                    key: Key('dragon-boss-field-$i'),
                    index: i,
                    hp: state.bossRemainingHp[i],
                    maxHp: card.fields[i].bossHp ?? 0,
                    usedThisRoll: state.bossFieldsUsedThisRoll.contains(i),
                    acceptsSelected:
                        selectedValue != null &&
                        selectedValue <= state.bossRemainingHp[i] &&
                        !state.bossFieldsUsedThisRoll.contains(i),
                    onTap:
                        enabled &&
                            state.bossRemainingHp[i] > 0 &&
                            !state.bossFieldsUsedThisRoll.contains(i) &&
                            (manualMode ||
                                (selectedValue != null &&
                                    selectedValue <= state.bossRemainingHp[i]))
                        ? () => onFieldTap(i)
                        : null,
                  ),
                },
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
    this.usedThisRoll = false,
    super.key,
  });
  final int index;
  final int hp;
  final int maxHp;
  final bool acceptsSelected;
  final VoidCallback? onTap;
  final bool usedThisRoll;

  @override
  Widget build(BuildContext context) {
    final defeated = hp <= 0;
    return Semantics(
      label:
          'Boss-Feld ${index + 1}: $hp von $maxHp HP${usedThisRoll ? ', bereits verwendet' : ''}',
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
                ? _luck.withValues(alpha: .25)
                : usedThisRoll
                ? const Color(0xFF1A2B3C)
                : acceptsSelected
                ? _gold.withValues(alpha: .25)
                : _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: defeated
                  ? _luck
                  : usedThisRoll
                  ? _muted.withValues(alpha: .5)
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
                color: defeated
                    ? _luck
                    : usedThisRoll
                    ? _muted
                    : _boss,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                defeated ? '✓' : '$hp',
                style: TextStyle(
                  fontSize: defeated ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: defeated
                      ? _luck
                      : usedThisRoll
                      ? _muted
                      : _boss,
                  decoration: usedThisRoll
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: _boss,
                  decorationThickness: 2.5,
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
    final isComplete =
        isFilled && !isOpen; // vollständig (nicht Summe oder Summe fertig)
    final isSum = field.kind == DragonFieldKind.sum;

    return Semantics(
      button: onTap != null,
      label: 'Feld ${index + 1}: $_label${isFilled ? ', belegt' : ', frei'}',
      child: InkWell(
        key: Key('dragon-field-$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isComplete && !isSum
                ? Colors.transparent
                : isPartial
                ? accent.withValues(alpha: .22)
                : acceptsSelected
                ? _gold.withValues(alpha: .25)
                : _fieldBgColor(field),
            borderRadius: BorderRadius.circular(14),
            border: isComplete && !isSum
                ? null
                : Border.all(
                    color: acceptsSelected
                        ? _gold
                        : accent.withValues(alpha: .72),
                    width: acceptsSelected ? 3 : 1.6,
                  ),
            boxShadow: acceptsSelected
                ? [
                    BoxShadow(
                      color: _gold.withValues(alpha: .48),
                      blurRadius: 13,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .42),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isComplete && !isSum)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: Key('dragon-field-dashed-$index'),
                      painter: _DashedRoundedBorderPainter(color: accent),
                    ),
                  ),
                ),
              if (isSum && !isComplete)
                const Positioned(
                  top: 5,
                  left: 5,
                  child: Icon(
                    Icons.north_east_rounded,
                    color: _deepGold,
                    size: 15,
                    shadows: [Shadow(color: Color(0xFF080403), blurRadius: 2)],
                  ),
                ),
              if (field.mandatory && !isFilled)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.star_rounded, color: _gold, size: 13),
                ),
              Text(
                key: isComplete && !isSum
                    ? Key('dragon-field-done-$index')
                    : null,
                isFilled ? _placedLabel : _label,
                style: TextStyle(
                  color: isComplete && !isSum
                      ? const Color(0xFFD6B77A)
                      : const Color(0xFFFFF2D1),
                  fontSize: isFilled ? 20 : 21,
                  height: .95,
                  fontWeight: FontWeight.w900,
                  shadows: isComplete && !isSum
                      ? null
                      : const [
                          Shadow(
                            color: Color(0xFF080403),
                            blurRadius: 3,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                  decoration: isComplete && !isSum
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: accent,
                  decorationThickness: 2.5,
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
    if (field.kind == DragonFieldKind.sum) {
      return '${field.remainingTarget(p.sum, reduction: reduction)}';
    }
    if (p.values.length == 1) {
      return '${p.values.single}';
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
      return '$effective';
    }
    return switch (field.kind) {
      DragonFieldKind.number => '${field.number}',
      DragonFieldKind.flame => '6',
      DragonFieldKind.empty => '🔥',
      DragonFieldKind.coloredDie => '${field.number}',
      DragonFieldKind.sum => '${field.sumTarget}',
      DragonFieldKind.bossHp => '♥${field.bossHp}',
    };
  }

  Color _fieldBgColor(DragonField field) {
    if (field.kind == DragonFieldKind.coloredDie && field.dieColor != null) {
      return _dieColor(field.dieColor!).withValues(alpha: .3);
    }
    return const Color(0xFF1A2B3C);
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    final paint = Paint()
      ..color = color.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 8) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
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
        border: Border.all(color: _muted.withValues(alpha: .3)),
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
              : 'Würfel wählen → Feld antippen. Σ-Felder: ein Würfel pro Wurf.',
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFFFE8B0)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? const Color(0xFFFFD54A) : color,
              width: selected ? 4 : 3,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
              if (selected)
                const BoxShadow(
                  color: Color(0xCCFFD54A),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
            ],
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
                '${die.value}',
                style: const TextStyle(
                  fontSize: 31,
                  height: .95,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A0D08),
                  shadows: [
                    Shadow(color: Color(0x55FFFFFF), offset: Offset(0, 1)),
                  ],
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
          Material(
            key: Key('dragon-ability-${ability.name}'),
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAbilityDialog(context, ability),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8A4A22), Color(0xFF30140A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDDAE4B),
                    width: 1.4,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x77000000),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    Icon(_abilityIcon(ability), size: 16, color: _deepGold),
                    const SizedBox(width: 6),
                    Text(
                      _plainAbilityLabel(context, ability),
                      style: const TextStyle(
                        color: Color(0xFFFFE6A6),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _plainAbilityLabel(BuildContext context, DragonAbility ability) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return switch (ability) {
      DragonAbility.reroll => english ? 'Reroll' : 'Neu würfeln',
      DragonAbility.reduce => english ? 'Scale & Gold' : 'Reduzieren',
      DragonAbility.handicap =>
        english ? 'Weaken opponent' : 'Gegner schwächen',
    };
  }

  IconData _abilityIcon(DragonAbility ability) => switch (ability) {
    DragonAbility.reroll => Icons.refresh_rounded,
    DragonAbility.reduce => Icons.vertical_align_bottom_rounded,
    DragonAbility.handicap => Icons.track_changes_rounded,
  };

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
      height: 62 + (textScale - 1).clamp(0, 1) * 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.players.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final player = state.players[index];
          final active = index == state.activePlayerIndex;
          return Container(
            key: Key('dragon-parchment-player-$index'),
            width: 142,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: active
                    ? [const Color(0xFFFFE0A1), const Color(0xFFC98A36)]
                    : [const Color(0xFFF5D493), const Color(0xFFB97832)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? _deepGold : const Color(0xFF52290F),
                width: active ? 2 : 1.3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
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
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: _gold,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${player.gold}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: _deepGold,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${player.tamedCount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
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

    return KeyedSubtree(
      key: const Key('dragon-action-frame'),
      child: Material(
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
                      _WoodActionFrame(child: actions[i]),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: _WoodActionFrame(child: actions[i]),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _WoodActionFrame extends StatelessWidget {
  const _WoodActionFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      image: const DecorationImage(
        image: AssetImage('assets/images/schuppenschatz/wood_action_frame.png'),
        fit: BoxFit.fill,
      ),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x227E4728), Color(0x553D1F13)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1D1512), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x77000000),
          blurRadius: 4,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Theme(
      data: Theme.of(context).copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFFFE8BC),
            disabledForegroundColor: const Color(0xFFB7A28A),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            textStyle: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFE8BC),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            textStyle: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
      child: child,
    ),
  );
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
            child: Text('$value', style: const TextStyle(fontSize: 20)),
          ),
      ],
    ),
  );
}

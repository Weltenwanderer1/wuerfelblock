import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

// ---------------------------------------------------------------------------
// Domain: Regicide enemies (Jacks / Queens / Kings)
// ---------------------------------------------------------------------------

enum RegicideRank { jack, queen, king }

extension RegicideRankData on RegicideRank {
  String get germanLabel {
    switch (this) {
      case RegicideRank.jack:
        return 'Bube';
      case RegicideRank.queen:
        return 'Dame';
      case RegicideRank.king:
        return 'König';
    }
  }

  int get baseAttack {
    switch (this) {
      case RegicideRank.jack:
        return 10;
      case RegicideRank.queen:
        return 15;
      case RegicideRank.king:
        return 20;
    }
  }

  int get baseHealth {
    switch (this) {
      case RegicideRank.jack:
        return 20;
      case RegicideRank.queen:
        return 30;
      case RegicideRank.king:
        return 40;
    }
  }

  IconData get icon {
    switch (this) {
      case RegicideRank.jack:
        return Icons.cruelty_free_outlined;
      case RegicideRank.queen:
        return Icons.auto_awesome_outlined;
      case RegicideRank.king:
        return Icons.shield_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RegicideRank.jack:
        return AppColors.sage;
      case RegicideRank.queen:
        return AppColors.lavender;
      case RegicideRank.king:
        return AppColors.rose;
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RegicideCounterScreen extends StatefulWidget {
  const RegicideCounterScreen({super.key});

  @override
  State<RegicideCounterScreen> createState() => _RegicideCounterScreenState();
}

class _RegicideCounterScreenState extends State<RegicideCounterScreen> {
  // Current enemy being fought
  RegicideRank _currentRank = RegicideRank.jack;
  int _currentSuitIndex = 0; // 0=Hearts,1=Diamonds,2=Clubs,3=Spades
  int _damageDealt = 0;
  int _attackReduction = 0; // spade shield

  // Castle tracking: how many of each rank defeated (0-4)
  final List<int> _defeated = [0, 0, 0]; // jack, queen, king

  static const _suits = ['♥', '♦', '♣', '♠'];
  static const _suitNames = ['Herz', 'Karo', 'Kreuz', 'Pik'];

  int get _currentHealth => _currentRank.baseHealth;
  int get _currentAttack =>
      (_currentRank.baseAttack - _attackReduction).clamp(0, 99);
  int get _remainingHealth =>
      (_currentHealth - _damageDealt).clamp(0, _currentHealth);
  double get _healthFraction =>
      _currentHealth == 0 ? 0 : _remainingHealth / _currentHealth;

  void _nextEnemy() {
    setState(() {
      final rankIndex = _currentRank.index;
      _defeated[rankIndex]++;
      if (_defeated[rankIndex] >= 4 && rankIndex < 2) {
        // Move to next rank
        _currentRank = RegicideRank.values[rankIndex + 1];
        _defeated[rankIndex] = 4; // cap
      } else if (_defeated[rankIndex] >= 4 && rankIndex == 2) {
        // All kings defeated — game won! Stay on king
        _defeated[rankIndex] = 4;
      }
      _damageDealt = 0;
      _attackReduction = 0;
      _currentSuitIndex = 0;
    });
  }

  void _resetAll() {
    setState(() {
      _currentRank = RegicideRank.jack;
      _defeated[0] = 0;
      _defeated[1] = 0;
      _defeated[2] = 0;
      _damageDealt = 0;
      _attackReduction = 0;
      _currentSuitIndex = 0;
    });
  }

  bool get _gameWon => _defeated[2] >= 4;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Regicide Gegner-Zähler'),
      actions: [
        IconButton(
          key: const Key('regicide-reset'),
          icon: const Icon(Icons.restart_alt),
          tooltip: localizeText(context, 'Zurücksetzen'),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const LocalizedText('Zurücksetzen?'),
              content: const LocalizedText(
                'Alle Fortschritte löschen und von vorne beginnen?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const LocalizedText('Abbrechen'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resetAll();
                  },
                  child: const LocalizedText('Zurücksetzen'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // Castle progress overview
              _buildCastleOverview(),
              const SizedBox(height: 16),
              if (_gameWon)
                _buildVictoryBanner()
              else ...[
                // Current enemy card
                _buildEnemyCard(),
                const SizedBox(height: 16),
                // Damage controls
                _buildDamageControls(),
                const SizedBox(height: 16),
                // Defeated button
                _buildDefeatedButton(),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // Castle overview — 3 rows showing defeated enemies
  // -------------------------------------------------------------------------

  Widget _buildCastleOverview() => Card(
    key: const Key('regicide-castle-overview'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LocalizedText(
            'Schloss',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          // Kings (bottom row)
          _buildRankRow(RegicideRank.king),
          const SizedBox(height: 6),
          // Queens (middle row)
          _buildRankRow(RegicideRank.queen),
          const SizedBox(height: 6),
          // Jacks (top row)
          _buildRankRow(RegicideRank.jack),
        ],
      ),
    ),
  );

  Widget _buildRankRow(RegicideRank rank) {
    final defeated = _defeated[rank.index];
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: LocalizedText(
            rank.germanLabel,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: rank.color,
              fontSize: 13,
            ),
          ),
        ),
        ...List.generate(4, (i) {
          final isDefeated = i < defeated;
          final isCurrent =
              !isDefeated && rank == _currentRank && i == defeated && !_gameWon;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedContainer(
              key: Key('castle-${rank.name}-$i'),
              duration: const Duration(milliseconds: 300),
              width: 34,
              height: 44,
              decoration: BoxDecoration(
                color: isDefeated
                    ? rank.color.withValues(alpha: 0.25)
                    : isCurrent
                    ? rank.color.withValues(alpha: 0.5)
                    : AppColors.plum.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent
                      ? rank.color
                      : AppColors.plum.withValues(alpha: 0.2),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Center(
                child: isDefeated
                    ? Icon(Icons.check, size: 18, color: rank.color)
                    : Icon(
                        rank.icon,
                        size: 16,
                        color: isCurrent
                            ? rank.color
                            : AppColors.plum.withValues(alpha: 0.35),
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Current enemy card — playing card style
  // -------------------------------------------------------------------------

  Widget _buildEnemyCard() {
    final rank = _currentRank;
    final suit = _suits[_currentSuitIndex];
    final suitName = _suitNames[_currentSuitIndex];
    final isRedSuit = _currentSuitIndex < 2;

    return Card(
      key: const Key('regicide-enemy-card'),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: rank.color, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rank.color.withValues(alpha: 0.15),
              Colors.white,
              rank.color.withValues(alpha: 0.08),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Suit selector
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(4, (i) {
                final selected = i == _currentSuitIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    key: Key('suit-$i'),
                    label: Text(
                      _suits[i],
                      style: TextStyle(
                        fontSize: 18,
                        color: i < 2 ? AppColors.rose : AppColors.plum,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.lavender.withValues(alpha: 0.5),
                    onSelected: (_) => setState(() => _currentSuitIndex = i),
                    tooltip: localizeText(context, _suitNames[i]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Card display
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                // Big suit symbol
                Text(
                  suit,
                  style: TextStyle(
                    fontSize: 48,
                    color: isRedSuit ? AppColors.rose : AppColors.plum,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      '${rank.germanLabel} $suit',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    LocalizedText(
                      suitName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.plum.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Health bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: LocalizedText(
                        'Gesundheit',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.plum.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      '$_remainingHealth / $_currentHealth',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    key: const Key('regicide-health-bar'),
                    value: _healthFraction,
                    minHeight: 14,
                    backgroundColor: AppColors.plum.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _healthFraction > 0.5
                          ? AppColors.sage
                          : _healthFraction > 0.25
                          ? AppColors.apricot
                          : AppColors.rose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Attack display
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.flash_on, size: 20, color: AppColors.apricot),
                const SizedBox(width: 6),
                LocalizedText(
                  'Angriff',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.plum.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_currentAttack',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                if (_attackReduction > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '♠ −$_attackReduction',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.plum,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Damage controls
  // -------------------------------------------------------------------------

  Widget _buildDamageControls() => Card(
    key: const Key('regicide-damage-controls'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LocalizedText(
            'Schaden zufügen',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [1, 2, 3, 5, 10])
                _DamageChip(
                  label: '+$value',
                  onTap: () => setState(() {
                    _damageDealt = (_damageDealt + value).clamp(
                      0,
                      _currentHealth,
                    );
                  }),
                ),
              _DamageChip(
                label: localizeText(context, '−1'),
                onTap: () => setState(() {
                  _damageDealt = (_damageDealt - 1).clamp(0, _currentHealth);
                }),
              ),
              _DamageChip(
                label: localizeText(context, 'Reset'),
                onTap: () => setState(() => _damageDealt = 0),
                isReset: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LocalizedText(
            'Pik-Schild (Angriff senken)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [1, 2, 3, 5])
                _DamageChip(
                  label: '♠ −$value',
                  onTap: () => setState(() {
                    _attackReduction = (_attackReduction + value).clamp(
                      0,
                      _currentRank.baseAttack,
                    );
                  }),
                  isSpade: true,
                ),
              _DamageChip(
                label: localizeText(context, '♠ Reset'),
                onTap: () => setState(() => _attackReduction = 0),
                isReset: true,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // Defeated button
  // -------------------------------------------------------------------------

  Widget _buildDefeatedButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton.icon(
      key: const Key('regicide-defeated-btn'),
      onPressed: _nextEnemy,
      icon: const Icon(Icons.emoji_events),
      label: const LocalizedText('Gegner besiegt!'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sage,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // Victory banner
  // -------------------------------------------------------------------------

  Widget _buildVictoryBanner() => Card(
    key: const Key('regicide-victory'),
    color: AppColors.sage.withValues(alpha: 0.2),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 56, color: AppColors.sage),
          const SizedBox(height: 12),
          const LocalizedText(
            'Schloss erobert!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const LocalizedText(
            'Alle 12 Gegner besiegt. Ihr habt Regicide gewonnen!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _resetAll,
            icon: const Icon(Icons.restart_alt),
            label: const LocalizedText('Neues Spiel'),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Damage chip widget
// ---------------------------------------------------------------------------

class _DamageChip extends StatelessWidget {
  const _DamageChip({
    required this.label,
    required this.onTap,
    this.isReset = false,
    this.isSpade = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isReset;
  final bool isSpade;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isReset
            ? AppColors.plum.withValues(alpha: 0.08)
            : isSpade
            ? AppColors.lavender.withValues(alpha: 0.3)
            : AppColors.apricot.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReset
              ? AppColors.plum.withValues(alpha: 0.3)
              : isSpade
              ? AppColors.lavender
              : AppColors.apricot,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
  );
}

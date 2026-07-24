import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

// ---------------------------------------------------------------------------
// Domain: Regicide enemies (Jacks / Queens / Kings)
// ---------------------------------------------------------------------------

enum RegicideRank { jack, queen, king }

extension RegicideRankData on RegicideRank {
  String get germanLabel => switch (this) {
    RegicideRank.jack => 'Bube',
    RegicideRank.queen => 'Dame',
    RegicideRank.king => 'König',
  };

  /// Corner index letter (German card notation)
  String get cornerLetter => switch (this) {
    RegicideRank.jack => 'B',
    RegicideRank.queen => 'D',
    RegicideRank.king => 'K',
  };

  int get baseAttack => switch (this) {
    RegicideRank.jack => 10,
    RegicideRank.queen => 15,
    RegicideRank.king => 20,
  };

  int get baseHealth => switch (this) {
    RegicideRank.jack => 20,
    RegicideRank.queen => 30,
    RegicideRank.king => 40,
  };

  Color get color => switch (this) {
    RegicideRank.jack => AppColors.sage,
    RegicideRank.queen => AppColors.lavender,
    RegicideRank.king => AppColors.rose,
  };
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
  RegicideRank _currentRank = RegicideRank.jack;
  int _currentSuitIndex = 0; // 0=Hearts,1=Diamonds,2=Clubs,3=Spades
  int _damageDealt = 0;
  int _attackReduction = 0; // spade shield
  final List<int> _defeated = [0, 0, 0]; // jack, queen, king

  static const _suits = ['♥', '♦', '♣', '♠'];
  static const _suitNames = ['Herz', 'Karo', 'Kreuz', 'Pik'];

  // Keep-screen-on colours
  static const _shieldBlue = Color(0xFF1E88E5);
  static const _heartRed = Color(0xFFD32F2F);
  static const _swordGrey = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  int get _currentHealth => _currentRank.baseHealth;
  int get _currentAttack =>
      (_currentRank.baseAttack - _attackReduction).clamp(0, 99);
  int get _remainingHealth =>
      (_currentHealth - _damageDealt).clamp(0, _currentHealth);

  bool get _gameWon => _defeated[2] >= 4;

  void _nextEnemy() {
    setState(() {
      final rankIndex = _currentRank.index;
      _defeated[rankIndex]++;
      if (_defeated[rankIndex] >= 4 && rankIndex < 2) {
        _currentRank = RegicideRank.values[rankIndex + 1];
      }
      _defeated[rankIndex] = _defeated[rankIndex].clamp(0, 4);
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

  /// Shows a dialog with a number input, calls [onSubmit] with the entered value.
  Future<void> _showNumberDialog({
    required String title,
    IconData? icon,
    String? iconText,
    required Color iconColor,
    required ValueChanged<int> onSubmit,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            if (iconText != null)
              Text(
                iconText,
                style: TextStyle(fontSize: 24, color: iconColor, height: 1.0),
              )
            else if (icon != null)
              Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Expanded(child: LocalizedText(title)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            hintText: '0',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onSubmitted: (value) =>
              Navigator.pop(dialogContext, int.tryParse(value) ?? 0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const LocalizedText('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(controller.text) ?? 0,
            ),
            child: const LocalizedText('OK'),
          ),
        ],
      ),
    );
    if (result != null) onSubmit(result);
  }

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
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _buildCastleOverview(),
              const SizedBox(height: 16),
              if (_gameWon)
                _buildVictoryBanner()
              else ...[
                _buildEnemyCard(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 12),
                _buildDefeatedButton(),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  // -------------------------------------------------------------------------
  // Castle overview
  // -------------------------------------------------------------------------

  Widget _buildCastleOverview() => Card(
    key: const Key('regicide-castle-overview'),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const LocalizedText(
            'Schloss',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _buildRankRow(RegicideRank.king),
          const SizedBox(height: 6),
          _buildRankRow(RegicideRank.queen),
          const SizedBox(height: 6),
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
          width: 52,
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
                        rank == RegicideRank.jack
                            ? Icons.cruelty_free_outlined
                            : rank == RegicideRank.queen
                            ? Icons.auto_awesome_outlined
                            : Icons.shield_outlined,
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
  // Enemy card — playing-card style per user's sketch
  // Corner indices (rank+suit in all 4 corners), center stats (♥ HP, ⚔ ATK)
  // -------------------------------------------------------------------------

  Widget _buildEnemyCard() {
    final rank = _currentRank;
    final suit = _suits[_currentSuitIndex];
    final isRedSuit = _currentSuitIndex < 2;
    final suitColor = isRedSuit ? AppColors.rose : AppColors.plum;
    final indexLabel = '${rank.cornerLetter}$suit';

    return Card(
      key: const Key('regicide-enemy-card'),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: rank.color, width: 2.5),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rank.color.withValues(alpha: 0.12),
              Colors.white,
              rank.color.withValues(alpha: 0.06),
            ],
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Suit selector row
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              children: List.generate(4, (i) {
                final selected = i == _currentSuitIndex;
                return ChoiceChip(
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
                );
              }),
            ),
            const SizedBox(height: 14),
            // Playing card face
            AspectRatio(
              aspectRatio: 5 / 7,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.plum.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: rank.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Top-left corner index
                    Positioned(
                      top: 10,
                      left: 12,
                      child: _CornerIndex(label: indexLabel, color: suitColor),
                    ),
                    // Top-right corner index
                    Positioned(
                      top: 10,
                      right: 12,
                      child: _CornerIndex(label: indexLabel, color: suitColor),
                    ),
                    // Bottom-left corner index
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: _CornerIndex(label: indexLabel, color: suitColor),
                    ),
                    // Bottom-right corner index
                    Positioned(
                      bottom: 10,
                      right: 12,
                      child: _CornerIndex(label: indexLabel, color: suitColor),
                    ),
                    // Center stats — Attack on top, Health below
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Attack: ⚔ + value
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                MdiIcons.swordCross,
                                color: _swordGrey,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_currentAttack',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
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
                                    color: _shieldBlue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '♠−$_attackReduction',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Health: ♥ + remaining
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: _heartRed,
                                size: 39,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_remainingHealth',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Action buttons — Attack (number input) and Shield (number input)
  // -------------------------------------------------------------------------

  Widget _buildActionButtons() => Row(
    children: [
      // Attack button
      Expanded(
        child: _ActionButton(
          key: const Key('regicide-attack-btn'),
          icon: MdiIcons.swordCross,
          iconColor: _swordGrey,
          label: 'Angriff',
          onTap: () => _showNumberDialog(
            title: 'Angriff eingeben',
            icon: MdiIcons.swordCross,
            iconColor: _swordGrey,
            onSubmit: (value) => setState(() {
              _damageDealt = (_damageDealt + value).clamp(0, _currentHealth);
            }),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Shield button
      Expanded(
        child: _ActionButton(
          key: const Key('regicide-shield-btn'),
          icon: Icons.shield,
          iconColor: _shieldBlue,
          label: 'Schild',
          onTap: () => _showNumberDialog(
            title: 'Schild eingeben',
            icon: Icons.shield,
            iconColor: _shieldBlue,
            onSubmit: (value) => setState(() {
              _attackReduction = (_attackReduction + value).clamp(
                0,
                _currentRank.baseAttack,
              );
            }),
          ),
        ),
      ),
    ],
  );

  // -------------------------------------------------------------------------
  // Defeated button
  // -------------------------------------------------------------------------

  Widget _buildDefeatedButton() => SizedBox(
    width: double.infinity,
    height: 54,
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
// Corner index widget (rank letter + suit symbol, like a real playing card)
// ---------------------------------------------------------------------------

class _CornerIndex extends StatelessWidget {
  const _CornerIndex({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label[0],
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.1,
        ),
      ),
      Text(
        label.substring(1),
        style: TextStyle(fontSize: 21, color: color, height: 1.1),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Action button (square icon button with label)
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 4),
          LocalizedText(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: iconColor,
            ),
          ),
        ],
      ),
    ),
  );
}

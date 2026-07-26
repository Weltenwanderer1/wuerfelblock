import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';
import '../core/app_theme.dart';
import '../models/saved_game_state.dart';
import '../services/locale_controller.dart';
import 'about_privacy_screen.dart';
import 'rules_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.savedGame,
    required this.onNewGame,
    required this.onContinue,
    required this.localeController,
    super.key,
  });
  final SavedGameState? savedGame;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Semantics(
                  label: localizeText(context, 'Würfelblock Logo mit Würfeln'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoDie(value: '⚄', color: AppColors.rose, turn: -0.12),
                      SizedBox(width: 8),
                      _LogoDie(
                        value: '⚂',
                        color: AppColors.lavender,
                        turn: 0.1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LocalizedText(
                  'Würfelblock',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                LocalizedText(
                  'Der schöne Wertungsblock für Yahtzee/Kniffel, Colordice, 10.000, Balut, Escalero und Drachengold',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (savedGame != null) ...[
                  Card(
                    color: AppColors.lavender,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.play_circle_fill,
                        size: 40,
                        color: AppColors.plum,
                      ),
                      title: const LocalizedText(
                        'Partie fortsetzen',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: LocalizedText(
                        '${savedGame!.gameLabel} · ${savedGame!.modeLabel}\n${savedGame!.progressLabel}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onContinue,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: onNewGame,
                  icon: const Icon(Icons.add),
                  label: const LocalizedText('Neue Partie'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('rules-action'),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RulesSelectionScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const LocalizedText('Spielregeln'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('settings-about-action'),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AboutPrivacyScreen(
                        localeController: localeController,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  label: const LocalizedText('Einstellungen & Info'),
                ),
                const SizedBox(height: 20),
                const LocalizedText(
                  '100 % offline · werbefrei · ohne Konto',
                  style: TextStyle(
                    color: AppColors.plum,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LogoDie extends StatelessWidget {
  const _LogoDie({
    required this.value,
    required this.color,
    required this.turn,
  });
  final String value;
  final Color color;
  final double turn;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: turn,
    child: Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LocalizedText(
        value,
        style: const TextStyle(fontSize: 54, color: AppColors.plum, height: 1),
      ),
    ),
  );
}

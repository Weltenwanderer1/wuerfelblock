import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../models/saved_game_state.dart';
import 'balut_rules_screen.dart';
import 'card_games_rules_screen.dart';
import 'qwixx_rules_screen.dart';
import 'rules_screen.dart';
import 'ten_thousand_rules_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.savedGame,
    required this.onNewGame,
    required this.onContinue,
    super.key,
  });
  final SavedGameState? savedGame;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;

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
                  label: 'Würfelblock Logo mit Würfeln',
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
                Text(
                  'Würfelblock',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Der schöne Wertungsblock für Yahtzee/Kniffel, Qwixx, 10.000 und Balut',
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
                      title: const Text(
                        'Partie fortsetzen',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
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
                  label: const Text('Neue Partie'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const RulesScreen(ruleSet: RuleSet.kniffel),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Yahtzee/Kniffel-Regeln'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QwixxRulesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Qwixx-Regeln'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TenThousandRulesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('10.000-Regeln'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BalutRulesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Balut-Regeln'),
                    ),
                    TextButton.icon(
                      key: const Key('card-games-rules-action'),
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CardGamesRulesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Spielregeln'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
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
      child: Text(
        value,
        style: const TextStyle(fontSize: 54, color: AppColors.plum, height: 1),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';
import 'balut_rules_screen.dart';
import 'card_games_rules_screen.dart';
import 'escalero_rules_screen.dart';
import 'colordice_rules_screen.dart';
import 'rules_screen.dart';
import 'schuppenschatz_rules_screen.dart';
import 'ten_thousand_rules_screen.dart';

class RulesSelectionScreen extends StatelessWidget {
  const RulesSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Spielregeln')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        LocalizedText(
          'Welche Spielanleitung möchtest du öffnen?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _RuleLink(
          key: Key('rules-link-yahtzee'),
          title: 'Yahtzee/Kniffel',
          subtitle: 'Klassischer Würfelspaß als Block oder digital',
          icon: Icons.casino_outlined,
          accent: AppColors.rose,
          ruleScreen: RulesScreen(ruleSet: RuleSet.kniffel),
        ),
        const _RuleLink(
          key: Key('rules-link-colordice'),
          title: 'Colordice',
          subtitle: 'Farbreihen als Block oder digital',
          icon: Icons.grid_3x3_outlined,
          accent: AppColors.lavender,
          ruleScreen: ColordiceRulesScreen(),
        ),
        const _RuleLink(
          key: Key('rules-link-ten-thousand'),
          title: '10.000',
          subtitle: 'Punktejagd als Block oder digital',
          icon: Icons.casino_outlined,
          accent: AppColors.apricot,
          ruleScreen: TenThousandRulesScreen(),
        ),
        const _RuleLink(
          key: Key('rules-link-balut'),
          title: 'Balut',
          subtitle: '28 Wertungen pro Person',
          icon: Icons.table_rows_outlined,
          accent: AppColors.rose,
          ruleScreen: BalutRulesScreen(),
        ),
        const _RuleLink(
          key: Key('rules-link-escalero'),
          title: 'Escalero',
          subtitle: 'Pokerwürfel und drei Kolonnen',
          icon: Icons.casino_outlined,
          accent: AppColors.lavender,
          ruleScreen: EscaleroRulesScreen(),
        ),
        const _RuleLink(
          key: Key('rules-link-schuppenschatz'),
          title: 'Schuppenschatz',
          subtitle: 'Drachen zähmen, Gold sichern, Risiko wagen',
          icon: Icons.local_fire_department_outlined,
          accent: AppColors.apricot,
          ruleScreen: SchuppenschatzRulesScreen(),
        ),
        const SizedBox(height: 12),
        LocalizedText(
          'Kartenspiele',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const _RuleLink(
          key: Key('rules-link-crisps'),
          title: 'Crisps!',
          subtitle: 'Kletter- und Ablegespiel für 2 Personen',
          icon: Icons.layers_outlined,
          accent: AppColors.rose,
          ruleScreen: CardGameRulesScreen(game: CardGame.crisps),
        ),
        const _RuleLink(
          key: Key('rules-link-regicide'),
          title: 'Regicide',
          subtitle: 'Kooperativ gegen das Schloss',
          icon: Icons.shield_outlined,
          accent: AppColors.lavender,
          ruleScreen: CardGameRulesScreen(game: CardGame.regicide),
        ),
        const _RuleLink(
          key: Key('rules-link-haggis'),
          title: 'Haggis',
          subtitle: 'Kombinationen, Stiche und Wetten',
          icon: Icons.style_outlined,
          accent: AppColors.apricot,
          ruleScreen: CardGameRulesScreen(game: CardGame.haggis),
        ),
      ],
    ),
  );
}

class _RuleLink extends StatelessWidget {
  const _RuleLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.ruleScreen,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget ruleScreen;

  @override
  Widget build(BuildContext context) => Card(
    color: accent,
    margin: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      button: true,
      label: localizeText(context, '$title: $subtitle'),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: AppColors.plum, size: 30),
        title: LocalizedText(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: LocalizedText(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.plum),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => ruleScreen),
        ),
      ),
    ),
  );
}

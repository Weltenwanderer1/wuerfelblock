import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Regelhilfe')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _RuleCard(
          title: 'So wird gespielt',
          color: AppColors.apricot,
          text:
              'Pro Zug darfst du bis zu dreimal würfeln. Nach jedem Wurf kannst du Würfel festhalten. Danach wird genau eine freie Kategorie gewertet – auch mit 0 Punkten zum Streichen.',
        ),
        _RuleCard(
          title: 'Oberer Block',
          color: AppColors.rose,
          text:
              'Addiere jeweils alle Einser bis Sechser. Ab 63 Punkten gibt es bei Yatzy 50 Bonuspunkte, bei Kniffel 35.',
        ),
        _RuleCard(
          title: 'Kniffel',
          color: AppColors.lavender,
          text:
              'Dreier- und Viererpasch zählen die Summe aller Würfel. Full House: 25, kleine Straße: 30, große Straße: 40, Kniffel: 50. Jeder zweite und weitere Kniffel bringt 50 Zusatzpunkte; zusätzlich darf ein freies Feld mit seiner Höchstpunktzahl belegt werden.',
        ),
        _RuleCard(
          title: 'Yatzy klassisch',
          color: AppColors.lavender,
          text:
              'Höchstes Paar; zwei verschiedene Paare – ein Viererpasch zählt nicht als zwei Paare. Pasche zählen nur passende Würfel. Straßen 1–5: 15 und 2–6: 20. Full House zählt die Würfelsumme, Yatzy 50. Im klassischen Yatzy gibt es keinen Zusatz-Yatzy-Bonus.',
        ),
      ],
    ),
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.text,
    required this.color,
  });
  final String title;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}

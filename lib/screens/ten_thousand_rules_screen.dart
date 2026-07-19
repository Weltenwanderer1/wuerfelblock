import 'package:flutter/material.dart';

import '../widgets/ten_thousand_score_sheet.dart';

class TenThousandRulesScreen extends StatelessWidget {
  const TenThousandRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Ziel & Material',
      'Spielt mit fünf echten Würfeln und sammelt als erste Person mindestens 10.000 Punkte. Traditionell gibt es unterschiedliche Angaben zur Gruppengröße; der praktische App-Block unterstützt 2–8 Personen.',
      Icons.casino_outlined,
    ),
    (
      'Werten und aufhören',
      'Eine 1 zählt 100 Punkte, eine 5 zählt 50 Punkte. Nach einem wertbaren Wurf darfst du Punkte sichern und jederzeit aufhören. Wer weiterwürfelt, riskiert die noch ungesicherten Punkte.',
      Icons.savings_outlined,
    ),
    (
      'Fehlwurf',
      'Zeigt ein Wurf keine wertbare Kombination, ist das ein Fehlwurf: Du verlierst alle ungesicherten Punkte dieser Runde. Bereits in früheren Runden eingetragene Punkte bleiben erhalten.',
      Icons.block,
    ),
    (
      'Pasch bestätigen',
      'Ein besonderer Pasch reicht nicht allein: Danach brauchst du noch einen wertbaren Wurf, um ihn zu bestätigen und die Runde sichern zu dürfen. Misslingt dieser Bestätigungswurf, verfallen die ungesicherten Rundenpunkte.',
      Icons.check_circle_outline,
    ),
    (
      'Kombinationen',
      'Ein Dreierpasch zählt Augenwert × 100; drei Einsen zählen 1.000 Punkte. Jeder weitere gleiche Würfel verdoppelt den Paschwert: Vier Zweien zählen 400 Punkte, vier Einsen 2.000 Punkte. Fünf gleiche Würfel verdoppeln erneut. Die Straße 1–2–3–4–5 zählt 2.000 Punkte.',
      Icons.format_list_numbered,
    ),
    (
      'Letzte Runde',
      'Wer zuerst mindestens 10.000 erreicht, löst die Schlussrunde aus. Jede andere Person erhält genau einen letzten Versuch. Danach gewinnt die höchste Gesamtsumme; Gleichstände sind möglich.',
      Icons.flag_outlined,
    ),
    (
      'Die App als Block',
      'Diese App ist ein manueller Punkteblock. Sie sieht keine Würfel, prüft keine Würfe und berechnet Kombinationen nicht automatisch. Tragt die nach der Verdopplungsregel gesicherten Rundenpunkte ein; „Fehlwurf (0)“ dokumentiert eine Runde ohne Punkte.',
      Icons.edit_note,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8E8),
    appBar: AppBar(title: const Text('10.000-Regeln')),
    body: SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '10.000 schnell erklärt',
              style: TextStyle(
                color: tenThousandInk,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Echte Würfel, klare Verdopplungsregel – die App bleibt euer übersichtlicher Papierblock.',
              style: TextStyle(fontSize: 16, height: 1.35),
            ),
            const SizedBox(height: 14),
            for (final section in sections)
              _RuleSection(
                title: section.$1,
                text: section.$2,
                icon: section.$3,
              ),
          ],
        ),
      ),
    ),
  );
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tenThousandPaper,
      border: Border.all(color: tenThousandInk, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: tenThousandInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tenThousandInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(text, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

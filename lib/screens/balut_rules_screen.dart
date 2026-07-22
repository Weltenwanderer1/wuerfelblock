import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../core/app_theme.dart';

const _balutInk = Color(0xFF2D2923);

class BalutRulesScreen extends StatelessWidget {
  const BalutRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Ziel & Material',
      'Gespielt wird mit fünf Würfeln – echt im Blockmodus oder digital in der App. Unterstützt werden 2 bis 8 Personen. Jede Person füllt sieben Kategorien mit jeweils vier Wertungen, also 28 Einträge pro Block.',
      Icons.casino_outlined,
    ),
    (
      'Kategorien',
      'Vierer: nur Vierer (4–20). Fünfer: nur Fünfer (5–25). Sechser: nur Sechser (6–30). Straßen: 1–5 = 15, 2–6 = 20. Full House: genau Drilling + Paar, die Augensumme zählt. Choice: jede Augensumme. Balut: fünf gleiche, 20 plus Augensumme. Ein Strich (0) ist in jeder Kategorie erlaubt.',
      Icons.format_list_numbered,
    ),
    (
      'Würfeln, halten und werten',
      'Pro Zug darfst du bis zu dreimal würfeln. Nach jedem Wurf kannst du Würfel halten, nur die übrigen werden neu gewürfelt. Danach wertest du den Wurf in genau einer offenen Kategorie – auch 0 (Strich) ist erlaubt. Die App prüft automatisch, ob die gewählte Kategorie zum Wurf passt.',
      Icons.casino,
    ),
    (
      'Incentive-Punkte',
      'Diese Extrapunkte kommen zur Rohwertung dazu:\n• Vierer gesamt mindestens 52: +2\n• Fünfer gesamt mindestens 65: +2\n• Sechser gesamt mindestens 78: +2\n• Alle 4 Straßen ohne Strich: +4\n• Alle 4 Full Houses ohne Strich: +3\n• Choice gesamt mindestens 100: +2\n• Jeder Balut ohne Strich: +2\n• Roh-Gesamtwert: unter 300 = −2, 300–349 = −1, 350–399 = 0, dann je 50 Punkte +1 bis maximal +6 ab 650.\nTheoretisches Maximum: 812 Rohpunkte + 29 Bonuspunkte.',
      Icons.workspace_premium,
    ),
    (
      'Sieg',
      'Es gewinnt, wer nach 28 Wertungen die meisten Punkte aus Roh- und Incentive-Punkten hat. Es gibt mehrere mögliche Siegerinnen und Sieger – die App listet alle mit Höchstwertung.',
      Icons.emoji_events,
    ),
    (
      'Block oder digitale Würfel',
      'Im Blockmodus tragt ihr die mit echten Würfeln geworfenen Ergebnisse selbst ein. Im Digitalmodus würfelt die App, ihr haltet per Tipp und die App wertet automatisch nach den offiziellen Regeln.',
      Icons.edit_note,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8E8),
    appBar: AppBar(title: const LocalizedText('Balut-Regeln')),
    body: SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocalizedText(
              'Balut schnell erklärt',
              style: TextStyle(
                color: _balutInk,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const LocalizedText(
              'Nach den offiziellen Regeln von Balut.org – als klassischer Block oder mit digitalen Würfeln.',
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
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.apricot,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.plum),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: LocalizedText(
                  title,
                  style: TextStyle(
                    color: _balutInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              LocalizedText(
                text,
                style: TextStyle(
                  color: _balutInk,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

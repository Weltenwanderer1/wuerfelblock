import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../widgets/ten_thousand_score_sheet.dart';

class TenThousandRulesScreen extends StatelessWidget {
  const TenThousandRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Ziel & Material',
      'Gespielt wird mit sechs Würfeln – echt im Blockmodus oder digital in der App. Unterstützt werden 2–8 Personen. Wer zuerst mindestens 10.000 Punkte erreicht, eröffnet die Schlussrunde.',
      Icons.casino_outlined,
    ),
    (
      'Punkte & Kombinationen',
      'Eine einzelne 1 zählt 100 Punkte, eine einzelne 5 zählt 50 Punkte; einzelne 2er, 3er, 4er und 6er zählen nichts. Dreierpasch: Augenwert × 100, drei Einsen zählen 1.000. Jeder weitere gleiche Würfel verdoppelt: Vier Zweien zählen 400 Punkte, vier Einsen 2.000 Punkte. Die Straße 1–2–3–4–5–6 zählt 1.000 Punkte, drei Paare zählen 500 Punkte.',
      Icons.format_list_numbered,
    ),
    (
      'Würfeln, sichern oder riskieren',
      'Du startest mit 6 Würfeln und legst nach jedem Wurf mindestens einen zählbaren Würfel oder eine Kombination beiseite. Mit den übrigen darfst du weiterwürfeln; die Punkte werden addiert. Einen Durchgang darfst du erst ab mindestens 350 Punkten aufschreiben. Beendest du ihn vorher freiwillig, wird eine Nullrunde eingetragen. Pasche dürfen über mehrere Würfe ergänzt werden: Jeder passende zusätzliche Würfel verdoppelt den Pasch erneut.',
      Icons.savings_outlined,
    ),
    (
      'Alle 6 Würfel zählen',
      'Sind alle 6 Würfel verwertbar, musst du mit allen 6 Würfeln weiterwürfeln. Das gilt besonders bei einer Straße oder drei Paaren: Der nächste Wurf muss mindestens 50 Punkte bringen. Gelingt er, werden die Punkte addiert; bei einer Macke verfallen alle Punkte dieses Durchgangs.',
      Icons.check_circle_outline,
    ),
    (
      'Macke',
      'Zeigt ein Wurf weder eine 1, eine 5 noch eine andere zählbare Kombination, ist das eine Macke. Alle bis dahin ungesicherten Punkte dieses Durchgangs verfallen und die nächste Person ist dran. Frühere Einträge bleiben natürlich stehen.',
      Icons.block,
    ),
    (
      'Hausbau & Brennen',
      'Liegen Würfel übereinander (Hausbau), schräg auf einer Kante oder fallen vom Tisch (Brennen), wird der gesamte Wurf wiederholt.',
      Icons.replay,
    ),
    (
      'Letzte Runde',
      'Sobald jemand mindestens 10.000 erreicht, dürfen die anderen noch nachwürfeln, bis die Person, die diese Schlussrunde begonnen hat, wieder an der Reihe wäre. Dann endet das Spiel. Es gewinnt die Person mit der höchsten Gesamtpunktzahl – also auch jemand, der erst beim Nachwürfeln überholt.',
      Icons.flag_outlined,
    ),
    (
      'Block oder digitale Würfel',
      'Im Blockmodus tragt ihr die mit echten Würfeln gesicherten Rundenpunkte selbst ein. Im Digitalmodus würfelt die App, ihr wählt die wertenden Würfel aus und die Kombinationen werden automatisch nach der Verdopplungsregel geprüft. Eine Macke beendet den ganzen Durchgang mit 0 Punkten.',
      Icons.edit_note,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF8E8),
    appBar: AppBar(title: const LocalizedText('10.000-Regeln')),
    body: SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LocalizedText(
              '10.000 schnell erklärt',
              style: TextStyle(
                color: tenThousandInk,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const LocalizedText(
              'Nach den Regeln der Berliner Würfelmeisterschaft – als klassischer Block oder mit digitalen Würfeln.',
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
              Semantics(
                header: true,
                child: LocalizedText(
                  title,
                  style: TextStyle(
                    color: tenThousandInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              LocalizedText(text, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

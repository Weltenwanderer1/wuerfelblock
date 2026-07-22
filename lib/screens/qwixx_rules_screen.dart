import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

class QwixxRulesScreen extends StatelessWidget {
  const QwixxRulesScreen({super.key});

  static const sections = <(String, String)>[
    (
      'Ziel & Material',
      'Qwixx nutzt zwei weiße und je einen roten, gelben, grünen und blauen Würfel. Ihr könnt mit echten Würfeln im Blockmodus oder direkt digital in der App spielen. Sammelt möglichst viele Kreuze und damit die meisten Punkte.',
    ),
    (
      'Von links nach rechts',
      'In jeder Farbreihe darfst du nur von links nach rechts ankreuzen. Du darfst Zahlen überspringen, aber übersprungene Felder sind für dich für immer verloren. Rot und Gelb laufen von 2 bis 12, Grün und Blau von 12 bis 2.',
    ),
    (
      'Aktion 1: Alle dürfen',
      'Die aktive Person würfelt alle sechs Würfel. Danach werden nur die beiden weißen Würfel addiert. Alle Personen dürfen – nacheinander und freiwillig – diese Summe in genau einer beliebigen Farbreihe ankreuzen.',
    ),
    (
      'Aktion 2: Nur die aktive Person',
      'Anschließend darf nur die aktive Person einen weißen Würfel mit genau einem Farbwürfel addieren und die Summe in der passenden Farbreihe ankreuzen. Auch diese Aktion ist freiwillig.',
    ),
    (
      'Fehlwurf',
      'Hat die aktive Person weder in Aktion 1 noch in Aktion 2 ein Kreuz gesetzt, muss sie einen Fehlwurf eintragen. Kreuze anderer Personen aus Aktion 1 verhindern diesen Fehlwurf nicht. Jeder Fehlwurf zählt minus 5 Punkte.',
    ),
    (
      'Reihe schließen',
      'Die letzte Zahl einer Reihe darfst du erst ankreuzen, wenn du davor mindestens fünf Kreuze in dieser Reihe hast. Dann kreuzt du zusätzlich das Schloss an: Es zählt als weiteres Kreuz. In Aktion 1 dürfen andere berechtigte Personen gleichzeitig dieselbe letzte Zahl ankreuzen, bevor die aktive Aktion und damit der Zug beendet wird. Danach ist die Farbe für alle geschlossen und der Farbwürfel wird aus dem Spiel genommen.',
    ),
    (
      'Spielende',
      'Das Spiel endet sofort, sobald eine Person ihren vierten Fehlwurf einträgt oder sobald insgesamt zwei Farbreihen geschlossen sind.',
    ),
    (
      'Punkte',
      'Pro Reihe zählen die Kreuze einschließlich Schloss: 0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66 oder 78 Punkte. Ziehe für jeden Fehlwurf 5 Punkte ab. Die höchste Gesamtsumme gewinnt; Gleichstände sind möglich.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Qwixx-Regeln')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LocalizedText(
            'Schnell erklärt',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const LocalizedText(
            'Für 2–5 Personen · Blockmodus oder digitale Würfel',
          ),
          const SizedBox(height: 16),
          for (final section in sections)
            Card(
              semanticContainer: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: LocalizedText(
                        section.$1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LocalizedText(section.$2),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

class SchuppenschatzRulesScreen extends StatelessWidget {
  const SchuppenschatzRulesScreen({super.key});

  static const sections = <(String, String, IconData)>[
    (
      'Spielidee',
      'Zähmt Drachen, sammelt Gold – und entscheidet klug, wann ihr aufhört. '
          'Wer zu gierig würfelt, verliert alles. '
          'Alle 7 Karten erscheint ein Boss-Drache! '
          'Nach der letzten Karte gewinnt, wer das meiste Gold besitzt.',
      Icons.emoji_events_outlined,
    ),
    (
      'Spielmaterial & Vorbereitung',
      '41 Drachenkarten (9 Wasser, 9 Feuer, 9 Glück, 9 Geister, 5 Bosse), '
          '48 Goldplättchen, 5 Würfel (2 weiß, 1 blau, 1 grün, 1 schwarz), 1 Bonuskarte (20 Gold). '
          'Mischt die Karten und legt sie als verdeckten Stapel bereit. '
          'Jeder 7. Platz im Stapel ist ein Boss-Drache.',
      Icons.deck_outlined,
    ),
    (
      'Die Würfel',
      '⚪ Weiß (×2): Normale Zahlen 1–5, Flamme bei 6.\n'
          '🔵 Blau (×1): Für blaue Felder (Wasserdrachen).\n'
          '🟢 Grün (×1): Für grüne Felder (Glücksdrachen).\n'
          '⚫ Schwarz (×1): Für schwarze Felder (Geisterdrachen).\n\n'
          'Farbwürfel-Felder brauchen exakt den richtigen Würfel mit der richtigen Augenzahl!',
      Icons.casino_outlined,
    ),
    (
      'Die Felder auf der Karte',
      'Zahlenfeld: braucht denselben Würfelwert oder eine Flamme (6).\n'
          '🔵/🟢/⚫ Farbfeld: braucht genau diesen Farbwürfel mit dieser Zahl.\n'
          '🔥 Flammenfeld: nur eine weiße 6.\n'
          '◇ Leeres Feld: jeder Würfel passt.\n'
          'Σ Summenfeld: 2–4 Würfel müssen exakt die Zielsumme ergeben.\n'
          '★ Pflichtfeld: muss belegt werden, bevor der Zug endet.',
      Icons.grid_view_rounded,
    ),
    (
      'Die vier Drachenarten',
      '💧 Wasserdrache (blau): Hat ein blaues Pflichtfeld – die Zahl muss mit dem blauen Würfel getroffen werden.\n\n'
          '🔥 Feuerdrache (rot): Immun gegen Flammen (keine 6 auf Zahlenfeldern). '
          'Hat ein Summenfeld aus 2–3 Würfeln.\n\n'
          '★ Glücksdrache (lila): Pflichtfelder + ein grünes Würfelfeld. '
          'Pflichtfelder müssen zuerst voll sein.\n\n'
          '👻 Geisterdrache (schwarz): Ein schwarzes Pflichtfeld + ein Summenfeld (2–4 Würfel). '
          'Zusätzlich 5–10 Bonuspunkte je nach Schwierigkeit.',
      Icons.auto_awesome,
    ),
    (
      'Dein Zug',
      '1. Würfle mit allen 5 Würfeln.\n'
          '2. Lege mindestens einen passenden Würfel auf die Karte.\n'
          '3. Entscheide: Weiterwürfeln oder Zug beenden?\n\n'
          'Weiterwürfeln: Wirf die übrigen Würfel erneut. '
          'Passt kein einziger Würfel → Zug sofort erfolglos beendet.\n\n'
          'Zug beenden: Du sicherst die Summe der gelegten Würfelaugen als Gold. '
          'Flammen zählen 0.',
      Icons.touch_app_outlined,
    ),
    (
      'Drachen weitergeben & zähmen',
      'Wurde ein Drache nicht gezähmt: Karte wandert zur nächsten Person, '
          'ein 5er-Goldplättchen kommt dazu.\n\n'
          'Hatten alle einen Versuch und niemand zähmt den Drachen → er entkommt.\n\n'
          'Drachen zähmen: Alle Felder belegt → du erhältst:\n'
          '• die Summe der Würfelaugen\n'
          '• alle Goldplättchen auf der Karte\n'
          '• Bonuspunkte (bei Geisterdrachen)\n'
          '• die Drachenkarte selbst',
      Icons.swap_horiz,
    ),
    (
      '🐉 Boss-Drache',
      'Alle 7 Karten erscheint ein Boss! Er hat 3–4 Felder mit hohen HP-Werten (z.B. 16/23/8).\n\n'
      'Jeder Spieler würfelt und reduziert mit seinen Würfeln die HP der Felder. '
          'Die Werte werden gespeichert und an den nächsten Spieler weitergegeben.\n\n'
      'Wer das letzte Feld auf genau 0 bringt, besiegt den Boss und erhält 20 Gold!\n\n'
      'Beispiel: Feld mit 16 HP → eine 6 reduziert auf 10, eine 4 auf 6, eine 6 auf 0 → besiegt!',
      Icons.cruelty_free_outlined,
    ),
    (
      '⚡ Fähigkeiten (1× pro Spieler/Spiel)',
      '🔄 Neu würfeln: Den letzten Wurf komplett neu würfeln.\n\n'
          '📉 Reduzieren: Eine Vorgabe auf der Karte um 1–3 Punkte senken.\n\n'
          '🎯 Gegner schwächen: Der nächste Spieler würfelt mit nur 3 statt 5 Würfeln.',
      Icons.bolt_outlined,
    ),
    (
      'Spielende & Sieg',
      'Das Spiel endet, sobald alle Drachenkarten abgehandelt sind.\n\n'
          'Die Person mit den meisten gezähmten Drachen erhält die Bonuskarte (20 Gold). '
          'Bei Gleichstand entfällt sie.\n\n'
          'Wer das meiste Gold hat, gewinnt und wird Drachenmeister:in!',
      Icons.monetization_on_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('Schuppenschatz · Regeln')),
    body: SelectionArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Card(
            color: Color(0xFFFFE7B3),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: LocalizedText(
                'Eigenständige Würfelblock-Adaption für 2 bis 4 Personen. '
                'Im Digitalmodus würfelt die App; im Blockmodus nutzt ihr fünf echte Würfel '
                '(2 weiß, 1 blau, 1 grün, 1 schwarz).',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final section in sections)
            Card(
              semanticContainer: false,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(section.$3, color: AppColors.plum),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                          const SizedBox(height: 4),
                          LocalizedText(section.$2),
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

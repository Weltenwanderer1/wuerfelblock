import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

const _rulesPage = Color(0xFF241209);
const _rulesInk = Color(0xFF2D160B);
const _rulesGold = Color(0xFFD79B2D);
const _rulesPanel = Color(0xFFF1D7A1);

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
      '28 Drachenkarten pro normaler Partie (aus dem 41-Karten-Stapel: 9 Wasser, 9 Feuer, 9 Glück, 9 Geister, 5 Bosse), '
          '18 Karten im schnellen Spiel, 48 Goldplättchen, 5 Würfel (2 weiß, 1 blau, 1 grün, 1 schwarz), 1 Bonuskarte (20 Gold). '
          'Mischt die Karten und legt den gewählten Stapel verdeckt bereit. '
          'Jeder 7. Platz im Stapel ist ein Boss-Drache.',
      Icons.deck_outlined,
    ),
    (
      'Die Würfel',
      '⚪ Weiß (×2): Normale Zahlen 1–6.\n'
          '🔵 Blau (×1): Für blaue Felder (Wasserdrachen).\n'
          '🟢 Grün (×1): Für grüne Felder (Glücksdrachen).\n'
          '⚫ Schwarz (×1): Für schwarze Felder (Geisterdrachen).\n\n'
          'Farbwürfel-Felder brauchen exakt den richtigen Würfel mit der richtigen Augenzahl!',
      Icons.casino_outlined,
    ),
    (
      'Die Felder auf der Karte',
      'Zahlenfeld: braucht exakt denselben Würfelwert von 1–6.\n'
          '🔵/🟢/⚫ Farbfeld: braucht genau diesen Farbwürfel mit dieser Zahl.\n'
          '🔥 Jokerfeld: jeder Würfel passt.\n'
          'Σ Summenfeld: Lege pro Wurf genau einen Würfel darauf. Sein Wert reduziert die Restsumme; in späteren Würfen reduzierst du weiter, bis 0 erreicht ist.\n'
          '★ Pflichtfeld: muss belegt werden, bevor der Zug endet.',
      Icons.grid_view_rounded,
    ),
    (
      'Die vier Drachenarten',
      '💧 Wasserdrache (blau): Hat ein blaues Würfelfeld – die Zahl muss mit dem blauen Würfel getroffen werden. Das Farbfeld ist kein Pflichtfeld.\n\n'
          '🔥 Feuerdrache (rot): Hat ein Summenfeld, das über 2–3 Würfe reduziert wird.\n\n'
          '★ Glücksdrache (lila): Separate Pflichtfelder + ein grünes Würfelfeld. '
          'Pflichtfelder müssen zuerst voll sein. Beim Zähmen erhältst du zufällig eine zusätzliche Spezialfähigkeit.\n\n'
          '👻 Geisterdrache (schwarz): Ein schwarzes Würfelfeld + ein Summenfeld über 2–4 Würfe. '
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
          'Zug beenden: Du sicherst die Summe der gelegten Würfelaugen als Gold. Auch eine 6 zählt 6 Gold.',
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
          'In jedem Wurf musst du mindestens einen Würfel auf ein Boss-Feld legen. Danach darfst du mit den noch nicht gesetzten Würfeln neu würfeln oder den Boss weitergeben. Jedes Feld nur 1× pro Wurf.\n\n'
          'Die HP werden gespeichert und an den nächsten Spieler weitergegeben. Wer das letzte Feld auf genau 0 bringt, besiegt den Boss und erhält 25 Gold. Ein Fehlwurf gibt den Boss unverändert weiter – kein rückwirkender Sieg für den vorherigen Spieler.\n\n'
          'Beispiel: Feld mit 16 HP → eine 6 reduziert auf 10, dann neu würfeln; eine 4 auf 6, dann neu würfeln; eine 6 auf 0 → besiegt!',
      Icons.cruelty_free_outlined,
    ),
    (
      '⚡ Fähigkeiten',
      'Zu Beginn besitzt jede Person jede Fähigkeit 1×. Für jeden gezähmten Glücksdrachen kommt zufällig eine weitere Ladung einer Fähigkeit dazu – ohne Obergrenze.\n\n'
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
    backgroundColor: _rulesPage,
    appBar: AppBar(
      title: const LocalizedText(
        'Schuppenschatz · Regeln',
        style: TextStyle(color: Color(0xFFF0C56A), fontWeight: FontWeight.w900),
      ),
      backgroundColor: const Color(0xFF1B100A),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4B2A16), Color(0xFF1A0D08)],
          ),
          border: Border(
            top: BorderSide(color: Color(0xFFDDAE4B), width: 1.4),
            bottom: BorderSide(color: Color(0xFF080403), width: 3),
          ),
        ),
      ),
      foregroundColor: const Color(0xFFF0C56A),
      surfaceTintColor: Colors.transparent,
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/schuppenschatz/dragon_board.png'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: SelectionArea(
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
                color: _rulesPanel.withValues(alpha: .94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: _rulesGold.withValues(alpha: .45)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: _rulesGold.withValues(alpha: .28),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(section.$3, color: _rulesInk),
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
    ),
  );
}

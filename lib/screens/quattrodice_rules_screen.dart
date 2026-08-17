import 'package:flutter/material.dart';
import '../l10n/localized_text.dart';

class QuattroRulesScreen extends StatelessWidget {
  const QuattroRulesScreen({super.key});

  static const sections = <(String, String)>[
    (
      'Ziel',
      '16 SQUARES (4×4, A1–D4). Jedes SQUARE hat 4 farbige Ecken (Rot oben links, Blau oben rechts, Grün unten links, Gelb unten rechts) und eine Zahl in der Mitte. Fülle die Ecken mit Würfelzahlen 1–6. Wenn die Summe aller 4 Ecken exakt die Mittelzahl ergibt (Seite B: im vorgegebenen Bereich liegt), kreist du sie ein → Pluspunkte in Höhe der Mittelzahl. Sonst: weißen Kreis schraffieren → –10 Punkte. Wer ein SQUARE zuerst korrekt schließt, sichert sich die Punkte – danach ist es für alle anderen blockiert (großes X, kein Minus). Tipp: Konzentriere dich auf wenige SQUARES gleichzeitig.',
    ),
    (
      'Material & Aufbau',
      'Jede Person braucht einen Zettel und Stift – alle nutzen dieselbe Seite (A = Standard, B = Fortgeschritten). 5 Würfel: Rot, Blau, Grün, Gelb + 1 weißer. Höchste Zahl beim Anwürfeln bestimmt, wer beginnt. Rot-Grün-Schwäche? Anordnung immer gleich (Rot-Blau oben, Grün-Gelb unten); roter Würfel schwarze Augen, grüner weiße.',
    ),
    (
      'Ablauf – Aktiv vs. Passiv',
      'Der Reihe nach ist je eine Person aktiv und würfelt alle 5 Würfel einmal. Aktiv: sucht sich 2 der 4 Farbwürel aus und trägt die Zahlen in 2 leere Ecken der passenden Farbe ein (Rot→rote Ecke usw.). Darf auf ein SQUARE konzentrieren oder auf zwei verteilen. Weiß wird ignoriert. Passiv: alle anderen tragen gleichzeitig die Zahl des weißen Würfels in eine beliebige leere Ecke ein – Farbe egal. Nur leere Ecken, Korrekturen bis zum nächsten Wurf erlaubt. Dann ist die nächste Person aktiv. Blick auf fremde Zettel ist ausdrücklich erlaubt!',
    ),
    (
      'SQUARE schließen',
      'Sobald in einem SQUARE alle 4 Ecken belegt sind, rufst du laut „SQUARE“ + Koordinaten (z. B. B2).\n• Summe falsch → weißen Kreis schraffieren (–10). Andere dürfen dieses SQUARE weiter füllen.\n• Summe korrekt → Zahl einkreisen (Pluspunkte).\n• Alle anderen malen sofort ein großes X durch dieses SQUARE und dürfen ab dem nächsten Wurf nichts mehr dort eintragen (kein Minus für sie).\nAusnahme: Wer im selben Wurf – als Passiver mit der weißen Zahl – das gleiche SQUARE ebenfalls voll macht, darf noch mitwerten: Bei exakter Summe ebenfalls einkreisen, sonst X bzw. schraffieren bei falscher Summe.',
    ),
    (
      'Brücken',
      'Zwei korrekt gekreiste SQUARES nebeneinander (waagrecht/senkrecht) → kleine Brücke dazwischen ausmalen = +5 Punkte je Brücke bei der Wertung.\n• Lila 4, 5, 6: je +5 extra, wenn sie korrekt gekreist UND über mindestens eine Brücke mit einem anderen gekreisten SQUARE verbunden sind.\n• Orange 20, 22, 24 (nur Seite A, unterste Reihe): keine Brücken möglich, geben keine Brücken-Boni.',
    ),
    (
      'Joker',
      'Willst du eine Zahl nicht (oder kannst nicht) in eine Ecke schreiben, darfst du sie stattdessen in eines der 2 Joker-Felder unten mittig eintragen. Aktiv: 1 oder 2 beliebige Farbwürel, Passiv: weißer Würfel. Jede Joker-Zahl zählt als Minuspunkt. Sind beide Joker-Felder voll, musst du wieder normal in Ecken schreiben. Hinweis: In der App einfach Joker-Boxen antippen.',
    ),
    (
      'Vorgaben & Seite B',
      'Manche Ecken zeigen eine weiße Zahl auf farbigem Grund (z. B. rote 6 in A1) → dort muss exakt diese Zahl in dieser Farbe eingetragen werden, sonst kann das SQUARE nie korrekt geschlossen werden.\nSeite A (Standard): alle Mittelzahlen fest.\nSeite B (Fortgeschritten): graue Bereiche – statt fester Zahl ein Bereich (z. B. ≥16 auf A1, 10–14 auf D1). Summe muss im Bereich liegen. Dann schreibst du die tatsächliche Summe in die Mitte, kreist sie ein und nennst die Koordinaten – sie zählt als Pluspunkt in Höhe der Summe.',
    ),
    (
      'Spielende',
      'Kann die aktive Person gegen Ende nur noch einen Farbwürfel sinnvoll nutzen, trägt sie nur diese eine Zahl ein – Rest verfällt.\nSobald die erste Person alle 16 SQUARES geschlossen hat (gekrist, schraffiert oder geblockt), ruft sie „COLOUR SQUARE“. Alle anderen würfeln noch genau einmal mit allen Würfeln (falls noch freie Ecken), tragen wie gewohnt ein (Joker erlaubt) und werten ggf. neue SQUARES.\nDanach: Alle noch offenen SQUARES (fehlende Ecken) → Kreis schraffieren. Brücken prüfen.',
    ),
    (
      'Wertung',
      'Plus: (1) alle eingekreisten Zahlen pro Zeile summieren → je Zeile ins Feld mit grünem Haken, dann die 4 Zeilen-Summen addieren = Feld 1. (2) Brücken zählen ×5 = Feld 2. (3) Lila-SQUARES 4/5/6 mit Brücke je +5 = Feld 3.\nMinus: (4) schraffierte SQUARES ×10 = Feld 4. (5) Summe beider Joker-Felder = Feld 5.\nEndstand = (Feld 1+2+3) − (Feld 4+5). Höchste Punkte gewinnt. In der App: Unter dem Brett siehst du die Vorschau.',
    ),
    (
      'Verdeckt & Solo-Aufgaben',
      'Verdeckte Variante: Alle decken den Zettel ab und rufen „SQUARE“ erst, wenn alle ihre Zahlen eingetragen haben – keine Korrekturen mehr.\nAufgaben (Solo, Seite A oder B): z. B. Schlange, Steigerung, Spalte für Spalte, Verbindung, Reihenfolge – je mit eigener Zählweise (Punkte oder Anzahl korrekter SQUARES). Joker dort als X = Farbe ändern bei gleicher Augenzahl, ohne Minus. Details auf spiel-das.de.',
    ),
    (
      'In der App spielen',
      'Digital würfeln oder mit echten Würfeln neben der App – beides geht. Brett antippen → Ecke wählen → 1–6 eintragen, leeren oder als X blockieren. Brücken-Punkte zwischen SQUARES antippen. Joker unten füllen. Würfeln, Nächste Person, Undo und Finish oben. Vorgabe-Ecken und Orange/Lila-Ränder sind farblich markiert. Viel Spaß!',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const LocalizedText('QuattroDice – Regeln')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LocalizedText(
                'COLOUR SQUARE – Standard & Fortgeschritten',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const LocalizedText(
                '2–6 Personen · 20–30 Min · 4 farbige + 1 weißer Würfel · Original: Patrick Katona / SPIEL DAS! Verlag',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const LocalizedText(
                'In Würfelblock heißt das Spiel QuattroDice. Seite A = Standard, Seite B = Fortgeschritten. Anleitung kurz genug für den Spieltisch, vollständig nach Original.',
                style: TextStyle(fontStyle: FontStyle.italic),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
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

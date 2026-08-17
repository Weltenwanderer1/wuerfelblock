import 'package:flutter/material.dart';
import '../l10n/localized_text.dart';

class QuattroRulesScreen extends StatelessWidget {
  const QuattroRulesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('QuattroDice – Regeln (COLOUR SQUARE)'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        LocalizedText(
          'Ziel: 16 SQUARES füllen. In jede Ecke (Rot/Blau/Grün/Gelb) kommt 1–6. Summe der 4 Ecken = Zahl in der Mitte → eingekreist = Pluspunkte. Sonst schraffiert = –10. Kreuz (X) = von anderem zuerst geschnappt – blockiert, kein Minus.',
          style: TextStyle(height: 1.35),
        ),
        SizedBox(height: 10),
        LocalizedText(
          'Würfel: 4 farbige + 1 weißer. Aktiv würfelt 5, nimmt 2 farbige in passende Farbe (aufgeteilt oder gleiches SQUARE). Alle Passiven schreiben weiß in beliebige Ecke (Farbe egal). Nur leere Ecken, Korrektur bis nächster Wurf.',
        ),
        SizedBox(height: 10),
        LocalizedText(
          'Brücken: Benachbarte (oben/neben) korrekt gekreiste SQUARES → Brücke ausmalen = +5 je Brücke. Lila 4/5/6: zusätzlich +5 je SQUARE wenn mit Brücke verbunden. Orange 20/22/24 (untere Reihe) haben keine Brücken.',
        ),
        SizedBox(height: 10),
        LocalizedText(
          'Joker: Willst du nicht in Ecken schreiben → in Joker-Felder (2 Felder unten) eintragen (Aktiv 1–2 farbige, Passiv weiß). Jede Joker-Zahl = Minuspunkt. Sind beide voll → wieder nur Ecken.',
        ),
        SizedBox(height: 10),
        LocalizedText(
          'SQUARE schließen: Sobald 4 Ecken voll → automatisch geprüft: Summe im Ziel (bzw. im Bereich bei Seite B) → gekreist, sonst schraffiert. Manuell kannst du ein fremdes SQUARE als X blockieren.',
        ),
        SizedBox(height: 10),
        LocalizedText(
          'Seite A (Standard): alle Mittelzahlen fest. Seite B (Fortgeschritten): graue Bereiche (z.B. ≥16, 10–14) – Summe muss im Bereich liegen; zählt dann als Plus in Höhe der tatsächlichen Summe. Weiße Vorgaben in Ecken müssen exakt getroffen werden.',
        ),
        SizedBox(height: 10),
        LocalizedText(
          'Ende: Wer zuerst alle 16 schließt ruft COLOUR SQUARE – alle anderen würfeln noch 1× nach. Offene SQUARES am Ende werden schraffiert. Wertung: Plus (gekreist + Brücken + Lila) minus (schraffiert×10 + Joker). Höchste Punkte gewinnt.',
        ),
        SizedBox(height: 14),
        LocalizedText(
          'Digital würfeln oder mit echten Würfeln abseits der App – beides möglich. In der App einfach Felder antippen, 1–6 wählen, Brücken antippen, Joker füllen.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    ),
  );
}

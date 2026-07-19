# Würfelblock – Implementierungsplan

## Ziel
Eine schöne, vollständig offline nutzbare Android-App für **Yatzy** und **Kniffel** mit zwei Spielarten:

1. **Blockmodus**: echte Würfel, App ersetzt nur den Papier-Wertungsblock.
2. **Digitalmodus**: fünf simulierte Würfel, bis zu drei Würfe, Würfel festhalten, automatische Wertung und Spielerwechsel.

## Produktentscheidungen

- App-Name: **Würfelblock**
- Projekt: `wuerfelblock`, Android package `at.weltenwanderer.wuerfelblock`
- Spielerzahl: **1–8**. Mehr ist auf einem Handy kein Spiel mehr, sondern Tabellenkalkulation.
- Offline, werbefrei, ohne Konto, ohne Netzwerkberechtigung.
- Deutsch als UI-Sprache.
- Portrait-first, auf Tablets responsiv.
- Eine laufende Partie wird lokal gespeichert und kann fortgesetzt oder verworfen werden.
- Letzten Eintrag rückgängig machen, damit ein Vertipper nicht die ganze Partie versaut.

## Regelwerke

### Kniffel (Schmidt)
Oberer Block: Einser bis Sechser; Summe; Bonus **35 bei mindestens 63**.
Unterer Block:
- Dreierpasch: Summe aller Würfel bei mindestens drei gleichen
- Viererpasch: Summe aller Würfel bei mindestens vier gleichen
- Full House: 25
- Kleine Straße: 30 (vier aufeinanderfolgende Werte)
- Große Straße: 40 (fünf aufeinanderfolgende Werte)
- Kniffel: 50
- Chance: Summe aller Würfel

Jede Kategorie genau einmal; nicht erfüllte Kategorie kann mit 0 gestrichen werden. Zusatz-Kniffel sind für die erste Version nicht Teil der automatischen Wertung, damit die Kernpartie eindeutig bleibt.

### Yatzy (klassisch/skandinavisch)
Oberer Block: Einser bis Sechser; Summe; Bonus **35 bei mindestens 63** (entspricht der vom Nutzer verlinkten Schweizer Regelquelle).
Unterer Block:
- Ein Paar: Summe des höchsten Paars
- Zwei Paare: Summe zweier verschiedener Paare
- Dreierpasch: Summe der drei gleichen Würfel
- Viererpasch: Summe der vier gleichen Würfel
- Kleine Straße: 15 für 1–2–3–4–5
- Große Straße: 20 für 2–3–4–5–6
- Full House: Summe aller Würfel bei Paar + Drilling
- Chance: Summe aller Würfel
- Yatzy: 50

## UX-Fluss

### Start
- Logo/Illustration aus Würfeln, Titel „Würfelblock“
- Primäraktion „Neue Partie“
- Falls gespeichert: „Partie fortsetzen“ mit Regelwerk, Modus und Fortschritt
- Kleine Regelhilfe

### Neue Partie
- Regelwerk-Karten: Yatzy / Kniffel
- Modus-Karten: Echte Würfel / Digital würfeln
- Spielerzahl Stepper 1–8
- Dynamische Namensfelder mit sinnvollen Vorgaben („Spieler 1“ usw.)
- Startbutton erst aktiv, wenn Namen nicht leer und eindeutig sind

### Blockmodus
- Papierblock-artige Matrix: Kategorien links, Spieler als Spalten
- Oberer und unterer Block farblich gruppiert
- Zellen groß genug und horizontal scrollbar
- Tipp auf freie Zelle öffnet kompaktes Punkteblatt mit gültigem Bereich, Schnellwahl 0 und Eingabe
- Summen/Bonus/Gesamt automatisch, nicht editierbar
- Fortschritt, Undo und Partie beenden

### Digitalmodus
- Aktiver Spieler deutlich oben
- Fünf große Würfel; Tipp hält/löst Würfel
- Bis zu drei Würfe; nach dem ersten Wurf Wertungsvorschläge anzeigen
- Jede freie Kategorie zeigt den automatisch berechneten Wert; Tipp trägt ein
- 0-Punkte-Kategorien bleiben auswählbar zum Streichen
- Nach Eintrag automatischer Spielerwechsel
- Kleine Scorecard des aktiven Spielers und Gesamtstand aller Spieler
- Ende nach allen Kategorien; Siegeransicht, Gleichstand korrekt behandeln

## Visuelles Design
Adaption des Papierblocks, keine Kopie:
- Warmes Off-White als „Papier“
- Pastell-Rosa für oberen Block, Lavendel für unteren Block
- Pflaume als Primärfarbe, Apricot für Bonus/Highlights
- Große, gut lesbare Schrift und klare Tabellenlinien
- Runde Karten, dezente Schatten, Würfel mit echten Augen statt Zahlen
- Material 3, aber nicht generischer Standard-Look
- Accessibility: Semantics, mindestens 48dp Touchflächen, ausreichender Kontrast

## Architektur

- `lib/core/`: Theme, Konstanten
- `lib/models/`: Enums, Spieler, Spielzustand, Score-Eintrag
- `lib/services/`: reine Scoring-Engine, lokale JSON-Persistenz
- `lib/controllers/`: GameController / DiceController als ChangeNotifier
- `lib/screens/`: Home, Setup, Blockspiel, Digitalspiel, Ergebnis, Regeln
- `lib/widgets/`: Dice, ScoreRow, PlayerHeader, SectionHeader etc.

Keine schwere State-Management-Abhängigkeit. `shared_preferences` reicht für eine einzelne lokale Partie.

## TDD / Qualitätsgates

1. Scoring-Tests zuerst und rot laufen lassen.
2. Scoring-Engine implementieren und Tests grün.
3. Controller-Tests: Spielerwechsel, max. drei Würfe, Hold-Verhalten, Spielende, Undo.
4. Widget-Tests: Startscreen, Setup-Validierung, Blockeingabe, Digitalwürfel.
5. `dart format --set-exit-if-changed .`
6. `flutter analyze` ohne Findings.
7. `flutter test` komplett grün.
8. Echter `flutter build apk --release` erfolgreich.
9. `git diff --check`, Status prüfen, committen und pushen.

## Akzeptanzkriterien

- Beide Regelwerke rechnen alle Kategorien korrekt.
- Blockmodus funktioniert ohne simulierte Würfel.
- Digitalmodus erlaubt Rollen/Halten/Werten für 1–8 Spieler.
- Aktive Partie überlebt App-Neustart.
- Undo funktioniert für den letzten Wertungseintrag.
- Ergebnisansicht zeigt Sieger oder Gleichstand.
- Keine Netzwerk-, Login- oder Werbeabhängigkeit.
- Release-APK baut auf dem realen lokalen Dateisystem.

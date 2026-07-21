# Escalero / Würfelpoker — Implementierungsplan

## Ziel

Escalero wird als fünftes spielbares Würfelspiel in Würfelblock ergänzt. Es gibt einen Blockmodus für echte Poker- oder Augenwürfel und einen Digitalmodus mit fünf Pokerwürfeln, Halten und maximal drei Würfen.

## Normative Regelentscheidung

Die App implementiert die Piatnik-Escalero-Regeln, wie sie in der deutschsprachigen Wikipedia beschrieben sind. Die BrainKing-Regel bestätigt den gemeinsamen Grundablauf aus fünf Würfeln, Halten und maximal drei Würfen, beschreibt aber ein anderes, Yahtzee-artiges Würfelpoker mit 13 Feldern und ist daher nicht die Escalero-Wertung. Das historische Pokerwürfel-PDF bestätigt die Pokerbilder, Grundkombinationen, Servierungslogik und Pflicht zum Eintragen beziehungsweise Streichen.

Quellen:

- https://de.wikipedia.org/wiki/Escalero
- https://brainking.com/de/GameRules?tp=97
- https://www.dienstac.de/adi/spiele/PokerWS.pdf

## Spielumfang

- 2–3 Personen; jede Person spielt ein eigenes Blatt.
- Fünf Pokerwürfel mit den Bildern 9, 10, Bube, Dame, König und Ass.
- Intern werden die sechs Bilder mit den Werten 1–6 dargestellt; die sichtbare UI zeigt Pokerbilder.
- Jede Person hat drei Kolonnen mit je zehn Feldern.
- Pro Zug sind ein bis drei Würfe erlaubt.
- Nach dem ersten und zweiten Wurf dürfen beliebige Würfel gehalten oder wieder freigegeben werden.
- Nach spätestens dem dritten Wurf muss genau ein freies Feld der aktiven Person befüllt werden.
- Ein unbrauchbares Ergebnis darf als 0 in ein beliebiges freies Feld eingetragen werden.

## Kategorien und Wertung

### Bilder

- Neun: Anzahl × 1
- Zehn: Anzahl × 2
- Bube: Anzahl × 3
- Dame: Anzahl × 4
- König: Anzahl × 5
- Ass: Anzahl × 6

### Kombinationen

- Straße: 9-10-B-D-K oder 10-B-D-K-A; 20 Punkte, serviert 25.
- Full House: drei gleiche und zwei andere gleiche; 30 Punkte, serviert 35.
- Poker: genau vier gleiche; 40 Punkte, serviert 45.
- Grande: fünf gleiche; 50 Punkte, serviert 80.

Eine Servierung liegt nur vor, wenn die wertbare Kombination aus einem Wurf entsteht, bei dem alle fünf Würfel gleichzeitig geworfen wurden. Das kann der erste, zweite oder dritte Wurf sein. Sobald für den entscheidenden Wurf Würfel gehalten bleiben, gibt es keinen Servierungsbonus.

## Kolonnen- und Partieabrechnung

- Jede Kolonne wird separat zwischen allen Personen verglichen.
- Kolonne 1 zählt 1 Spielpunkt, Kolonne 2 zählt 2, Kolonne 3 zählt 4.
- Bei Gleichstand erhält in diesem Paarvergleich niemand Punkte.
- Für jeden Gegner, gegen den eine Person alle drei Kolonnen gewinnt, kommen 2 Bonuspunkte hinzu.
- Bei zwei Personen ergibt ein vollständiger Sieg 1 + 2 + 4 + 2 = 9 Spielpunkte.
- Bei drei Personen werden die positiven und negativen Paarergebnisse summiert; das entspricht der Piatnik-Abrechnung.
- Ergebnis-Ranking: zuerst Netto-Spielpunkte, dann Gesamt-Rohpunkte; exakte Gleichheit bleibt Gleichstand.

## Architektur

Eigene Domäne statt Erweiterung des klassischen Kniffel-Modells:

- `lib/models/escalero_models.dart`
- `lib/controllers/escalero_controller.dart`
- `lib/widgets/poker_die_widget.dart`
- `lib/widgets/escalero_score_sheet.dart`
- `lib/screens/escalero_game_screen.dart`
- `lib/screens/escalero_result_screen.dart`
- `lib/screens/escalero_rules_screen.dart`

Persistenz-Diskriminator: `type: escalero`.

Der Controller verwendet `ControllerTransactions` für Busy-Guard, Rollback, Undo und Digital-Save-Retry. Digitale Würfe und Halteänderungen bleiben bei Save-Fehler sichtbar und müssen mit exakt demselben Zustand erneut gespeichert werden.

## UX

- Setup-Karte im bestehenden responsiven 2er-Grid.
- Moduswahl: „Echte Würfel“ oder „Digitale Pokerwürfel“.
- Blockmodus zeigt ein responsives Tabellenblatt mit Spielerwahl, Kolonnen und zehn Wertungsreihen.
- Digitalmodus zeigt große Pokerwürfel mit klarer Halten-Markierung, Wurfzähler, Vorschau aller noch freien Kategorien und expliziter Bestätigung.
- Jede Score-Zelle und jeder Würfel erhält einen stabilen Key und ein vollständiges Semantik-Label.
- Ergebnis-Screen zeigt Kolonnensummen, Paarabrechnung, Netto-Spielpunkte und Sieger.
- Regelseite ist über die zentrale Spielregeln-Auswahl sowie Spiel- und Ergebnis-Screen erreichbar.

## TDD-Phasen

1. Scoring, Servierung, Kategorien, 30 Felder, Fortschritt, Sieger und JSON strikt testen.
2. Controller für Block/Digital, Spielerrotation, Hold/Reroll, Save-Retry, Undo und Abbruch testen.
3. Repository, Setup und App-Routing integrieren und testen.
4. Block- und Digital-Screen samt vollständigem UI-Score-Pfad testen.
5. Regelnavigation, kleine Displays 360×800 und 200-%-Text testen.
6. Vollständige Analyse, Test-Suite, ARM64-Release-Build und APK-Signaturprüfung.
7. Frischen adversarialen Pre-Release-Audit ausführen; P0/P1 vor Tag beheben.
8. Version auf 1.5.0 erhöhen, committen, `master` pushen, Tag `v1.5.0` veröffentlichen, CI und GitHub-APK prüfen.
9. Frischen Post-Release-Audit auf dem veröffentlichten Commit ausführen; gefundene P0 als separaten Hotfix behandeln.

## Nicht enthalten

- Online-Multiplayer oder Teammodus für vier und mehr Personen.
- Geld-/Chip-Abrechnung außerhalb der Spielpunkte.
- BrainKings 13-Felder-Würfelpoker als zusätzliche Variante.
- Joker-Poker, offenes/verdecktes Poker oder andere Varianten aus dem historischen PDF.

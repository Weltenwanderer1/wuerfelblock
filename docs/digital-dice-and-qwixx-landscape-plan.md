# Digitale Würfel für alle Spiele – Implementierungsplan

## Ziel
Qwixx und 10.000 erhalten neben dem bestehenden Blockmodus einen vollständigen digitalen Würfelmodus. Der Qwixx-Spielbildschirm läuft im Querformat und passt ohne Scrollen; der klassische Zweispieler-Block passt auf 360 px Breite.

## Architektur
- `GameMode` wird auch in Qwixx- und 10.000-Spielständen gespeichert; alte JSON-Saves ohne Feld laden als Blockmodus.
- Qwixx-Digitalmodus speichert sechs Würfel, Wurfstatus und bereits genutzte weiße/farbige Aktionen des laufenden Zuges. Ein Zug erlaubt den weißen Summenwurf für alle und zusätzlich Weiß+Farbe für die aktive Person.
- 10.000-Digitalmodus verwendet einen eigenen, persistierten Zugzustand mit sechs Würfeln, Auswahl, Rundenpunkten, beiseitegelegten Paschen und Hot-Dice/Bestätigungsstatus. Erst gesicherte Rundenpunkte gehen in das bestehende Zugprotokoll.
- Qwixx-Spiel und -Ergebnis erzwingen Querformat und stellen beim Verlassen die normalen App-Ausrichtungen wieder her.

## TDD-Schritte
1. Setup-Tests: Bei allen drei Spielen Block/Digital auswählbar; Modus landet im Controller und JSON-Migration bleibt kompatibel.
2. Klassischer Block: Widgettest auf 360 px ohne horizontale Scrollstrecke; Tabellenbreiten minimal reduzieren.
3. Qwixx-Domäne: Tests für Würfelwurf, erlaubte weiße/farbige Summen, einmalige Aktionen, Zugabschluss/Fehlwurf, Reset und Persistenz.
4. Qwixx-UI: Querformat-Test bei 800×360 ohne Overflow und ohne ScrollViews; kompakter Steuerbereich plus vier flexibel breite Reihen.
5. 10.000-Wertung: Tests für Einzel-1/5, Pasche, Verdopplung über Würfe, Straße, drei Paare, ungültige Auswahl, Macke, Hot Dice und 350-Punkte-Sicherung.
6. 10.000-UI: Würfeln, Würfel auswählen, werten, weiterwürfeln, sichern/Macke; laufenden Zug persistieren und wiederaufnehmen.
7. Routing/Ergebnis/Regeln an beide Modi anpassen.
8. Vollständige Tests, Analyzer, 360×800/800×360-Widgettests, ARM64-Release-Build, unabhängiger Review, Version/Release.

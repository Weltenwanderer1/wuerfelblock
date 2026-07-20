# Balut – Implementierungsplan

## Ziel
Balut nach den Regeln von balut.org als viertes öffentliches Spiel ergänzen. Wie alle anderen Spiele bietet es Blockmodus mit echten Würfeln und einen vollständigen digitalen Würfelmodus.

## Architektur
- Eigene Domäne statt Erweiterung des Yahtzee/Kniffel-Modells: sieben Kategorien, vier Einträge je Kategorie, 28 Wertungen pro Person.
- `BalutGameState` persistiert Spielerblätter, aktiven Spieler, Modus sowie den digitalen Fünf-Würfel-Zug.
- `BalutController` übernimmt Würfeln/Halten (maximal drei Würfe), Blockeingabe, digitale Wertung, Undo und atomare Speicherung.
- Wertungs- und Incentive-Punkte werden aus den Einträgen abgeleitet: Schwellenpunkte je Kategorie, 2 Punkte je Balut sowie Gesamtwert-Bonus von −2 bis +6.
- Eigene Screens für Spiel, Ergebnis und deutsche Anfängerregeln; Auswahl im bestehenden Setup und Routing über `SavedGameState`.

## TDD-Schritte
1. Modelltests für Kategorien, zulässige Blockwerte, digitale Würfelwertung und Incentive-/Gesamtpunkte schreiben und rot ausführen.
2. `BalutCategory`, `BalutPlayer`, `BalutGameState` und Scoring implementieren; JSON-Roundtrip und strikte Validierung testen.
3. Controllertests für Blockwertung, Würfeln/Halten, drei Würfe, digitale Wertung, Undo, Save-Rollback und Wiederaufnahme schreiben und implementieren.
4. Repository-Decoder um `type: balut` erweitern und Legacy-/Fehlerfälle testen.
5. Setup um Balut (2–8 Personen, Block/Digital) erweitern und Routingtests schreiben.
6. Balut-Spielbildschirm mit wählbarem Spielerblatt, sieben Kategorien × vier Einträgen, Summen/Incentives und Block-/Digitalsteuerung erstellen.
7. Ergebnis- und Regelseite ergänzen; Regeln vollständig auf Deutsch erklären.
8. README und Versionsdaten aktualisieren.
9. Vollständige Tests, Analyzer, Layouttests, ARM64-Release-Build, Signaturprüfung und unabhängiger Review.
10. Erst danach Commit, Push und GitHub-Release.

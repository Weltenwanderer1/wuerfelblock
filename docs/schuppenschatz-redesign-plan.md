# Schuppenschatz – Redesign- und Regelkorrekturplan

**Ziel:** Den bisherigen öffentlichen Spielmodus „Drachengold“ als eigenständige Würfelblock-Adaption **Schuppenschatz** neu gestalten und zentrale Regel-/UX-Fehler korrigieren.

**Quelle:** Dragon Dice Spielanleitung, EMF-Verlag 2026, vom Nutzer bereitgestellt. Regeltexte werden eigenständig zusammengefasst; Markenname, Layout und Illustrationen werden nicht übernommen.

## Produktentscheidungen

- Öffentlicher Name: **Schuppenschatz**.
- Interne Dart-Klassen bleiben vorerst `Dragon*`, damit der Umbau klein und prüfbar bleibt.
- Persistenz-Diskriminator bleibt aus Abwärtskompatibilität `dragongold`; neue und alte Saves laden weiter.
- Die 6 ersetzt weiterhin die Flamme und zählt beim Goldwert 0.
- Eigene Kartenkonfigurationen statt kopierter Kartenillustrationen; Vollspiel nutzt 41 Karten, Kurzspiel 20.

## Task 1 – Regelverträge korrigieren (TDD)

**Dateien:**
- `test/dragon_models_test.dart`
- `test/dragon_controller_test.dart`
- `lib/models/dragon_models.dart`
- `lib/controllers/dragon_controller.dart`

1. Rote Tests: Vollspiel hat 41 Karten; Glücksdrache darf passende freiwillige Felder belegen, auch wenn Pflichtfelder offen sind; Blockmodus kann einen erfolglosen Wurf melden.
2. Testlauf muss erwartungsgemäß rot sein.
3. Deck auf 41 eigene Karten korrigieren; `newGame` nimmt im Vollspiel alle 41.
4. Fit-Prüfung auf alle offenen passenden Felder anwenden; Pflichtfelder sperren nur freiwilliges Aufhören.
5. `failAttempt()` für Blockmodus ergänzen; digitaler Modus bleibt automatisch.
6. Fokussierte Tests grün.

## Task 2 – Öffentliche Umbenennung und Regeln (TDD)

**Dateien:**
- `lib/screens/setup_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/models/dragon_models.dart`
- `lib/screens/schuppenschatz_rules_screen.dart` (neu)
- `lib/screens/rules_selection_screen.dart`
- `tool/translations_en.json`
- relevante Widgettests

1. Rote Tests für „Schuppenschatz“, korrekte Beschreibung „5 Würfel · 2–5 Felder · Risiko & Gold“ und Regelseiten-Navigation.
2. Alle öffentlichen „Drachengold“-Strings ersetzen; interne Legacy-Typen nicht ändern.
3. Eigenständig formulierte Regelseite mit Spielziel, Feldern, Zugablauf, Drachenarten, Gold und Spielende ergänzen.
4. Englischen Offline-Katalog regenerieren.
5. Fokussierte Tests grün.

## Task 3 – Game-Screen neu gestalten (TDD)

**Dateien:**
- `lib/screens/dragon_game_screen.dart`
- `test/dragon_widget_test.dart`

1. Rote Widgettests für Statusleiste, Risikoanzeige, Regelbutton, feste Aktionsleiste, Block-Fehlschlag und 200-%-Text.
2. Visuelle Hierarchie:
   - ruhiger AppBar-Titel „Schuppenschatz“, aktiver Spieler im Statusband;
   - kompakte Kennzahlen: Karten übrig, Goldtopf, Gold auf Karte;
   - große eigenständige Drachenkarte mit typabhängigem Verlauf und Material-Icon;
   - gut erkennbare Ziel-Sockel mit Pflicht-/Jokerzustand;
   - Live-Wert „Jetzt sicher: N Gold“;
   - kompakte Spielerleiste;
   - Aktionsleiste immer unten erreichbar.
3. Digitalmodus: Würfel auswählen → gültige Sockel leuchten; primäre Entscheidung „Weiter würfeln“, sekundär „N Gold sichern“.
4. Blockmodus: Werte auf Sockel tippen; explizite Aktion „Kein Würfel passt“.
5. Save-Retry bleibt erreichbar und sperrt sich nicht selbst.
6. Portrait 360×800 und 200 % Text ohne Overflow.

## Task 4 – Ergebnis-Screen neu gestalten (TDD)

**Dateien:**
- `lib/screens/dragon_result_screen.dart`
- Widgettests

1. Rote Tests für Gewinner, Bonus, Rangfolge, Regeln und Clear-Retry.
2. Siegerkarte mit eigenständigem Schatz-/Wappenstil.
3. Ranking-Zeilen zeigen Rang, Drachen, Grundgold, Bonus und Gesamtgold klar getrennt.
4. Regeln erreichbar; Startseite erst nach erfolgreichem Clear.

## Task 5 – Vollständige Verifikation und Release

1. `dart format --output=none --set-exit-if-changed lib test tool`
2. `flutter analyze --fatal-infos`
3. `flutter test`
4. `git diff --check` + Diff-Stat prüfen.
5. Frischer Pre-Release-Audit: Regelkonformität, tote UI-Pfade, Save-Retry, Ranking, i18n, 200-%-Layout.
6. Versions-/Buildnummer erhöhen, ARM64-APK bauen und Signatur prüfen.
7. Commit auf `master`, pushen, freien Patch-Tag erstellen, CI/Release-Asset verifizieren.
8. Post-Release-Audit.

# Würfelblock – Abschluss der technischen Nachbesserungen

## Ziel
Die sieben bewusst zurückgestellten Audit-Punkte werden nachgezogen, ohne das Spielmodell oder die bestehende Kartenspiel-Regelhilfe unnötig umzubauen:

1. Qwixx bei 200 % Textgröße auf kleinem Gerät prüfen und ohne harte Textskalierung zugänglich halten.
2. 10.000-Zugverlauf virtualisiert darstellen, ohne Editier-/Lösch-/Undo-Verhalten zu verändern.
3. Gemeinsame transaktionale Controller-Hilfslogik für Qwixx, 10.000 und Balut extrahieren; domänenspezifische Regeln bleiben in den Controllern.
4. Regelkonstanten zentralisieren, mindestens die gemeinsam wiederholten 10.000-/Eingabe-/Fehlermeldungskonstanten.
5. Historische JSON-Fixtures für normale, laufende, vollständige, tombstoned und alte Spielstände ergänzen.
6. Property-/Exhaustivtests für Balut, Qwixx-Reihenfolge und 10.000-Ledger ergänzen, ohne Produktionslogik zu verändern.
7. Home-Load mit Generation Guard gegen veraltete asynchrone Ergebnisse absichern.

## Leitplanken

- Bestehende uncommitted Änderungen für die Kartenspiel-Regelhilfe bleiben erhalten.
- Keine neuen Abhängigkeiten, kein Online-/Cloud-Code.
- Keine Änderung der Spielregeln oder der bestehenden öffentlichen Bedienung.
- TDD: neue Regressionstests zuerst rot, danach kleinste Implementierung, dann vollständige Suite.
- Nicht committen, taggen oder pushen.

## Prüfungen

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
git diff --check
git status --short
```

## Status

Alle sieben Punkte umgesetzt. Verifiziert mit `flutter analyze`, 217 bestandenen `flutter test`-Tests, format-cleanem Dart-Code und sauberem `git diff --check`.


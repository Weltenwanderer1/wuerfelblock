# Würfelblock

Eine vollständig offline nutzbare Android-App für **Yahtzee/Kniffel**, **Qwixx**, **10.000** und **Balut**. Alle vier Spiele funktionieren wahlweise als Wertungsblock für echte Würfel oder als komplettes digitales Würfelspiel.

Ältere, gespeicherte Partien des ursprünglich angebotenen skandinavischen Yatzy bleiben kompatibel. Sie werden als **Yatzy (klassisch)** mit ihren ursprünglichen Kategorien, Wertungen und Regeln fortgesetzt, stehen aber nicht mehr zur Auswahl für neue Partien.

## Funktionen

- Yahtzee/Kniffel für 2–8, Qwixx für 2–5, 10.000 und Balut für 2–8 Personen
- Yahtzee/Kniffel-Regelwerk mit automatischen Summen, Bonus und Zusatz-Kniffel
- **Blockmodus:** klassische Papierblock-Matrix mit klebenden Spielernamen, validierter Eingabe sowie nachträglichem Ändern und Löschen
- **Digitalmodus:** spielgerechte Würfel und automatische Wertungsprüfung für alle vier Spiele
- **Qwixx:** sechs farbige Würfel, vier Farbreihen, Links-nach-rechts-Sperren, Schlösser, Fehlwürfe und automatische Wertung im kompakten Querformat
- **10.000:** sechs Würfel nach Berliner Meisterschaftsregeln, Pasch-Verdopplung über mehrere Würfe, Straße, drei Paare, Macke und automatisch geführte Schlussrunde
- **Balut:** fünf Würfel, sieben Kategorien mit je vier Wertungen, 28 Einträge pro Person, plus automatische Schwellen- und Balut-Boni
- Spielerwechsel, Sieger- und Gleichstandserkennung
- Undo des letzten Wertungseintrags
- Lokales Fortsetzen via `shared_preferences`
- Anfängergerechte Regelhilfen für alle vier öffentlichen Spiele und Info-Tasten für jede Yahtzee/Kniffel-Wertung
- Zugängliche Touchflächen und Semantics
- Keine Netzwerkberechtigung, Werbung, Konten oder Online-Dienste

## Entwicklung

Voraussetzung: Flutter 3.41.5 (Dart 3.11.3).

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
```

Die Release-APK liegt anschließend unter `build/app/outputs/flutter-apk/app-release.apk`.

## GitHub Actions und Releases

Der Workflow `.github/workflows/android.yml` analysiert und testet jeden Push auf `master` und baut anschließend eine **signierte** Release-APK als Workflow-Artefakt. Tags nach dem Muster `v*` erzeugen zusätzlich automatisch ein privates GitHub Release mit angehängter APK.

Die dauerhafte Update-Signatur liegt **nicht im Repository**. Der Keystore und seine Passwörter werden ausschließlich über diese GitHub-Secrets eingespeist:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

Ohne `android/key.properties` bricht ein lokaler Release-Build absichtlich ab; ein versehentlich debug-signiertes Release gibt es damit nicht.

## Struktur

- `lib/core` – Designsystem
- `lib/models` – Regelwerk und Spielzustand
- `lib/services` – Scoring und lokale Persistenz
- `lib/controllers` – Spiel- und Würfellogik
- `lib/screens` – App-Screens
- `lib/widgets` – wiederverwendbare UI-Komponenten
- `test` – Scoring-, Controller- und Widget-Tests

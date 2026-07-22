# Würfelblock

Eine vollständig offline nutzbare Android-App für **Yahtzee/Kniffel**, **Qwixx**, **10.000**, **Balut** und **Escalero**. Alle fünf Spiele funktionieren wahlweise als Wertungsblock für echte Würfel oder als komplettes digitales Würfelspiel. Die Oberfläche ist auf **Deutsch und Englisch** verfügbar.

Ältere, gespeicherte Partien des ursprünglich angebotenen skandinavischen Yatzy bleiben kompatibel. Sie werden als **Yatzy (klassisch)** mit ihren ursprünglichen Kategorien, Wertungen und Regeln fortgesetzt, stehen aber nicht mehr zur Auswahl für neue Partien.

## Funktionen

- Yahtzee/Kniffel für 2–8, Qwixx für 2–5, 10.000 und Balut für 2–8 sowie Escalero für 2–3 Personen
- Yahtzee/Kniffel-Regelwerk mit automatischen Summen, Bonus und Zusatz-Kniffel
- **Blockmodus:** klassische Papierblock-Matrix mit validierter Eingabe und bewusster Korrekturfunktion für belegte Wertungen
- **Digitalmodus:** spielgerechte Würfel und automatische Wertungsprüfung für alle fünf Spiele
- **Qwixx:** sechs farbige Würfel, vier Farbreihen, Links-nach-rechts-Sperren, Schlösser, Fehlwürfe und automatische Wertung im kompakten Querformat
- **10.000:** sechs Würfel nach Berliner Meisterschaftsregeln, Pasch-Verdopplung über mehrere Würfe, Straße, drei Paare, Macke und automatisch geführte Schlussrunde
- **Balut:** fünf Würfel, sieben Kategorien mit je vier Wertungen, 28 Einträge pro Person, plus automatische Schwellen- und Balut-Boni
- **Escalero:** fünf Pokerwürfel, zehn Kategorien und drei unterschiedlich gewichtete Kolonnen pro Person
- Spielerwechsel, Sieger- und Gleichstandserkennung
- Undo des letzten Wertungseintrags
- Lokales Fortsetzen via `shared_preferences`
- Persistenter Sprachwechsel zwischen Deutsch und Englisch
- Anfängergerechte Regelhilfen für alle fünf öffentlichen Würfelspiele und Info-Tasten für jede Yahtzee/Kniffel-Wertung
- Separate, auswählbare Spielregeln für die Standarddeck-Varianten **Crisps!**, **Regicide** und **Haggis**
- Zugängliche Touchflächen und Semantics
- Keine Netzwerkberechtigung, Werbung, Konten oder Online-Dienste
- In-App-Datenschutzhinweis; der Entwickler hat keinen Zugriff auf lokale Namen oder Spielstände

Entwickelt von **Günther Schuch**. Die zweisprachige Datenschutzerklärung steht in [`PRIVACY.md`](PRIVACY.md) und [öffentlich auf GitHub Pages](https://weltenwanderer1.github.io/wuerfelblock-legal/); die geprüften Play-/EU-Veröffentlichungspunkte sind unter [`docs/google-play-eu-release-checklist.md`](docs/google-play-eu-release-checklist.md) dokumentiert.

## Entwicklung

Voraussetzung: Flutter 3.41.5 (Dart 3.11.3).

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Die Release-APK liegt anschließend unter `build/app/outputs/flutter-apk/app-release.apk`, das Play-App-Bundle unter `build/app/outputs/bundle/release/app-release.aab`.

## GitHub Actions und Releases

Der Workflow `.github/workflows/android.yml` analysiert und testet jeden Push auf `master` und baut anschließend eine **signierte** Release-APK sowie ein signiertes Play-App-Bundle. Tags nach dem Muster `v*` erzeugen zusätzlich automatisch ein privates GitHub Release mit beiden Artefakten. Alle Drittanbieter-Actions sind auf feste Commit-SHAs gepinnt.

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

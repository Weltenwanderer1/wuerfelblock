# Würfelblock

Eine vollständig offline nutzbare Android-App für **klassisches skandinavisches Yatzy** und **Kniffel**. Die App kann als digitaler Wertungsblock für echte Würfel oder als komplettes Würfelspiel verwendet werden.

## Funktionen

- 1–8 Spieler mit frei wählbaren, eindeutigen Namen
- Yatzy- und Kniffel-Regelwerk mit automatischen Summen und Bonus
- **Blockmodus:** horizontale Papierblock-Matrix, validierte manuelle Eingabe, Streichen mit 0
- **Digitalmodus:** fünf Würfel, bis zu drei Würfe, Hold per Tipp, automatische Wertungsvorschläge
- Spielerwechsel, Sieger- und Gleichstandserkennung
- Undo des letzten Wertungseintrags
- Lokales Fortsetzen via `shared_preferences`
- Regelhilfe, Material-3-Design und zugängliche Touchflächen/Semantics
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

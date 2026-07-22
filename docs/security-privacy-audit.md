# Security- und Privacy-Audit für v1.6.0

Stand: 2026-07-22

## Umfang

Geprüft wurden der finale Release-Arbeitsbaum, alle 13 davor erreichbaren Git-Commits, Android-Manifest und Abhängigkeiten sowie die lokal gebauten Release-Artefakte für `1.6.0+14`.

Das App-Repository bleibt privat. Frühere Commit- und Tag-Metadaten enthalten private Autor-E-Mail-Adressen und sind deshalb nicht für einen öffentlichen Source-Release freigegeben. Diese Git-Metadaten sind nicht Bestandteil von APK oder AAB.

## Secrets und personenbezogene Daten

- Gitleaks `v8.30.1`: 13 Vor-Release-Commits plus finaler Release-Arbeitsbaum, keine Secrets gefunden.
- Gitleaks `v8.30.1`: Snapshot aus 142 getrackten und nicht ignorierten Arbeitsbaumdateien, keine Secrets gefunden.
- Keine getrackten Keystores, `key.properties`, `.env`, PEM/P12-Dateien oder `google-services.json`.
- `.gitignore` deckt diese Dateiklassen ausdrücklich ab.
- Der absichtlich sichtbare Herstellername lautet **Günther Schuch**.
- Keine private E-Mail-Adresse und keine Wohnadresse werden in App, APK, AAB oder öffentlicher Datenschutzerklärung veröffentlicht.

## Netzwerk, Berechtigungen und lokale Daten

- Keine `INTERNET`-Berechtigung im finalen APK.
- Keine gefährlichen oder sensiblen Android-Berechtigungen.
- Die einzige deklarierte `uses-permission` ist die automatisch von AndroidX erzeugte, signaturgeschützte App-interne `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- Keine Werbe-, Analytics-, Firebase-, Crash-Reporting- oder Netzwerk-SDKs.
- Spielstände, Spielernamen und Sprachauswahl werden ausschließlich lokal über SharedPreferences gespeichert.
- `android:allowBackup="false"` und `android:fullBackupContent="false"` sind im gemergten Release-Manifest aktiv.
- `android:dataExtractionRules` schließt sämtliche App-Domänen sowohl von Cloud-Backup als auch Geräteübertragung aus.

## Release-Artefakte

| Prüfung | Ergebnis |
|---|---|
| Paket | `at.weltenwanderer.wuerfelblock` |
| Version | `1.6.0` |
| VersionCode | APK `2014` (ARM64-Split), AAB `14` |
| Min SDK | `24` |
| Target SDK | `36` |
| APK-ABI | ausschließlich `arm64-v8a` |
| AAB-ABIs | arm64-v8a, armeabi-v7a, x86_64 für Google Play |
| APK-Signatur | gültig, APK Signature Scheme v2 |
| AAB-Signatur | gültige JAR-Signatur |
| Zertifikat SHA-256 | `E02887B69D0E8C6D4A927C775D0A34BFA8F445132ECFA14B711C177FE13B92EF` |
| Lokale APK SHA-256 | `ba3e8ab153d47d23bf503f6742d08c16191895b10610415c478ac19c254a2743` |
| Lokales AAB SHA-256 | `8bbeaa1770c624840e72b9035fcd7e7c3ca2b6cfbc1a744244e92eaea5dca1b1` |

Lokale und CI-Artefakte können aufgrund von Build-Metadaten unterschiedliche Dateihashes haben. Nach dem Tag-Workflow müssen die endgültigen GitHub-Artefakte erneut heruntergeladen und separat geprüft werden.

## Qualitätsgates

- `dart format`: sauber
- `flutter analyze --fatal-infos`: keine Probleme
- `flutter test`: 268 Tests erfolgreich
- professionell kuratierter Offline-Englischkatalog: 628 Einträge
- Platzhalter-, Scanner-Debris- und Maschinenübersetzungs-Regressionschecks: erfolgreich
- APK- und AAB-Release-Build: erfolgreich

## Noch außerhalb des Codes erforderlich

- Öffentliche und live abgerufene Datenschutz-URL: https://weltenwanderer1.github.io/wuerfelblock-legal/
- Play-Console-Identität sowie öffentliche Entwickler-E-Mail hinterlegen.
- Händlerstatus bewusst festlegen.
- Data Safety, Inhaltsbewertung, Zielgruppe und App-Zugriff ausfüllen.
- Gegebenenfalls 14-tägigen geschlossenen Test mit 12 Personen absolvieren.
- Finales AAB in Play App Signing/Test-Track hochladen.

Dieser Bericht dokumentiert technische Prüfungen und ist keine Rechtsberatung.

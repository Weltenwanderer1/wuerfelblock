# Google-Play- und EU-Veröffentlichungscheckliste

Stand: 2026-07-22

> Diese Datei dokumentiert technische Prüfungen und offizielle Plattformanforderungen. Sie ersetzt keine individuelle Rechtsberatung. Händlerstatus, Monetarisierung und nationale Pflichten müssen vor dem Produktionsstart bewusst festgelegt werden.

## App und verantwortliche Person

- App: **Würfelblock**
- Paket: `at.weltenwanderer.wuerfelblock`
- Entwickelt von: **Günther Schuch**
- Vertriebsmodell des geprüften Builds: kostenlos, ohne Werbung, In-App-Käufe oder Abos
- Betrieb: vollständig offline; kein Konto, Backend, Tracking oder Analytics

## Technisch erfüllt

- [x] Android `targetSdkVersion 36` (Google Play verlangt für neue Apps mindestens API 35)
- [x] 64-Bit-Unterstützung (`arm64-v8a`)
- [x] Signierter Release-Build
- [x] CI baut APK für Direktinstallation und AAB für Google Play
- [x] Keine `INTERNET`-Berechtigung
- [x] Keine sensiblen Android-Berechtigungen
- [x] Keine Werbe-, Analyse-, Firebase- oder Netzwerk-SDKs
- [x] Spielstände, frei eingegebene Spielernamen und Spracheinstellung bleiben ausschließlich lokal
- [x] Android-Cloud-Backup und Geräteübertragung für sämtliche App-Daten explizit deaktiviert
- [x] Lokale Daten lassen sich durch Verwerfen der Partie bzw. Löschen der App entfernen
- [x] Gitleaks-Prüfung über die komplette Git-Historie: keine Secrets
- [x] Keystore und `key.properties` sind ignoriert und waren nicht committed
- [x] CI-Actions sind auf feste Commit-SHAs gepinnt
- [x] App-Repository bleibt privat; alte Commit-/Tag-Metadaten enthalten private Autor-E-Mails und sind nicht für einen öffentlichen Source-Release freigegeben
- [x] Datenschutzhinweis ist vollständig in der App erreichbar
- [x] Deutsch und Englisch sind in der App auswählbar

## Google Play Console – zwingend manuell

### Entwicklerkonto

Für ein persönliches Play-Console-Konto verlangt Google:

- rechtlichen Namen
- rechtliche Anschrift
- Kontakt-E-Mail und Telefonnummer für Google
- öffentliche Entwickler-E-Mail
- Identitätsprüfung

Google zeigt bei einem nicht monetarisierten persönlichen Konto mindestens rechtlichen Namen, Land und Entwickler-E-Mail öffentlich an. Bei Monetarisierung wird laut Google zusätzlich die vollständige Anschrift angezeigt.

**Noch offen:** Diese Daten gehören ausschließlich in die Play Console und dürfen nicht in Quellcode, APK oder Git-Historie eingetragen werden.

### Testpflicht für neue persönliche Konten

Wurde das persönliche Entwicklerkonto nach dem 13. November 2023 erstellt, verlangt Google vor Produktionszugang einen geschlossenen Test mit mindestens 12 dauerhaft angemeldeten Testpersonen über 14 aufeinanderfolgende Tage.

### App-Inhalte / Formulare

- [ ] AAB in Play App Signing aufnehmen und in einen Test-Track hochladen
- [ ] Data-Safety-Formular ausfüllen
- [x] öffentliche Datenschutz-URL veröffentlicht: https://weltenwanderer1.github.io/wuerfelblock-legal/
- [ ] Inhaltsbewertung ausfüllen
- [ ] Zielgruppe festlegen; nicht als Kinder-App deklarieren, sofern sie nicht gezielt an Kinder vermarktet wird
- [ ] Werbung: **Nein**
- [ ] App-Zugriff: **Alle Funktionen ohne Anmeldung erreichbar**
- [ ] Händlerstatus nach DSA bewusst als Händler oder Nicht-Händler erklären
- [ ] Store-Texte und Screenshots auf Deutsch und Englisch einreichen

## Empfohlene Antworten im Data-Safety-Formular

Für den geprüften Build:

- Werden Nutzerdaten gesammelt oder mit Dritten geteilt? **Nein**
- Werden Daten vom Gerät übertragen? **Nein**
- Gibt es Konten? **Nein**
- Gibt es Werbung oder Tracking? **Nein**
- Werden lokale Spielernamen/Spielstände als „gesammelt“ gemeldet? **Nein**, solange sie ausschließlich auf dem Gerät verarbeitet und nie übertragen werden. Google nimmt reine On-Device-Verarbeitung ausdrücklich von „collection“ aus.

Diese Antworten müssen nach jeder neuen Dependency oder Funktion erneut geprüft werden.

## Datenschutz / DSGVO

Die App verarbeitet freiwillig eingegebene Spielernamen und Spielstände nur lokal. Der Entwickler erhält diese Daten nicht und kann nicht darauf zugreifen. Es gibt keine Übermittlung, Profilbildung oder Gerätekennzeichen. Der Datenschutzhinweis erklärt:

- welche lokalen Daten existieren
- wofür sie benötigt werden
- dass keine Übertragung oder Weitergabe stattfindet
- wie die lokalen Daten gelöscht werden
- wer die App entwickelt hat

Da Google auch für Apps ohne Datensammlung ein Data-Safety-Formular und eine Datenschutz-URL verlangt, muss die beigefügte Policy öffentlich abrufbar gemacht werden.

## DSA / Händlerstatus

Google Play ist als Marktplatz verpflichtet, Händler zu verifizieren und deren Kontaktdaten anzuzeigen. Ob Günther Schuch als „Händler“ gilt, hängt nicht allein davon ab, ob die App kostenlos ist, sondern unter anderem von gewerblichem Zweck, Regelmäßigkeit, Monetarisierung und Auftreten.

- Rein private, nicht kommerzielle Veröffentlichung: Nicht-Händler kann naheliegen.
- Werbung, Käufe, bezahlte App, geschäftliche Vermarktung oder planmäßige Erwerbstätigkeit: Händlerstatus rechtlich prüfen.

**Keine automatische Festlegung im Code.** Die Erklärung erfolgt in der Play Console.

## Cyber Resilience Act (CRA)

Die CRA gilt für Hard- und Softwareprodukte mit digitalen Elementen, die im Rahmen einer kommerziellen Tätigkeit auf dem EU-Markt bereitgestellt werden. Vollständige Anwendung: **11. Dezember 2027**; Meldepflichten für aktiv ausgenutzte Schwachstellen und schwere Sicherheitsvorfälle: **11. September 2026**.

Für diesen Offline-Build ist das Angriffsprofil sehr klein. Falls die Veröffentlichung als kommerzielle Bereitstellung einzustufen ist:

- Sicherheitsrisikobewertung und technische Dokumentation fortführen
- Dependencies und Android-Zielversion regelmäßig pflegen
- Melde-/Kontaktweg für Schwachstellen bereitstellen
- Sicherheitsupdates für den angekündigten Supportzeitraum ermöglichen
- CRA-Konformitätsbewertung rechtzeitig vor Dezember 2027 durchführen

Der aktuelle Audit ist eine technische Vorbereitung, keine formelle CRA-Konformitätserklärung oder CE-Kennzeichnung.

## GPSR und österreichische Anbieterpflichten

Ob die GPSR auf rein digitale Software ohne körperliches Produkt unmittelbar anzuwenden ist, ist rechtlich nicht so eindeutig wie bei physischen Verbraucherprodukten. Keine ungeprüfte „GPSR-konform“-Werbeaussage verwenden.

Für eine geschäftliche Veröffentlichung aus Österreich können zusätzlich ECG-, Medien- und Verbraucherpflichten (insbesondere Anbieter-/Kontaktangaben) greifen. Name allein reicht bei geschäftlichem Auftreten regelmäßig nicht für vollständige Anbieterangaben. Anschrift und Kontaktkanal gehören dann in Store-Profil bzw. öffentliche Rechtsinformationen, nicht in den App-Code.

## Offizielle Quellen

- Google Play – Entwicklerkontodaten: https://support.google.com/googleplay/android-developer/answer/13628312?hl=en
- Google Play – Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469?hl=en
- Google Play – User Data Policy: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en
- Google Play – Testpflicht neuer persönlicher Konten: https://support.google.com/googleplay/android-developer/answer/14151465?hl=en
- Google Play – Target API: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en
- EU-Kommission – Digital Services Act: https://digital-strategy.ec.europa.eu/en/policies/digital-services-act
- EU-Kommission – CRA-Zusammenfassung: https://digital-strategy.ec.europa.eu/en/policies/cra-summary
- EU-Kommission – CRA-Meldepflichten: https://digital-strategy.ec.europa.eu/en/policies/cra-reporting
- EUR-Lex – DSGVO: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- EUR-Lex – GPSR: https://eur-lex.europa.eu/eli/reg/2023/988/oj

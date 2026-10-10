# Backgammon · Salon im Hochformat

Dieser implementierte Auftrag ersetzt die alte Mindestbreite-720-/Scroll-Vorgabe in backgammon-design.md. Inspiration: eigener Ozeandampfer-Salon um 1912, keine historische Titanic-Rekonstruktion.

## Umsetzung
- Portrait-native Geometrie in BackgammonBoardLayout: links 13–24 von oben nach unten, rechts 12–1. Sechs Reihen je Seite/Hälfte, horizontale Bar, zwei Ablagen unten. Painter und native InkWell-/Semantics-Hitregionen verwenden dieselben Rects. Keine Rotation alter 720px-Flächen.
- Normalansicht: kompakte aktive Person + beide Namen, vollständiges Brett, zwei Elfenbeinwürfel, primäre Wurf-/Zugende-/Save-Retry-Aktion und Undo/Bedienansicht. Kein Scrollable, Panning oder Zoom. Details, Pipcounts, alle Positionen und native Quell-/Zielliste im gezielten Modalpanel. Regeln auf eigener Hilfe-Route.
- Große Schrift ab Faktor 1.5 bzw. accessibleNavigation erzwingt flexible native Listenbedienung; Quellen/Ziele/Wurf/Undo/Retry/Ergebnis bleiben erreichbar. Nur diese Bedienalternative und Hilfe/Detailpanels scrollen. Querformat: Brett und Controls nebeneinander, keine Orientierungssperre.
- Stapel: bis fünf gedrechselte Steine, darüber vollständige lesbare Gesamtzahl; Bar/Ablagen haben vollständige Zähler. Globale PointIDs, Zugrichtung und Heimfelder unverändert. Auswahl mit Rahmen + Häkchen, Ziele mit Rahmen + Pfeil/Würfelwert. 48px Hauptaktionen und native Listenbuttons; Portrait-Pointhitregionen 148×30.67px statt winziger Einzelsteinziele.
- Separates lokales Salon-Theme: rötliches Mahagoni, Messing, Elfenbein und Ebenholz auch für Buttons, Dialoge, Hilfetexte, Badge und Ergebnis. Keine neuen Dependencies, Fonts oder Netzwerkzugriffe.

## Originale Runtime-Grafiken
assets/images/backgammon/mahogany.png, emblem.png, roll.png, undo.png, rules.png; pubspec registriert das Verzeichnis. Reproduzierbares eigenes Rasterverfahren: tools/draw_backgammon_salon.py (Pillow, nur Entwicklung). Würfelaugen und gedrechselte Materialsteine: lokale Canvas-Painter. Alle fünf Grafiken tatsächlich eingebunden, keine Schrift in Artwork.

## Reale Prüfung
22 gezielte Tests aus backgammon_screen_test.dart, backgammon_integration_test.dart und backgammon_acceptance_test.dart grün; nach finaler Symbol-/Fallbackkorrektur fünf Screen-Tests nochmals grün. Gezielte Analyse der sieben Dart-Dateien ohne Befund; git diff --check grün. Kein Build, keine Vollsuite, kein Commit/Push/Release.
Gemessen bei 360×800 mit SafeArea top/bottom je 24: Brett Rect(10,138,350,610); primär Rect(10,670,350,718); Point1 Rect(180,535.33,328,566). Alle 24 Points, beide Bar-/Off-Regionen, beide Würfel und Hauptaktionen im Viewport. Scrollables=0 (keine Scrollposition vorhanden, nicht bloß Offset 0). Quelle→Ziel, Bar→Point, Point→Ausspielen, Undo, Save-Retry ohne neuen Wurf, unterdrücktes Ergebnis bei fehlgeschlagenem Sieg-Save, echte manuelle Würfel, Pasch, Fortsetzen, DE/EN-Regelrouten und 200%-Fallback geprüft.

Drei selbst angesehene echte Produktionswidget-Renderings (nach Asset-Precache und Fontladen), keine Mockups:
- build/backgammon-screenshots/salon-opening.png
- build/backgammon-screenshots/salon-selected.png
- build/backgammon-screenshots/salon-save-error.png

Domain, Controller, RNG, Saveidentitäten, andere Spiele und Version bleiben unverändert. Alte UI-Matrix mit erwarteter horizontaler Scrollbedienung ersetzt; vorhandene Interaktionstests an Modal-Zugliste und Tooltip-Regelbutton angepasst. Gerätescreenreader/haptische Treffgenauigkeit und Originalsigner/APK/Release prüft Kiro im vorab angelegten Child t_0f5e2dcf. Keine Screenshots/APK vorab an Günther ausliefern (gewünschte Überraschung).
Modell/Provider: gpt-6.1-sol / openai-codex, kein Fallback.

## Kiros finale Abnahme
- Fünf Screen-/Interaktionstests nochmals mit dem tatsächlichen `buildTheme()` grün, inklusive 200%-Fallback, Bar/Ausspielen, Undo und Save-Retry. Hauptbuttons rötlich-hölzern statt massiv messingfarben; gezielte Analyse sauber. Finale Opening-/Fehlerbilder selbst angesehen, vollständiges Brett und Aktionen innerhalb 360×800 ohne Scrollable.
- Version 1.18.1+66. Master-CI führt die einzige finale Vollsuite und den signierten Split-ARM64-Build aus; APK/AAB werden ohne Actions-Artefaktspeicher zunächst als Release-Entwurf abgelegt. Kiro veröffentlicht erst nach grünem exact-SHA-Lauf und Prüfung der heruntergeladenen Originalartefakte; kein zweiter Tag-Build nötig.
- Physischer Android-/TalkBack-Test bleibt bei Günther unter #28 offen.

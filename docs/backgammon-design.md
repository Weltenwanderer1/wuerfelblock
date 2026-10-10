# Backgammon – verbindlicher Designhandoff für Forge

## 1. Scope und belegte Basis

Zwei Menschen teilen ein Gerät; echtes klassisches Backgammon, offline. Dasselbe Brett bei echten und digitalen Würfeln. Keine KI, kein Online-Spiel, keine Matchverwaltung. Empfehlung: Einzelpartie **ohne Verdopplung**; Setup und Hilfe sagen das ausdrücklich. Keine dekorative, funktionslose Cube-Grafik. Normaler Sieg/Gammon/Backgammon zählt 1/2/3 Punkte ohne Geldbezug; keine Jacoby-/Crawford-/Beaver-/automatischen Verdopplungsregeln.

Quellcode geprüft: `lib/core/app_theme.dart:3–61` definiert Papier #FFFAF3, Pflaume #673A62, Tinte #382D36, Material 3, 17-sp-Fließtext, 54-dp-Buttons und runde Karten. `lib/screens/setup_screen.dart:20–105,159–173,210–211,306–453` enthält Auswahl, Block/Digital, Spielernamen und aktuell zufällige Namensreihenfolge. `lib/widgets/die_widget.dart:6–130` enthält 62-dp-Würfel und Semantics; gehalten/locked ist NICHT identisch mit Backgammon-Würfelverbrauch. `lib/app.dart:125–163` routet Spiel/Ergebnis. Schuppenschatz hat bereits einen eigenen spielbezogenen Look (`lib/screens/dragon_game_screen.dart:11–21`); daher lokale Brettpalette statt globalem Theme-Umbau.

Keine laufende Backgammon-UI vorhanden, keine Screenshots/Attachments auf dieser Karte. Alle folgenden Maße sind Designvorgaben, keine gemessenen Screenshots. Diese Lieferung enthält keine Renderings und keine neuen Bildassets: deterministisches CustomPaint reicht aus, keine Dependencies/Fonts erforderlich. Forge muss die tatsächlichen Produktionswidgets rendern und ansehen.

## 2. Visuelle Hierarchie und Tokens

App-Chrome bleibt Papier/Pflaume wie Bestand. Holz nur Brett/Bar/Ablagen, nicht sämtliche Dialoge. Brett: ruhiges Walnussholz, cremefarbenes Leder-Inlay, dunkles Rotbraun und Salbeigrün als klassische Dreiecke, elfenbeinfarbene und nahezu schwarze Steine. Kein Neon, Glitzer, Dauerpulsieren, Plastikglanz oder thematisches Vollbild-Hintergrundfoto.

Lokale Tokens (opaque sRGB):

| Rolle | Wert / Vorgabe |
|---|---|
| Papier / Primärtext / App-Aktion | bestehend #FFFAF3 / #382D36 / #673A62 |
| Holz außen, helle Maserung, tiefe Kante | #68432D / #926744 / #38251C |
| Leder-Inlay, innere Schattierung | #E8D8B8 / #CABB9E |
| Dreieck A / B | #783F36 / #486052 |
| Heller Stein oben / Rand | #FFF5DF / #BDAA88 |
| Dunkler Stein oben / Rand | #363633 / #121916 |
| Messing dekorativ | #B99960 (niemals kleiner Text) |
| Zielbadge Hintergrund / Text | #FFFAF3 / #382D36 |
| Fokus/Auswahl | #673A62 auf Papier; auf Brett erst 2-dp Papierhalo, dann 3-dp Pflaume |
| Fehler | Material-ColorScheme.error + errorContainer, immer Icon und Text |

Kontrast-Abnahme: Fließtext mindestens 4,5:1, große Schrift 3:1, notwendige UI-Grenzen/Fokus 3:1. Die Maserung darf keinen Text durchlaufen. Farben sind Vorgaben, keine bereits verifizierten Kontrastmessungen; Forge/Sentinel berechnen reale Paare inklusive Alpha. Pips dunkel auf hell; auf dunklen Steinen kein Text ohne Papierbadge.

Abstände 4/8/12/16/24 dp. App-Seitenrand 16 dp (enge Landschaft 8). Kartenradius 16, Brettradius 14, Inlayradius 5. Titel bestehend 22 sp/700, Spieler und Hauptaktionen 17 sp/700, Information 16 sp/1,35, sekundär 14 sp. Keine Schrift unter 14 sp für notwendige Information; native Texte skalieren unverändert bis 200%. Namen umbrechen, kein ausschließliches Ellipsis. Dekorative Pointziffern dürfen 12 sp haben, weil vollständige native Punktlabels parallel existieren.

## 3. Brettgeometrie und Identität

Feste Orientierung, niemals automatisches Drehen bei Zugwechsel. Hell zieht von globalem Punkt 24 nach 1 und dann aus; Dunkel von 1 nach 24 und dann aus. Globale sichtbare Punktnummern sind stabil. Hilfe erklärt: Dunkels eigener Punkt n entspricht global 25−n. Hell unten rechts Heimfeld (1–6), Dunkel oben rechts (19–24). Keine gleichzeitigen zwei Nummerierungssets.

Obere Reihe von links nach rechts: 13,14,15,16,17,18 | Bar | 19,20,21,22,23,24.
Untere Reihe von links nach rechts: 12,11,10,9,8,7 | Bar | 6,5,4,3,2,1.
Rechts oben dunkle Ausspielablage, rechts unten helle Ausspielablage.
Start Hell: 24×2,13×5,8×3,6×5; Dunkel: 1×2,12×5,17×3,19×5. Je 15 inklusive Bar und ausgespielt.

Interaktives Brett hat **Mindestbreite 720 dp**, nicht auf 328 dp herunterskalieren. Grundgeometrie W=720: äußerer Holzrahmen 12 links/rechts; Pointfläche 12 Spalten à 48; Bar 40; rechte Ablage 64; zwei Trenner zwischen Spielfeld und Ablage/Bar zusammen 16. Summe 24+576+40+64+16=720. Links startet Pointfläche bei x=12. Erste sechs Spalten x=12…300, Bar x=300…340, danach 8-dp-Holzkante, zweite sechs x=348…636, 8-dp-Holzkante, Ablage x=644…708. Bei W>720 restliche Breite gleichmäßig auf 12 Pointspalten; Bar/Ablage bleiben fest.

H=400 in Portrait/großen Flächen; H=288 in enger Landschaft. Oben/unten Holzrahmen 12, Nummernrail 20; mittleres freies Band 24. Jede Point-Hälfte hat h=(H−88)/2. Dreieckbasis gesamte Spaltenbreite minus 4, Spitze zur Mitte, Dreieckhöhe 0,90h. Steindurchmesser d=min(40,Spaltenbreite−8); Unterkante/oberste Kante des ersten Steins 4 dp innerhalb Pointfläche. Zeichne maximal fünf sichtbare Steine; Abstand der Mittelpunkte min(d+2,(h−d−8)/4). Bei mehr als fünf: fünfter Stein bekommt native Papierbadge mit **Gesamtzahl**, z.B. „9“, nicht „+4“. Auch bei 1–5 sind Anzahl und Besitzer im Point-Semanticslabel enthalten. Opponentenfarben können nicht denselben Point teilen.

Bar: zwei gestapelte Bereiche, Dunkel oben/Hell unten, max. drei sichtbare Steine plus Gesamtzahlbadge. 40-dp-Bar zu schmal für separates 48-dp-Tapziel: deshalb eigener 48-dp-Bar-Button außerhalb des Bretts ist verpflichtend; Barpainter bleibt Anzeige, nicht überlappender Trefferbereich. Ausspielablagen zeigen flach versetzte Kanten/Steine plus Zahl 0–15; aktuelles legales Ausspielziel erhält Zielbadge. Außen zusätzlich zwei native Labels „Hell: n ausgespielt“ / „Dunkel: n ausgespielt“.

Holz: linearer Gradient #926744 → #68432D, maximal 12 feste feine gekrümmte Maserungslinien mit 6% heller/dunkler Alpha, keine Zufallswerte im paint. Inlay: flacher Gradient #E8D8B8 → #CABB9E, 1-dp Innenkante und innen 2-dp Schatten. Dreiecke matte Füllung, 1-dp Kante; keine Schatten auf jedem Dreieck. Steine: Schatten offset(0,2), blur3, schwarz 22%; radialer Gradient oben links heller, dunklere Außenkante 1,5 dp, schmale innere Ellipse 0,8 dp für gedrechselten Rand. Keine Glasreflexe. Holzdetails separat cachen; nur Belegung/Selektion neu zeichnen (`RepaintBoundary`, sinnvolles shouldRepaint).

## 4. Responsiv: tatsächlich spielbar, nicht nur overflowfrei

Ein vollständiges Brett mit 24 Punkten ist in 360 dp Breite nicht gleichzeitig mit 48-dp-Spalten spielbar. Empfehlung nicht verstecken: „Im Querformat siehst du mehr vom Brett.“ Rotation freiwillig, nicht sperren.

Portrait 360×800: SafeArea; AppBar; Spielerstatus; Wurf; 400-dp-hohes Brett in **horizontalem Scrollbereich** bei mindestens 720 dp Breite. Scrollbar und Text „Brett seitlich verschieben“; initial rechte Heimfelder sichtbar. Unterhalb native Zugliste und Aktionen. Gesamte Seite vertikal scrollbar, kein festes BottomSheet verdeckt Züge. Einfache horizontale Brettnavigation „Links / Rechts“ als 48-dp-Buttons erlaubt; nie auf Canvas schwenken durch Tooltip/Drag erzwingen.

Landschaft 800×360: SafeArea plus kompakte AppBar; LayoutBuilder auf **verfügbare**, nicht Gerätehöhe. Brett W=max(720,verfügbare Breite−16), H=288. Status/Würfel/Aktionen außerhalb, darunter/oberhalb innerhalb vertikalem Scrollbereich. Normale AppBar + 288 Brett + Actions passen nicht ohne Scroll; **Scroll ist explizit vorgesehen**, keine heimliche Schrumpfung. Optional Status/Aktionen als Seitenpanel erst ab verfügbarer Breite ≥1040 und Panel ≥280. Keine unerreichbaren Steuerungen im 800er-Layout.

Bei Text ≥150% oder aktiviertem Screenreader startet **„Zugliste“** als primäre Bedienansicht; sichtbarer Umschalter „Brett / Zugliste“ mit unverändertem Spielzustand, Brett bleibt erreichbar. Zugliste steht auch bei normalem Text unter dem Brett bereit. Sie besteht aus 48-dp-minimalen, höhenflexiblen Quellenbuttons (nur aktuell erlaubte Quellen) und nach Auswahl legalen Zielbuttons, z.B. „Punkt 13 → Punkt 8 · Würfel 5“. Bar und Ausspielen sind normale Buttons. Damit sind beide Größen bei 200% ohne pan/zoom spielbar. Vollständige Brettübersicht mit allen 24 Pointbelegungen als aufklappbare native Liste, wenn gerade keine Quellen vorhanden sind; nicht nur legalen Ausschnitt zeigen. Text200%: Moduswahl, Namen, Dicechips und Aktionen Wrap/Column, niemals FittedBox oder TextScale-Clamp. Tabs/Umschalter ebenfalls umbruchfähig.

Brett-Hitflächen Pointspalte×halbe Brettfläche, nicht bloßer Steinkreis. Die 48-dp-Spalten berühren sich ohne Überlappung. Painter und Hit-Rect verwenden exakt dieselbe Geometrie. Horizontaler Scroll gewinnt bei Scrollgeste; einfacher Tap führt Zugauswahl aus. Keine Drag-Pflicht, kein 24-Punkte-Mini-Brett als einzige Steuerung.

## 5. Ablauf und Interaktionen

Setup-Auswahl: „Backgammon“ / „Zwei Personen · echtes Brett · echte oder digitale Würfel“. Bestand-GameMode weiterverwenden, aber spielbezogene Labels „Echte Würfel“ und „Digitale Würfel“. Echte: „Würfelt am Tisch und gebt die beiden Werte ein. Die App führt das Brett.“ Digital: „Die App würfelt; ihr bewegt die Steine.“ Zusatz „Einzelpartie ohne Verdopplung“. Genau zwei Namen, keine Hinzufügen/Entfernen-Buttons. Für Backgammon keine zufällige Namensreihenfolge: Name1=Hell, Name2=Dunkel; der Eröffnungswurf entscheidet, nicht Setup-Shuffle. Vor Start Rollen sichtbar.

Spielstatus: eigenes rundes Steinmuster + „Name · Hell/Dunkel · am Zug“, Gegner darunter/zweite Karte, Pipcounts „Noch n Augen bis zum Ausspielen“ optional in Details statt unerklärtes „Pips“. Aktiver Spieler hat zusätzlich „Am Zug“ und Kontur, nicht nur Farbwechsel. Richtungsinfo außerhalb: „Hell: 24 → 1 → Ausspielen“ / „Dunkel: 1 → 24 → Ausspielen“. Keine automatische Rotation/Seitenwechsel.

Eröffnung: Überschrift „Eröffnungswurf“, je Spieler ein Würfel. Digital Aktion „Eröffnungswurf würfeln“ produziert beide Einzelwerte einmal. Echte Eingabe hat zwei benannte Gruppen „Name · Hell“ und „Name · Dunkel“, jeweils Auswahl 1–6 (48-dp-Buttons, Wrap). Kein voreingestelltes Ergebnis; Bestätigen erst bei zwei expliziten Werten. Gleichstand erklärt „Gleichstand – beide würfeln noch einmal“ und erneuert nur die Eröffnung. Gewinner beginnt mit genau den zwei ermittelten Werten, kein zusätzlicher Normalwurf.

Normalwurf: digital „Würfeln“, echte „Wurf eingeben“ mit zwei Gruppen „Würfel 1/2“, 1–6, leerer Ausgangswert, Vorschau und „Wurf übernehmen“; Abbrechen mutiert nichts. Nach Übernahme Werte bis nächstem Zug unveränderlich. Keine Zufallsanimation im echten Modus. Digitale kurze Animation höchstens 200 ms erst nach gesichertem Ergebnis, reduced motion sofort.

Verbrauch: zwei unveränderliche Ergebniswürfel, darunter einzelne native Verbrauchschips „5 · offen“ / „3 · verwendet ✓“. Pasch zeigt „Pasch – vier Züge mit 4“ und vier 4er-Chips; nicht nur zwei Dice mit unklarem „x2“. Die Chips sind Status, keine Würfel-Haltebuttons. Vor Wurf keine erfundenen 1er zeigen, sondern „Noch kein Wurf“.

Quelle antippen → 3-dp-Außenring plus Häkchenbadge, native Meldung „Punkt 13 gewählt. Ziel auswählen.“ Erlaubte Ziele: Papierbadge mit Pfeil und Würfelwert, markierter Pointumriss; Textliste nennt jedes Ziel. Nur durch globale Maximalverbrauch-Regel erlaubte Fortsetzungen anbieten, nicht lokal legale Sackgassen. Antippen desselben Quellpunkts oder „Auswahl aufheben“ beendet Auswahl. Andere erlaubte Quelle ersetzt Auswahl. Gegner/gesperrter Point bewegt nichts; kurze inline Erklärung, keine Modalflut.

Ein Tap bewegt **einen Stein um genau einen Würfelwert**. Keine unsichtbare automatische Summe beider Würfel. Wenn ein Ausspielziel mehrere zulässige Werte verbrauchen könnte: vor Bewegung native Auswahl „Mit Würfel 3 / Mit Würfel 5“, nur zulässige Alternativen. Ein Ziel mit gegnerischem Einzelstein sagt „Punkt 8 · schlagen · Würfel 5“. Barpriorität: automatisch Bar als Quelle wählen; „Zuerst n Steine von der Bar einsetzen“, normale Quellen deaktiviert. Ausspielen erst nach regelkonformem Heimfeldzustand; Erklärung im Hilfetext, nicht dekorativer Ablageblink.

Zugende: nach Verbrauch aller spielbaren Werte „Zug abschließen“. Wenn keine Fortsetzung: „Keine weiteren legalen Züge. n Würfel nicht spielbar.“ Bei komplett blockierter Bar „Bar blockiert – kein Einsetzen möglich“. Abschluss ist explizit, gibt Zeit für Undo und Geräteübergabe; keine Reroll-Taste im selben Zug. Vorzeitiger Abschluss niemals aktiv. Bei höheren-Würfel-Pflicht „Nur ein Wert spielbar: der höhere Würfel muss verwendet werden.“

Undo: „Letzten Zug zurücknehmen“, nur Bewegungen innerhalb des aktuellen Wurfs, inklusive geschlagenem Stein/Bar und Verbrauch. Disabled vor erster Bewegung, während Speichern, nach Abschluss/Sieg. Wurf und Eröffnung werden nicht zurückgerollt; kein neues RNG. Abschlussbutton heißt danach für nächsten Spieler vor dessen Wurf wieder „Würfeln“/„Wurf eingeben“.

## 6. Zustände, Persistenz, Ergebnis

Initiales Laden: native Fortschrittsanzeige „Partie wird geladen“, kein Startbrett als vermeintlicher gespeicherter Zustand. Kein Save vorhanden: Home bietet neue Partie, kein Geisterspiel. Beschädigter Save: bestehende Fehlerstrategie mit verständlicher Meldung, nicht stillschweigend neues Backgammon starten.

Speichern: Transaktionsstrategie der bestehenden Controller übernehmen, nicht im Design ändern. Pending/saving sperrt sämtliche mutierenden Aktionen und zeigt „Wird gespeichert …“. Bei Fehler **persistente Inline-Karte** oberhalb Zugaktionen: „Speichern fehlgeschlagen. Dieser Stand ist noch nicht gesichert.“ + „Erneut speichern“. Brett zeigt eindeutig denselben ausstehenden Stand, keinerlei neue RNG/Wurf-/Zugfortschritte. Retry verwendet exakt denselben Zustand, keine neue Würfelberechnung. Auswahl darf gelesen, aber nicht bewegt werden. Screenreader-LiveRegion bei Fehler/Erfolg; Erfolg „Gespeichert“ ruhig inline, keine Toastflut pro Stein. Beim Verlassen mit ungelöstem Savefehler Warnung und „Hier bleiben“ als Default; keine Garantie eines gesicherten Stands. Mehrfach-Taps führen genau eine Transaktion aus.

Zurück bei erfolgreichem Save pausiert/kehrt Home zurück, kein destruktives „Beenden“. „Partie verwerfen“ nur im Overflow, Bestätigungsdialog mit Verlusttext, Abbrechen zuerst. Keine Verwechslung mit „Zug abschließen“. Regeln jederzeit lesbar, nach Rückkehr identischer Zustand.

Sieg: letzter legaler Ausspielzug wird gesichert, dann Ergebnis. Bei Savefehler bleibt Siegerstellung samt Savehinweis und keine neue Partie startet. Ergebnis zeigt Name, Farbe, „Gewonnen“, Typ plus kurze Begründung: normal „Die andere Person hat bereits Steine ausgespielt“ (1 Punkt); Gammon „Die andere Person hat keinen Stein ausgespielt“ (2 Punkte); Backgammon „Kein Stein ausgespielt und noch Steine auf der Bar oder in deinem Heimfeld“ (3 Punkte). Typeberechnung kommt aus Domain, kein UI-Heuristik. „Brett ansehen“ read-only und „Zur Startseite“, neue Partie über vorhandenen sicheren Setupweg. Keine Gewinneranimation nötig, reduced motion respektieren.

Hilfe in kurzen Abschnitten: Ziel/Startaufstellung; Richtungen und stabile Punktnummern; einzelne Würfelbewegung und Zwischenschritt; maximaler Verbrauch/höherer Wert; Pasch; Schlagen/Bar; Ausspielen/Überwurf; Eröffnung; Siegtypen; echte Eingabe/Undo. Quelle: Backgammon Galore, https://www.bkgm.com/rules.html (für diese Spezifikation erneut abgerufen). Optionalregeln als **nicht verwendet** nennen. DE/EN vollständig einschließlich Eingabe, Fehler, Semantics und dynamischer Namen; Namen unverändert einsetzen, keine Übersetzung ganzer zusammengesetzter Strings ohne sichere Platzhalter. Beispiel EN: “Physical dice”, “Enter roll”, “Opening roll”, “Bear off”, “Undo last move”, “Save failed. This position has not been saved yet.”

## 7. Flutter-Vertrag und Accessibility

Vorgeschlagene Verantwortlichkeiten, keine existierenden Symbole behauptet: `BackgammonBoardPainter` nur Materialien/Points/Steine; gemeinsames BoardLayout liefert Zeichen- und Hitrects; natives Overlay für Ziel/Anzahl/Focus; `BackgammonTurnPanel` für Wurf/Verbrauch; `BackgammonMoveList` als gleichwertige Bedienung. Sämtliche Legalität und Verbrauch vom Controller/Domain, keine Regeln im Painter. Native Text-/Buttonwidgets außerhalb dekorativer Leinwand. Keine neuen Packages.

Bestehendes DieWidget kann nicht blind wiederverwendet werden: seine `held`-Semantik bedeutet gehalten, `locked` wird nicht gesprochen. Entweder neue lokale noninteractive Diceface mit bestehender Pips-Geometrie oder gezielt passende semantische Labels plus externe Chips; keine „nicht gehalten“-Meldungen in diesem Spiel. Würfelstatus und Ergebnis nicht doppelt durch verschachtelte Semantics vorlesen.

Jeder Point als eigener Semanticsknoten: „Punkt 13, 5 helle Steine“, Rolle Button nur wenn auswählbar, selected/disabled korrekt; Ziele zusätzlich „Ziel, Würfel 5, schlägt einen dunklen Stein“. Bar und Ablage erhalten Besitzer/Anzahl. Dekorativer Painter ExcludeSemantics; native Übersicht liefert vollständiges Brett. Fokus Reihenfolge: aktiver Spieler → Würfel → Quellen → Ziele → Undo → Abschluss → Regeln. Tab/ShiftTab, Enter/Space funktionieren; Escape hebt Auswahl auf, nicht Partie verwerfen. Kein Keyboard-Trap im Scrollbereich/Dialog. Nach Bewegung Fokus auf nächste erlaubte Quelle oder Abschluss, LiveRegion „Hell: Punkt 13 nach 8, Würfel 5 verwendet“. Nach Wurf Fokus auf Quellenüberschrift, nicht willkürlich Gegnername.

48×48 dp Mindestziel für jedes Bedienelement; keine überlappenden Canvas-Hits. Auswahl/Legalität zusätzlich durch Ring, Häkchen/Pfeil und Text, nicht allein Farbe. 200% Text keine abgeschnittenen Namen/Buttons. Portrait und Landschaft ohne Orientierungslock. Haptik optional dezent bei Bewegung, nie einzige Rückmeldung. Kein dauerhaft animierter Glow; nur 120–180-ms-Auswahländerung, disableAnimations ausschalten. Keine Textspiegelung bei dunklem Zug.

## 8. Testbare Abnahme (Forge implementiert, Sentinel prüft)

1. Setup → echte/digitale Eröffnung → Bewegung → Pause/Fortsetzen → Sieg in DE/EN. Exakt zwei Farben/Namen, gleiche Brettgeometrie, keine Blockmodus-RNG-Werte, kein zusätzlicher Wurf nach Eröffnung.
2. Vollständige 24 Points in obiger Reihenfolge, richtige 15er-Aufstellung, beide Barsegmente/Ablagen; 1,5,9,15 auf einem Point überlappen keine gegnerische Hälfte und zeigen Gesamtzahl. Globale Richtung bleibt beim Spielerwechsel stabil.
3. Quellen/Ziele entsprechen maximal legaler Zugsequenz inklusive höherem Würfel, Barpriorität, Überwurf und vierfach Pasch. Kein vorzeitiger Abschluss, keine Summe ohne Zwischenzug. Zielmehrdeutigkeit beim Ausspielen explizit auflösen.
4. Undo restauriert Schlagen/Bar/Verbrauch ohne neuen Wurf; Savefehler+Retry erhält identische Würfel und sperrt Fortschritt. Mehrfach-Tap keine Doppelaktion. Erfolgsnavigation erst nach Save.
5. Produktionswidget-Screenshots bei 360×800 und 800×360, jeweils Text100%/200%, DE/EN, SafeArea aktiv. Tatsächlich ansehen: kein Overflow, alle Aktionen erreichbar, Wurf-/Namenslabels nicht abgeschnitten, Brett nicht unspielbar verkleinert. Bei 200% komplette Partie allein via Zugliste bedienbar. Scrollbarkeit ist akzeptiert und sichtbar.
6. Screenshotzustände: Startaufstellung; Quelle plus zwei Ziele; geschlagener Stein/Bar; 9er-Stapel; Paschverbrauch; Ausspielen; Savefehler; Sieg. Materialdetails subtil und lesbar, keine zufällige Maserung zwischen Frames.
7. TalkBack/Widget-Semantics prüfen: alle 24 Pointbelegungen zugänglich, aktiv/ausgewählt/legal korrekt, eindeutige Würfelwerte/Verbrauch ohne gehalten-Sprache. Tastatur gesamte Sequenz inklusive Dialog und Escape; Fokus bleibt sichtbar.
8. Reale Farbpaare berechnen und Kontrast bestätigen; mindestens 48-dp-Hits inkl. Bar-Button; reduzierte Bewegung ohne verzögerte Aktion. Keine Canvas-Texte als einzige Information.

Offene Risiken: reale Produktionsrenderings/Materialwirkung und Kontraste sind erst nach Forge-Implementierung verifizierbar. Querformat mit wenig Höhe benötigt bewusst Scroll; ein kleineres Komplettbrett ohne gleichwertige native Bedienung ist keine akzeptable Abkürzung. Keine Produktentscheidung blockiert diesen Handoff; Verdopplung bewusst weggelassen.

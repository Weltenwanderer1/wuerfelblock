# Spielregeln: Kartenspiele mit Standarddeck

## Ziel

Eine eigenständige, lesbare **Spielregeln**-Sektion in Würfelblock. Sie ist zunächst eine Regelhilfe und kein neuer digitaler Spielmodus: drei Kartenspiele aus den bereitgestellten Regelquellen werden vollständig erklärt und ausdrücklich auf ein normales Rummy-/Canasta-Deck angepasst.

## UI

- Home bekommt genau einen neuen Einstieg **Spielregeln**.
- Der Einstieg öffnet `CardGamesRulesScreen`.
- Die Seite nutzt eine scrollbare, auswählbare Darstellung mit drei klar getrennten Spielkarten: Crisps!, Regicide und Haggis.
- Jede Regelkarte enthält Ziel, Material/Deckanpassung, Vorbereitung, Zugablauf, Kombinationen bzw. Sonderregeln, Rundenende und Sieg/Abrechnung.
- Keine Aufnahme der Spiele in `SetupScreen`, keine Persistenz und keine neue Spiel-Engine.

## Verbindliche Standarddeck-Anpassungen

### Crisps! — 2 Personen

- Ein normales 52er-Deck verwenden, Farben ignorieren.
- Buben und Könige entfernen; im Spiel bleiben Ass bis 10 und vier Damen = 44 Karten.
- Ass zählt als 1. Die Damen ersetzen die vier speziellen „Crisps“-Karten, sind die höchsten Einzelkarten/Paare und dürfen nicht in Straßen vorkommen.
- 12 Karten pro Person geben; die nächsten 4 Karten ungesehen beiseitelegen; die nächste Karte offen auslegen; der Rest bleibt verdeckt als Nachziehstapel. Die hungrigere Person beginnt den ersten Deal.
- Standardkombinationen: Einzelkarte, Paar, Straße aus mindestens 3 aufeinanderfolgenden Werten, Straße aus mindestens 2 aufeinanderfolgenden Paaren. Gleicher Typ und gleiche Länge müssen mit gleichem oder höherem Rang überboten werden.
- Spezialkombinationen: genau drei oder vier gleiche Karten (ohne Damen, weil Damen nur Einzelkarte/Paar sind). Sie dürfen eröffnet werden. Eine Spezialkombination darf nur auf eine gewöhnliche Kombination gelegt werden, die eine oder zwei Damen enthält; danach darf nur noch eine stärkere Spezialkombination folgen. Drei gleiche Karten werden durch ein höheres Dreierset oder jeden Vierling geschlagen; ein Vierling nur durch einen höheren Vierling.
- Wer passt, beendet die laufende Runde. Die zuletzt ausgespielte Person gewinnt, wählt offen oder verdeckt; die andere Person nimmt die verbleibende Karte. Gespielte Karten kommen aus dem Spiel. Danach eröffnet der Gewinner die nächste Runde; eine neue offene Karte wird vom Stapel aufgedeckt. Ist der Stapel leer, wird nur noch ausgespielt.
- Wer zuerst die eigene Hand leert, gewinnt den Deal und erhält einen Punkt. Nach jedem Deal komplett neu mischen; wer weniger Punkte hat, beginnt. Gleichstand: die Person, die im vorherigen Deal nicht begonnen hat. Wer zuerst 3 Punkte erreicht, gewinnt.

### Regicide — kooperativ, 1–4 Personen

- Am besten ein 52er-Deck plus 2 Joker verwenden. Buben, Damen und Könige bilden das Schloss; Ass bis 10 bilden mit den Jokern die Taverne. Für 3/4 Personen werden 1/2 Joker benötigt; ohne Joker nur mit 1/2 Personen spielen oder Ersatzkarten eindeutig als Joker markieren.
- Schloss verdeckt stapeln: Könige unten, Damen darauf, Buben oben; oberste Karte aufdecken. Gegnerwerte: Bube Angriff 10/Gesundheit 20, Dame 15/30, König 20/40.
- Tavernenkarten: Ass = Tiergefährte mit Wert 1, Zahlenkarten zählen ihren Wert, Joker = Narr mit Wert 0. Handmaximum: 1 Person 8, 2 Personen 7, 3 Personen 6, 4 Personen 5 Karten.
- Jeder Zug: (1) eine Karte spielen oder passen/„Yield“, (2) Farbkraft ausführen, (3) Schaden zufügen und Niederlage des Gegners prüfen, (4) bei überlebendem Gegner den Angriff durch Abwerfen bezahlen.
- Herz heilt aus dem offenen Ablagestapel, indem Karten in Höhe des Angriffswerts ungesehen unter die Taverne gelegt werden; Karo lässt reihum Karten ziehen, nie über das Handmaximum; Kreuz verdoppelt den in diesem Zug verursachten Schaden; Pik senkt den Angriff des aktuellen Gegners dauerhaft um den Wert aller gegen ihn gespielten Pik.
- Farbenkräfte sind Pflicht. Herz und Karo werden sofort abgehandelt, bei einer Kombination zuerst Herz (Heilung), dann Karo (Ziehen); Kreuz und Pik wirken in den späteren Schritten. Ein Gegner ist gegen seine eigene Farbe immun; der Kartenwert zählt trotzdem zum Schaden. Ein Joker hebt diese Immunität für den Gegner auf. Wird ein Joker gegen einen Pik-Gegner gespielt, zählen zuvor gespielte Pik-Karten rückwirkend als Schild; zuvor gespielte Kreuz-Karten werden gegen einen Kreuz-Gegner nicht nachträglich verdoppelt.
- Angriffe können als einzelne Karte oder als 2/3/4 gleiche Zahlenkarten gespielt werden, solange ihre Summe höchstens 10 ist. Tiergefährten dürfen allein oder mit genau einer anderen Karte gespielt werden; zwei passende Tiergefährten wenden eine Farbkraft nur einmal an. Ein Narr wird allein gespielt, negiert die Immunität, macht 0 Schaden, überspringt Schaden und Gegenangriff und bestimmt, wer als Nächstes spielt.
- Nach einem besiegten Gegner kommen alle gespielten Karten in den Ablagestapel; bei exakt passendem Schaden kommt der Gegner verdeckt oben auf die Taverne, sonst offen in den Ablagestapel. Der besiegte Spieler beginnt sofort gegen den neuen Gegner. Ein später gezogener Bube, eine Dame oder ein König zählt als Angriffs- bzw. Abwurfkarte 10/15/20; seine Farbkraft gilt normal.
- Beim Gegenangriff müssen Karten offen abgelegt werden, bis ihr Gesamtwert mindestens dem modifizierten Angriff entspricht. Bube zählt 10, Dame 15, König 20, Ass 1, Joker 0. Wer das nicht schafft, verliert die Partie; eine leere Hand ist erlaubt.
- Yield überspringt Farbkraft und Schaden und führt direkt zum Gegenangriff. Man darf nicht passen, wenn alle anderen Personen in ihrem letzten Zug gepasst haben. Kommunikation darf keine Handkarten verraten oder nahelegen; Handgröße und öffentliche Stapelinfos sind erlaubt. Nach einem Joker darf bis zum Beginn des nächsten Zuges allgemein über die gewünschte nächste Person gesprochen werden.
- Sieg: den letzten König besiegen. Niederlage: Gegenangriff nicht bezahlen oder weder Karte spielen noch passen können. Solo: eine Hand mit maximal 8 Karten; zwei beiseitegelegte Joker können je einmal zu Beginn von Schritt 1 oder 4 die Hand abwerfen und wieder auf 8 auffüllen, ohne die Immunität zu brechen. 2 eingesetzte Joker ergeben Bronze, 1 Silber, 0 Gold.

### Haggis — Standarddeck-Variante, 2–3 Personen

- Ein normales 52er-Deck mit vier Farben verwenden; Ass zählt als 1, danach 2–10. Die offenen Buben, Damen und Könige sind persönliche Jokerkarten.
- Pro Person einen Buben, eine Dame und einen König offen auslegen. Bei 2 Personen werden 2 Exemplare jedes Rangs, bei 3 Personen 3 Exemplare jedes Rangs benötigt. Die übrigen Buben/Damen/Könige kommen in den Haggis-Stapel und sind keine Joker. Pro Person 13 verdeckte Handkarten geben; der Rest ist Haggis. Die 13 statt 14 Karten sind die notwendige Anpassung an ein einzelnes Standarddeck.
- Rangfolge von niedrig nach hoch: Ass, 2–10, Bube, Dame, König. Offene Buben/Damen/Könige können als normale Einzelkarte, als Set oder als Straßenbestandteil gespielt werden und dabei jede niedrigere Karte ersetzen; in einer größeren Kombination muss mindestens eine echte Zahlenkarte enthalten sein.
- Ein Set besteht aus 1–8 Karten gleichen Wertes. Eine Straße besteht aus mindestens 3 aufeinanderfolgenden Einzelkarten oder mindestens 2 gleich großen, aufeinanderfolgenden Sets. Bei Straßen muss die Farbenkombination der einzelnen Sets gleich bleiben; Joker dürfen eine beliebige Farbe annehmen.
- Bomben, von niedrig nach hoch: 3-5-7-9 in vier verschiedenen Farben (ohne Joker), B-D, B-K, D-K, B-D-K, danach 3-5-7-9 in derselben Farbe (ohne Joker). Bomben dürfen jede normale Kombination schlagen; nach einer Bombe darf nur eine höhere Bombe folgen.
- Wer dran ist, darf eine höhere Kombination gleichen Typs und gleicher Kartenanzahl legen oder passen. Ein Stich endet bei 2 Personen nach einem Pass, bei 3 Personen nach zwei aufeinanderfolgenden Pässen. Passt im Dreierspiel zunächst nur eine Person, darf sie später wieder mitspielen. Die höchste ausgespielte Kombination gewinnt und nimmt die gespielten Karten; wer mit einer Bombe gewinnt, verschenkt die Karten an eine andere Person nach eigener Wahl. Die Stichgewinnerin eröffnet den nächsten Stich.
- Solange eine Person in der Runde noch keine Karte gespielt hat, darf sie einmalig auf das erste Leeren der Hand wetten: keine Wette, 15 oder 30 Punkte; danach nicht mehr ändern. Erfolgreiche Wetten zählen für die Gewinnerin, verlorene Wetten gehen an die Person, die zuerst leer war; Personen ohne Wette erhalten die Wette der jeweiligen Gegnerin.
- Rundenende: Bei 2 Personen endet die Runde sofort, wenn eine Hand leer ist. Bei 3 Personen endet sie, sobald die zweite Person leer ist; diese erhält den letzten Stich, außer er wurde durch eine Bombe gewonnen. Die letzte Person spielt nicht weiter. Die Handkarten der letzten Person und der Haggis gehen an die erste Person, die leer war. Vor dem Abgeben die Kartenanzahl einschließlich Joker notieren.
- Wertung: Die erste Person mit leerer Hand erhält 5 Punkte je Karte auf der größten gegnerischen Hand einschließlich offener Joker. Erbeutete 3er, 5er, 7er und 9er zählen je 1 Punkt, Buben 2, Damen 3, Könige 5. Dazu kommen die Wetten. Neue Runde: Punkte addieren, neu geben; die Gesamtführende gibt, die Person mit dem niedrigsten Gesamtstand eröffnet, bei Gleichstand die Person links von der Geberin. Ziel 250 Punkte (kurz) oder 350 Punkte (lang); bei Gleichstand weiterspielen.

## Quellen

- Crisps! Rules 1.0 PDF, vom Nutzer bereitgestellt; ergänzend die offizielle Crisps!-Beschreibung und das Video-Regeltranskript.
- Regicide Rules A4 PDF, vom Nutzer bereitgestellt: https://www.regicidegame.com/site_files/33132/upload_files/RegicideRulesA4.pdf
- Haggis-Regeln, vom Nutzer bereitgestellt: https://www.bambusspieleverlag.de/archiv/download/haggis.pdf

Die Texte in der App sind ausdrücklich als **Standarddeck-Varianten** gekennzeichnet, nicht als unveränderte Originalmaterialien.

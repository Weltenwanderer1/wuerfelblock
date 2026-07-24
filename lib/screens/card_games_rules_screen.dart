import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../core/app_theme.dart';
import 'regicide_counter_screen.dart';

enum CardGame { crisps, regicide, haggis }

class CardGameRulesScreen extends StatelessWidget {
  const CardGameRulesScreen({required this.game, super.key});

  final CardGame game;

  static const _games = <_GameRules>[
    _GameRules(
      kind: CardGame.crisps,
      keyName: 'crisps',
      title: 'Crisps!',
      subtitle: 'Standarddeck-Variante · 2 Personen',
      icon: Icons.layers_outlined,
      accent: AppColors.rose,
      sections: [
        _RulesSection(
          'Ziel',
          'Leere deine Hand vor der anderen Person. Jeder gewonnene Deal bringt 1 Punkt; wer zuerst 3 Punkte erreicht, gewinnt das Spiel.',
        ),
        _RulesSection(
          'Material & Deckanpassung',
          'Verwendet ein normales 52er-Deck und ignoriert die Farben. Buben und Könige entfernen; im Spiel bleiben Ass bis 10 sowie die vier Damen, insgesamt also 44 Karten. Das Ass zählt als 1. Die Damen ersetzen die vier besonderen „Crisps“-Karten: Sie sind die höchsten Einzelkarten und Paare, dürfen aber nie Teil einer Straße sein.',
        ),
        _RulesSection(
          'Vorbereitung',
          'Mischt alle 44 Karten und gebt jeder Person 12 Karten. Legt die nächsten 4 Karten ungesehen beiseite. Deckt danach 1 Karte offen auf; die übrigen Karten bilden den verdeckten Nachziehstapel. Die hungrigere Person – also wer mehr Appetit auf Crisps hat – beginnt den ersten Deal.',
        ),
        _RulesSection(
          'Gewöhnliche Kombinationen',
          'Du darfst eine Einzelkarte, ein Paar, eine Straße aus mindestens 3 aufeinanderfolgenden Werten oder eine Straße aus mindestens 2 aufeinanderfolgenden Paaren ausspielen. Eine bereits liegende Kombination muss mit demselben Typ und derselben Kartenanzahl sowie mit gleichem oder höherem Rang überboten werden.',
        ),
        _RulesSection(
          'Spezialkombinationen',
          'Genau 3 oder 4 gleiche Karten bilden eine Spezialkombination. Damen sind ausgeschlossen, weil sie nur einzeln oder als Paar gespielt werden dürfen. Eine Spezialkombination darf einen Durchgang eröffnen. Auf eine gewöhnliche Kombination darf sie jedoch nur gelegt werden, wenn diese 1 oder 2 Damen enthält; danach darf nur noch eine stärkere Spezialkombination folgen. Ein Dreierset wird von einem höheren Dreierset oder jedem Vierling geschlagen. Einen Vierling schlägt nur ein höherer Vierling.',
        ),
        _RulesSection(
          'Passen & Rundenende',
          'Sobald jemand passt, endet die laufende Runde. Die Person, die zuletzt Karten ausgespielt hat, gewinnt. Sie wählt die offen liegende oder die verdeckte Karte; die andere Person nimmt die verbleibende Karte. Alle ausgespielten Karten kommen aus dem Spiel. Die Gewinnerin oder der Gewinner eröffnet die nächste Runde, und vom Stapel wird eine neue offene Karte aufgedeckt. Ist der Stapel leer, spielt ihr nur noch eure Handkarten aus.',
        ),
        _RulesSection(
          'Deal & Spielsieg',
          'Wer zuerst keine Handkarten mehr hat, gewinnt den Deal und erhält 1 Punkt. Mischt nach jedem Deal das gesamte Deck neu. Den nächsten Deal beginnt, wer weniger Punkte hat. Bei Gleichstand beginnt die Person, die im vorherigen Deal nicht begonnen hat. Das Spiel endet, sobald jemand 3 Punkte erreicht.',
        ),
      ],
    ),
    _GameRules(
      kind: CardGame.regicide,
      keyName: 'regicide',
      title: 'Regicide',
      subtitle: 'Standarddeck-Variante · kooperativ · 1–4 Personen',
      icon: Icons.shield_outlined,
      accent: AppColors.lavender,
      sections: [
        _RulesSection(
          'Ziel',
          'Ihr spielt als Team gegen das Spiel. Besiegt nacheinander alle 12 Gegner im Schloss – erst die 4 Buben, dann die 4 Damen, zuletzt die 4 Könige. Schafft ihr den letzten König, habt ihr gemeinsam gewonnen. Kann das Team einen Gegenangriff nicht bezahlen oder hat keine Karten mehr zum Ausspielen oder Passen, verliert ihr gemeinsam.',
        ),
        _RulesSection(
          'Material',
          'Ein normales 52er-Kartendeck plus 2 Joker. Die 12 Bildkarten (Buben, Damen, Könige) bilden das Schloss – eure Gegner. Ass bis 10 plus Joker bilden die Taverne – euer Nachziehstapel. Solo und zu zweit spielt ihr ohne Joker. Zu dritt mischt ihr 1 Joker in die Taverne, zu viert beide Joker. Habt ihr keine Joker, markiert einfach zwei Ersatzkarten eindeutig als solche.',
        ),
        _RulesSection(
          'Das Schloss aufbauen',
          'Trennt die 12 Bildkarten in drei Gruppen: 4 Könige, 4 Damen, 4 Buben. Mischt jede Gruppe einzeln. Baut dann einen verdeckten Stapel mit den Königen ganz unten, den Damen in der Mitte und den Buben ganz oben. Deckt den obersten Gegner (einen Buben) auf – der erste Kampf beginnt.',
        ),
        _RulesSection(
          'Gegner-Werte',
          'Bube: Angriff 10, Gesundheit 20 (4 Stück). Dame: Angriff 15, Gesundheit 30 (4 Stück). König: Angriff 20, Gesundheit 40 (4 Stück). Der Angriffswert bestimmt, wie viel Schaden der Gegner bei seinem Gegenangriff verursacht. Die Gesundheit bestimmt, wie viel Schaden ihr zufügen müsst, um ihn zu besiegen.',
        ),
        _RulesSection(
          'Taverne & Handkarten',
          'Die Taverne ist euer Nachziehstapel. Zieht nach, bis jede Person das Handmaximum erreicht hat. Solo: max. 8 Karten, zu zweit: max. 7, zu dritt: max. 6, zu viert: max. 5. Kartenwerte: Zahlenkarten zählen ihren aufgedruckten Wert, das Ass zählt als 1 (Tiergefährte), Joker zählen als 0 (Narr). Besiegte Gegner, die in der Taverne liegen, zählen als 10 (Bube), 15 (Dame) oder 20 (König), wenn ihr sie später ausspielt oder abwerft.',
        ),
        _RulesSection(
          'Zugablauf – Schritt 1: Karte spielen',
          'Spielt entweder eine einzelne Karte oder eine Kombination aus eurer Hand – oder passt (Yield). Erlaubte Kombinationen: 2 bis 4 gleiche Zahlenkarten, deren Summe höchstens 10 beträgt (z. B. zwei 5er = 10, drei 3er = 9). Tiergefährten (Asse) dürfen allein oder mit genau 1 weiteren Karte kombiniert werden. Ein Narr (Joker) wird immer allein gespielt. Wer nicht spielen kann oder will, muss passen.',
        ),
        _RulesSection(
          'Zugablauf – Schritt 2: Farbkraft',
          'Die Farbe der gespielten Karte löst eine Pflicht-Farbkraft aus. Bei mehreren Karten derselben Farbe zählt der Gesamtwert. Herz: Mischt den offenen Ablagestapel, zählt so viele Karten ab wie der Angriffswert, legt sie ungesehen unter die Taverne, dann kommt der Rest offen zurück. Karo: Zieht so viele Karten wie der Angriffswert – erst du, dann im Uhrzeigersinn; das Handmaximum darf nie überschritten werden. Kreuz: Verdoppelt den gesamten Schaden dieses Zuges. Pik: Senkt den Angriff des aktuellen Gegners dauerhaft um den Pik-Wert – das gilt auch für spätere Züge gegen denselben Gegner. Bei verschiedenen Farben: Herz und Karo werden sofort abgehandelt (Herz vor Karo), Kreuz und Pik wirken als Modifikatoren auf den Schaden.',
        ),
        _RulesSection(
          'Farb-Immunität',
          'Ein Gegner ist gegen seine eigene Farbe immun. Beispiel: Gegen den Pik-König verursachen Pik-Karten keinen Schaden – der Kartenwert zählt aber trotzdem als Angriffsbeitrag. Ein Narr (Joker) hebt die Immunität des aktuellen Gegners auf: Zuvor gespielte Pik-Karten zählen dann rückwirkend als Schild, aber zuvor gespielte Kreuz-Karten werden nicht nachträglich verdoppelt.',
        ),
        _RulesSection(
          'Zugablauf – Schritt 3: Schaden prüfen',
          'Addiert den Gesamtwert aller in diesem Zug gespielten Karten, wendet Kreuz-Verdopplung und Pik-Schild an. Erreicht der Schaden die Gesundheit des Gegners oder mehr, ist er besiegt. Exakt passender Schaden: Der Gegner kommt verdeckt auf die Taverne (ihr könnt ihn später nachziehen). Überschüssiger Schaden: Der Gegner kommt offen auf den Ablagestapel. Alle gegen ihn gespielten Karten kommen ebenfalls auf den Ablagestapel. Die Person, die den Gegner besiegt hat, beginnt sofort gegen den nächsten aufgedeckten Gegner.',
        ),
        _RulesSection(
          'Zugablauf – Schritt 4: Gegenangriff',
          'Überlebt der Gegner, greift er zurück. Wirft offen Handkarten ab, bis ihre Wertsumme mindestens dem (durch Pik reduzierten) Angriffswert entspricht. Es zählen: Zahlenkarten ihr Wert, Ass = 1, Bube = 10, Dame = 15, König = 20, Joker = 0. Eine leere Hand nach dem Bezahlen ist erlaubt. Könnt ihr den Gegenangriff nicht bezahlen, verliert das Team sofort.',
        ),
        _RulesSection(
          'Yield (Passen)',
          'Statt eine Karte zu spielen, könnt ihr passen. Das überspringt Farbkraft und Schaden und führt direkt zum Gegenangriff des Gegners. Wichtig: Ihr dürft nicht passen, wenn alle anderen Personen in ihrem jeweils letzten Zug ebenfalls gepasst haben. Das verhindert Endlosschleifen.',
        ),
        _RulesSection(
          'Karten gemeinsam spielen',
          'Zwei oder mehr gleiche Zahlenkarten (Summe max. 10) bilden einen gemeinsamen Angriff. Die Farbkraft wird nur einmal mit dem Gesamtwert ausgeführt. Werden zwei passende Tiergefährten kombiniert, wird ihre Farbkraft ebenfalls nur einmal ausgeführt. Ein Narr wird immer allein gespielt: Er verursacht 0 Schaden, hebt die Immunität auf, überspringt Gegenangriff und bestimmt, wer als Nächstes spielt.',
        ),
        _RulesSection(
          'Kommunikation',
          'Streng geheim: Ihr dürft keine Informationen über eure Handkarten verraten oder auch nur andeuten. Erlaubt: Über die eigene Handgröße und alle öffentlich sichtbaren Stapel sprechen. Nach einem ausgespielten Joker dürft ihr bis zum Beginn des nächsten Zuges allgemein sagen, wer gern oder ungern als Nächstes dran wäre – aber niemals konkrete Karten nennen.',
        ),
        _RulesSection(
          'Solo-Variante',
          'Spielt allein mit 1 Hand und höchstens 8 Karten. Legt zu Beginn beide Joker beiseite. Jeden Joker dürft ihr einmal einsetzen – entweder zu Beginn von Schritt 1 oder zu Beginn von Schritt 4: Wirft eure gesamte Hand ab und zieht wieder auf 8 Karten auf. Die Immunität des Gegners wird dabei nicht aufgehoben. Wertung: Sieg mit 2 eingesetzten Jokern = Bronze, mit 1 Joker = Silber, ohne Joker = Gold.',
        ),
      ],
    ),
    _GameRules(
      kind: CardGame.haggis,
      keyName: 'haggis',
      title: 'Haggis',
      subtitle: 'Standarddeck-Variante · 2–3 Personen',
      icon: Icons.style_outlined,
      accent: AppColors.apricot,
      sections: [
        _RulesSection(
          'Ziel',
          'Werde deine Karten möglichst früh los, gewinne wertvolle Karten in den Stichen und sammle über mehrere Runden die meisten Punkte.',
        ),
        _RulesSection(
          'Material & Deckanpassung',
          'Verwendet ein normales 52er-Deck mit vier Farben. Das Ass zählt als 1, danach folgen 2 bis 10. Legt pro Person 1 Buben, 1 Dame und 1 König offen als persönliche Jokerkarten aus. Für 2 Personen braucht ihr also je 2 Exemplare dieser Ränge, für 3 Personen je 3. Übrige Buben, Damen und Könige kommen in den Haggis-Stapel und sind keine Joker. Gebt jeder Person 13 verdeckte Handkarten; alle übrigen Karten bilden den Haggis. Die 13 statt 14 Karten sind die notwendige Anpassung an ein einzelnes Standarddeck.',
        ),
        _RulesSection(
          'Rangfolge & persönliche Joker',
          'Die Rangfolge von niedrig nach hoch lautet: Ass, 2–10, Bube, Dame, König. Deine offenen Buben, Damen und Könige darfst du als normale Einzelkarte, in einem Set oder in einer Straße spielen. Sie können dabei jede niedrigere Karte ersetzen. In jeder größeren Kombination muss aber mindestens 1 echte Zahlenkarte enthalten sein.',
        ),
        _RulesSection(
          'Sets & Straßen',
          'Ein Set besteht aus 1 bis 8 Karten mit demselben Wert. Eine Straße besteht entweder aus mindestens 3 aufeinanderfolgenden Einzelkarten oder aus mindestens 2 gleich großen Sets mit aufeinanderfolgenden Werten. Bei einer Straße muss die Zusammenstellung der Kartenfarben in jedem Set gleich bleiben; Joker dürfen dafür jede beliebige Farbe annehmen.',
        ),
        _RulesSection(
          'Bomben',
          'Bomben schlagen jede normale Kombination. Von niedrig nach hoch sind das: 3-5-7-9 in vier verschiedenen Farben (ohne Joker); Bube–Dame; Bube–König; Dame–König; Bube–Dame–König; schließlich 3-5-7-9 in derselben Farbe (ohne Joker). Nach einer Bombe darf nur eine höhere Bombe folgen.',
        ),
        _RulesSection(
          'Zug & Stichende',
          'Wer an der Reihe ist, legt eine höhere Kombination desselben Typs mit derselben Kartenanzahl oder passt. Zu zweit endet der Stich nach 1 Pass, zu dritt nach 2 aufeinanderfolgenden Pässen. Wenn im Dreierspiel erst eine Person passt, darf sie später wieder mitspielen. Die höchste ausgespielte Kombination gewinnt; die Gewinnerin oder der Gewinner nimmt alle gespielten Karten. Wer mit einer Bombe gewinnt, verschenkt diese Karten stattdessen an eine andere Person nach eigener Wahl. Die Person, die den Stich gewonnen hat, eröffnet den nächsten Stich.',
        ),
        _RulesSection(
          'Wetten',
          'Jede Person darf jederzeit wetten, solange sie in dieser Runde noch keine Karte gespielt hat, als Erste die Hand zu leeren: keine Wette, 15 Punkte oder 30 Punkte. Danach lässt sich die Ansage nicht mehr ändern. Eine erfolgreiche Wette zählt für die Gewinnerin oder den Gewinner; verlorene Wetten gehen an die Person, die zuerst leer war. Wer selbst nicht gewettet hat, erhält die Wette der jeweiligen Gegnerin oder des jeweiligen Gegners.',
        ),
        _RulesSection(
          'Rundenende',
          'Bei 2 Personen endet die Runde sofort, wenn die erste Hand leer ist. Bei 3 Personen endet sie, sobald die zweite Person leer ist. Die zweite Person, die leer wird, erhält die Karten des letzten Stichs, außer dieser wurde durch eine Bombe gewonnen. Die letzte Person spielt danach nicht weiter. Ihre übrigen Handkarten und der gesamte Haggis gehen an die Person, die zuerst leer war. Notiert vor dem Abgeben die Anzahl dieser Handkarten einschließlich offener Joker.',
        ),
        _RulesSection(
          'Wertung & Spielsieg',
          'Die Person, die zuerst leer war, erhält 5 Punkte für jede Karte auf der größten gegnerischen Hand, einschließlich offener Joker. In den erbeuteten Karten zählen jede 3, 5, 7 und 9 jeweils 1 Punkt, jeder Bube 2, jede Dame 3 und jeder König 5 Punkte. Addiert anschließend die Wetten. Für die nächste Runde wird neu gegeben: Die Person mit dem höchsten Gesamtstand gibt, die mit dem niedrigsten Gesamtstand eröffnet. Bei Gleichstand beginnt die Person links von der Geberin. Spielt bis 250 Punkte (kurz) oder 350 Punkte (lang). Bei Gleichstand spielt ihr weitere Runden.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedGame = _games.firstWhere((item) => item.kind == game);
    return Scaffold(
      appBar: AppBar(title: LocalizedText('${selectedGame.title}-Regeln')),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  if (game == CardGame.regicide)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('regicide-counter-from-rules'),
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegicideCounterScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.castle_outlined),
                          label: const LocalizedText('Gegner-Zähler öffnen'),
                        ),
                      ),
                    ),
                  _GameRulesCard(
                    key: Key('card-game-rules-${selectedGame.keyName}'),
                    game: selectedGame,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameRulesCard extends StatelessWidget {
  const _GameRulesCard({required this.game, super.key});

  final _GameRules game;

  @override
  Widget build(BuildContext context) => Card(
    semanticContainer: false,
    margin: const EdgeInsets.only(bottom: 20),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.plum, width: 1.2),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: game.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(game.icon, color: AppColors.plum),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: LocalizedText(
                        game.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 3),
                    LocalizedText(
                      game.subtitle,
                      style: const TextStyle(
                        color: AppColors.plum,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < game.sections.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            _SectionContent(section: game.sections[index]),
          ],
        ],
      ),
    ),
  );
}

class _SectionContent extends StatelessWidget {
  const _SectionContent({required this.section});

  final _RulesSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: LocalizedText(
          section.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 6),
      LocalizedText(section.body, style: const TextStyle(height: 1.45)),
    ],
  );
}

class _GameRules {
  const _GameRules({
    required this.kind,
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.sections,
  });

  final CardGame kind;
  final String keyName;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_RulesSection> sections;
}

class _RulesSection {
  const _RulesSection(this.title, this.body);

  final String title;
  final String body;
}

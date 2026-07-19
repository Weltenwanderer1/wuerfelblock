import 'game_models.dart';

class RuleSection {
  const RuleSection(this.title, this.body);

  final String title;
  final String body;
}

class CategoryHelp {
  const CategoryHelp({
    required this.category,
    required this.title,
    required this.explanation,
    required this.example,
  });

  final ScoreCategory category;
  final String title;
  final String explanation;
  final String example;
}

class RulesContent {
  const RulesContent({
    required this.ruleSet,
    required this.sections,
    required this.categories,
    this.extraKniffel,
  });

  final RuleSet ruleSet;
  final List<RuleSection> sections;
  final List<CategoryHelp> categories;
  final RuleSection? extraKniffel;

  String get title => '${ruleSet.label}-Regeln';

  static RulesContent forRuleSet(RuleSet rules) {
    final bonus = rules == RuleSet.yatzy ? 50 : 35;
    return RulesContent(
      ruleSet: rules,
      sections: [
        const RuleSection(
          'Ziel',
          'Sammle in den Wertungsfeldern möglichst viele Punkte. Jede Kategorie darf pro Person genau einmal benutzt werden.',
        ),
        RuleSection(
          'Material',
          rules == RuleSet.kniffel
              ? 'Yahtzee/Kniffel ist für 2 bis 8 Personen. Zum offiziellen Material gehören fünf Würfel, ein Würfelbecher, ein Kniffel-Block und vier Bleistifte. Im digitalen Spiel sind die Würfel bereits in der App enthalten.'
              : 'Du brauchst fünf Würfel und den Wertungsblock. Im digitalen Spiel sind die Würfel bereits in der App enthalten.',
        ),
        if (rules == RuleSet.kniffel)
          const RuleSection(
            'Spielvorbereitung',
            'Alle würfeln einmal; die Person mit der höchsten Zahl beginnt. Tragt diese Person in der App als Spieler 1 ein, danach geht es reihum weiter.',
          ),
        const RuleSection(
          'Spielzug',
          'Wer an der Reihe ist, würfelt bis zu dreimal. Nach jedem Wurf dürfen beliebige Würfel festgehalten oder wieder freigegeben werden. Spätestens nach dem dritten Wurf muss eine freie Kategorie gewertet werden.',
        ),
        RuleSection(
          'Wertung',
          rules == RuleSet.yatzy
              ? 'Im oberen Block zählen gleiche Augen. Im unteren Block gelten die Kombinationen unten: Paare und Pasche zählen nur die passenden Würfel, Straßen haben feste Werte und das Full House zählt die Würfelsumme.'
              : 'Im oberen Block zählen gleiche Augen. Im unteren Block gelten die Kombinationen unten: Pasche und Chance zählen alle fünf Würfel; Straßen und Full House haben feste Werte.',
        ),
        RuleSection(
          'Bonus im oberen Block',
          'Wer mit Einsern bis Sechsern zusammen mindestens 63 Punkte erreicht, erhält $bonus Bonuspunkte.',
        ),
        RuleSection(
          'Streichen',
          rules == RuleSet.kniffel
              ? 'Standardregel: Erfüllt der Wurf keine Bedingung und gibt es dafür kein passendes freies Feld, musst du ein beliebiges freies Feld mit 0 streichen. Die optionale Meisterschaftsregel erlaubt außerdem, freiwillig ein beliebiges Feld zu streichen. Die App bleibt in beiden Spielarten bewusst permissiv und unterstützt diese Meisterschafts-Freiheit.'
              : 'Passt kein Wurf oder möchtest du ein Feld aufgeben, trägst du dort 0 Punkte ein. Dieses Feld ist danach verbraucht.',
        ),
        const RuleSection(
          'Spielende und Gewinner',
          'Das Spiel endet, sobald alle Personen jedes Feld ausgefüllt haben. Alle Wertungen und Boni werden addiert. Die höchste Gesamtsumme gewinnt; bei Gleichstand gibt es mehrere Gewinner.',
        ),
      ],
      categories: [
        for (final category in rules.categories) categoryHelp(rules, category),
      ],
      extraKniffel: rules == RuleSet.kniffel
          ? const RuleSection(
              'Zusatz-Kniffel',
              'Ist das Kniffel-Feld bereits mit 50 Punkten belegt und du würfelst erneut fünf gleiche Würfel, erhältst du 50 Zusatzpunkte. Zusätzlich wählst du ein noch freies Feld; die App trägt dort die für dieses Feld vorgesehene Höchstpunktzahl ein.',
            )
          : null,
    );
  }

  static CategoryHelp categoryHelp(RuleSet rules, ScoreCategory category) {
    final title = category.displayLabel(rules);
    final (explanation, example) = switch (category) {
      ScoreCategory.ones => ('Zähle alle Einser.', '⚀ ⚀ ⚂ ⚄ ⚅ = 2 Punkte'),
      ScoreCategory.twos => ('Zähle alle Zweier.', '⚁ ⚁ ⚁ ⚃ ⚅ = 6 Punkte'),
      ScoreCategory.threes => ('Zähle alle Dreier.', '⚂ ⚂ ⚄ ⚅ ⚀ = 6 Punkte'),
      ScoreCategory.fours => ('Zähle alle Vierer.', '⚃ ⚃ ⚃ ⚀ ⚁ = 12 Punkte'),
      ScoreCategory.fives => ('Zähle alle Fünfer.', '⚄ ⚄ ⚁ ⚂ ⚅ = 10 Punkte'),
      ScoreCategory.sixes => ('Zähle alle Sechser.', '⚅ ⚅ ⚅ ⚀ ⚂ = 18 Punkte'),
      ScoreCategory.onePair => (
        'Das höchste Paar zählt; nur die beiden passenden Würfel werden addiert.',
        '⚄ ⚄ ⚂ ⚂ ⚀ = 10 Punkte',
      ),
      ScoreCategory.twoPairs => (
        'Zwei verschiedene Paare zählen; nur die vier passenden Würfel werden addiert.',
        '⚄ ⚄ ⚂ ⚂ ⚀ = 16 Punkte',
      ),
      ScoreCategory.threeOfAKind =>
        rules == RuleSet.yatzy
            ? (
                'Mindestens drei gleiche Augen; nur die drei passenden Würfel zählen.',
                '⚃ ⚃ ⚃ ⚀ ⚅ = 12 Punkte',
              )
            : (
                'Mindestens drei gleiche Augen; alle fünf Würfel werden addiert.',
                '⚃ ⚃ ⚃ ⚀ ⚅ = 19 Punkte',
              ),
      ScoreCategory.fourOfAKind =>
        rules == RuleSet.yatzy
            ? (
                'Mindestens vier gleiche Augen; nur die vier passenden Würfel zählen.',
                '⚄ ⚄ ⚄ ⚄ ⚀ = 20 Punkte',
              )
            : (
                'Mindestens vier gleiche Augen; alle fünf Würfel werden addiert.',
                '⚄ ⚄ ⚄ ⚄ ⚀ = 21 Punkte',
              ),
      ScoreCategory.smallStraight =>
        rules == RuleSet.yatzy
            ? ('Genau die Folge 1–2–3–4–5.', '⚀ ⚁ ⚂ ⚃ ⚄ = 15 Punkte')
            : ('Vier aufeinanderfolgende Werte.', '⚁ ⚂ ⚃ ⚄ ⚄ = 30 Punkte'),
      ScoreCategory.largeStraight =>
        rules == RuleSet.yatzy
            ? ('Genau die Folge 2–3–4–5–6.', '⚁ ⚂ ⚃ ⚄ ⚅ = 20 Punkte')
            : ('Fünf aufeinanderfolgende Werte.', '⚁ ⚂ ⚃ ⚄ ⚅ = 40 Punkte'),
      ScoreCategory.fullHouse =>
        rules == RuleSet.yatzy
            ? (
                'Ein Paar und ein Drilling; alle Würfel werden addiert.',
                '⚄ ⚄ ⚂ ⚂ ⚂ = 19 Punkte',
              )
            : ('Ein Paar und ein Drilling.', '⚄ ⚄ ⚂ ⚂ ⚂ = 25 Punkte'),
      ScoreCategory.chance => (
        'Jeder Wurf ist erlaubt; alle fünf Würfel werden addiert.',
        '⚅ ⚄ ⚃ ⚂ ⚁ = 20 Punkte',
      ),
      ScoreCategory.yatzy => (
        'Fünf Würfel mit derselben Augenzahl.',
        '⚅ ⚅ ⚅ ⚅ ⚅ = 50 Punkte',
      ),
    };
    return CategoryHelp(
      category: category,
      title: title,
      explanation: explanation,
      example: example,
    );
  }
}

extension RuleAwareCategoryLabel on ScoreCategory {
  String displayLabel(RuleSet rules) => this == ScoreCategory.yatzy
      ? rules == RuleSet.yatzy
            ? 'Yatzy'
            : 'Kniffel'
      : label;
}

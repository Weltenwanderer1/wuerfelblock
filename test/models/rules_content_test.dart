import 'package:flutter_test/flutter_test.dart';
import 'package:wuerfelblock/models/game_models.dart';
import 'package:wuerfelblock/models/rules_content.dart';

void main() {
  group('rules content', () {
    test('each ruleset covers every beginner rules section', () {
      for (final rules in RuleSet.values) {
        final content = RulesContent.forRuleSet(rules);
        expect(content.title, '${rules.label}-Regeln');
        expect(
          content.sections.map((section) => section.title),
          containsAll(<String>[
            'Ziel',
            'Material',
            'Spielzug',
            'Wertung',
            'Bonus im oberen Block',
            'Streichen',
            'Spielende und Gewinner',
          ]),
        );
        expect(
          content.categories.map((help) => help.category),
          orderedEquals(rules.categories),
        );
        expect(
          content.categories.every((help) => help.example.isNotEmpty),
          isTrue,
        );
      }
    });

    test('extra Kniffel appears only in Kniffel rules', () {
      expect(RulesContent.forRuleSet(RuleSet.kniffel).extraKniffel, isNotNull);
      expect(RulesContent.forRuleSet(RuleSet.yatzy).extraKniffel, isNull);
    });

    test('Kniffel documents official material, start and strike variants', () {
      final sections = {
        for (final section in RulesContent.forRuleSet(RuleSet.kniffel).sections)
          section.title: section.body,
      };
      expect(sections['Material'], contains('2 bis 8'));
      expect(sections['Material'], contains('fünf Würfel'));
      expect(sections['Material'], contains('Würfelbecher'));
      expect(sections['Material'], contains('vier Bleistifte'));
      expect(sections['Spielvorbereitung'], contains('höchste'));
      expect(sections['Spielvorbereitung'], contains('Spieler 1'));
      expect(sections['Streichen'], contains('Standardregel'));
      expect(sections['Streichen'], contains('kein passendes freies Feld'));
      expect(sections['Streichen'], contains('Meisterschaft'));
      expect(sections['Streichen'], contains('freiwillig'));
    });

    test('category help reflects rule-dependent scoring', () {
      expect(
        RulesContent.categoryHelp(
          RuleSet.yatzy,
          ScoreCategory.threeOfAKind,
        ).explanation,
        contains('passenden Würfel'),
      );
      expect(
        RulesContent.categoryHelp(
          RuleSet.kniffel,
          ScoreCategory.threeOfAKind,
        ).explanation,
        contains('alle fünf Würfel'),
      );
      expect(
        RulesContent.categoryHelp(
          RuleSet.yatzy,
          ScoreCategory.smallStraight,
        ).example,
        contains('15 Punkte'),
      );
      expect(
        RulesContent.categoryHelp(
          RuleSet.kniffel,
          ScoreCategory.fullHouse,
        ).example,
        contains('25 Punkte'),
      );
    });
  });
}

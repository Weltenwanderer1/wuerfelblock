import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../models/rules_content.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({required this.ruleSet, super.key});

  final RuleSet ruleSet;

  @override
  Widget build(BuildContext context) {
    final content = RulesContent.forRuleSet(ruleSet);
    return Scaffold(
      appBar: AppBar(title: LocalizedText(content.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _IntroBanner(ruleSet: ruleSet),
          const SizedBox(height: 12),
          for (final section in content.sections)
            _RuleSectionCard(section: section),
          Semantics(
            header: true,
            child: LocalizedText(
              'Kategorien',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          LocalizedText(
            'Tippe im Spiel auf das Info-Symbol neben einer Kategorie, um diese Erklärung schnell wiederzufinden.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          for (final help in content.categories)
            Card(
              child: ExpansionTile(
                title: LocalizedText(
                  help.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: LocalizedText(help.explanation),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    'Beispiel: ${help.example}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          if (content.extraKniffel case final extra?) ...[
            const SizedBox(height: 10),
            _RuleSectionCard(section: extra, accent: AppColors.apricot),
          ],
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.ruleSet});

  final RuleSet ruleSet;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EEF7),
      border: Border.all(color: const Color(0xFF264F78), width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.casino_outlined, size: 38, color: Color(0xFF264F78)),
        const SizedBox(width: 14),
        Expanded(
          child: LocalizedText(
            '${ruleSet.label} einfach erklärt – vom ersten Wurf bis zur Endabrechnung.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    ),
  );
}

class _RuleSectionCard extends StatelessWidget {
  const _RuleSectionCard({required this.section, this.accent});

  final RuleSection section;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Card(
    semanticContainer: false,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: accent ?? const Color(0xFF264F78), width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: LocalizedText(
              section.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 6),
          LocalizedText(
            section.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}

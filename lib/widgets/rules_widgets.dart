import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../models/rules_content.dart';
import '../screens/rules_screen.dart';

class ActiveRulesButton extends StatelessWidget {
  const ActiveRulesButton({required this.ruleSet, super.key});

  final RuleSet ruleSet;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '${ruleSet.label}-Regeln öffnen',
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    onPressed: () => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => RulesScreen(ruleSet: ruleSet)),
    ),
    icon: const Icon(Icons.menu_book_outlined),
  );
}

class CategoryInfoButton extends StatelessWidget {
  const CategoryInfoButton({
    required this.ruleSet,
    required this.category,
    this.foregroundColor,
    super.key,
  });

  final RuleSet ruleSet;
  final ScoreCategory category;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final title = category.displayLabel(ruleSet);
    return IconButton(
      key: Key('category-info-${category.name}'),
      tooltip: '$title erklären',
      iconSize: 19,
      color: foregroundColor,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => showCategoryHelp(context, ruleSet, category),
      icon: const Icon(Icons.info_outline),
    );
  }
}

Future<void> showCategoryHelp(
  BuildContext context,
  RuleSet ruleSet,
  ScoreCategory category,
) {
  final help = RulesContent.categoryHelp(ruleSet, category);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(help.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(help.explanation),
          const SizedBox(height: 12),
          Text(
            'Beispiel: ${help.example}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Verstanden'),
        ),
      ],
    ),
  );
}

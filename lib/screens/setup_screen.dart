import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../controllers/game_controller.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    required this.repository,
    required this.onStarted,
    super.key,
  });
  final GameRepository repository;
  final ValueChanged<GameController> onStarted;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  RuleSet rules = RuleSet.yatzy;
  GameMode mode = GameMode.block;
  final List<TextEditingController> names = [
    TextEditingController(text: 'Spieler 1'),
  ];
  bool starting = false;
  String? startError;

  bool get valid {
    final values = names.map((controller) => controller.text.trim()).toList();
    return values.every((name) => name.isNotEmpty) &&
        values.toSet().length == values.length;
  }

  bool get duplicate {
    final values = names
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    return values.toSet().length != values.length;
  }

  @override
  void dispose() {
    for (final controller in names) {
      controller.dispose();
    }
    super.dispose();
  }

  void addPlayer() {
    if (names.length == 8) return;
    setState(
      () =>
          names.add(TextEditingController(text: 'Spieler ${names.length + 1}')),
    );
  }

  void removePlayer(int index) {
    setState(() {
      names.removeAt(index).dispose();
      for (var playerIndex = 0; playerIndex < names.length; playerIndex++) {
        if (RegExp(r'^Spieler \d+$').hasMatch(names[playerIndex].text)) {
          names[playerIndex].text = 'Spieler ${playerIndex + 1}';
        }
      }
    });
  }

  Future<void> start() async {
    if (starting) return;
    setState(() {
      starting = true;
      startError = null;
    });
    final game = GameController.newGame(
      ruleSet: rules,
      mode: mode,
      names: names.map((controller) => controller.text.trim()).toList(),
      repository: widget.repository,
    );
    try {
      await widget.repository.save(game.state);
      if (mounted) widget.onStarted(game);
    } catch (_) {
      if (mounted) {
        setState(() {
          starting = false;
          startError = 'Die Partie konnte nicht gespeichert werden.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Neue Partie')),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (duplicate) ...[
            const Text(
              'Namen müssen eindeutig sein.',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
          ],
          if (startError case final error?) ...[
            Text(error, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            key: const Key('start-game'),
            onPressed: valid && !starting ? start : null,
            icon: const Icon(Icons.casino),
            label: const Text('Partie starten'),
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Regelwerk', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final item in RuleSet.values)
              Expanded(
                child: _ChoiceCard(
                  label: item.label,
                  detail: item == RuleSet.yatzy
                      ? 'Klassisch skandinavisch'
                      : 'Schmidt-Regeln',
                  selected: rules == item,
                  onTap: () => setState(() => rules = item),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Spielart', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final item in GameMode.values)
              Expanded(
                child: _ChoiceCard(
                  label: item.label,
                  detail: item == GameMode.block
                      ? 'App als Scoreblock'
                      : 'Würfel auf dem Handy',
                  selected: mode == item,
                  onTap: () => setState(() => mode = item),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Spieler (${names.length}/8)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('add-player'),
              tooltip: 'Spieler hinzufügen',
              onPressed: names.length < 8 ? addPlayer : null,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
        for (var index = 0; index < names.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextFormField(
              controller: names[index],
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name Spieler ${index + 1}',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: names.length > 1
                    ? IconButton(
                        onPressed: () => removePlayer(index),
                        icon: const Icon(Icons.close),
                        tooltip: 'Spieler entfernen',
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(5),
    color: selected ? AppColors.rose : null,
    child: Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: '$label, $detail',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: AppColors.plum,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

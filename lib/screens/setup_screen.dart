import 'package:flutter/material.dart';

import '../controllers/balut_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/qwixx_controller.dart';
import '../controllers/ten_thousand_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';

enum GameKind { yahtzeeKniffel, qwixx, tenThousand, balut }

extension on GameKind {
  String get label => switch (this) {
    GameKind.yahtzeeKniffel => 'Yahtzee/Kniffel',
    GameKind.qwixx => 'Qwixx',
    GameKind.tenThousand => '10.000',
    GameKind.balut => 'Balut',
  };

  String get detail => switch (this) {
    GameKind.yahtzeeKniffel => 'Klassischer Würfelspaß als Block oder digital',
    GameKind.qwixx => 'Farbreihen als Block oder digital',
    GameKind.tenThousand => 'Punktejagd als Block oder digital',
    GameKind.balut => '28 Wertungen pro Spieler – Block oder digital',
  };
}

const publicGameKinds = <GameKind>[
  GameKind.yahtzeeKniffel,
  GameKind.qwixx,
  GameKind.tenThousand,
  GameKind.balut,
];

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    required this.repository,
    required this.onStarted,
    super.key,
  });
  final GameRepository repository;
  final ValueChanged<Object> onStarted;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  GameKind game = GameKind.yahtzeeKniffel;
  GameMode mode = GameMode.block;
  final List<TextEditingController> names = [
    TextEditingController(text: 'Spieler 1'),
    TextEditingController(text: 'Spieler 2'),
  ];
  bool starting = false;
  String? startError;

  bool get isQwixx => game == GameKind.qwixx;
  bool get isClassic => game == GameKind.yahtzeeKniffel;
  int get minimumPlayers => 2;
  int get maximumPlayers => isQwixx ? 5 : 8;

  List<String> get cleanedNames =>
      names.map((controller) => controller.text.trim()).toList();

  bool get valid =>
      names.length >= minimumPlayers &&
      names.length <= maximumPlayers &&
      cleanedNames.every((name) => name.isNotEmpty) &&
      cleanedNames.toSet().length == names.length;

  bool get duplicate {
    final values = cleanedNames.where((name) => name.isNotEmpty).toList();
    return values.toSet().length != values.length;
  }

  @override
  void dispose() {
    for (final controller in names) {
      controller.dispose();
    }
    super.dispose();
  }

  void selectGame(GameKind selected) {
    setState(() {
      game = selected;
      if (isQwixx) {
        while (names.length > 5) {
          names.removeLast().dispose();
        }
      }
      while (names.length < minimumPlayers) {
        names.add(TextEditingController(text: 'Spieler ${names.length + 1}'));
      }
    });
  }

  void addPlayer() {
    if (names.length == maximumPlayers) return;
    setState(
      () =>
          names.add(TextEditingController(text: 'Spieler ${names.length + 1}')),
    );
  }

  void removePlayer(int index) {
    if (names.length <= minimumPlayers) return;
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
    if (starting || !valid) return;
    setState(() {
      starting = true;
      startError = null;
    });
    final Object controller = switch (game) {
      GameKind.qwixx => QwixxController.newGame(
        names: cleanedNames,
        repository: widget.repository,
        mode: mode,
      ),
      GameKind.tenThousand => TenThousandController.newGame(
        names: cleanedNames,
        repository: widget.repository,
        mode: mode,
      ),
      GameKind.balut => BalutController.newGame(
        names: cleanedNames,
        repository: widget.repository,
        mode: mode,
      ),
      GameKind.yahtzeeKniffel => GameController.newGame(
        ruleSet: RuleSet.kniffel,
        mode: mode,
        names: cleanedNames,
        repository: widget.repository,
      ),
    };
    try {
      await widget.repository.save(switch (controller) {
        QwixxController() => controller.state,
        TenThousandController() => controller.state,
        BalutController() => controller.state,
        GameController() => controller.state,
        _ => throw StateError('Unbekannter Controller.'),
      });
      if (mounted) widget.onStarted(controller);
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
        Text('Spiel', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          children: [
            for (final item in publicGameKinds)
              SizedBox(
                width: 180,
                child: _ChoiceCard(
                  label: item.label,
                  detail: item.detail,
                  selected: game == item,
                  onTap: () => selectGame(item),
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
                  key: Key('game-mode-${item.name}'),
                  label: item.label,
                  detail: item.shortDescription,
                  selected: mode == item,
                  onTap: () => setState(() => mode = item),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            mode.longDescription,
            key: const Key('game-mode-help'),
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Spieler (${names.length}/$maximumPlayers)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('add-player'),
              tooltip: 'Spieler hinzufügen',
              onPressed: names.length < maximumPlayers ? addPlayer : null,
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ],
        ),
        if (isQwixx) const Text('Qwixx wird mit 2 bis 5 Personen gespielt.'),
        if (game == GameKind.yahtzeeKniffel)
          const Text('Yahtzee/Kniffel wird mit 2 bis 8 Personen gespielt.'),
        if (game == GameKind.tenThousand)
          const Text('10.000 wird mit 2 bis 8 Personen gespielt.'),
        if (game == GameKind.balut)
          const Text('Balut wird mit 2 bis 8 Personen gespielt.'),
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
                suffixIcon: names.length > minimumPlayers
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
    super.key,
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

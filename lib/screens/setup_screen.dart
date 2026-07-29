import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

import '../controllers/balut_controller.dart';
import '../controllers/dragon_controller.dart';
import '../controllers/escalero_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/colordice_controller.dart';
import '../controllers/ten_thousand_controller.dart';
import '../core/app_theme.dart';
import '../models/game_models.dart';
import '../services/game_repository.dart';
import 'regicide_counter_screen.dart';

enum GameKind {
  yahtzeeKniffel,
  colordice,
  tenThousand,
  balut,
  escalero,
  dragongold,
  regicide,
}

extension on GameKind {
  String get label => switch (this) {
    GameKind.yahtzeeKniffel => 'Yahtzee/Kniffel',
    GameKind.colordice => 'Colordice',
    GameKind.tenThousand => '10.000',
    GameKind.balut => 'Balut',
    GameKind.escalero => 'Escalero',
    GameKind.regicide => 'Regicide',
    GameKind.dragongold => 'Schuppenschatz',
  };

  String get detail => switch (this) {
    GameKind.yahtzeeKniffel => 'Klassischer Würfelspaß als Block oder digital',
    GameKind.colordice => 'Farbreihen als Block oder digital',
    GameKind.tenThousand => 'Punktejagd als Block oder digital',
    GameKind.balut => '28 Wertungen pro Spieler – Block oder digital',
    GameKind.escalero => 'Pokerwürfel · 3 Kolonnen',
    GameKind.regicide => 'Kooperativer Gegner-Zähler fürs Kartenspiel',
    GameKind.dragongold => '5 Würfel · 2–5 Felder · Risiko & Gold',
  };
}

const publicGameKinds = <GameKind>[
  GameKind.yahtzeeKniffel,
  GameKind.colordice,
  GameKind.tenThousand,
  GameKind.balut,
  GameKind.escalero,
  GameKind.regicide,
  GameKind.dragongold,
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
  final List<TextEditingController> names = [];
  final List<bool> nameWasEdited = [];
  String? _defaultPlayerPrefix;
  bool starting = false;
  String? startError;
  bool dragonQuickGame = false;

  bool get isColordice => game == GameKind.colordice;
  bool get isClassic => game == GameKind.yahtzeeKniffel;
  bool get isEscalero => game == GameKind.escalero;
  bool get isRegicide => game == GameKind.regicide;
  bool get isDragonGold => game == GameKind.dragongold;
  int get minimumPlayers => 2;
  int get maximumPlayers => isEscalero
      ? 3
      : isColordice
      ? 5
      : isDragonGold
      ? 4
      : 8;

  List<String> get cleanedNames =>
      names.map((controller) => controller.text.trim()).toList();

  bool get valid =>
      isRegicide ||
      (names.length >= minimumPlayers &&
          names.length <= maximumPlayers &&
          cleanedNames.every((name) => name.isNotEmpty) &&
          cleanedNames.toSet().length == names.length);

  bool get duplicate {
    final values = cleanedNames.where((name) => name.isNotEmpty).toList();
    return values.toSet().length != values.length;
  }

  String get defaultPlayerPrefix =>
      _defaultPlayerPrefix ?? localizeText(context, 'Spieler');

  String defaultPlayerName(int index) => '$defaultPlayerPrefix ${index + 1}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPrefix = localizeText(context, 'Spieler');
    final previousPrefix = _defaultPlayerPrefix;
    if (names.isEmpty) {
      _defaultPlayerPrefix = nextPrefix;
      names.addAll([
        TextEditingController(text: defaultPlayerName(0)),
        TextEditingController(text: defaultPlayerName(1)),
      ]);
      nameWasEdited.addAll([false, false]);
      return;
    }
    if (previousPrefix != null && previousPrefix != nextPrefix) {
      for (var index = 0; index < names.length; index++) {
        if (!nameWasEdited[index]) {
          names[index].text = '$nextPrefix ${index + 1}';
        }
      }
    }
    _defaultPlayerPrefix = nextPrefix;
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
      if (isColordice || isEscalero || isDragonGold) {
        while (names.length > maximumPlayers) {
          names.removeLast().dispose();
          nameWasEdited.removeLast();
        }
      }
      while (names.length < minimumPlayers) {
        names.add(TextEditingController(text: defaultPlayerName(names.length)));
        nameWasEdited.add(false);
      }
    });
  }

  void addPlayer() {
    if (names.length == maximumPlayers) return;
    setState(() {
      names.add(TextEditingController(text: defaultPlayerName(names.length)));
      nameWasEdited.add(false);
    });
  }

  void removePlayer(int index) {
    if (names.length <= minimumPlayers) return;
    setState(() {
      names.removeAt(index).dispose();
      nameWasEdited.removeAt(index);
      for (var playerIndex = 0; playerIndex < names.length; playerIndex++) {
        if (!nameWasEdited[playerIndex]) {
          names[playerIndex].text = defaultPlayerName(playerIndex);
        }
      }
    });
  }

  Future<void> start() async {
    // Regicide is a standalone counter tool — open it directly
    if (game == GameKind.regicide) {
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const RegicideCounterScreen()),
      );
      return;
    }
    if (starting || !valid) return;
    setState(() {
      starting = true;
      startError = null;
    });
    final Object controller = switch (game) {
      GameKind.colordice => ColordiceController.newGame(
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
      GameKind.escalero => EscaleroController.newGame(
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
      GameKind.regicide => throw StateError('Regicide is handled earlier.'),
      GameKind.dragongold => DragonController.newGame(
        names: cleanedNames,
        repository: widget.repository,
        mode: mode,
        quickGame: dragonQuickGame,
      ),
    };
    try {
      await widget.repository.save(switch (controller) {
        ColordiceController() => controller.state,
        TenThousandController() => controller.state,
        BalutController() => controller.state,
        EscaleroController() => controller.state,
        GameController() => controller.state,
        DragonController() => controller.state,
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
    appBar: AppBar(title: const LocalizedText('Neue Partie')),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (duplicate) ...[
            const LocalizedText(
              'Namen müssen eindeutig sein.',
              style: TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
          ],
          if (startError case final error?) ...[
            LocalizedText(
              error,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            key: const Key('start-game'),
            onPressed: valid && !starting ? start : null,
            icon: const Icon(Icons.casino),
            label: const LocalizedText('Partie starten'),
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LocalizedText('Spiel', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              children: [
                for (final item in publicGameKinds)
                  SizedBox(
                    width: cardWidth,
                    child: _ChoiceCard(
                      key: Key('game-kind-${item.name}'),
                      label: item.label,
                      detail: item.detail,
                      selected: game == item,
                      selectedColor: item == GameKind.dragongold
                          ? const Color(0xFFE0B56A)
                          : null,
                      onTap: () => selectGame(item),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (!isRegicide) ...[
          LocalizedText(
            'Spielart',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
            child: LocalizedText(
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
                child: LocalizedText(
                  'Spieler (${names.length}/$maximumPlayers)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: const Key('add-player'),
                tooltip: localizeText(context, 'Spieler hinzufügen'),
                onPressed: names.length < maximumPlayers ? addPlayer : null,
                icon: const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          if (isColordice)
            const LocalizedText(
              'Colordice wird mit 2 bis 5 Personen gespielt.',
            ),
          if (game == GameKind.yahtzeeKniffel)
            const LocalizedText(
              'Yahtzee/Kniffel wird mit 2 bis 8 Personen gespielt.',
            ),
          if (game == GameKind.tenThousand)
            const LocalizedText('10.000 wird mit 2 bis 8 Personen gespielt.'),
          if (game == GameKind.balut)
            const LocalizedText('Balut wird mit 2 bis 8 Personen gespielt.'),
          if (game == GameKind.escalero)
            const LocalizedText('Escalero wird mit 2 bis 3 Personen gespielt.'),
          if (isDragonGold) ...[
            const LocalizedText(
              'Schuppenschatz wird mit 2 bis 4 Personen gespielt.',
            ),
            CheckboxListTile(
              key: const Key('dragon-quick-game'),
              value: dragonQuickGame,
              onChanged: (value) =>
                  setState(() => dragonQuickGame = value ?? false),
              title: const LocalizedText('Schnelles Spiel (20 Karten)'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
          for (var index = 0; index < names.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                controller: names[index],
                onChanged: (_) => setState(() => nameWasEdited[index] = true),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: localizeText(context, 'Name Spieler ${index + 1}'),
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: names.length > minimumPlayers
                      ? IconButton(
                          onPressed: () => removePlayer(index),
                          icon: const Icon(Icons.close),
                          tooltip: localizeText(context, 'Spieler entfernen'),
                        )
                      : null,
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LocalizedText(
              'Kooperativer Gegner-Zähler für Regicide. Kein Spielstand nötig – einfach starten und die Gegner im Schloss besiegen!',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
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
    this.selectedColor,
  });
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(5),
    color: selected ? (selectedColor ?? AppColors.rose) : null,
    child: Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      label: localizeText(context, '$label, $detail'),
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
              LocalizedText(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              LocalizedText(
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

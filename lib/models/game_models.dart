enum RuleSet { yatzy, kniffel }

enum GameMode { block, digital }

enum ScoreCategory {
  ones,
  twos,
  threes,
  fours,
  fives,
  sixes,
  onePair,
  twoPairs,
  threeOfAKind,
  fourOfAKind,
  smallStraight,
  largeStraight,
  fullHouse,
  chance,
  yatzy,
}

extension RuleSetInfo on RuleSet {
  String get label => this == RuleSet.yatzy ? 'Yatzy' : 'Kniffel';
  List<ScoreCategory> get categories => [
    ScoreCategory.ones,
    ScoreCategory.twos,
    ScoreCategory.threes,
    ScoreCategory.fours,
    ScoreCategory.fives,
    ScoreCategory.sixes,
    if (this == RuleSet.yatzy) ScoreCategory.onePair,
    if (this == RuleSet.yatzy) ScoreCategory.twoPairs,
    ScoreCategory.threeOfAKind,
    ScoreCategory.fourOfAKind,
    ScoreCategory.smallStraight,
    ScoreCategory.largeStraight,
    ScoreCategory.fullHouse,
    ScoreCategory.chance,
    ScoreCategory.yatzy,
  ];
}

extension GameModeInfo on GameMode {
  String get label =>
      this == GameMode.block ? 'Echte Würfel' : 'Digital würfeln';
}

extension ScoreCategoryInfo on ScoreCategory {
  String get label => switch (this) {
    ScoreCategory.ones => 'Einser',
    ScoreCategory.twos => 'Zweier',
    ScoreCategory.threes => 'Dreier',
    ScoreCategory.fours => 'Vierer',
    ScoreCategory.fives => 'Fünfer',
    ScoreCategory.sixes => 'Sechser',
    ScoreCategory.onePair => 'Ein Paar',
    ScoreCategory.twoPairs => 'Zwei Paare',
    ScoreCategory.threeOfAKind => 'Dreierpasch',
    ScoreCategory.fourOfAKind => 'Viererpasch',
    ScoreCategory.smallStraight => 'Kleine Straße',
    ScoreCategory.largeStraight => 'Große Straße',
    ScoreCategory.fullHouse => 'Full House',
    ScoreCategory.chance => 'Chance',
    ScoreCategory.yatzy => 'Yatzy / Kniffel',
  };

  bool get isUpper => index <= ScoreCategory.sixes.index;

  int maxScore(RuleSet rules) => switch (this) {
    ScoreCategory.ones => 5,
    ScoreCategory.twos => 10,
    ScoreCategory.threes => 15,
    ScoreCategory.fours => 20,
    ScoreCategory.fives => 25,
    ScoreCategory.sixes => 30,
    ScoreCategory.onePair => 12,
    ScoreCategory.twoPairs => 22,
    ScoreCategory.threeOfAKind => rules == RuleSet.kniffel ? 30 : 18,
    ScoreCategory.fourOfAKind => rules == RuleSet.kniffel ? 30 : 24,
    ScoreCategory.smallStraight => rules == RuleSet.kniffel ? 30 : 15,
    ScoreCategory.largeStraight => rules == RuleSet.kniffel ? 40 : 20,
    ScoreCategory.fullHouse => rules == RuleSet.kniffel ? 25 : 28,
    ScoreCategory.chance => 30,
    ScoreCategory.yatzy => 50,
  };
}

class Player {
  Player({required this.name, Map<ScoreCategory, int>? scores})
    : scores = Map.of(scores ?? const {});
  final String name;
  final Map<ScoreCategory, int> scores;

  int get upperTotal => scores.entries
      .where((entry) => entry.key.isUpper)
      .fold(0, (sum, entry) => sum + entry.value);
  int get bonus => upperTotal >= 63 ? 35 : 0;
  int get total => scores.values.fold(0, (a, b) => a + b) + bonus;

  Map<String, dynamic> toJson() => {
    'name': name,
    'scores': {for (final entry in scores.entries) entry.key.name: entry.value},
  };
  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'] as String,
    scores: (json['scores'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(ScoreCategory.values.byName(key), value as int),
    ),
  );
}

class GameState {
  GameState({
    required this.ruleSet,
    required this.mode,
    required this.players,
    this.currentPlayerIndex = 0,
    this.isComplete = false,
    List<int>? dice,
    List<bool>? held,
    this.rollCount = 0,
  }) : dice = List.of(dice ?? const [1, 1, 1, 1, 1]),
       held = List.of(held ?? const [false, false, false, false, false]);
  final RuleSet ruleSet;
  final GameMode mode;
  final List<Player> players;
  int currentPlayerIndex;
  bool isComplete;
  final List<int> dice;
  final List<bool> held;
  int rollCount;
  Player get currentPlayer => players[currentPlayerIndex];
  int get completedEntries =>
      players.fold(0, (sum, player) => sum + player.scores.length);
  int get totalEntries => players.length * ruleSet.categories.length;

  Map<String, dynamic> toJson() => {
    'ruleSet': ruleSet.name,
    'mode': mode.name,
    'players': players.map((player) => player.toJson()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'isComplete': isComplete,
    'dice': dice,
    'held': held,
    'rollCount': rollCount,
  };
  factory GameState.fromJson(Map<String, dynamic> json) {
    try {
      final ruleSet = RuleSet.values.byName(json['ruleSet'] as String);
      final mode = GameMode.values.byName(json['mode'] as String);
      final players = (json['players'] as List)
          .map(
            (item) => Player.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final currentPlayerIndex = json['currentPlayerIndex'] as int;
      final isComplete = json['isComplete'] as bool;
      final dice = (json['dice'] as List? ?? const [1, 1, 1, 1, 1])
          .map((value) => value as int)
          .toList();
      final held =
          (json['held'] as List? ?? const [false, false, false, false, false])
              .map((value) => value as bool)
              .toList();
      final rollCount = json['rollCount'] as int? ?? 0;
      if (players.isEmpty || players.length > 8) {
        throw const FormatException('Ungültige Spieleranzahl.');
      }
      if (players.any((player) => player.name.trim().isEmpty) ||
          players.map((player) => player.name).toSet().length !=
              players.length) {
        throw const FormatException('Ungültige Spielernamen.');
      }
      if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
        throw const FormatException('Ungültiger Spielerindex.');
      }
      if (dice.length != 5 ||
          dice.any((value) => value < 1 || value > 6) ||
          held.length != 5 ||
          rollCount < 0 ||
          rollCount > 3) {
        throw const FormatException('Ungültiger Würfelzustand.');
      }
      for (final player in players) {
        for (final entry in player.scores.entries) {
          if (!ruleSet.categories.contains(entry.key) ||
              entry.value < 0 ||
              entry.value > entry.key.maxScore(ruleSet)) {
            throw const FormatException('Ungültige Wertung.');
          }
        }
      }
      final actuallyComplete = players.every(
        (player) => player.scores.length == ruleSet.categories.length,
      );
      if (isComplete != actuallyComplete) {
        throw const FormatException('Ungültiger Abschlussstatus.');
      }
      return GameState(
        ruleSet: ruleSet,
        mode: mode,
        players: players,
        currentPlayerIndex: currentPlayerIndex,
        isComplete: isComplete,
        dice: dice,
        held: held,
        rollCount: rollCount,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Spielstand.', error);
    }
  }
}

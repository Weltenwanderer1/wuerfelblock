import 'saved_game_state.dart';
import 'game_models.dart';

enum ColordiceColor { red, yellow, green, blue }

enum ColordiceDigitalAction { white, color }

/// Authoritative board dimensions and end conditions for Colordice.
abstract final class ColordiceRules {
  static const rowColors = ColordiceColor.values;
  static const ascendingRowNumbers = <int>[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static const descendingRowNumbers = <int>[12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2];
  static const whiteDiceCount = 2;
  static const diceCount = whiteDiceCount + 4;
  static const minimumDieValue = 1;
  static const maximumDieValue = 6;
  static const marksBeforeLock = 5;
  static const maximumScoredCrosses = 12;
  static const maximumMisses = 4;
  static const missPenalty = 5;
  static const rowsToCloseGame = 2;
  static const minimumPlayers = 2;
  static const maximumPlayers = 5;
  static const initialDice = <int>[1, 1, 1, 1, 1, 1];
}

extension ColordiceColorInfo on ColordiceColor {
  int get digitalDieIndex => index + ColordiceRules.whiteDiceCount;

  List<int> get numbers => switch (this) {
    ColordiceColor.red ||
    ColordiceColor.yellow => ColordiceRules.ascendingRowNumbers,
    ColordiceColor.green ||
    ColordiceColor.blue => ColordiceRules.descendingRowNumbers,
  };

  String get label => switch (this) {
    ColordiceColor.red => 'Rot',
    ColordiceColor.yellow => 'Gelb',
    ColordiceColor.green => 'Grün',
    ColordiceColor.blue => 'Blau',
  };
}

class ColordicePlayer {
  ColordicePlayer({
    required this.name,
    Map<ColordiceColor, Set<int>>? crossed,
    Set<ColordiceColor>? lockedColors,
    this.misses = 0,
  }) : crossed = {
         for (final color in ColordiceColor.values)
           color: Set.of(crossed?[color] ?? const {}),
       },
       lockedColors = Set.of(lockedColors ?? const {});

  final String name;
  final Map<ColordiceColor, Set<int>> crossed;
  final Set<ColordiceColor> lockedColors;
  int misses;

  bool canMark(ColordiceColor color, int value) {
    final numbers = color.numbers;
    final index = numbers.indexOf(value);
    if (index < 0 || lockedColors.contains(color)) return false;
    final marks = crossed[color]!;
    if (marks.contains(value)) return false;
    final furthest = marks
        .map(numbers.indexOf)
        .fold(-1, (maximum, item) => item > maximum ? item : maximum);
    if (index <= furthest) return false;
    return index != numbers.length - 1 ||
        marks.length >= ColordiceRules.marksBeforeLock;
  }

  void mark(ColordiceColor color, int value) {
    if (!canMark(color, value)) {
      throw StateError('Diese Zahl kann nicht mehr angekreuzt werden.');
    }
    crossed[color]!.add(value);
    if (value == color.numbers.last) lockedColors.add(color);
  }

  int crossCount(ColordiceColor color) =>
      crossed[color]!.length + (lockedColors.contains(color) ? 1 : 0);

  static int scoreForCrosses(int crosses) {
    if (crosses < 0 || crosses > ColordiceRules.maximumScoredCrosses) {
      throw RangeError.range(
        crosses,
        0,
        ColordiceRules.maximumScoredCrosses,
        'crosses',
      );
    }
    return crosses * (crosses + 1) ~/ 2;
  }

  int rowScore(ColordiceColor color) => scoreForCrosses(crossCount(color));
  int get missPenalty => misses * -ColordiceRules.missPenalty;
  int get total =>
      ColordiceColor.values.fold(0, (sum, color) => sum + rowScore(color)) +
      missPenalty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'crossed': {
      for (final color in ColordiceColor.values)
        color.name: crossed[color]!.toList()..sort(),
    },
    'lockedColors': lockedColors.map((color) => color.name).toList(),
    'misses': misses,
  };

  factory ColordicePlayer.fromJson(Map<String, dynamic> json) {
    try {
      final name = json['name'] as String;
      final rawCrossed = Map<String, dynamic>.from(json['crossed'] as Map);
      final locked = (json['lockedColors'] as List)
          .map((value) => ColordiceColor.values.byName(value as String))
          .toSet();
      final misses = json['misses'] as int;
      final crossed = <ColordiceColor, Set<int>>{};
      for (final color in ColordiceColor.values) {
        final values = (rawCrossed[color.name] as List? ?? const [])
            .map((value) => value as int)
            .toSet();
        if (values.any((value) => !color.numbers.contains(value))) {
          throw const FormatException('Ungültige Kreuze.');
        }
        crossed[color] = values;
      }
      if (name.trim().isEmpty ||
          misses < 0 ||
          misses > ColordiceRules.maximumMisses) {
        throw const FormatException('Ungültiger Colordice-Spieler.');
      }
      for (final color in locked) {
        final marks = crossed[color]!;
        if (!marks.contains(color.numbers.last) || marks.length < 6) {
          throw const FormatException('Ungültiger Reihenverschluss.');
        }
      }
      return ColordicePlayer(
        name: name,
        crossed: crossed,
        lockedColors: locked,
        misses: misses,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Colordice-Spieler.', error);
    }
  }
}

class ColordiceGameState implements SavedGameState {
  ColordiceGameState({
    required this.players,
    this.mode = GameMode.block,
    Set<ColordiceColor>? closedColors,
    Set<ColordiceColor>? pendingClosedColors,
    this.activePlayerIndex = 0,
    this.isComplete = false,
    List<int>? dice,
    this.hasRolled = false,
    Set<int>? whiteMarkedPlayerIndices,
    this.colorMarked = false,
  }) : closedColors = Set.of(closedColors ?? const {}),
       pendingClosedColors = Set.of(pendingClosedColors ?? const {}),
       dice = List.of(dice ?? ColordiceRules.initialDice),
       whiteMarkedPlayerIndices = Set.of(whiteMarkedPlayerIndices ?? const {});

  factory ColordiceGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
  }) {
    final cleaned = names.map((name) => name.trim()).toList();
    if (cleaned.length < ColordiceRules.minimumPlayers ||
        cleaned.length > ColordiceRules.maximumPlayers) {
      throw ArgumentError('Bei Colordice sind 2 bis 5 Spieler erlaubt.');
    }
    if (cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
    return ColordiceGameState(
      players: cleaned.map((name) => ColordicePlayer(name: name)).toList(),
      mode: mode,
    );
  }

  @override
  final List<ColordicePlayer> players;
  final GameMode mode;
  final Set<ColordiceColor> closedColors;
  final Set<ColordiceColor> pendingClosedColors;
  int activePlayerIndex;
  @override
  bool isComplete;
  final List<int> dice;
  bool hasRolled;
  final Set<int> whiteMarkedPlayerIndices;
  bool colorMarked;

  int get whiteSum => dice[0] + dice[1];

  Map<ColordiceColor, Set<int>> get coloredSums => {
    for (final color in ColordiceColor.values)
      color: {
        dice[0] + dice[color.digitalDieIndex],
        dice[1] + dice[color.digitalDieIndex],
      },
  };

  ColordicePlayer get activePlayer => players[activePlayerIndex];
  bool canMark(int playerIndex, ColordiceColor color, int value) {
    if (isComplete ||
        closedColors.contains(color) ||
        playerIndex < 0 ||
        playerIndex >= players.length) {
      return false;
    }
    if (pendingClosedColors.contains(color) && value != color.numbers.last) {
      return false;
    }
    return players[playerIndex].canMark(color, value);
  }

  void mark(int playerIndex, ColordiceColor color, int value) {
    if (!canMark(playerIndex, color, value)) {
      throw StateError('Dieses Feld ist nicht verfügbar.');
    }
    players[playerIndex].mark(color, value);
    if (players[playerIndex].lockedColors.contains(color)) {
      pendingClosedColors.add(color);
    }
  }

  void rollDigital(List<int> values) {
    if (mode != GameMode.digital || isComplete || hasRolled) {
      throw StateError('Jetzt kann nicht gewürfelt werden.');
    }
    if (values.length != ColordiceRules.diceCount ||
        values.any(
          (value) =>
              value < ColordiceRules.minimumDieValue ||
              value > ColordiceRules.maximumDieValue,
        )) {
      throw ArgumentError.value(
        values,
        'values',
        'Sechs gültige Würfel nötig.',
      );
    }
    dice.setAll(0, values);
    hasRolled = true;
  }

  bool canMarkDigital(
    int playerIndex,
    ColordiceColor color,
    int value,
    ColordiceDigitalAction action,
  ) {
    if (mode != GameMode.digital ||
        !hasRolled ||
        !canMark(playerIndex, color, value)) {
      return false;
    }
    return switch (action) {
      ColordiceDigitalAction.white =>
        value == whiteSum && !whiteMarkedPlayerIndices.contains(playerIndex),
      ColordiceDigitalAction.color =>
        playerIndex == activePlayerIndex &&
            !colorMarked &&
            coloredSums[color]!.contains(value),
    };
  }

  void markDigital(
    int playerIndex,
    ColordiceColor color,
    int value,
    ColordiceDigitalAction action,
  ) {
    if (!canMarkDigital(playerIndex, color, value, action)) {
      throw StateError('Diese Würfelaktion ist nicht verfügbar.');
    }
    mark(playerIndex, color, value);
    if (action == ColordiceDigitalAction.white) {
      whiteMarkedPlayerIndices.add(playerIndex);
    } else {
      colorMarked = true;
    }
  }

  void finishDigitalTurn() {
    if (mode != GameMode.digital || !hasRolled || isComplete) {
      throw StateError('Der digitale Zug kann nicht beendet werden.');
    }
    final activeMarked =
        whiteMarkedPlayerIndices.contains(activePlayerIndex) || colorMarked;
    if (!activeMarked) {
      final player = activePlayer;
      if (player.misses >= ColordiceRules.maximumMisses) {
        throw StateError('Vier Fehlwürfe sind erreicht.');
      }
      player.misses++;
    }
    _finalizePendingClosures();
    if (!isComplete) {
      activePlayerIndex = (activePlayerIndex + 1) % players.length;
    }
    hasRolled = false;
    whiteMarkedPlayerIndices.clear();
    colorMarked = false;
  }

  void nextPlayer() {
    if (isComplete) throw StateError('Die Partie ist bereits beendet.');
    _finalizePendingClosures();
    if (!isComplete) {
      activePlayerIndex = (activePlayerIndex + 1) % players.length;
    }
  }

  void markMiss(int playerIndex) {
    if (isComplete) throw StateError('Die Partie ist bereits beendet.');
    if (playerIndex < 0 || playerIndex >= players.length) {
      throw RangeError.index(playerIndex, players);
    }
    final player = players[playerIndex];
    if (player.misses >= ColordiceRules.maximumMisses) {
      throw StateError('Vier Fehlwürfe sind erreicht.');
    }
    player.misses++;
    _finalizePendingClosures();
  }

  void _finalizePendingClosures() {
    closedColors.addAll(pendingClosedColors);
    pendingClosedColors.clear();
    _updateComplete();
  }

  void _updateComplete() {
    isComplete =
        closedColors.length >= ColordiceRules.rowsToCloseGame ||
        players.any((player) => player.misses >= ColordiceRules.maximumMisses);
  }

  int totalFor(ColordicePlayer player) => player.total;

  @override
  String get gameLabel => 'Colordice';
  @override
  String get modeLabel => mode.label;
  @override
  String get progressLabel =>
      '${closedColors.length} von ${ColordiceRules.rowsToCloseGame} Reihen geschlossen';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'colordice',
    'mode': mode.name,
    'players': players.map((player) => player.toJson()).toList(),
    'closedColors': closedColors.map((color) => color.name).toList(),
    'pendingClosedColors': pendingClosedColors
        .map((color) => color.name)
        .toList(),
    'activePlayerIndex': activePlayerIndex,
    'isComplete': isComplete,
    'dice': dice,
    'hasRolled': hasRolled,
    'whiteMarkedPlayerIndices': whiteMarkedPlayerIndices.toList()..sort(),
    'colorMarked': colorMarked,
  };

  factory ColordiceGameState.fromJson(Map<String, dynamic> json) {
    try {
      final players = (json['players'] as List)
          .map(
            (value) => ColordicePlayer.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList();
      final closed = (json['closedColors'] as List)
          .map((value) => ColordiceColor.values.byName(value as String))
          .toSet();
      final pending = (json['pendingClosedColors'] as List? ?? const [])
          .map((value) => ColordiceColor.values.byName(value as String))
          .toSet();
      final active = json['activePlayerIndex'] as int;
      final complete = json['isComplete'] as bool;
      final mode = GameMode.values.byName(
        json['mode'] as String? ?? GameMode.block.name,
      );
      final dice = (json['dice'] as List? ?? ColordiceRules.initialDice)
          .map((value) => value as int)
          .toList();
      final hasRolled = json['hasRolled'] as bool? ?? false;
      final whiteMarkedPlayerIndices =
          (json['whiteMarkedPlayerIndices'] as List? ?? const [])
              .map((value) => value as int)
              .toSet();
      final colorMarked = json['colorMarked'] as bool? ?? false;
      if (players.length < ColordiceRules.minimumPlayers ||
          players.length > ColordiceRules.maximumPlayers ||
          players.map((player) => player.name).toSet().length !=
              players.length ||
          active < 0 ||
          active >= players.length ||
          dice.length != ColordiceRules.diceCount ||
          dice.any(
            (value) =>
                value < ColordiceRules.minimumDieValue ||
                value > ColordiceRules.maximumDieValue,
          ) ||
          whiteMarkedPlayerIndices.any(
            (index) => index < 0 || index >= players.length,
          ) ||
          (mode == GameMode.block &&
              (hasRolled ||
                  whiteMarkedPlayerIndices.isNotEmpty ||
                  colorMarked)) ||
          (!hasRolled &&
              (whiteMarkedPlayerIndices.isNotEmpty || colorMarked))) {
        throw const FormatException('Ungültiger Colordice-Spielstand.');
      }
      final actualClosures = players
          .expand((player) => player.lockedColors)
          .toSet();
      final persistedClosures = {...closed, ...pending};
      if (closed.any(pending.contains) ||
          persistedClosures.length != actualClosures.length ||
          !persistedClosures.containsAll(actualClosures)) {
        throw const FormatException('Ungültige geschlossene Reihen.');
      }
      final actuallyComplete =
          closed.length >= ColordiceRules.rowsToCloseGame ||
          players.any(
            (player) => player.misses >= ColordiceRules.maximumMisses,
          );
      if (complete != actuallyComplete) {
        throw const FormatException('Ungültiger Abschlussstatus.');
      }
      return ColordiceGameState(
        players: players,
        mode: mode,
        closedColors: closed,
        pendingClosedColors: pending,
        activePlayerIndex: active,
        isComplete: complete,
        dice: dice,
        hasRolled: hasRolled,
        whiteMarkedPlayerIndices: whiteMarkedPlayerIndices,
        colorMarked: colorMarked,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Colordice-Spielstand.', error);
    }
  }
}

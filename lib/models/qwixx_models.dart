import 'saved_game_state.dart';
import 'game_models.dart';

enum QwixxColor { red, yellow, green, blue }

enum QwixxDigitalAction { white, color }

/// Authoritative board dimensions and end conditions for Qwixx.
abstract final class QwixxRules {
  static const rowColors = QwixxColor.values;
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

extension QwixxColorInfo on QwixxColor {
  int get digitalDieIndex => index + QwixxRules.whiteDiceCount;

  List<int> get numbers => switch (this) {
    QwixxColor.red || QwixxColor.yellow => QwixxRules.ascendingRowNumbers,
    QwixxColor.green || QwixxColor.blue => QwixxRules.descendingRowNumbers,
  };

  String get label => switch (this) {
    QwixxColor.red => 'Rot',
    QwixxColor.yellow => 'Gelb',
    QwixxColor.green => 'Grün',
    QwixxColor.blue => 'Blau',
  };
}

class QwixxPlayer {
  QwixxPlayer({
    required this.name,
    Map<QwixxColor, Set<int>>? crossed,
    Set<QwixxColor>? lockedColors,
    this.misses = 0,
  }) : crossed = {
         for (final color in QwixxColor.values)
           color: Set.of(crossed?[color] ?? const {}),
       },
       lockedColors = Set.of(lockedColors ?? const {});

  final String name;
  final Map<QwixxColor, Set<int>> crossed;
  final Set<QwixxColor> lockedColors;
  int misses;

  bool canMark(QwixxColor color, int value) {
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
        marks.length >= QwixxRules.marksBeforeLock;
  }

  void mark(QwixxColor color, int value) {
    if (!canMark(color, value)) {
      throw StateError('Diese Zahl kann nicht mehr angekreuzt werden.');
    }
    crossed[color]!.add(value);
    if (value == color.numbers.last) lockedColors.add(color);
  }

  int crossCount(QwixxColor color) =>
      crossed[color]!.length + (lockedColors.contains(color) ? 1 : 0);

  static int scoreForCrosses(int crosses) {
    if (crosses < 0 || crosses > QwixxRules.maximumScoredCrosses) {
      throw RangeError.range(
        crosses,
        0,
        QwixxRules.maximumScoredCrosses,
        'crosses',
      );
    }
    return crosses * (crosses + 1) ~/ 2;
  }

  int rowScore(QwixxColor color) => scoreForCrosses(crossCount(color));
  int get missPenalty => misses * -QwixxRules.missPenalty;
  int get total =>
      QwixxColor.values.fold(0, (sum, color) => sum + rowScore(color)) +
      missPenalty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'crossed': {
      for (final color in QwixxColor.values)
        color.name: crossed[color]!.toList()..sort(),
    },
    'lockedColors': lockedColors.map((color) => color.name).toList(),
    'misses': misses,
  };

  factory QwixxPlayer.fromJson(Map<String, dynamic> json) {
    try {
      final name = json['name'] as String;
      final rawCrossed = Map<String, dynamic>.from(json['crossed'] as Map);
      final locked = (json['lockedColors'] as List)
          .map((value) => QwixxColor.values.byName(value as String))
          .toSet();
      final misses = json['misses'] as int;
      final crossed = <QwixxColor, Set<int>>{};
      for (final color in QwixxColor.values) {
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
          misses > QwixxRules.maximumMisses) {
        throw const FormatException('Ungültiger Qwixx-Spieler.');
      }
      for (final color in locked) {
        final marks = crossed[color]!;
        if (!marks.contains(color.numbers.last) || marks.length < 6) {
          throw const FormatException('Ungültiger Reihenverschluss.');
        }
      }
      return QwixxPlayer(
        name: name,
        crossed: crossed,
        lockedColors: locked,
        misses: misses,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Qwixx-Spieler.', error);
    }
  }
}

class QwixxGameState implements SavedGameState {
  QwixxGameState({
    required this.players,
    this.mode = GameMode.block,
    Set<QwixxColor>? closedColors,
    Set<QwixxColor>? pendingClosedColors,
    this.activePlayerIndex = 0,
    this.isComplete = false,
    List<int>? dice,
    this.hasRolled = false,
    Set<int>? whiteMarkedPlayerIndices,
    this.colorMarked = false,
  }) : closedColors = Set.of(closedColors ?? const {}),
       pendingClosedColors = Set.of(pendingClosedColors ?? const {}),
       dice = List.of(dice ?? QwixxRules.initialDice),
       whiteMarkedPlayerIndices = Set.of(whiteMarkedPlayerIndices ?? const {});

  factory QwixxGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
  }) {
    final cleaned = names.map((name) => name.trim()).toList();
    if (cleaned.length < QwixxRules.minimumPlayers ||
        cleaned.length > QwixxRules.maximumPlayers) {
      throw ArgumentError('Bei Qwixx sind 2 bis 5 Spieler erlaubt.');
    }
    if (cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
    return QwixxGameState(
      players: cleaned.map((name) => QwixxPlayer(name: name)).toList(),
      mode: mode,
    );
  }

  @override
  final List<QwixxPlayer> players;
  final GameMode mode;
  final Set<QwixxColor> closedColors;
  final Set<QwixxColor> pendingClosedColors;
  int activePlayerIndex;
  @override
  bool isComplete;
  final List<int> dice;
  bool hasRolled;
  final Set<int> whiteMarkedPlayerIndices;
  bool colorMarked;

  int get whiteSum => dice[0] + dice[1];

  Map<QwixxColor, Set<int>> get coloredSums => {
    for (final color in QwixxColor.values)
      color: {
        dice[0] + dice[color.digitalDieIndex],
        dice[1] + dice[color.digitalDieIndex],
      },
  };

  QwixxPlayer get activePlayer => players[activePlayerIndex];
  bool canMark(int playerIndex, QwixxColor color, int value) {
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

  void mark(int playerIndex, QwixxColor color, int value) {
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
    if (values.length != QwixxRules.diceCount ||
        values.any(
          (value) =>
              value < QwixxRules.minimumDieValue ||
              value > QwixxRules.maximumDieValue,
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
    QwixxColor color,
    int value,
    QwixxDigitalAction action,
  ) {
    if (mode != GameMode.digital ||
        !hasRolled ||
        !canMark(playerIndex, color, value)) {
      return false;
    }
    return switch (action) {
      QwixxDigitalAction.white =>
        value == whiteSum && !whiteMarkedPlayerIndices.contains(playerIndex),
      QwixxDigitalAction.color =>
        playerIndex == activePlayerIndex &&
            !colorMarked &&
            coloredSums[color]!.contains(value),
    };
  }

  void markDigital(
    int playerIndex,
    QwixxColor color,
    int value,
    QwixxDigitalAction action,
  ) {
    if (!canMarkDigital(playerIndex, color, value, action)) {
      throw StateError('Diese Würfelaktion ist nicht verfügbar.');
    }
    mark(playerIndex, color, value);
    if (action == QwixxDigitalAction.white) {
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
      if (player.misses >= QwixxRules.maximumMisses) {
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
    if (player.misses >= QwixxRules.maximumMisses) {
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
        closedColors.length >= QwixxRules.rowsToCloseGame ||
        players.any((player) => player.misses >= QwixxRules.maximumMisses);
  }

  int totalFor(QwixxPlayer player) => player.total;

  @override
  String get gameLabel => 'Qwixx';
  @override
  String get modeLabel => mode.label;
  @override
  String get progressLabel =>
      '${closedColors.length} von ${QwixxRules.rowsToCloseGame} Reihen geschlossen';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'qwixx',
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

  factory QwixxGameState.fromJson(Map<String, dynamic> json) {
    try {
      final players = (json['players'] as List)
          .map(
            (value) =>
                QwixxPlayer.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList();
      final closed = (json['closedColors'] as List)
          .map((value) => QwixxColor.values.byName(value as String))
          .toSet();
      final pending = (json['pendingClosedColors'] as List? ?? const [])
          .map((value) => QwixxColor.values.byName(value as String))
          .toSet();
      final active = json['activePlayerIndex'] as int;
      final complete = json['isComplete'] as bool;
      final mode = GameMode.values.byName(
        json['mode'] as String? ?? GameMode.block.name,
      );
      final dice = (json['dice'] as List? ?? QwixxRules.initialDice)
          .map((value) => value as int)
          .toList();
      final hasRolled = json['hasRolled'] as bool? ?? false;
      final whiteMarkedPlayerIndices =
          (json['whiteMarkedPlayerIndices'] as List? ?? const [])
              .map((value) => value as int)
              .toSet();
      final colorMarked = json['colorMarked'] as bool? ?? false;
      if (players.length < QwixxRules.minimumPlayers ||
          players.length > QwixxRules.maximumPlayers ||
          players.map((player) => player.name).toSet().length !=
              players.length ||
          active < 0 ||
          active >= players.length ||
          dice.length != QwixxRules.diceCount ||
          dice.any(
            (value) =>
                value < QwixxRules.minimumDieValue ||
                value > QwixxRules.maximumDieValue,
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
        throw const FormatException('Ungültiger Qwixx-Spielstand.');
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
          closed.length >= QwixxRules.rowsToCloseGame ||
          players.any((player) => player.misses >= QwixxRules.maximumMisses);
      if (complete != actuallyComplete) {
        throw const FormatException('Ungültiger Abschlussstatus.');
      }
      return QwixxGameState(
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
      throw FormatException('Ungültiger Qwixx-Spielstand.', error);
    }
  }
}

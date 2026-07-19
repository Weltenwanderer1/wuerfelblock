import 'saved_game_state.dart';

enum QwixxColor { red, yellow, green, blue }

extension QwixxColorInfo on QwixxColor {
  List<int> get numbers => switch (this) {
    QwixxColor.red || QwixxColor.yellow => [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    QwixxColor.green || QwixxColor.blue => [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2],
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
    return index != numbers.length - 1 || marks.length >= 5;
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
    if (crosses < 0 || crosses > 12) {
      throw RangeError.range(crosses, 0, 12, 'crosses');
    }
    return crosses * (crosses + 1) ~/ 2;
  }

  int rowScore(QwixxColor color) => scoreForCrosses(crossCount(color));
  int get missPenalty => misses * -5;
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
      if (name.trim().isEmpty || misses < 0 || misses > 4) {
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
    Set<QwixxColor>? closedColors,
    Set<QwixxColor>? pendingClosedColors,
    this.activePlayerIndex = 0,
    this.isComplete = false,
  }) : closedColors = Set.of(closedColors ?? const {}),
       pendingClosedColors = Set.of(pendingClosedColors ?? const {});

  factory QwixxGameState.newGame(List<String> names) {
    final cleaned = names.map((name) => name.trim()).toList();
    if (cleaned.length < 2 || cleaned.length > 5) {
      throw ArgumentError('Bei Qwixx sind 2 bis 5 Spieler erlaubt.');
    }
    if (cleaned.any((name) => name.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Spielernamen müssen ausgefüllt und eindeutig sein.');
    }
    return QwixxGameState(
      players: cleaned.map((name) => QwixxPlayer(name: name)).toList(),
    );
  }

  @override
  final List<QwixxPlayer> players;
  final Set<QwixxColor> closedColors;
  final Set<QwixxColor> pendingClosedColors;
  int activePlayerIndex;
  @override
  bool isComplete;

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
    if (player.misses >= 4) throw StateError('Vier Fehlwürfe sind erreicht.');
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
        closedColors.length >= 2 || players.any((player) => player.misses >= 4);
  }

  int totalFor(QwixxPlayer player) => player.total;

  @override
  String get gameLabel => 'Qwixx';
  @override
  String get modeLabel => 'Echte Würfel';
  @override
  String get progressLabel => '${closedColors.length} von 2 Reihen geschlossen';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'qwixx',
    'players': players.map((player) => player.toJson()).toList(),
    'closedColors': closedColors.map((color) => color.name).toList(),
    'pendingClosedColors': pendingClosedColors
        .map((color) => color.name)
        .toList(),
    'activePlayerIndex': activePlayerIndex,
    'isComplete': isComplete,
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
      if (players.length < 2 ||
          players.length > 5 ||
          players.map((player) => player.name).toSet().length !=
              players.length ||
          active < 0 ||
          active >= players.length) {
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
          closed.length >= 2 || players.any((player) => player.misses >= 4);
      if (complete != actuallyComplete) {
        throw const FormatException('Ungültiger Abschlussstatus.');
      }
      return QwixxGameState(
        players: players,
        closedColors: closed,
        pendingClosedColors: pending,
        activePlayerIndex: active,
        isComplete: complete,
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Ungültiger Qwixx-Spielstand.', error);
    }
  }
}

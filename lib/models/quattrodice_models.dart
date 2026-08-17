import 'game_models.dart';
import 'saved_game_state.dart';

enum QuattroSide { a, b }

enum QuattroCorner { red, blue, green, yellow }

extension QuattroCornerInfo on QuattroCorner {
  String get label => switch (this) {
    QuattroCorner.red => 'Rot',
    QuattroCorner.blue => 'Blau',
    QuattroCorner.green => 'Grün',
    QuattroCorner.yellow => 'Gelb',
  };
  // board position: TL red, TR blue, BL green, BR yellow
}

enum QuattroStatus { open, circled, shaded, crossed }

class QuattroRange {
  const QuattroRange({required this.min, required this.max});
  final int min;
  final int max;
  bool contains(int v) => v >= min && v <= max;
  String get label =>
      min == max ? '$min' : (min == 4 && max == 24 ? '4–24' : '$min–$max');
  Map<String, dynamic> toJson() => {'min': min, 'max': max};
  factory QuattroRange.fromJson(Map<String, dynamic> j) =>
      QuattroRange(min: j['min'] as int, max: j['max'] as int);
  factory QuattroRange.exact(int v) => QuattroRange(min: v, max: v);
}

class QuattroSquareDef {
  const QuattroSquareDef({
    required this.id,
    required this.range,
    this.preset = const {},
    this.isOrange = false,
    this.isLila = false,
  });
  final String id; // e.g. A1
  final QuattroRange range;
  final Map<QuattroCorner, int>
  preset; // white numbers that must be exactly that
  final bool isOrange;
  final bool isLila; // 4,5,6 extra
  bool get isExact => range.min == range.max;
  bool get hasPreset => preset.isNotEmpty;
}

class QuattroBridge {
  const QuattroBridge(this.a, this.b);
  final String a;
  final String b;
  String get key => a.compareTo(b) < 0 ? '$a-$b' : '$b-$a';
  @override
  bool operator ==(Object other) => other is QuattroBridge && other.key == key;
  @override
  int get hashCode => key.hashCode;
}

/// Board configs -------------------------------------------------------------

abstract final class QuattroBoards {
  // layout 4 cols A-D, 4 rows 1-4 (1 top)
  static const sideA = [
    QuattroSquareDef(id: 'A1', range: QuattroRange(min: 14, max: 14)),
    QuattroSquareDef(id: 'B1', range: QuattroRange(min: 12, max: 12)),
    QuattroSquareDef(id: 'C1', range: QuattroRange(min: 16, max: 16)),
    QuattroSquareDef(id: 'D1', range: QuattroRange(min: 18, max: 18)),
    QuattroSquareDef(id: 'A2', range: QuattroRange(min: 10, max: 10)),
    QuattroSquareDef(id: 'B2', range: QuattroRange(min: 13, max: 13)),
    QuattroSquareDef(id: 'C2', range: QuattroRange(min: 11, max: 11)),
    QuattroSquareDef(id: 'D2', range: QuattroRange(min: 15, max: 15)),
    QuattroSquareDef(id: 'A3', range: QuattroRange(min: 8, max: 8)),
    QuattroSquareDef(
      id: 'B3',
      range: QuattroRange(min: 4, max: 4),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'C3',
      range: QuattroRange(min: 5, max: 5),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'D3',
      range: QuattroRange(min: 6, max: 6),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'A4',
      range: QuattroRange(min: 20, max: 20),
      isOrange: true,
    ),
    QuattroSquareDef(
      id: 'B4',
      range: QuattroRange(min: 22, max: 22),
      isOrange: true,
    ),
    QuattroSquareDef(
      id: 'C4',
      range: QuattroRange(min: 24, max: 24),
      isOrange: true,
    ),
    QuattroSquareDef(id: 'D4', range: QuattroRange(min: 9, max: 9)),
  ];

  static const sideB = [
    QuattroSquareDef(
      id: 'A1',
      range: QuattroRange(min: 16, max: 24),
      preset: {QuattroCorner.red: 6},
    ),
    QuattroSquareDef(id: 'B1', range: QuattroRange(min: 12, max: 12)),
    QuattroSquareDef(id: 'C1', range: QuattroRange(min: 10, max: 14)),
    QuattroSquareDef(id: 'D1', range: QuattroRange(min: 18, max: 18)),
    QuattroSquareDef(id: 'A2', range: QuattroRange(min: 10, max: 10)),
    QuattroSquareDef(
      id: 'B2',
      range: QuattroRange(min: 13, max: 13),
      preset: {QuattroCorner.yellow: 3},
    ),
    QuattroSquareDef(id: 'C2', range: QuattroRange(min: 11, max: 11)),
    QuattroSquareDef(
      id: 'D2',
      range: QuattroRange(min: 15, max: 15),
      preset: {QuattroCorner.green: 5},
    ),
    QuattroSquareDef(id: 'A3', range: QuattroRange(min: 8, max: 8)),
    QuattroSquareDef(
      id: 'B3',
      range: QuattroRange(min: 4, max: 6),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'C3',
      range: QuattroRange(min: 5, max: 5),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'D3',
      range: QuattroRange(min: 6, max: 6),
      isLila: true,
    ),
    QuattroSquareDef(
      id: 'A4',
      range: QuattroRange(min: 20, max: 20),
      isOrange: true,
    ),
    QuattroSquareDef(
      id: 'B4',
      range: QuattroRange(min: 22, max: 22),
      isOrange: true,
    ),
    QuattroSquareDef(
      id: 'C4',
      range: QuattroRange(min: 24, max: 24),
      isOrange: true,
    ),
    QuattroSquareDef(id: 'D4', range: QuattroRange(min: 9, max: 13)),
  ];

  static List<QuattroSquareDef> forSide(QuattroSide s) =>
      s == QuattroSide.a ? sideA : sideB;

  static QuattroSquareDef defFor(QuattroSide s, String id) =>
      forSide(s).firstWhere((e) => e.id == id);

  // orthogonal bridges (no diagonal, no orange involved)
  static List<QuattroBridge> bridgesFor(QuattroSide s) {
    // grid 4x4
    const cols = ['A', 'B', 'C', 'D'];
    List<QuattroBridge> out = [];
    for (int r = 1; r <= 4; r++) {
      for (int ci = 0; ci < 4; ci++) {
        final id = '${cols[ci]}$r';
        final def = defFor(s, id);
        if (def.isOrange) continue;
        // right neighbor
        if (ci < 3) {
          final nid = '${cols[ci + 1]}$r';
          final ndef = defFor(s, nid);
          if (!ndef.isOrange) out.add(QuattroBridge(id, nid));
        }
        // down neighbor
        if (r < 4) {
          final nid = '${cols[ci]}${r + 1}';
          final ndef = defFor(s, nid);
          if (!ndef.isOrange) out.add(QuattroBridge(id, nid));
        }
      }
    }
    return out;
  }
}

// --- player state per square -------------------------------------------------

class QuattroSquareState {
  QuattroSquareState({
    Map<QuattroCorner, int?>? corners,
    this.status = QuattroStatus.open,
  }) : corners = {for (var c in QuattroCorner.values) c: corners?[c]};
  final Map<QuattroCorner, int?> corners;
  QuattroStatus status;
  bool get isFilled => corners.values.every((v) => v != null);
  int get sum => corners.values.whereType<int>().fold(0, (a, b) => a + b);
  Map<String, dynamic> toJson() => {
    'corners': {for (var c in QuattroCorner.values) c.name: corners[c]},
    'status': status.name,
  };
  factory QuattroSquareState.fromJson(Map<String, dynamic> j) {
    final raw = Map<String, dynamic>.from(j['corners'] as Map);
    final m = <QuattroCorner, int?>{};
    for (var c in QuattroCorner.values) {
      final v = raw[c.name];
      m[c] = v == null ? null : v as int;
    }
    return QuattroSquareState(
      corners: m,
      status: QuattroStatus.values.byName(j['status'] as String),
    );
  }
  QuattroSquareState copy() => QuattroSquareState.fromJson(toJson());
}

class QuattroPlayer {
  QuattroPlayer({
    required this.name,
    Map<String, QuattroSquareState>? squares,
    List<int?>? jokers,
    Set<String>? bridges,
  }) : squares = {
         for (var e
             in squares?.entries ?? <MapEntry<String, QuattroSquareState>>[])
           e.key: e.value.copy(),
       },
       jokers = List<int?>.from(jokers ?? [null, null]),
       bridges = Set<String>.from(bridges ?? <String>{}) {
    // ensure all squares present
    for (var def in QuattroBoards.sideA) {
      this.squares.putIfAbsent(def.id, () => QuattroSquareState());
    }
  }

  final String name;
  final Map<String, QuattroSquareState> squares;
  final List<int?> jokers; // len 2
  final Set<String> bridges; // keys like A1-B1

  bool get isComplete =>
      squares.values.every((s) => s.status != QuattroStatus.open);

  int
  get circledSum => squares.entries.where((e) => e.value.status == QuattroStatus.circled).fold(0, (
    sum,
    e,
  ) {
    final defA = QuattroBoards.defFor(QuattroSide.a, e.key);
    final defB = QuattroBoards.defFor(QuattroSide.b, e.key);
    // use stored sum? For exact boards sum==range, for range boards we store actual circled sum elsewhere? store as sum
    // For simplicity circled points = square sum (for range squares the actual sum entered)
    // For exact squares it's range value.
    // We'll store points as sum for shaded? Actually circled points should be range value for exact, or actual sum for range.
    // We keep sum for exact as range; for range, the sum entered is the points.
    // Since we don't store separate points, use e.value.sum if isCircled (which equals entered sum)
    if (defA.isOrange || defB.isOrange) {
      // just use sum
    }
    return sum + e.value.sum;
  });

  int get shadedCount =>
      squares.values.where((s) => s.status == QuattroStatus.shaded).length;
  int get bridgePoints => bridges.length * 5;
  int get lilaExtra {
    var seen = <String>{};
    int count = 0;
    for (var def in QuattroBoards.sideA.where((d) => d.isLila)) {
      if (seen.contains(def.id)) {
        continue;
      }
      seen.add(def.id);
      final st = squares[def.id];
      if (st?.status == QuattroStatus.circled &&
          bridges.any((k) => k.contains(def.id))) {
        count++;
      }
    }
    return count * 5;
  }

  int get jokerSum => jokers.whereType<int>().fold(0, (a, b) => a + b);
  int get total {
    final plus = circledSum + bridgePoints + lilaExtra;
    final minus = shadedCount * 10 + jokerSum;
    return plus - minus;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'squares': {for (var e in squares.entries) e.key: e.value.toJson()},
    'jokers': jokers,
    'bridges': bridges.toList(),
  };
  factory QuattroPlayer.fromJson(Map<String, dynamic> j) {
    final rawSq = Map<String, dynamic>.from(j['squares'] as Map);
    final sq = <String, QuattroSquareState>{};
    rawSq.forEach(
      (k, v) => sq[k] = QuattroSquareState.fromJson(
        Map<String, dynamic>.from(v as Map),
      ),
    );
    return QuattroPlayer(
      name: j['name'] as String,
      squares: sq,
      jokers: (j['jokers'] as List).map((e) => e as int?).toList(),
      bridges: (j['bridges'] as List).map((e) => e as String).toSet(),
    );
  }
  QuattroPlayer copy() => QuattroPlayer.fromJson(toJson());
}

// --- game state --------------------------------------------------------------

class QuattroGameState implements SavedGameState {
  QuattroGameState({
    required List<QuattroPlayer> players,
    this.side = QuattroSide.a,
    this.mode = GameMode.block,
    this.activePlayerIndex = 0,
    this.dice = const [1, 1, 1, 1, 1],
    this.hasRolled = false,
    this.isComplete = false,
    this.roundActiveDone = 0,
    this.passiveCursor = -1,
    this.isFinalRound = false,
    this.finalStarterIndex,
  }) : players = players.map((p) => p.copy()).toList();

  factory QuattroGameState.newGame(
    List<String> names, {
    GameMode mode = GameMode.block,
    QuattroSide side = QuattroSide.a,
  }) {
    final cleaned = names.map((e) => e.trim()).toList();
    if (cleaned.isEmpty || cleaned.length > 6) {
      throw ArgumentError('1–6 Spieler');
    }
    if (cleaned.any((e) => e.isEmpty) ||
        cleaned.toSet().length != cleaned.length) {
      throw ArgumentError('Namen eindeutig');
    }
    return QuattroGameState(
      players: cleaned.map((n) => QuattroPlayer(name: n)).toList(),
      mode: mode,
      side: side,
    );
  }

  @override
  final List<QuattroPlayer> players;
  final QuattroSide side;
  final GameMode mode;
  int activePlayerIndex;
  List<int> dice; // [rot,blau,grün,gelb,weiß] 1-6
  bool hasRolled;
  @override
  bool isComplete;
  // turn flow: active does 2 entries (corners or jokers), then each passive does 1; enforces endgame
  int roundActiveDone;
  int passiveCursor; // -1 while active's turn, else index of current passive player (may equal active -> skipped)
  bool isFinalRound;
  int? finalStarterIndex;

  QuattroPlayer get activePlayer => players[activePlayerIndex];
  int get currentActorIndex => passiveCursor == -1 ? activePlayerIndex : passiveCursor;
  String get currentActorName => players[currentActorIndex].name;
  bool get isActivePhase => passiveCursor == -1;
  List<QuattroSquareDef> get board => QuattroBoards.forSide(side);

  // validation helpers
  bool canWriteCorner(int pIdx, String sqId, QuattroCorner corner, int value) {
    if (pIdx < 0 || pIdx >= players.length) return false;
    if (value < 1 || value > 6) return false;
    final def = QuattroBoards.defFor(side, sqId);
    final sq = players[pIdx].squares[sqId]!;
    if (sq.status != QuattroStatus.open) return false;
    if (sq.corners[corner] != null) return false;
    // preset check
    if (def.preset.containsKey(corner) && def.preset[corner] != value) {
      return false;
    }
    // if preset corner already has value mismatch -> blocked
    return true;
  }

  void writeCorner(int pIdx, String sqId, QuattroCorner corner, int value) {
    if (!canWriteCorner(pIdx, sqId, corner, value)) {
      throw StateError('Ecke nicht verfügbar');
    }
    players[pIdx].squares[sqId]!.corners[corner] = value;
    // auto close check: if now filled, evaluate
    final sq = players[pIdx].squares[sqId]!;
    if (sq.isFilled) {
      final def = QuattroBoards.defFor(side, sqId);
      final sum = sq.sum;
      final ok = def.range.contains(sum);
      // preset already enforced, if preset corners wrong -> would have prevented write, so ok stays
      if (ok) {
        sq.status = QuattroStatus.circled;
      } else {
        sq.status = QuattroStatus.shaded;
      }
    }
    _recordEntry(pIdx);
  }

  void clearCorner(int pIdx, String sqId, QuattroCorner corner) {
    final sq = players[pIdx].squares[sqId]!;
    if (sq.status != QuattroStatus.open) {
      throw StateError('Bereits geschlossen');
    }
    sq.corners[corner] = null;
  }

  void markCross(int pIdx, String sqId) {
    final sq = players[pIdx].squares[sqId]!;
    if (sq.status != QuattroStatus.open) {
      throw StateError('Schon geschlossen');
    }
    // only allowed when another player circled it first - we allow manual
    sq.status = QuattroStatus.crossed;
  }

  bool canJoker(int pIdx, int value) {
    final pl = players[pIdx];
    return pl.jokers.contains(null) && value >= 1 && value <= 6;
  }

  void writeJoker(int pIdx, int value) {
    final pl = players[pIdx];
    final idx = pl.jokers.indexOf(null);
    if (idx < 0) throw StateError('Joker voll');
    if (value < 1 || value > 6) throw ArgumentError('1-6');
    pl.jokers[idx] = value;
    _recordEntry(pIdx);
  }

  void clearJoker(int pIdx, int idx) {
    players[pIdx].jokers[idx] = null;
  }

  void toggleBridge(int pIdx, String a, String b) {
    final pl = players[pIdx];
    final key = a.compareTo(b) < 0 ? '$a-$b' : '$b-$a';
    // validate bridge exists and both squares circled and not orange
    final allowed = QuattroBoards.bridgesFor(
      side,
    ).map((e) => e.key).contains(key);
    if (!allowed) {
      throw StateError('Keine Brücke hier');
    }
    final sa = pl.squares[a]!;
    final sb = pl.squares[b]!;
    if (sa.status != QuattroStatus.circled ||
        sb.status != QuattroStatus.circled) {
      throw StateError('Beide SQUARES müssen gekreist sein');
    }
    if (pl.bridges.contains(key)) {
      pl.bridges.remove(key);
    } else {
      pl.bridges.add(key);
    }
  }

  void roll(List<int> values) {
    if (values.length != 5 || values.any((v) => v < 1 || v > 6)) {
      throw ArgumentError('5 Würfel 1-6');
    }
    dice = List.of(values);
    hasRolled = true;
  }

  // turn bookkeeping: call after each successful entry
  void _recordEntry(int pIdx) {
    if (isComplete || isFinalRound && _finalRoundDone()) return;
    if (passiveCursor == -1) {
      // active phase
      if (pIdx != activePlayerIndex) return;
      roundActiveDone++;
      if (roundActiveDone >= 2) {
        passiveCursor = (activePlayerIndex + 1) % players.length;
        // skip if only 1 player? then no passive
        if (players.length == 1) {
          _endRoundAndRotate();
        }
        hasRolled = false;
      }
    } else {
      // passive phase — expect exactly passiveCursor
      if (pIdx != passiveCursor) return;
      passiveCursor = (passiveCursor + 1) % players.length;
      if (passiveCursor == activePlayerIndex) {
        // all passives done (wrapped back to active)
        _endRoundAndRotate();
      } else {
        hasRolled = false;
      }
    }
  }

  bool _finalRoundDone() {
    // final round: starter already complete, others have had their single final roll; we shade and finish
    return isComplete;
  }

  void _endRoundAndRotate() {
    _autoX();
    _autoBridges();
    final finisher = _firstCompleteIndex();
    // Bereits in der Finalrunde: diese Runde war die letzte für alle anderen -> jetzt endgültig schließen
    if (isFinalRound) {
      for (final p in players) {
        for (final e in p.squares.entries) {
          if (e.value.status == QuattroStatus.open) {
            e.value.status = QuattroStatus.shaded;
          }
        }
      }
      _autoBridges();
      isComplete = true;
      passiveCursor = -1;
      roundActiveDone = 0;
      return;
    }
    // Erster Abschluss: Finalrunde starten – alle anderen bekommen noch genau eine Runde
    if (finisher != null) {
      isFinalRound = true;
      finalStarterIndex = finisher;
      if (players.every((p) => p.isComplete)) {
        isComplete = true;
        passiveCursor = -1;
        roundActiveDone = 0;
        return;
      }
      // normal rotieren – die gerade gestartete Finalrunde läuft ganz normal weiter
    }
    activePlayerIndex = (activePlayerIndex + 1) % players.length;
    hasRolled = false;
    roundActiveDone = 0;
    passiveCursor = -1;
  }

  int? _firstCompleteIndex() {
    for (int i = 0; i < players.length; i++) {
      if (players[i].isComplete) return i;
    }
    return null;
  }

  void _autoX() {
    for (final def in QuattroBoards.forSide(side)) {
      final id = def.id;
      final anyCircled = players.any(
        (p) => p.squares[id]!.status == QuattroStatus.circled,
      );
      if (!anyCircled) continue;
      for (final p in players) {
        if (p.squares[id]!.status == QuattroStatus.open) {
          p.squares[id]!.status = QuattroStatus.crossed;
        }
      }
    }
  }

  void _autoBridges() {
    final bridges = QuattroBoards.bridgesFor(side);
    for (final p in players) {
      for (final b in bridges) {
        if (p.bridges.contains(b.key)) continue;
        final sa = p.squares[b.a]!.status;
        final sb = p.squares[b.b]!.status;
        if (sa == QuattroStatus.circled && sb == QuattroStatus.circled) {
          p.bridges.add(b.key);
        }
      }
    }
  }

  void nextPlayer() {
    // manual override: treat as end-of-round rotate (also used by Nächste-Person button)
    if (passiveCursor != -1) {
      // if passives still pending, just step to next passive
      passiveCursor = (passiveCursor + 1) % players.length;
      if (passiveCursor == activePlayerIndex) {
        _endRoundAndRotate();
      } else {
        hasRolled = false;
      }
      return;
    }
    if (roundActiveDone > 0) {
      // active had 1 or 2 entries, force end of active phase
      if (roundActiveDone >= 2 || players.length == 1) {
        passiveCursor = (activePlayerIndex + 1) % players.length;
        if (players.length == 1) {
          _endRoundAndRotate();
        } else {
          hasRolled = false;
        }
        return;
      }
      // only 1 entry but user wants to advance → allow (Rest verfällt laut Regel gegen Ende)
      passiveCursor = (activePlayerIndex + 1) % players.length;
      hasRolled = false;
      return;
    }
    _endRoundAndRotate();
  }

  void checkEnd() {
    if (players.any((p) => p.isComplete)) {
      isComplete = true;
    }
  }

  QuattroGameState copy() => QuattroGameState.fromJson(toJson());

  @override
  String get gameLabel => 'QuattroDice';
  @override
  String get modeLabel => '${side.name.toUpperCase()} · ${mode.label}';
  @override
  String get progressLabel {
    final open = players
        .map(
          (p) => p.squares.values
              .where((s) => s.status == QuattroStatus.open)
              .length,
        )
        .join('/');
    return 'Offen: $open';
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'quattrodice',
    'schemaVersion': 3,
    'side': side.name,
    'mode': mode.name,
    'players': players.map((p) => p.toJson()).toList(),
    'activePlayerIndex': activePlayerIndex,
    'dice': dice,
    'hasRolled': hasRolled,
    'isComplete': isComplete,
    'roundActiveDone': roundActiveDone,
    'passiveCursor': passiveCursor,
    'isFinalRound': isFinalRound,
    'finalStarterIndex': finalStarterIndex,
  };

  factory QuattroGameState.fromJson(Map<String, dynamic> j) {
    final side = QuattroSide.values.byName(j['side'] as String);
    final mode = GameMode.values.byName(j['mode'] as String);
    final players = (j['players'] as List)
        .map((e) => QuattroPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return QuattroGameState(
      players: players,
      side: side,
      mode: mode,
      activePlayerIndex: j['activePlayerIndex'] as int,
      dice: (j['dice'] as List).map((e) => e as int).toList(),
      hasRolled: j['hasRolled'] as bool,
      isComplete: j['isComplete'] as bool,
      roundActiveDone: (j['roundActiveDone'] as int?) ?? 0,
      passiveCursor: (j['passiveCursor'] as int?) ?? -1,
      isFinalRound: (j['isFinalRound'] as bool?) ?? false,
      finalStarterIndex: j['finalStarterIndex'] as int?,
    );
  }
}

// ignore: unused_element
void _requireExactKeys(Map j, Set<String> exp) {
  // kept for future strict JSON checks
  if (j.length != exp.length || !j.keys.toSet().containsAll(exp)) {
    throw const FormatException('JSON keys');
  }
}

import 'package:flutter/material.dart';
import '../controllers/quattrodice_controller.dart';
import '../l10n/localized_text.dart';
import '../models/quattrodice_models.dart';
import 'quattrodice_result_screen.dart';

class QuattroGameScreen extends StatefulWidget {
  const QuattroGameScreen({required this.game, super.key});
  final QuattroController game;
  @override
  State<QuattroGameScreen> createState() => _QuattroGameScreenState();
}

class _QuattroGameScreenState extends State<QuattroGameScreen> {
  QuattroController get game => widget.game;
  int displayed = 0;
  @override
  void initState() {
    super.initState();
    displayed = game.state.activePlayerIndex;
    game.addListener(_upd);
  }

  @override
  void dispose() {
    game.removeListener(_upd);
    super.dispose();
  }

  void _upd() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() op) async {
    try {
      await op();
      if (mounted && game.state.isComplete) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuattroResultScreen(game: game)),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = game.state;
    final pl = st.players[displayed];
    final diceLabels = const ['Rot', 'Blau', 'Grün', 'Gelb', 'Weiß'];
    final diceColors = const [
      Color(0xFFD94F4F),
      Color(0xFF4A90D9),
      Color(0xFF4CAF7A),
      Color(0xFFF2C14E),
      Colors.white,
    ];
    return Scaffold(
      appBar: AppBar(
        title: LocalizedText(
          'QuattroDice · Seite ${st.side.name.toUpperCase()}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: game.canUndo ? () => _run(game.undo) : null,
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _confirmFinish(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // player selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < st.players.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        st.players[i].name +
                            (i == st.activePlayerIndex ? ' ★' : ''),
                      ),
                      selected: displayed == i,
                      onSelected: (_) => setState(() => displayed = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // dice bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < 5; i++)
                        Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: diceColors[i],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${st.dice[i]}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: i == 4 ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              diceLabels[i],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => _run(game.roll),
                        icon: const Icon(Icons.casino),
                        label: const Text('Würfeln'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _run(game.nextPlayer),
                        child: const Text('Nächste Person'),
                      ),
                      const Spacer(),
                      Text(
                        'Aktiv: ${st.activePlayer.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // board grid
          _BoardGrid(
            state: st,
            playerIndex: displayed,
            onTapCorner: (sq, c) => _pickCorner(sq, c),
            onTapCross: (sq) => _run(() => game.markCross(displayed, sq)),
            onToggleBridge: (a, b) =>
                _run(() => game.toggleBridge(displayed, a, b)),
          ),
          const SizedBox(height: 12),
          // jokers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Joker (Minuspunkte)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (int i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _JokerBox(
                            value: pl.jokers[i],
                            onSet: (v) =>
                                _run(() => game.writeJoker(displayed, v)),
                            onClear: () =>
                                _run(() => game.clearJoker(displayed, i)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Aktiv: 2 farbige / Passiv: weiß – stattdessen hier eintragen. Summe zählt als Minus.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ScorePreview(player: pl, side: st.side),
        ],
      ),
    );
  }

  Future<void> _pickCorner(String sqId, QuattroCorner c) async {
    final plIdx = displayed;
    // value picker 1-6 + clear + cross
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('$sqId · ${c.label}'),
        children: [
          for (int i = 1; i <= 6; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, i),
              child: Text('$i eintragen'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: const Text('Leeren'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -2),
            child: const Text('Als geblockt (X) markieren'),
          ),
        ],
      ),
    );
    if (v == null) {
      return;
    }
    if (v == -1) {
      await _run(() => game.clearCorner(plIdx, sqId, c));
    } else if (v == -2) {
      await _run(() => game.markCross(plIdx, sqId));
    } else {
      await _run(() => game.writeCorner(plIdx, sqId, c, v));
    }
  }

  Future<void> _confirmFinish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partie beenden?'),
        content: const Text('Wertung anzeigen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(game.finishGame);
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.state,
    required this.playerIndex,
    required this.onTapCorner,
    required this.onTapCross,
    required this.onToggleBridge,
  });
  final QuattroGameState state;
  final int playerIndex;
  final void Function(String, QuattroCorner) onTapCorner;
  final void Function(String) onTapCross;
  final void Function(String, String) onToggleBridge;
  @override
  Widget build(BuildContext context) {
    final cols = ['A', 'B', 'C', 'D'];
    final pl = state.players[playerIndex];
    // map id -> def
    return Column(
      children: [
        for (int r = 1; r <= 4; r++)
          Row(
            children: [
              for (int ci = 0; ci < 4; ci++)
                Builder(
                  builder: (ctx) {
                    final id = '${cols[ci]}$r';
                    final def = QuattroBoards.defFor(state.side, id);
                    final sq = pl.squares[id]!;
                    final isCirc = sq.status == QuattroStatus.circled;
                    final isShaded = sq.status == QuattroStatus.shaded;
                    final isCrossed = sq.status == QuattroStatus.crossed;
                    return Expanded(
                      child: Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCrossed
                                  ? Colors.grey.shade300
                                  : isShaded
                                  ? Colors.red.shade100
                                  : isCirc
                                  ? Colors.green.shade100
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: def.isOrange
                                    ? Colors.orange
                                    : def.isLila
                                    ? Colors.purple
                                    : Colors.black12,
                                width: def.isOrange || def.isLila ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  id,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                                // center number/range
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isShaded
                                        ? Colors.red.shade200
                                        : isCirc
                                        ? Colors.green.shade200
                                        : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    def.range.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: def.range.label.length > 3
                                          ? 12
                                          : 16,
                                      decoration: isCrossed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                // 2x2 corners
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          _CornerCell(
                                            color: QuattroCorner.red,
                                            value:
                                                sq.corners[QuattroCorner.red],
                                            preset:
                                                def.preset[QuattroCorner.red],
                                            enabled:
                                                sq.status == QuattroStatus.open,
                                            onTap: () => onTapCorner(
                                              id,
                                              QuattroCorner.red,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _CornerCell(
                                            color: QuattroCorner.blue,
                                            value:
                                                sq.corners[QuattroCorner.blue],
                                            preset:
                                                def.preset[QuattroCorner.blue],
                                            enabled:
                                                sq.status == QuattroStatus.open,
                                            onTap: () => onTapCorner(
                                              id,
                                              QuattroCorner.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _CornerCell(
                                            color: QuattroCorner.green,
                                            value:
                                                sq.corners[QuattroCorner.green],
                                            preset:
                                                def.preset[QuattroCorner.green],
                                            enabled:
                                                sq.status == QuattroStatus.open,
                                            onTap: () => onTapCorner(
                                              id,
                                              QuattroCorner.green,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _CornerCell(
                                            color: QuattroCorner.yellow,
                                            value: sq
                                                .corners[QuattroCorner.yellow],
                                            preset: def
                                                .preset[QuattroCorner.yellow],
                                            enabled:
                                                sq.status == QuattroStatus.open,
                                            onTap: () => onTapCorner(
                                              id,
                                              QuattroCorner.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCirc)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                if (isShaded)
                                  const Icon(
                                    Icons.block,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                if (isCrossed)
                                  const Text(
                                    'X',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  'Σ ${sq.sum}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // bridge toggles - right and bottom
                          if (ci < 3)
                            Positioned(
                              right: -2,
                              top: 38,
                              child: _BridgeDot(
                                a: id,
                                b: '${cols[ci + 1]}$r',
                                state: state,
                                playerIndex: playerIndex,
                                onToggle: onToggleBridge,
                              ),
                            ),
                          if (r < 4)
                            Positioned(
                              bottom: -2,
                              left: 38,
                              child: _BridgeDot(
                                a: id,
                                b: '${cols[ci]}${r + 1}',
                                state: state,
                                playerIndex: playerIndex,
                                onToggle: onToggleBridge,
                                vertical: true,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _CornerCell extends StatelessWidget {
  const _CornerCell({
    required this.color,
    required this.value,
    this.preset,
    required this.enabled,
    required this.onTap,
  });
  final QuattroCorner color;
  final int? value;
  final int? preset;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final bg = switch (color) {
      QuattroCorner.red => const Color(0xFFE57373),
      QuattroCorner.blue => const Color(0xFF64B5F6),
      QuattroCorner.green => const Color(0xFF81C784),
      QuattroCorner.yellow => const Color(0xFFFFD54F),
    };
    final txt = value?.toString() ?? (preset != null ? '·$preset' : '');
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          alignment: Alignment.center,
          child: Text(
            txt,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: preset != null && value == null
                  ? Colors.white70
                  : Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _BridgeDot extends StatelessWidget {
  const _BridgeDot({
    required this.a,
    required this.b,
    required this.state,
    required this.playerIndex,
    required this.onToggle,
    this.vertical = false,
  });
  final String a;
  final String b;
  final QuattroGameState state;
  final int playerIndex;
  final void Function(String, String) onToggle;
  final bool vertical;
  @override
  Widget build(BuildContext context) {
    final key = a.compareTo(b) < 0 ? '$a-$b' : '$b-$a';
    final active = state.players[playerIndex].bridges.contains(key);
    final allowed = QuattroBoards.bridgesFor(
      state.side,
    ).map((e) => e.key).contains(key);
    if (!allowed) return const SizedBox.shrink();
    final sa =
        state.players[playerIndex].squares[a]!.status == QuattroStatus.circled;
    final sb =
        state.players[playerIndex].squares[b]!.status == QuattroStatus.circled;
    final can = sa && sb;
    return InkWell(
      onTap: can ? () => onToggle(a, b) : null,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: active
              ? Colors.orange
              : can
              ? Colors.white
              : Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: can ? Colors.orange : Colors.grey),
        ),
        alignment: Alignment.center,
        child: Icon(
          active ? Icons.link : Icons.link_off,
          size: 12,
          color: can ? Colors.orange.shade900 : Colors.grey,
        ),
      ),
    );
  }
}

class _JokerBox extends StatelessWidget {
  const _JokerBox({
    required this.value,
    required this.onSet,
    required this.onClear,
  });
  final int? value;
  final void Function(int) onSet;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: value == null
        ? () async {
            final v = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: const Text('Joker 1-6'),
                children: [
                  for (int i = 1; i <= 6; i++)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, i),
                      child: Text('$i'),
                    ),
                ],
              ),
            );
            if (v != null) onSet(v);
          }
        : onClear,
    child: Container(
      width: 60,
      height: 44,
      decoration: BoxDecoration(
        color: value == null ? Colors.white : Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Text(
        value?.toString() ?? '—',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
    ),
  );
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview({required this.player, required this.side});
  final QuattroPlayer player;
  final QuattroSide side;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wertung ${player.name}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Gekreist: ${player.circledSum}  Brücken: ${player.bridgePoints} (×5)  Lila-Extra: ${player.lilaExtra}',
          ),
          Text(
            'Minus: schraffiert ${player.shadedCount}×10=${player.shadedCount * 10}  Joker ${player.jokerSum}',
            style: const TextStyle(color: Colors.red),
          ),
          const Divider(),
          Text(
            'Gesamt: ${player.total}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

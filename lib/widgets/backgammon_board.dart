import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/backgammon_models.dart';

String bgText(BuildContext context, String de, String en) =>
    Localizations.localeOf(context).languageCode == 'de' ? de : en;

/// Single source of truth for paint and native hit regions.
class BackgammonBoardLayout {
  const BackgammonBoardLayout(this.size);
  final Size size;
  double get column => (size.width - 144) / 12;
  double get half => (size.height - 88) / 2;
  Rect point(int p) {
    final top = p >= 13;
    final i = top ? p - 13 : 12 - p;
    final x = 12 + i * column + (i >= 6 ? 48 : 0);
    return Rect.fromLTWH(x, top ? 32 : size.height - 32 - half, column, half);
  }

  Rect bar(int player) => Rect.fromLTWH(
    12 + 6 * column,
    player == 1 ? 32 : size.height / 2 + 12,
    40,
    half,
  );
  Rect off(int player) => Rect.fromLTWH(
    size.width - 76,
    player == 1 ? 32 : size.height / 2 + 12,
    64,
    half,
  );
}

class BackgammonBoard extends StatelessWidget {
  const BackgammonBoard({
    super.key,
    required this.state,
    this.selected,
    this.onPoint,
    this.height = 400,
    this.width = 720,
  });
  final BackgammonGameState state;
  final int? selected;
  final ValueChanged<int>? onPoint;
  final double height, width;
  @override
  Widget build(BuildContext context) {
    final layout = BackgammonBoardLayout(Size(math.max(720, width), height));
    final moves = onPoint == null ? <BackgammonMove>[] : state.legalMoves;
    return RepaintBoundary(
      child: SizedBox(
        width: layout.size.width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _Wood(layout)),
              ),
            ),
            Positioned.fill(
              child: ExcludeSemantics(
                child: CustomPaint(painter: _Pieces(layout, state)),
              ),
            ),
            for (var p = 1; p <= 24; p++) _point(context, layout, p, moves),
            for (var player = 0; player < 2; player++) ...[
              Positioned.fromRect(
                rect: layout.bar(player),
                child: Semantics(
                  label: '${state.names[player]}, Bar, ${state.bar[player]}',
                  child: Align(
                    alignment: Alignment.center,
                    child: _badge('${state.bar[player]}'),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: layout.off(player),
                child: Semantics(
                  label:
                      '${state.names[player]}, ${bgText(context, 'ausgespielt', 'borne off')}, ${state.off[player]}',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          player == state.activePlayerIndex &&
                              moves.any((m) => m.from == selected && m.to == 25)
                          ? () => onPoint?.call(25)
                          : null,
                      child: Center(
                        child: _badge(
                          '${state.off[player]}${player == state.activePlayerIndex && moves.any((m) => m.from == selected && m.to == 25) ? ' →' : ''}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _point(
    BuildContext context,
    BackgammonBoardLayout l,
    int p,
    List<BackgammonMove> moves,
  ) {
    final n = state.points[p - 1];
    final targets = moves
        .where((m) => m.from == selected && m.to == p)
        .toList();
    final enabled = moves.any((m) => m.from == p) || targets.isNotEmpty;
    final label =
        '${bgText(context, 'Punkt', 'Point')} $p, ${n.abs()} ${n >= 0 ? bgText(context, 'helle Steine', 'light checkers') : bgText(context, 'dunkle Steine', 'dark checkers')}'
        '${targets.isEmpty ? '' : ', ${bgText(context, 'Ziel, Würfel', 'destination, die')} ${targets.map((m) => m.die).join(', ')}'}';
    return Positioned.fromRect(
      rect: l.point(p),
      child: Semantics(
        label: label,
        selected: selected == p,
        button: enabled,
        onTap: enabled ? () => onPoint?.call(p) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: enabled ? () => onPoint?.call(p) : null,
            child: Container(
              foregroundDecoration: selected == p || targets.isNotEmpty
                  ? BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF673A62),
                        width: 3,
                      ),
                    )
                  : null,
              decoration: BoxDecoration(
                border: selected == p || targets.isNotEmpty
                    ? Border.all(color: const Color(0xFFFFFAF3), width: 5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: p >= 13
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (selected == p) _badge('✓'),
                  if (targets.isNotEmpty)
                    _badge('→ ${targets.map((m) => m.die).join('/')}'),
                  if (n.abs() > 5) _badge('${n.abs()}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _badge(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  decoration: BoxDecoration(
    color: const Color(0xFFFFFAF3),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    text,
    style: const TextStyle(
      fontFamily: 'Roboto',
      color: Color(0xFF382D36),
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
);

class _Wood extends CustomPainter {
  _Wood(this.l);
  final BackgammonBoardLayout l;
  @override
  void paint(Canvas c, Size size) {
    final outer = Offset.zero & size;
    c.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(14)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF926744), Color(0xFF68432D), Color(0xFF38251C)],
        ).createShader(outer),
    );
    for (var i = 0; i < 12; i++) {
      c.drawPath(
        Path()
          ..moveTo(0, i * size.height / 12)
          ..quadraticBezierTo(
            size.width / 2,
            i * size.height / 12 + 12,
            size.width,
            i * size.height / 12,
          ),
        Paint()
          ..color = Colors.white.withValues(alpha: .06)
          ..style = PaintingStyle.stroke,
      );
    }
    for (var p = 1; p <= 24; p++) {
      final r = l.point(p);
      c.drawRect(
        r.inflate(0),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE8D8B8), Color(0xFFCABB9E)],
          ).createShader(r),
      );
      final top = p >= 13;
      final path = Path()
        ..moveTo(r.left + 2, top ? r.top : r.bottom)
        ..lineTo(r.right - 2, top ? r.top : r.bottom)
        ..lineTo(
          r.center.dx,
          top ? r.top + r.height * .9 : r.bottom - r.height * .9,
        )
        ..close();
      c.drawPath(
        path,
        Paint()
          ..color = p.isEven
              ? const Color(0xFF783F36)
              : const Color(0xFF486052),
      );
      final t = TextPainter(
        text: TextSpan(
          text: '$p',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFFFFFAF3),
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(
        c,
        Offset(r.center.dx - t.width / 2, top ? 14 : size.height - 28),
      );
    }
  }

  @override
  bool shouldRepaint(_Wood old) => old.l.size != l.size;
}

class _Pieces extends CustomPainter {
  _Pieces(this.l, this.state);
  final BackgammonBoardLayout l;
  final BackgammonGameState state;
  void checker(Canvas c, Offset center, double d, bool light) {
    final rect = Rect.fromCircle(center: center, radius: d / 2);
    c.drawCircle(
      center + const Offset(0, 2),
      d / 2,
      Paint()
        ..color = Colors.black.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    c.drawCircle(
      center,
      d / 2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.4),
          colors: light
              ? [const Color(0xFFFFF5DF), const Color(0xFFBDAA88)]
              : [const Color(0xFF555650), const Color(0xFF121916)],
        ).createShader(rect),
    );
    c.drawCircle(
      center,
      d / 2 - .8,
      Paint()
        ..color = light ? const Color(0xFF68432D) : const Color(0xFF121916)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    c.drawOval(
      rect.deflate(4),
      Paint()
        ..color = (light ? Colors.white : Colors.white24).withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
  }

  @override
  void paint(Canvas c, Size size) {
    final d = math.min(40.0, l.column - 8);
    for (var p = 1; p <= 24; p++) {
      final r = l.point(p), n = state.points[p - 1];
      final spacing = math.min(d + 2, (r.height - d - 8) / 4);
      for (var i = 0; i < math.min(5, n.abs()); i++) {
        checker(
          c,
          Offset(
            r.center.dx,
            p >= 13
                ? r.top + 4 + d / 2 + i * spacing
                : r.bottom - 4 - d / 2 - i * spacing,
          ),
          d,
          n > 0,
        );
      }
    }
    for (var player = 0; player < 2; player++) {
      final b = l.bar(player), o = l.off(player);
      for (var i = 0; i < math.min(3, state.bar[player]); i++) {
        checker(c, Offset(b.center.dx, b.top + 22 + i * 30), 32, player == 0);
      }
      for (var i = 0; i < state.off[player]; i++) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(o.left + 8, o.top + 6 + i * 7, 48, 10),
            const Radius.circular(4),
          ),
          Paint()
            ..color = player == 0
                ? const Color(0xFFFFF5DF)
                : const Color(0xFF363633),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Pieces old) => old.state != state || old.l.size != l.size;
}

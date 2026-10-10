import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/backgammon_models.dart';
import 'backgammon_salon.dart';

String bgText(BuildContext context, String de, String en) =>
    Localizations.localeOf(context).languageCode == 'de' ? de : en;

/// Clockwise portrait geometry; global IDs and movement rules remain unchanged.
/// Both paint and native interactive regions use these exact rectangles.
class BackgammonBoardLayout {
  const BackgammonBoardLayout(this.size);
  final Size size;
  double get column => (size.height - 104) / 12;
  double get half => (size.width - 44) / 2;
  Rect point(int p) {
    final left = p >= 13;
    final i = left ? p - 13 : 12 - p;
    return Rect.fromLTWH(
      left ? 22 : size.width / 2,
      12 + i * column + (i >= 6 ? 48 : 0),
      half,
      column,
    );
  }

  Rect bar(int player) => Rect.fromLTWH(
    player == 0 ? 22 : size.width / 2,
    12 + 6 * column,
    half,
    48,
  );
  Rect off(int player) => Rect.fromLTWH(
    player == 0 ? 22 : size.width / 2,
    size.height - 44,
    half,
    40,
  );
}

class BackgammonBoard extends StatelessWidget {
  const BackgammonBoard({
    super.key,
    required this.state,
    this.selected,
    this.onPoint,
    this.height = 500,
    this.width = 336,
  });
  final BackgammonGameState state;
  final int? selected;
  final ValueChanged<int>? onPoint;
  final double height, width;
  @override
  Widget build(BuildContext context) {
    final l = BackgammonBoardLayout(Size(width, height));
    final moves = onPoint == null ? <BackgammonMove>[] : state.legalMoves;
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              const Positioned.fill(
                child: SalonSurface(child: SizedBox.expand()),
              ),
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(painter: _BoardPaint(l, state)),
                ),
              ),
              for (var p = 1; p <= 24; p++) _point(context, l, p, moves),
              for (var player = 0; player < 2; player++) ...[
                _tray(
                  l.bar(player),
                  'bar-$player',
                  '${state.names[player]}, Bar, ${state.bar[player]}',
                  '${player == 0 ? '○' : '●'} Bar ${state.bar[player]}',
                  player == state.activePlayerIndex &&
                          moves.any((m) => m.from == 0)
                      ? () => onPoint?.call(0)
                      : null,
                ),
                _tray(
                  l.off(player),
                  'off-$player',
                  '${state.names[player]}, ${bgText(context, 'ausgespielt', 'borne off')}, ${state.off[player]}',
                  '${player == 0 ? '○' : '●'} ${state.off[player]}/15${player == state.activePlayerIndex && moves.any((m) => m.from == selected && m.to == 25) ? ' →' : ''}',
                  player == state.activePlayerIndex &&
                          moves.any((m) => m.from == selected && m.to == 25)
                      ? () => onPoint?.call(25)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tray(
    Rect rect,
    String key,
    String label,
    String text,
    VoidCallback? tap,
  ) => Positioned.fromRect(
    rect: rect,
    child: Semantics(
      label: label,
      button: tap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(key),
          onTap: tap,
          child: Center(child: _badge(text)),
        ),
      ),
    ),
  );
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
    return Positioned.fromRect(
      rect: l.point(p),
      child: Semantics(
        label:
            '${bgText(context, 'Punkt', 'Point')} $p, ${n.abs()} ${n >= 0 ? bgText(context, 'helle Steine', 'light checkers') : bgText(context, 'dunkle Steine', 'dark checkers')}${targets.isNotEmpty ? ', ${bgText(context, 'Ziel, Würfel', 'destination, die')} ${targets.map((m) => m.die).join(', ')}' : ''}',
        selected: selected == p,
        button: enabled,
        onTap: enabled ? () => onPoint?.call(p) : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('point-$p'),
            excludeFromSemantics: true,
            onTap: enabled ? () => onPoint?.call(p) : null,
            child: Container(
              decoration: BoxDecoration(
                border: selected == p || targets.isNotEmpty
                    ? Border.all(color: salonIvory, width: 2)
                    : null,
              ),
              child: Align(
                alignment: p >= 13
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

Widget _badge(String text) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  decoration: BoxDecoration(
    color: salonIvory,
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    text,
    style: const TextStyle(
      fontFamily: 'Roboto',
      color: Color(0xFF351914),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    ),
  ),
);

class _BoardPaint extends CustomPainter {
  _BoardPaint(this.l, this.state);
  final BackgammonBoardLayout l;
  final BackgammonGameState state;
  void checker(Canvas c, Offset center, double d, bool light) {
    final rect = Rect.fromCircle(center: center, radius: d / 2);
    c.drawCircle(
      center + const Offset(1, 2),
      d / 2,
      Paint()..color = Colors.black54,
    );
    c.drawCircle(
      center,
      d / 2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.5, -.5),
          colors: light
              ? [const Color(0xFFFFF8E4), const Color(0xFFD4BD91)]
              : [const Color(0xFF51473C), const Color(0xFF100E0C)],
        ).createShader(rect),
    );
    for (final inset in [1.5, 4.0]) {
      c.drawCircle(
        center,
        math.max(1, d / 2 - inset),
        Paint()
          ..color = light ? const Color(0xFFA58A5B) : const Color(0xFF887552)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
  }

  @override
  void paint(Canvas c, Size size) {
    for (var p = 1; p <= 24; p++) {
      final r = l.point(p), left = p >= 13;
      c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE3CAA0), Color(0xFFB8986B)],
          ).createShader(r),
      );
      final path = Path()
        ..moveTo(left ? r.left : r.right, r.top + 1)
        ..lineTo(left ? r.left : r.right, r.bottom - 1)
        ..lineTo(left ? r.right - 10 : r.left + 10, r.center.dy)
        ..close();
      c.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: p.isEven
                ? [const Color(0xFF78382D), const Color(0xFF431C17)]
                : [const Color(0xFF42302A), const Color(0xFF211A15)],
          ).createShader(r),
      );
      final text = TextPainter(
        text: TextSpan(
          text: '$p',
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: salonIvory,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        c,
        Offset(left ? 3 : size.width - 20, r.center.dy - text.height / 2),
      );
      final n = state.points[p - 1];
      final d = math.min(32.0, r.height - 4);
      final count = math.min(5, n.abs());
      final spacing = math.min(d + 1, (r.width - 42 - d) / 4);
      for (var i = 0; i < count; i++) {
        checker(
          c,
          Offset(
            left
                ? r.left + 4 + d / 2 + i * spacing
                : r.right - 4 - d / 2 - i * spacing,
            r.center.dy,
          ),
          d,
          n > 0,
        );
      }
    }
    final paint = Paint()
      ..color = salonBrass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    c.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        const Radius.circular(14),
      ),
      paint,
    );
    c.drawLine(
      Offset(size.width / 2, 12),
      Offset(size.width / 2, size.height - 48),
      paint,
    );
    for (var i = 0; i < 2; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(l.off(i).deflate(3), const Radius.circular(5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardPaint old) =>
      old.state != state || old.l.size != l.size;
}

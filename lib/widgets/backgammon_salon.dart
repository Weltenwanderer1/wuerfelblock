import 'package:flutter/material.dart';

const salonIvory = Color(0xFFFFF0D2);
const salonBrass = Color(0xFFD9B974);
const salonWood = Color(0xFF481D19);

ThemeData salonTheme(BuildContext context) => Theme.of(context).copyWith(
  scaffoldBackgroundColor: salonWood,
  iconTheme: const IconThemeData(color: salonIvory),
  colorScheme: const ColorScheme.dark(
    primary: salonBrass,
    onPrimary: salonWood,
    surface: Color(0xFF351914),
    onSurface: salonIvory,
    secondary: salonBrass,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF351914),
    foregroundColor: salonIvory,
    centerTitle: true,
  ),
  textTheme: Theme.of(
    context,
  ).textTheme.apply(bodyColor: salonIvory, displayColor: salonIvory),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: salonWood,
      foregroundColor: salonIvory,
      side: const BorderSide(color: salonBrass),
      disabledForegroundColor: const Color(0xFFD3BFA3),
      disabledBackgroundColor: const Color(0xFF5A3226),
      minimumSize: const Size(48, 48),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: salonIvory,
      backgroundColor: const Color(0xFF481D19),
      side: const BorderSide(color: salonBrass),
      minimumSize: const Size(48, 48),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: salonBrass,
      minimumSize: const Size(48, 48),
    ),
  ),
);

class SalonSurface extends StatelessWidget {
  const SalonSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/backgammon/mahogany.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: child,
  );
}

class SalonSymbol extends StatelessWidget {
  const SalonSymbol(this.kind, {super.key, this.size = 24});
  final String kind;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/images/backgammon/$kind.png',
      width: size,
      height: size,
    ),
  );
}

class IvoryDie extends StatelessWidget {
  const IvoryDie(this.value, {super.key});
  final int? value;
  @override
  Widget build(BuildContext context) => Semantics(
    label: value == null ? '—' : '$value',
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFBA9A61)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCED), Color(0xFFE0CCA6)],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
      child: CustomPaint(painter: _Pips(value)),
    ),
  );
}

class _Pips extends CustomPainter {
  _Pips(this.value);
  final int? value;
  @override
  void paint(Canvas canvas, Size size) {
    final n = value;
    if (n == null) {
      canvas.drawCircle(
        size.center(Offset.zero),
        3,
        Paint()..color = const Color(0xFFBA9A61),
      );
      return;
    }
    final points = <Offset>[];
    if (n.isOdd) points.add(const Offset(.5, .5));
    if (n >= 2) points.addAll([const Offset(.26, .26), const Offset(.74, .74)]);
    if (n >= 4) points.addAll([const Offset(.74, .26), const Offset(.26, .74)]);
    if (n == 6) points.addAll([const Offset(.26, .5), const Offset(.74, .5)]);
    for (final p in points) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        3.1,
        Paint()..color = const Color(0xFF321B17),
      );
    }
  }

  @override
  bool shouldRepaint(_Pips old) => old.value != value;
}

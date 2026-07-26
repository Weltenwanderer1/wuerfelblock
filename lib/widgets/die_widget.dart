import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/localized_text.dart';

class DieWidget extends StatelessWidget {
  const DieWidget({
    required this.value,
    required this.held,
    required this.onTap,
    required this.index,
    this.selectedSemantic = 'gehalten',
    this.unselectedSemantic = 'nicht gehalten',
    this.selectable = false,
    this.locked = false,
    this.face,
    this.semanticValue,
    super.key,
  });
  final int value;
  final bool held;
  final VoidCallback? onTap;
  final int index;
  final String selectedSemantic;
  final String unselectedSemantic;

  /// Zeigt einen leichten blauen Glow, wenn der Würfel auswählbar ist.
  final bool selectable;

  /// Markiert einen bereits gewerteten Würfel, der nicht mehr gewürfelt wird.
  final bool locked;

  /// Optionales spielabhängiges Würfelgesicht, z. B. eine Flamme statt sechs Augen.
  final Widget? face;

  /// Gesprochener Wert für ein benutzerdefiniertes Würfelgesicht.
  final String? semanticValue;

  static const positions = <int, List<Alignment>>{
    1: [Alignment.center],
    2: [Alignment.topLeft, Alignment.bottomRight],
    3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
    4: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    5: [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.center,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    6: [
      Alignment.topLeft,
      Alignment.centerLeft,
      Alignment.bottomLeft,
      Alignment.topRight,
      Alignment.centerRight,
      Alignment.bottomRight,
    ],
  };

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label:
        '${localizeText(context, 'Würfel')} ${semanticValue ?? value}, '
        '${localizeText(context, held ? selectedSemantic : unselectedSemantic)}',
    child: InkWell(
      key: Key('die-$index'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 62,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: held
              ? AppColors.apricot
              : locked
              ? const Color(0xFFE8E0E4)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: held
                ? AppColors.plum
                : locked
                ? const Color(0xFFB0A4AE)
                : const Color(0xFFD4C4CF),
            width: held ? 3 : 1.5,
          ),
          boxShadow: [
            if (selectable && !held && onTap != null)
              const BoxShadow(
                color: Color(0x334488FF),
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 0),
              ),
            const BoxShadow(
              color: Color(0x22000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child:
            face ??
            Stack(
              children: [
                for (final alignment in positions[value]!)
                  Align(
                    alignment: alignment,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.plum,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 9),
                    ),
                  ),
              ],
            ),
      ),
    ),
  );
}

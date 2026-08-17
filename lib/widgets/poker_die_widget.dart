import 'package:flutter/material.dart';

import '../l10n/localized_text.dart';

/// A tactile, accessible poker die displaying 9, 10, B, D, K or A.
class PokerDieWidget extends StatelessWidget {
  const PokerDieWidget({
    required this.value,
    this.held = false,
    this.onTap,
    this.size = 54,
    super.key,
  }) : assert(value >= 1 && value <= 6);

  final int value;
  final bool held;
  final VoidCallback? onTap;
  final double size;

  static const _faces = ['9', '10', 'B', 'D', 'K', 'A'];
  static const _names = ['Neun', 'Zehn', 'Bube', 'Dame', 'König', 'Ass'];
  static const _colors = [
    Color(0xFF1D4ED8),
    Color(0xFF1D4ED8),
    Color(0xFFB91C1C),
    Color(0xFFB91C1C),
    Color(0xFF171717),
    Color(0xFF171717),
  ];

  @override
  Widget build(BuildContext context) {
    final face = _faces[value - 1];
    final enabled = onTap != null;
    final faceName = localizeText(context, _names[value - 1]);
    final status = localizeText(
      context,
      held ? 'festgehalten' : 'nicht gehalten',
    );
    return Semantics(
      button: enabled,
      selected: held,
      label: '$faceName, $status',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: held ? const Color(0xFFFFE7A3) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: held ? const Color(0xFF9A5A00) : const Color(0xFF8C8174),
                width: held ? 3 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LocalizedText(
                  face,
                  style: TextStyle(
                    color: _colors[value - 1],
                    fontSize: face.length == 2 ? size * .42 : size * .52,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

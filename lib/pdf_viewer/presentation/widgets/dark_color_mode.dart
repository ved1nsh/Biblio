import 'package:flutter/material.dart';

// Small helper widget / util to invert colors using a ColorFilter matrix.
// Use `invert == true` to invert the colors of the [child].
class ColorInverter extends StatelessWidget {
  final bool invert;
  final Widget child;

  const ColorInverter({super.key, required this.invert, required this.child});

  static const List<double> _invertMatrix = <double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    if (!invert) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(_invertMatrix),
      child: child,
    );
  }
}

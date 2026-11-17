import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Brand colours shared by the whole app.
abstract final class OrreryColors {
  static const background = Color(0xFF0A0A0A);
  static const panel = Color(0xE6101010);
  static const text = Color(0xFFEDEDED);
  static const muted = Color(0xFF9A9A9A);
  static const accent = Color(0xFFE3B341);
  static const outline = Color(0x22EDEDED);
}

ThemeData buildOrreryTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: OrreryColors.background,
    colorScheme: const ColorScheme.dark(
      primary: OrreryColors.accent,
      onPrimary: OrreryColors.background,
      secondary: OrreryColors.accent,
      surface: Color(0xFF121212),
      onSurface: OrreryColors.text,
      outline: OrreryColors.outline,
    ),
  );
  return base.copyWith(
    sliderTheme: base.sliderTheme.copyWith(
      trackHeight: 2,
      inactiveTrackColor: OrreryColors.outline,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF111111),
      showDragHandle: true,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}

/// Translucent rounded panel that floats over the sky.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OrreryColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OrreryColors.outline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The logo drawn in code (same geometry as assets/logo.svg): a Sun, two
/// orbits and two planets.
class OrreryMark extends StatelessWidget {
  const OrreryMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    final c = Offset(32 * k, 32 * k);
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * k
      ..color = OrreryColors.accent;
    canvas.drawCircle(
      c,
      21 * k,
      orbit..color = OrreryColors.accent.withValues(alpha: 0.55),
    );
    canvas.drawCircle(c, 12 * k, orbit..color = OrreryColors.accent);
    canvas.drawCircle(c, 5 * k, Paint()..color = OrreryColors.accent);
    final gap = Paint()..color = OrreryColors.background;
    final inner =
        c + Offset(math.cos(-math.pi / 4), math.sin(-math.pi / 4)) * 12 * k;
    final outer =
        c +
        Offset(math.cos(3 * math.pi / 4), math.sin(3 * math.pi / 4)) * 21 * k;
    canvas.drawCircle(inner, 5.5 * k, gap);
    canvas.drawCircle(inner, 3.5 * k, Paint()..color = OrreryColors.text);
    canvas.drawCircle(outer, 6 * k, gap);
    canvas.drawCircle(outer, 4 * k, Paint()..color = OrreryColors.accent);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

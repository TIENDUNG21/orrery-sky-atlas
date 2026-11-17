import 'dart:math' as math;

/// Outline of the lit part of a unit disk for an illuminated fraction [k],
/// with the bright limb towards +x and y pointing up.
///
/// The bright limb is a half circle x = cos φ; the terminator is the half
/// ellipse x = (1 − 2k)·cos φ, so the enclosed area is exactly k·π.
List<(double, double)> moonLitPolygon(double k, {int samples = 48}) {
  final f = k.clamp(0.0, 1.0);
  final points = <(double, double)>[];
  for (var i = 0; i <= samples; i++) {
    final phi = -math.pi / 2 + math.pi * i / samples;
    points.add((math.cos(phi), math.sin(phi)));
  }
  for (var i = samples; i >= 0; i--) {
    final phi = -math.pi / 2 + math.pi * i / samples;
    points.add(((1 - 2 * f) * math.cos(phi), math.sin(phi)));
  }
  return points;
}

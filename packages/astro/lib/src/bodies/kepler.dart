/// Kepler's equation (Meeus chapter 30).
library;

import 'dart:math' as math;

/// Solves Kepler's equation E − e·sin E = M for the eccentric anomaly E.
///
/// Angles are in radians; [e] must be in [0, 1). Newton's method starts from
/// M + e·sin M, or from π for very eccentric orbits where that guess can
/// overshoot, and converges to about 1e-14 rad.
double solveKepler(double meanAnomalyRad, double e) {
  if (!(e >= 0 && e < 1)) {
    throw ArgumentError.value(e, 'e', 'eccentricity must be in [0, 1)');
  }
  const twoPi = 2 * math.pi;
  // Solve for M reduced to [0, π] and restore the turn and the sign after.
  final turns = (meanAnomalyRad / twoPi).roundToDouble();
  final reduced = meanAnomalyRad - turns * twoPi;
  final m = reduced.abs();
  var ecc = e < 0.8 ? m + e * math.sin(m) : math.pi;
  for (var i = 0; i < 100; i++) {
    final delta = (ecc - e * math.sin(ecc) - m) / (1 - e * math.cos(ecc));
    ecc -= delta;
    if (delta.abs() < 1e-14) break;
  }
  return (reduced < 0 ? -ecc : ecc) + turns * twoPi;
}

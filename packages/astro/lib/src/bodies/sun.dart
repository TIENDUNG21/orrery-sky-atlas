/// Position of the Sun, low-accuracy theory (Meeus chapter 25).
library;

import 'dart:math' as math;

import '../coords/coordinates.dart';
import '../coords/nutation.dart';
import '../math/angle.dart';
import '../time/julian.dart';

/// Geocentric position of the Sun at one instant.
class SunPosition {
  /// Creates a Sun position.
  const SunPosition({
    required this.trueLongitudeDeg,
    required this.apparentLongitudeDeg,
    required this.meanAnomalyDeg,
    required this.distanceAu,
    required this.apparent,
  });

  /// Geometric longitude ☉ referred to the mean equinox of date.
  final double trueLongitudeDeg;

  /// Apparent longitude λ, corrected for nutation and aberration.
  final double apparentLongitudeDeg;

  /// Mean anomaly M.
  final double meanAnomalyDeg;

  /// Distance from Earth in astronomical units.
  final double distanceAu;

  /// Apparent right ascension and declination of date.
  final Equatorial apparent;
}

/// The Sun's position for a Julian ephemeris day, accurate to about 0.01°.
SunPosition sunPosition(double jdTt) {
  final t = julianCenturies(jdTt);
  final l0 = 280.46646 + t * (36000.76983 + t * 0.0003032);
  final m = 357.52911 + t * (35999.05029 - t * 0.0001537);
  final e = 0.016708634 - t * (0.000042037 + t * 0.0000001267);
  final mr = m * deg2rad;
  final c =
      (1.914602 - t * (0.004817 + t * 0.000014)) * math.sin(mr) +
      (0.019993 - 0.000101 * t) * math.sin(2 * mr) +
      0.000289 * math.sin(3 * mr);
  final trueLongitude = normalizeDegrees(l0 + c);
  final trueAnomaly = (m + c) * deg2rad;
  final r = 1.000001018 * (1 - e * e) / (1 + e * math.cos(trueAnomaly));
  final omega = (125.04 - 1934.136 * t) * deg2rad;
  final lambda = normalizeDegrees(
    trueLongitude - 0.00569 - 0.00478 * math.sin(omega),
  );
  final epsilon = meanObliquityDegrees(jdTt) + 0.00256 * math.cos(omega);
  final lr = lambda * deg2rad;
  final er = epsilon * deg2rad;
  final ra = math.atan2(math.cos(er) * math.sin(lr), math.cos(lr));
  final dec = math.asin(math.sin(er) * math.sin(lr));
  return SunPosition(
    trueLongitudeDeg: trueLongitude,
    apparentLongitudeDeg: lambda,
    meanAnomalyDeg: normalizeDegrees(m),
    distanceAu: r,
    apparent: Equatorial(normalizeDegrees(ra * rad2deg), dec * rad2deg),
  );
}

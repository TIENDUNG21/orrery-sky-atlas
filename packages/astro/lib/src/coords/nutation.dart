/// Nutation and the obliquity of the ecliptic (Meeus chapter 22).
library;

import 'dart:math' as math;

import '../math/angle.dart';
import '../time/julian.dart';

/// Nutation in longitude and obliquity at one instant.
class Nutation {
  /// Creates a nutation value; all angles in degrees.
  const Nutation({
    required this.deltaPsiDeg,
    required this.deltaEpsDeg,
    required this.meanObliquityDeg,
  });

  /// Nutation in longitude Δψ.
  final double deltaPsiDeg;

  /// Nutation in obliquity Δε.
  final double deltaEpsDeg;

  /// Mean obliquity of the ecliptic ε0.
  final double meanObliquityDeg;

  /// True obliquity ε = ε0 + Δε.
  double get trueObliquityDeg => meanObliquityDeg + deltaEpsDeg;
}

/// Mean obliquity of the ecliptic in degrees (Meeus 22.2).
double meanObliquityDegrees(double jdTt) {
  final t = julianCenturies(jdTt);
  final seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813));
  return 23.0 + (26.0 + seconds / 60.0) / 60.0;
}

/// Nutation from the four largest terms of the IAU 1980 series.
///
/// Meeus states an accuracy of 0.5″ in Δψ and 0.1″ in Δε, far below what a
/// sky view can show.
Nutation nutation(double jdTt) {
  final t = julianCenturies(jdTt);
  final omega =
      (125.04452 - 1934.136261 * t + 0.0020708 * t * t + t * t * t / 450000) *
      deg2rad;
  final l = (280.4665 + 36000.7698 * t) * deg2rad;
  final lMoon = (218.3165 + 481267.8813 * t) * deg2rad;
  final dPsi =
      -17.20 * math.sin(omega) -
      1.32 * math.sin(2 * l) -
      0.23 * math.sin(2 * lMoon) +
      0.21 * math.sin(2 * omega);
  final dEps =
      9.20 * math.cos(omega) +
      0.57 * math.cos(2 * l) +
      0.10 * math.cos(2 * lMoon) -
      0.09 * math.cos(2 * omega);
  return Nutation(
    deltaPsiDeg: dPsi / 3600.0,
    deltaEpsDeg: dEps / 3600.0,
    meanObliquityDeg: meanObliquityDegrees(jdTt),
  );
}

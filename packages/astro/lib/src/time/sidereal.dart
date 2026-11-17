/// Sidereal time (Meeus chapter 12).
library;

import 'dart:math' as math;

import '../coords/nutation.dart';
import '../math/angle.dart';
import 'julian.dart';

/// Greenwich mean sidereal time in degrees for a Julian day in UT (Meeus 12.4).
double greenwichMeanSiderealDegrees(double jdUt) {
  final t = julianCenturies(jdUt);
  return normalizeDegrees(
    280.46061837 +
        360.98564736629 * (jdUt - j2000) +
        t * t * (0.000387933 - t / 38710000.0),
  );
}

/// Greenwich apparent sidereal time: mean time plus the equation of the
/// equinoxes Δψ·cos ε, which needs the instant in TT as well.
double greenwichApparentSiderealDegrees(double jdUt, double jdTt) {
  final n = nutation(jdTt);
  return normalizeDegrees(
    greenwichMeanSiderealDegrees(jdUt) +
        n.deltaPsiDeg * math.cos(n.trueObliquityDeg * deg2rad),
  );
}

/// Local sidereal time for an east-positive longitude.
double localSiderealDegrees(double greenwichDeg, double longitudeEastDeg) =>
    normalizeDegrees(greenwichDeg + longitudeEastDeg);

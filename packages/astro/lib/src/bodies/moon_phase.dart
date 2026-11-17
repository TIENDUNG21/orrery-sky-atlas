/// Illumination and phases of the Moon (Meeus chapters 48 and 49).
library;

import 'dart:math' as math;

import '../math/angle.dart';
import 'moon.dart';
import 'sun.dart';

/// Kilometres in one astronomical unit.
const double kmPerAu = 149597870.7;

/// Mean length of the synodic month in days.
const double synodicMonthDays = 29.530588853;

/// The eight conventional names of the lunar phase.
enum MoonPhaseName {
  /// Within about half a day of conjunction with the Sun.
  newMoon('New Moon'),

  /// Lit sliver in the evening sky.
  waxingCrescent('Waxing crescent'),

  /// Half lit, about a week after new Moon.
  firstQuarter('First quarter'),

  /// More than half lit and growing.
  waxingGibbous('Waxing gibbous'),

  /// Opposite the Sun.
  fullMoon('Full Moon'),

  /// More than half lit and shrinking.
  waningGibbous('Waning gibbous'),

  /// Half lit, about a week after full Moon.
  lastQuarter('Last quarter'),

  /// Lit sliver in the morning sky.
  waningCrescent('Waning crescent');

  const MoonPhaseName(this.label);

  /// Human-readable label.
  final String label;
}

/// The four principal phases, by the Moon's elongation in longitude.
enum LunarPhaseKind {
  /// Elongation 0°.
  newMoon(0),

  /// Elongation 90°.
  firstQuarter(90),

  /// Elongation 180°.
  fullMoon(180),

  /// Elongation 270°.
  lastQuarter(270);

  const LunarPhaseKind(this.elongationDeg);

  /// Excess of the Moon's apparent longitude over the Sun's.
  final double elongationDeg;
}

/// Summary of the Moon's phase at one instant.
class MoonPhase {
  /// Creates a phase summary.
  const MoonPhase({
    required this.illuminatedFraction,
    required this.phaseAngleDeg,
    required this.elongationDeg,
    required this.name,
  });

  /// Fraction of the disk that is lit, 0 to 1.
  final double illuminatedFraction;

  /// Sun–Moon–Earth angle i.
  final double phaseAngleDeg;

  /// Moon's apparent longitude minus the Sun's, [0, 360).
  final double elongationDeg;

  /// Conventional phase name.
  final MoonPhaseName name;

  /// Approximate days since new Moon, from the mean synodic month.
  double get ageDays => elongationDeg / 360.0 * synodicMonthDays;
}

/// Geocentric elongation ψ (Meeus 48.2) in radians.
double _elongation(SunPosition sun, MoonPosition moon) {
  final d0 = sun.apparent.decDeg * deg2rad;
  final d = moon.apparent.decDeg * deg2rad;
  final da = (sun.apparent.raDeg - moon.apparent.raDeg) * deg2rad;
  final c =
      math.sin(d0) * math.sin(d) + math.cos(d0) * math.cos(d) * math.cos(da);
  return math.acos(c.clamp(-1.0, 1.0));
}

/// Phase angle i in degrees (Meeus 48.3).
double moonPhaseAngleDeg(SunPosition sun, MoonPosition moon) {
  final psi = _elongation(sun, moon);
  final r = sun.distanceAu * kmPerAu;
  return math.atan2(r * math.sin(psi), moon.distanceKm - r * math.cos(psi)) *
      rad2deg;
}

/// Illuminated fraction k of the Moon's disk (Meeus 48.1).
double moonIlluminatedFraction(SunPosition sun, MoonPosition moon) =>
    (1 + math.cos(moonPhaseAngleDeg(sun, moon) * deg2rad)) / 2;

/// Position angle of the Moon's bright limb, measured from celestial north
/// through east (Meeus 48.5).
double brightLimbAngleDeg(SunPosition sun, MoonPosition moon) {
  final a0 = sun.apparent.raDeg * deg2rad;
  final d0 = sun.apparent.decDeg * deg2rad;
  final a = moon.apparent.raDeg * deg2rad;
  final d = moon.apparent.decDeg * deg2rad;
  final chi = math.atan2(
    math.cos(d0) * math.sin(a0 - a),
    math.sin(d0) * math.cos(d) - math.cos(d0) * math.sin(d) * math.cos(a0 - a),
  );
  return normalizeDegrees(chi * rad2deg);
}

/// Phase name for an elongation in degrees; each principal phase spans
/// ±6° (about half a day) around its exact elongation.
MoonPhaseName phaseNameForElongation(double elongationDeg) {
  final e = normalizeDegrees(elongationDeg);
  if (e < 6 || e >= 354) return MoonPhaseName.newMoon;
  if (e < 84) return MoonPhaseName.waxingCrescent;
  if (e < 96) return MoonPhaseName.firstQuarter;
  if (e < 174) return MoonPhaseName.waxingGibbous;
  if (e < 186) return MoonPhaseName.fullMoon;
  if (e < 264) return MoonPhaseName.waningGibbous;
  if (e < 276) return MoonPhaseName.lastQuarter;
  return MoonPhaseName.waningCrescent;
}

double _elongationInLongitude(double jdTt) => normalizeDegrees(
  moonPosition(jdTt).apparentLongitudeDeg -
      sunPosition(jdTt).apparentLongitudeDeg,
);

/// Phase of the Moon for a Julian ephemeris day.
MoonPhase moonPhase(double jdTt) {
  final sun = sunPosition(jdTt);
  final moon = moonPosition(jdTt);
  final i = moonPhaseAngleDeg(sun, moon);
  final elongation = _elongationInLongitude(jdTt);
  return MoonPhase(
    illuminatedFraction: (1 + math.cos(i * deg2rad)) / 2,
    phaseAngleDeg: i,
    elongationDeg: elongation,
    name: phaseNameForElongation(elongation),
  );
}

/// Julian ephemeris day of the first [kind] phase strictly after [jdTt].
///
/// Steps forward half a day until the elongation passes the target, then
/// bisects to about 0.1 s. The result depends on this package's Sun and Moon
/// theories, so it agrees with Meeus chapter 49 to about a minute.
double findLunarPhase(double jdTt, LunarPhaseKind kind) {
  double offset(double jd) =>
      normalizeSignedDegrees(_elongationInLongitude(jd) - kind.elongationDeg);

  const step = 0.5;
  var a = jdTt + 1e-6;
  var fa = offset(a);
  for (var i = 0; i < 80; i++) {
    final b = a + step;
    final fb = offset(b);
    if (fa < 0 && fb >= 0 && fb - fa < 90) {
      var lo = a;
      var hi = b;
      while (hi - lo > 1e-6) {
        final mid = (lo + hi) / 2;
        if (offset(mid) < 0) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return (lo + hi) / 2;
    }
    a = b;
    fa = fb;
  }
  throw StateError('No lunar phase found within 40 days of $jdTt');
}

/// Precession from J2000.0 and stellar proper motion (Meeus chapter 21).
library;

import 'dart:math' as math;

import '../math/angle.dart';
import '../math/vector.dart';
import '../time/julian.dart';
import 'coordinates.dart';

/// The three precession angles ζ, z and θ in radians for an epoch given as
/// a Julian ephemeris day, starting from J2000.0 (Meeus 21.3 with T = 0).
(double, double, double) _angles(double jdTt) {
  final t = julianCenturies(jdTt);
  const arcsec = deg2rad / 3600.0;
  final zeta = (2306.2181 + (0.30188 + 0.017998 * t) * t) * t * arcsec;
  final z = (2306.2181 + (1.09468 + 0.018203 * t) * t) * t * arcsec;
  final theta = (2004.3109 - (0.42665 + 0.041833 * t) * t) * t * arcsec;
  return (zeta, z, theta);
}

/// Rotation taking J2000.0 equatorial vectors to the mean equator and
/// equinox of [jdTt]: Rz(z) · Ry(−θ) · Rz(ζ).
Mat3 precessionMatrixFromJ2000(double jdTt) {
  final (zeta, z, theta) = _angles(jdTt);
  return Mat3.rotationZ(z) * Mat3.rotationY(-theta) * Mat3.rotationZ(zeta);
}

/// Precesses a J2000.0 position to the mean equinox of [jdTt]
/// (Meeus 21.4, rigorous method).
Equatorial precessFromJ2000(Equatorial eq, double jdTt) {
  final (zeta, z, theta) = _angles(jdTt);
  final a0 = eq.raDeg * deg2rad;
  final d0 = eq.decDeg * deg2rad;
  final a = math.cos(d0) * math.sin(a0 + zeta);
  final b =
      math.cos(theta) * math.cos(d0) * math.cos(a0 + zeta) -
      math.sin(theta) * math.sin(d0);
  final c =
      math.sin(theta) * math.cos(d0) * math.cos(a0 + zeta) +
      math.cos(theta) * math.sin(d0);
  final ra = math.atan2(a, b) + z;
  final dec = math.atan2(c, math.sqrt(a * a + b * b));
  return Equatorial(normalizeDegrees(ra * rad2deg), dec * rad2deg);
}

/// Moves a star along its proper motion for [years].
///
/// [pmRaCosDecMasPerYear] is μα·cos δ, the convention of the Bright Star
/// Catalogue and Hipparcos. The motion is applied as a small displacement on
/// the sphere, so stars near the poles stay well behaved.
Equatorial applyProperMotion(
  Equatorial eq, {
  required double pmRaCosDecMasPerYear,
  required double pmDecMasPerYear,
  required double years,
}) {
  const masToRad = deg2rad / 3600000.0;
  final a = eq.raDeg * deg2rad;
  final d = eq.decDeg * deg2rad;
  final east = Vec3(-math.sin(a), math.cos(a), 0);
  final north = Vec3(
    -math.sin(d) * math.cos(a),
    -math.sin(d) * math.sin(a),
    math.cos(d),
  );
  final moved =
      eq.toVector() +
      east * (pmRaCosDecMasPerYear * years * masToRad) +
      north * (pmDecMasPerYear * years * masToRad);
  return Equatorial.fromVector(moved.normalized());
}

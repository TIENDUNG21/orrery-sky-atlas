/// Coordinate transformations (Meeus chapters 13 and 17).
library;

import 'dart:math' as math;

import '../math/angle.dart';
import '../math/vector.dart';
import 'coordinates.dart';

/// Equatorial to ecliptic coordinates for an obliquity in degrees
/// (Meeus 13.1, 13.2).
Ecliptic equatorialToEcliptic(Equatorial eq, double obliquityDeg) {
  final a = eq.raDeg * deg2rad;
  final d = eq.decDeg * deg2rad;
  final e = obliquityDeg * deg2rad;
  final lon = math.atan2(
    math.sin(a) * math.cos(e) * math.cos(d) + math.sin(d) * math.sin(e),
    math.cos(a) * math.cos(d),
  );
  final lat = math.asin(
    (math.sin(d) * math.cos(e) - math.cos(d) * math.sin(e) * math.sin(a)).clamp(
      -1.0,
      1.0,
    ),
  );
  return Ecliptic(normalizeDegrees(lon * rad2deg), lat * rad2deg);
}

/// Ecliptic to equatorial coordinates (Meeus 13.3, 13.4).
Equatorial eclipticToEquatorial(Ecliptic ecl, double obliquityDeg) {
  final l = ecl.lonDeg * deg2rad;
  final b = ecl.latDeg * deg2rad;
  final e = obliquityDeg * deg2rad;
  final ra = math.atan2(
    math.sin(l) * math.cos(e) * math.cos(b) - math.sin(b) * math.sin(e),
    math.cos(l) * math.cos(b),
  );
  final dec = math.asin(
    (math.sin(b) * math.cos(e) + math.cos(b) * math.sin(e) * math.sin(l)).clamp(
      -1.0,
      1.0,
    ),
  );
  return Equatorial(normalizeDegrees(ra * rad2deg), dec * rad2deg);
}

/// Equatorial coordinates of date to horizontal (Meeus 13.5, 13.6), with
/// azimuth counted from north. Both arguments of the arctangent in 13.5 are
/// multiplied by cos δ so the celestial pole needs no special case.
Horizontal equatorialToHorizontal(
  Equatorial eq, {
  required double lstDeg,
  required double latitudeDeg,
}) {
  final h = (lstDeg - eq.raDeg) * deg2rad;
  final d = eq.decDeg * deg2rad;
  final phi = latitudeDeg * deg2rad;
  final azFromSouth = math.atan2(
    math.cos(d) * math.sin(h),
    math.cos(d) * math.cos(h) * math.sin(phi) - math.sin(d) * math.cos(phi),
  );
  final alt = math.asin(
    (math.sin(phi) * math.sin(d) + math.cos(phi) * math.cos(d) * math.cos(h))
        .clamp(-1.0, 1.0),
  );
  return Horizontal(
    normalizeDegrees(azFromSouth * rad2deg + 180),
    alt * rad2deg,
  );
}

/// Horizontal coordinates back to equatorial coordinates of date.
Equatorial horizontalToEquatorial(
  Horizontal hor, {
  required double lstDeg,
  required double latitudeDeg,
}) {
  final m = equatorialToHorizontalMatrix(lstDeg, latitudeDeg);
  return Equatorial.fromVector(m.transpose().transform(hor.toVector()));
}

/// Rotation from equatorial-of-date vectors to east-north-up vectors.
///
/// Rotating by the local sidereal time gives the hour-angle frame; a second
/// rotation by the latitude tilts the pole up to its altitude above north.
Mat3 equatorialToHorizontalMatrix(double lstDeg, double latitudeDeg) {
  final phi = latitudeDeg * deg2rad;
  final sp = math.sin(phi);
  final cp = math.cos(phi);
  final tilt = Mat3(0, 1, 0, -sp, 0, cp, cp, 0, sp);
  return tilt * Mat3.rotationZ(-lstDeg * deg2rad);
}

/// Angular distance between two directions in degrees, numerically stable
/// for tiny and near-180° separations (Meeus chapter 17).
double angularSeparationDeg(Equatorial a, Equatorial b) {
  final va = a.toVector();
  final vb = b.toVector();
  return math.atan2(va.cross(vb).length, va.dot(vb)) * rad2deg;
}

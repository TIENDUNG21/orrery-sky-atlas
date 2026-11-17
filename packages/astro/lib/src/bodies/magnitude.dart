/// Visual magnitudes of the planets (Meeus chapter 41, the expressions of
/// the Astronomical Almanac since 1984) and Saturn's ring geometry
/// (Meeus chapter 45).
library;

import 'dart:math' as math;

import '../math/angle.dart';
import '../math/vector.dart';
import 'planets.dart';

/// Orientation of Saturn's rings as seen from Earth and from the Sun.
class SaturnRingGeometry {
  /// Creates the ring geometry.
  const SaturnRingGeometry({
    required this.earthLatitudeDeg,
    required this.deltaUDeg,
  });

  /// B: Saturnicentric latitude of Earth referred to the ring plane.
  final double earthLatitudeDeg;

  /// ΔU: difference between the Saturnicentric longitudes of Sun and Earth
  /// measured in the ring plane.
  final double deltaUDeg;
}

// Ring plane pole for the ecliptic and equinox J2000.0 (Meeus 45, T = 0).
const double _ringInclinationDeg = 28.075216;
const double _ringNodeDeg = 169.508470;

/// Ring geometry from Saturn's heliocentric and geocentric vectors (AU,
/// ecliptic J2000.0).
SaturnRingGeometry saturnRingGeometry(Vec3 heliocentric, Vec3 geocentric) {
  final i = _ringInclinationDeg * deg2rad;
  final node = _ringNodeDeg * deg2rad;

  (double, double) ringAngles(Vec3 v) {
    final (lonDeg, latDeg) = v.toSpherical();
    final l = lonDeg * deg2rad;
    final b = latDeg * deg2rad;
    final sinLat =
        math.sin(i) * math.cos(b) * math.sin(l - node) -
        math.cos(i) * math.sin(b);
    final u = math.atan2(
      math.sin(i) * math.sin(b) +
          math.cos(i) * math.cos(b) * math.sin(l - node),
      math.cos(b) * math.cos(l - node),
    );
    return (math.asin(sinLat.clamp(-1.0, 1.0)), u);
  }

  final (earthLat, uEarth) = ringAngles(geocentric);
  final (_, uSun) = ringAngles(heliocentric);
  return SaturnRingGeometry(
    earthLatitudeDeg: earthLat * rad2deg,
    deltaUDeg: normalizeSignedDegrees((uSun - uEarth) * rad2deg).abs(),
  );
}

/// Visual magnitude of a planet from its distances (AU) and phase angle.
///
/// For Saturn the ring term needs [saturnRing]; without it the globe alone
/// is used, which is fainter by up to about 0.8 magnitude.
double planetMagnitude(
  Planet planet, {
  required double sunDistanceAu,
  required double earthDistanceAu,
  required double phaseAngleDeg,
  SaturnRingGeometry? saturnRing,
}) {
  final base = 5 * math.log(sunDistanceAu * earthDistanceAu) / math.ln10;
  final i = phaseAngleDeg;
  switch (planet) {
    case Planet.mercury:
      return -0.42 +
          base +
          0.0380 * i -
          0.000273 * i * i +
          0.000002 * i * i * i;
    case Planet.venus:
      return -4.40 +
          base +
          0.0009 * i +
          0.000239 * i * i -
          0.00000065 * i * i * i;
    case Planet.mars:
      return -1.52 + base + 0.016 * i;
    case Planet.jupiter:
      return -9.40 + base + 0.005 * i;
    case Planet.saturn:
      if (saturnRing == null) return -8.88 + base;
      final sinB = math.sin(saturnRing.earthLatitudeDeg.abs() * deg2rad);
      return -8.88 +
          base +
          0.044 * saturnRing.deltaUDeg -
          2.60 * sinB +
          1.25 * sinB * sinB;
    case Planet.uranus:
      return -7.19 + base;
    case Planet.neptune:
      return -6.87 + base;
  }
}

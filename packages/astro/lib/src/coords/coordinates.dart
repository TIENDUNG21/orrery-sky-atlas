/// Value types for the three spherical frames used by the app.
library;

import 'dart:math' as math;

import '../math/angle.dart';
import '../math/vector.dart';

/// Equatorial coordinates: right ascension and declination in degrees.
class Equatorial {
  /// Creates equatorial coordinates.
  const Equatorial(this.raDeg, this.decDeg);

  /// Equatorial coordinates of a direction vector (x toward the equinox,
  /// z toward the north celestial pole).
  factory Equatorial.fromVector(Vec3 v) {
    final (lon, lat) = v.toSpherical();
    return Equatorial(lon, lat);
  }

  /// Right ascension in degrees, [0, 360).
  final double raDeg;

  /// Declination in degrees, [-90, 90].
  final double decDeg;

  /// Unit vector of this direction.
  Vec3 toVector() => Vec3.fromSpherical(raDeg, decDeg);

  @override
  String toString() => 'Equatorial(ra: $raDeg, dec: $decDeg)';
}

/// Ecliptic longitude and latitude in degrees.
class Ecliptic {
  /// Creates ecliptic coordinates.
  const Ecliptic(this.lonDeg, this.latDeg);

  /// Ecliptic longitude in degrees, [0, 360).
  final double lonDeg;

  /// Ecliptic latitude in degrees.
  final double latDeg;

  @override
  String toString() => 'Ecliptic(lon: $lonDeg, lat: $latDeg)';
}

/// Horizontal coordinates. Azimuth is measured from north through east,
/// unlike Meeus who measures from south.
class Horizontal {
  /// Creates horizontal coordinates.
  const Horizontal(this.azDeg, this.altDeg);

  /// Horizontal coordinates of an east-north-up vector.
  factory Horizontal.fromVector(Vec3 enu) {
    final az = normalizeDegrees(math.atan2(enu.x, enu.y) * rad2deg);
    final alt =
        math.atan2(enu.z, math.sqrt(enu.x * enu.x + enu.y * enu.y)) * rad2deg;
    return Horizontal(az, alt);
  }

  /// Azimuth in degrees from north through east, [0, 360).
  final double azDeg;

  /// Altitude above the horizon in degrees.
  final double altDeg;

  /// Unit vector in the east-north-up frame.
  Vec3 toVector() {
    final az = azDeg * deg2rad;
    final alt = altDeg * deg2rad;
    final c = math.cos(alt);
    return Vec3(c * math.sin(az), c * math.cos(az), math.sin(alt));
  }

  @override
  String toString() => 'Horizontal(az: $azDeg, alt: $altDeg)';
}

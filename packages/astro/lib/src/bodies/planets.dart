/// Planet positions from JPL's approximate Keplerian elements.
///
/// Source: E. M. Standish, "Keplerian Elements for Approximate Positions of
/// the Major Planets", JPL Solar System Dynamics, table 1 (valid 1800–2050).
/// The geocentric reduction (light time, precession, nutation, aberration)
/// follows Meeus chapters 21, 22, 23 and 33.
library;

import 'dart:math' as math;

import '../coords/coordinates.dart';
import '../coords/nutation.dart';
import '../coords/precession.dart';
import '../coords/transforms.dart';
import '../math/angle.dart';
import '../math/vector.dart';
import '../time/julian.dart';
import 'kepler.dart';
import 'magnitude.dart';
import 'moon.dart';
import 'sun.dart';

/// First instant covered by the element set.
final DateTime planetElementsValidFrom = DateTime.utc(1800);

/// Last instant covered by the element set.
final DateTime planetElementsValidUntil = DateTime.utc(2050, 12, 31, 23, 59);

/// The seven planets other than Earth.
enum Planet {
  /// Mercury.
  mercury('Mercury'),

  /// Venus.
  venus('Venus'),

  /// Mars.
  mars('Mars'),

  /// Jupiter.
  jupiter('Jupiter'),

  /// Saturn.
  saturn('Saturn'),

  /// Uranus.
  uranus('Uranus'),

  /// Neptune.
  neptune('Neptune');

  const Planet(this.label);

  /// English name.
  final String label;
}

/// Apparent geocentric state of a planet.
class PlanetPosition {
  /// Creates a planet position.
  const PlanetPosition({
    required this.planet,
    required this.apparent,
    required this.apparentEcliptic,
    required this.distanceAu,
    required this.sunDistanceAu,
    required this.lightTimeDays,
    required this.phaseAngleDeg,
    required this.elongationDeg,
    required this.magnitude,
  });

  /// Which planet.
  final Planet planet;

  /// Apparent right ascension and declination of date.
  final Equatorial apparent;

  /// Apparent ecliptic coordinates of date.
  final Ecliptic apparentEcliptic;

  /// Distance from Earth in AU at the moment the light left the planet.
  final double distanceAu;

  /// Distance from the Sun in AU.
  final double sunDistanceAu;

  /// Light travel time to Earth in days.
  final double lightTimeDays;

  /// Sun–planet–Earth angle.
  final double phaseAngleDeg;

  /// Sun–Earth–planet angle.
  final double elongationDeg;

  /// Visual magnitude.
  final double magnitude;

  /// Fraction of the disk that is lit.
  double get illuminatedFraction => (1 + math.cos(phaseAngleDeg * deg2rad)) / 2;
}

/// Obliquity of the ecliptic at J2000.0 used by JPL to rotate the elements.
const double obliquityJ2000Deg = 23.43928;

/// Light time per astronomical unit in days.
const double lightDaysPerAu = 0.0057755183;

/// General precession in ecliptic longitude since J2000.0, in degrees
/// (Meeus 21.6 with the J2000 starting epoch).
double generalPrecessionDeg(double jdTt) {
  final t = julianCenturies(jdTt);
  return (5029.0966 * t + 1.11113 * t * t) / 3600.0;
}

/// Heliocentric position in AU, ecliptic and equinox J2000.0.
Vec3 heliocentricEclipticJ2000(Planet planet, double jdTt) =>
    _fromElements(_elements[planet.index], jdTt);

/// Heliocentric position of Earth in AU, ecliptic and equinox J2000.0: the
/// tabulated Earth–Moon barycentre moved by the lunar offset (mass ratio
/// 81.30), which is worth up to 25″ for Venus or Mars near opposition.
Vec3 earthHeliocentricEclipticJ2000(double jdTt) {
  final barycentre = _fromElements(_earthMoonBarycentre, jdTt);
  final moon = moonPosition(jdTt);
  final moonVec =
      Vec3.fromSpherical(
        moon.geometric.lonDeg - generalPrecessionDeg(jdTt),
        moon.geometric.latDeg,
      ) *
      (moon.distanceKm / 149597870.7);
  return barycentre - moonVec * (1 / (1 + 81.30057));
}

/// Apparent geocentric position of [planet] for a Julian ephemeris day.
PlanetPosition planetPosition(Planet planet, double jdTt) {
  final earth = earthHeliocentricEclipticJ2000(jdTt);
  var tau = 0.0;
  var helio = heliocentricEclipticJ2000(planet, jdTt);
  var geo = helio - earth;
  for (var i = 0; i < 3; i++) {
    tau = geo.length * lightDaysPerAu;
    helio = heliocentricEclipticJ2000(planet, jdTt - tau);
    geo = helio - earth;
  }

  // Ecliptic J2000 → equator J2000 → mean equator of date → ecliptic of date.
  final toEquator = Mat3.rotationX(obliquityJ2000Deg * deg2rad);
  final meanEquatorial = Equatorial.fromVector(
    precessionMatrixFromJ2000(jdTt).transform(toEquator.transform(geo)),
  );
  final n = nutation(jdTt);
  final ecliptic = equatorialToEcliptic(meanEquatorial, n.meanObliquityDeg);

  // Nutation in longitude and annual aberration (Meeus 23.2, e terms dropped).
  const kappa = 20.49552 / 3600.0;
  final sunLon = sunPosition(jdTt).trueLongitudeDeg * deg2rad;
  final lon = ecliptic.lonDeg * deg2rad;
  final lat = ecliptic.latDeg * deg2rad;
  final apparentEcliptic = Ecliptic(
    normalizeDegrees(
      ecliptic.lonDeg +
          n.deltaPsiDeg -
          kappa * math.cos(sunLon - lon) / math.cos(lat),
    ),
    ecliptic.latDeg - kappa * math.sin(lat) * math.sin(sunLon - lon),
  );

  final r = helio.length;
  final delta = geo.length;
  final earthSun = earth.length;
  final phase = _angleFromSides(r, delta, earthSun);
  return PlanetPosition(
    planet: planet,
    apparent: eclipticToEquatorial(apparentEcliptic, n.trueObliquityDeg),
    apparentEcliptic: apparentEcliptic,
    distanceAu: delta,
    sunDistanceAu: r,
    lightTimeDays: tau,
    phaseAngleDeg: phase,
    elongationDeg: _angleFromSides(earthSun, delta, r),
    magnitude: planetMagnitude(
      planet,
      sunDistanceAu: r,
      earthDistanceAu: delta,
      phaseAngleDeg: phase,
      saturnRing: planet == Planet.saturn
          ? saturnRingGeometry(helio, geo)
          : null,
    ),
  );
}

/// Saturnicentric latitude of Earth referred to the ring plane, in degrees.
double saturnRingTiltDeg(double jdTt) {
  final earth = earthHeliocentricEclipticJ2000(jdTt);
  final helio = heliocentricEclipticJ2000(Planet.saturn, jdTt);
  return saturnRingGeometry(helio, helio - earth).earthLatitudeDeg;
}

/// Angle opposite side [c] in a triangle with sides [a], [b], [c].
double _angleFromSides(double a, double b, double c) {
  final cosine = (a * a + b * b - c * c) / (2 * a * b);
  return math.acos(cosine.clamp(-1.0, 1.0)) * rad2deg;
}

Vec3 _fromElements(_Elements el, double jdTt) {
  final t = julianCenturies(jdTt);
  final a = el.a + el.aRate * t;
  final e = el.e + el.eRate * t;
  final i = (el.i + el.iRate * t) * deg2rad;
  final l = el.l + el.lRate * t;
  final peri = el.peri + el.periRate * t;
  final node = (el.node + el.nodeRate * t) * deg2rad;
  final w = peri * deg2rad - node;
  final m = normalizeSignedDegrees(l - peri) * deg2rad;
  final ecc = solveKepler(m, e);
  final xp = a * (math.cos(ecc) - e);
  final yp = a * math.sqrt(1 - e * e) * math.sin(ecc);
  final cw = math.cos(w), sw = math.sin(w);
  final cn = math.cos(node), sn = math.sin(node);
  final ci = math.cos(i), si = math.sin(i);
  return Vec3(
    (cw * cn - sw * sn * ci) * xp + (-sw * cn - cw * sn * ci) * yp,
    (cw * sn + sw * cn * ci) * xp + (-sw * sn + cw * cn * ci) * yp,
    (sw * si) * xp + (cw * si) * yp,
  );
}

class _Elements {
  const _Elements(
    this.a,
    this.e,
    this.i,
    this.l,
    this.peri,
    this.node,
    this.aRate,
    this.eRate,
    this.iRate,
    this.lRate,
    this.periRate,
    this.nodeRate,
  );

  final double a, e, i, l, peri, node;
  final double aRate, eRate, iRate, lRate, periRate, nodeRate;
}

// dart format off
// JPL table 1: a (AU), e, I, L, long. perihelion, long. node (degrees) at
// J2000.0, then their rates per Julian century.
const _elements = [
  _Elements(0.38709927, 0.20563593, 7.00497902, 252.25032350, 77.45779628, 48.33076593,
      0.00000037, 0.00001906, -0.00594749, 149472.67411175, 0.16047689, -0.12534081),
  _Elements(0.72333566, 0.00677672, 3.39467605, 181.97909950, 131.60246718, 76.67984255,
      0.00000390, -0.00004107, -0.00078890, 58517.81538729, 0.00268329, -0.27769418),
  _Elements(1.52371034, 0.09339410, 1.84969142, -4.55343205, -23.94362959, 49.55953891,
      0.00001847, 0.00007882, -0.00813131, 19140.30268499, 0.44441088, -0.29257343),
  _Elements(5.20288700, 0.04838624, 1.30439695, 34.39644051, 14.72847983, 100.47390909,
      -0.00011607, -0.00013253, -0.00183714, 3034.74612775, 0.21252668, 0.20469106),
  _Elements(9.53667594, 0.05386179, 2.48599187, 49.95424423, 92.59887831, 113.66242448,
      -0.00125060, -0.00050991, 0.00193609, 1222.49362201, -0.41897216, -0.28867794),
  _Elements(19.18916464, 0.04725744, 0.77263783, 313.23810451, 170.95427630, 74.01692503,
      -0.00196176, -0.00004397, -0.00242939, 428.48202785, 0.40805281, 0.04240589),
  _Elements(30.06992276, 0.00859048, 1.77004347, -55.12002969, 44.96476227, 131.78422574,
      0.00026291, 0.00005105, 0.00035372, 218.45945325, -0.32241464, -0.00508664),
];

const _earthMoonBarycentre = _Elements(
    1.00000261, 0.01671123, -0.00001531, 100.46457166, 102.93768193, 0.0,
    0.00000562, -0.00004392, -0.01294668, 35999.37244981, 0.32327364, 0.0);
// dart format on

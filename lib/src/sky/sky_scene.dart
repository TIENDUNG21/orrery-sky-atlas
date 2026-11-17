import 'dart:math' as math;
import 'dart:typed_data';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';

/// Kinds of solar-system bodies in the scene.
enum BodyKind { sun, moon, planet }

/// Identifier used throughout the app for a star.
String starId(int hr) => 'hr:$hr';

/// HR number from a star identifier, or null for other objects.
int? hrFromId(String id) =>
    id.startsWith('hr:') ? int.tryParse(id.substring(3)) : null;

/// Identifier of a planet.
String planetId(Planet planet) => 'planet:${planet.name}';

/// A solar-system body as seen by the observer.
class BodyState {
  const BodyState({
    required this.id,
    required this.name,
    required this.kind,
    required this.apparent,
    required this.horizontal,
    required this.enu,
    required this.magnitude,
    required this.angularDiameterDeg,
    this.planet,
  });

  final String id;
  final String name;
  final BodyKind kind;
  final Planet? planet;

  /// Geocentric apparent right ascension and declination of date.
  final Equatorial apparent;

  /// Observed position: refracted, and topocentric for the Moon.
  final Horizontal horizontal;

  /// [horizontal] as an east-north-up unit vector.
  final Vec3 enu;
  final double magnitude;
  final double angularDiameterDeg;
}

/// Star directions prepared once per catalogue: J2000 unit vectors and their
/// drift per year from proper motion, packed for fast per-frame updates.
class StarField {
  StarField(this.catalog)
    : _base = Float64List(catalog.stars.length * 3),
      _drift = Float64List(catalog.stars.length * 3) {
    const masToRad = math.pi / 180 / 3600000;
    for (var i = 0; i < catalog.stars.length; i++) {
      final s = catalog.stars[i];
      final eq = s.j2000;
      final a = eq.raDeg * deg2rad;
      final d = eq.decDeg * deg2rad;
      final v = eq.toVector();
      final east = Vec3(-math.sin(a), math.cos(a), 0);
      final north = Vec3(
        -math.sin(d) * math.cos(a),
        -math.sin(d) * math.sin(a),
        math.cos(d),
      );
      final drift =
          east * (s.pmRaMas * masToRad) + north * (s.pmDecMas * masToRad);
      _base.setAll(i * 3, [v.x, v.y, v.z]);
      _drift.setAll(i * 3, [drift.x, drift.y, drift.z]);
    }
  }

  final SkyCatalog catalog;
  final Float64List _base;
  final Float64List _drift;

  int get length => catalog.stars.length;
}

/// Everything the painter needs for one instant and place.
class SkyScene {
  SkyScene._({
    required this.time,
    required this.observer,
    required this.lstDeg,
    required this.j2000ToEnu,
    required this.ofDateToEnu,
    required this.starEnu,
    required this.bodies,
    required this.sun,
    required this.moon,
    required this.moonPhase,
    required this.moonBrightLimbDeg,
  });

  final AstroTime time;
  final Observer observer;

  /// Local apparent sidereal time.
  final double lstDeg;

  /// Rotation from J2000 vectors to east-north-up (before refraction).
  final Mat3 j2000ToEnu;

  /// Rotation from equator-of-date vectors to east-north-up.
  final Mat3 ofDateToEnu;

  /// Refracted east-north-up vectors, three values per catalogue star.
  final Float64List starEnu;
  final List<BodyState> bodies;
  final SunPosition sun;
  final MoonPosition moon;
  final MoonPhase moonPhase;

  /// Position angle of the Moon's bright limb from celestial north.
  final double moonBrightLimbDeg;

  /// Observed direction of the star at [index] in catalogue order.
  Vec3 starVector(int index) =>
      Vec3(starEnu[index * 3], starEnu[index * 3 + 1], starEnu[index * 3 + 2]);

  /// Body with identifier [id]; throws if absent.
  BodyState body(String id) => bodies.firstWhere((b) => b.id == id);

  /// Refracted direction of a J2000 vector (used for labels and figures).
  Vec3 enuOfJ2000(Vec3 v) => refractEnu(j2000ToEnu.transform(v));

  /// Refracted direction of an equator-of-date position.
  Vec3 enuOfDate(Equatorial eq) =>
      refractEnu(ofDateToEnu.transform(eq.toVector()));
}

/// Lifts a geometric east-north-up direction by atmospheric refraction.
Vec3 refractEnu(Vec3 v) {
  final horizontal = math.sqrt(v.x * v.x + v.y * v.y);
  final alt = math.atan2(v.z, horizontal) * rad2deg;
  final lifted = apparentAltitudeDeg(alt);
  if (lifted == alt || horizontal < 1e-12) return v;
  final k = math.cos(lifted * deg2rad) / horizontal;
  return Vec3(v.x * k, v.y * k, math.sin(lifted * deg2rad));
}

/// Computes the scene. Stars get proper motion and precession; nutation and
/// aberration (together under 40″) are left out for them. The Sun, Moon and
/// planets use their full apparent positions.
SkyScene computeScene(StarField field, AstroTime time, Observer observer) {
  final lst = localSiderealDegrees(
    greenwichApparentSiderealDegrees(time.jdUt, time.jdTt),
    observer.longitudeDeg,
  );
  final ofDateToEnu = equatorialToHorizontalMatrix(lst, observer.latitudeDeg);
  final j2000ToEnu = ofDateToEnu * precessionMatrixFromJ2000(time.jdTt);
  final years = (time.jdTt - j2000) / 365.25;

  final out = Float64List(field.length * 3);
  final base = field._base;
  final drift = field._drift;
  for (var i = 0; i < out.length; i += 3) {
    var x = base[i] + drift[i] * years;
    var y = base[i + 1] + drift[i + 1] * years;
    var z = base[i + 2] + drift[i + 2] * years;
    final n = 1 / math.sqrt(x * x + y * y + z * z);
    x *= n;
    y *= n;
    z *= n;
    final v = refractEnu(j2000ToEnu.transform(Vec3(x, y, z)));
    out[i] = v.x;
    out[i + 1] = v.y;
    out[i + 2] = v.z;
  }

  final sun = sunPosition(time.jdTt);
  final moon = moonPosition(time.jdTt);
  final phase = moonPhase(time.jdTt);

  BodyState body({
    required String id,
    required String name,
    required BodyKind kind,
    required Equatorial apparent,
    required double magnitude,
    required double diameterDeg,
    Planet? planet,
    double parallaxDeg = 0,
  }) {
    final geometric = Horizontal.fromVector(
      ofDateToEnu.transform(apparent.toVector()),
    );
    final topocentric = Horizontal(
      geometric.azDeg,
      topocentricAltitudeDeg(geometric.altDeg, parallaxDeg),
    );
    final enu = refractEnu(topocentric.toVector());
    return BodyState(
      id: id,
      name: name,
      kind: kind,
      planet: planet,
      apparent: apparent,
      horizontal: Horizontal.fromVector(enu),
      enu: enu,
      magnitude: magnitude,
      angularDiameterDeg: diameterDeg,
    );
  }

  final bodies = <BodyState>[
    body(
      id: 'sun',
      name: 'Sun',
      kind: BodyKind.sun,
      apparent: sun.apparent,
      magnitude: -26.74,
      diameterDeg: 0.5332 / sun.distanceAu,
    ),
    body(
      id: 'moon',
      name: 'Moon',
      kind: BodyKind.moon,
      apparent: moon.apparent,
      // Allen's approximation of the Moon's brightness by phase angle.
      magnitude:
          -12.73 +
          0.026 * phase.phaseAngleDeg +
          4e-9 * math.pow(phase.phaseAngleDeg, 4),
      diameterDeg: 2 * math.asin(1737.4 / moon.distanceKm) * rad2deg,
      parallaxDeg: moon.parallaxDeg,
    ),
    for (final planet in Planet.values)
      () {
        final p = planetPosition(planet, time.jdTt);
        return body(
          id: planetId(planet),
          name: planet.label,
          kind: BodyKind.planet,
          planet: planet,
          apparent: p.apparent,
          magnitude: p.magnitude,
          diameterDeg: 0,
        );
      }(),
  ];

  return SkyScene._(
    time: time,
    observer: observer,
    lstDeg: lst,
    j2000ToEnu: j2000ToEnu,
    ofDateToEnu: ofDateToEnu,
    starEnu: out,
    bodies: bodies,
    sun: sun,
    moon: moon,
    moonPhase: phase,
    moonBrightLimbDeg: brightLimbAngleDeg(sun, moon),
  );
}

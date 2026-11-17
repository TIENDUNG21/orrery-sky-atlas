// Prints a Markdown table comparing this package with the worked examples
// in Meeus, "Astronomical Algorithms" (2nd ed.). The same inputs are pinned
// as tests with tolerances; this script reports the actual differences.
//
// Usage (from packages/astro): dart run tool/accuracy_report.dart

import 'dart:math' as math;

import 'package:astro/astro.dart';

final _rows = <List<String>>[];

void _row(
  String example,
  String quantity,
  String meeus,
  String ours,
  String diff,
) => _rows.add([example, quantity, meeus, ours, diff]);

String _f(double v, int digits) => v.toStringAsFixed(digits);

String _arcsec(double degrees) => '${_f(degrees * 3600, 2)}″';

void main() {
  // 12.a / 12.b: sidereal time, compared in seconds of time.
  final gmst = greenwichMeanSiderealDegrees(2446895.5);
  _row(
    '12.a',
    'mean sidereal time',
    '13h10m46.3668s',
    formatHms(gmst, fractionDigits: 4),
    '${_f((gmst - hmsToDegrees(13, 10, 46.3668)) * 240, 4)} s',
  );
  final gast = greenwichApparentSiderealDegrees(
    2446895.5,
    AstroTime.fromJulianDayTt(2446895.5).jdTt,
  );
  _row(
    '12.a',
    'apparent sidereal time',
    '13h10m46.1351s',
    formatHms(gast, fractionDigits: 4),
    '${_f((gast - hmsToDegrees(13, 10, 46.1351)) * 240, 4)} s',
  );

  // 13.b: Venus seen from Washington, using Meeus's hour angle.
  final venusEq = Equatorial(
    hmsToDegrees(23, 9, 16.641),
    dmsToDegrees(6, 43, 11.61, negative: true),
  );
  final h = equatorialToHorizontal(
    venusEq,
    lstDeg: normalizeDegrees(venusEq.raDeg + 64.352133),
    latitudeDeg: dmsToDegrees(38, 55, 17),
  );
  _row(
    '13.b',
    'azimuth (from south)',
    '68.0337°',
    '${_f(h.azDeg - 180, 4)}°',
    _arcsec(h.azDeg - 180 - 68.0337),
  );
  _row(
    '13.b',
    'altitude',
    '15.1249°',
    '${_f(h.altDeg, 4)}°',
    _arcsec(h.altDeg - 15.1249),
  );

  // 21.b: theta Persei precessed to 2028 Nov 13.19 TD.
  const jde21 = 2462088.69;
  final theta = Equatorial(
    hmsToDegrees(2, 44, 11.986),
    dmsToDegrees(49, 13, 42.48),
  );
  final moved = applyProperMotion(
    theta,
    pmRaCosDecMasPerYear: 0.03425 * 15000 * math.cos(theta.decDeg * deg2rad),
    pmDecMasPerYear: -89.5,
    years: (jde21 - j2000) / 365.25,
  );
  final p = precessFromJ2000(moved, jde21);
  _row(
    '21.b',
    'right ascension',
    '41.547214°',
    '${_f(p.raDeg, 6)}°',
    _arcsec(p.raDeg - 41.547214),
  );
  _row(
    '21.b',
    'declination',
    '49.348483°',
    '${_f(p.decDeg, 6)}°',
    _arcsec(p.decDeg - 49.348483),
  );

  // 22.a: nutation (four-term series).
  final n = nutation(2446895.5);
  _row(
    '22.a',
    'nutation in longitude',
    '−3.788″',
    _arcsec(n.deltaPsiDeg),
    _arcsec(n.deltaPsiDeg + 3.788 / 3600),
  );
  _row(
    '22.a',
    'nutation in obliquity',
    '+9.443″',
    _arcsec(n.deltaEpsDeg),
    _arcsec(n.deltaEpsDeg - 9.443 / 3600),
  );

  // 25.a: the Sun.
  final sun = sunPosition(2448908.5);
  _row(
    '25.a',
    'Sun right ascension',
    '198.38083°',
    '${_f(sun.apparent.raDeg, 5)}°',
    _arcsec(sun.apparent.raDeg - 198.38083),
  );
  _row(
    '25.a',
    'Sun declination',
    '−7.78507°',
    '${_f(sun.apparent.decDeg, 5)}°',
    _arcsec(sun.apparent.decDeg + 7.78507),
  );

  // 47.a: the Moon.
  final moon = moonPosition(2448724.5);
  _row(
    '47.a',
    'Moon longitude',
    '133.162655°',
    '${_f(moon.geometric.lonDeg, 6)}°',
    _arcsec(moon.geometric.lonDeg - 133.162655),
  );
  _row(
    '47.a',
    'Moon latitude',
    '−3.229126°',
    '${_f(moon.geometric.latDeg, 6)}°',
    _arcsec(moon.geometric.latDeg + 3.229126),
  );
  _row(
    '47.a',
    'Moon distance',
    '368409.7 km',
    '${_f(moon.distanceKm, 1)} km',
    '${_f(moon.distanceKm - 368409.7, 2)} km',
  );
  _row(
    '47.a',
    'Moon right ascension',
    '134.688470°',
    '${_f(moon.apparent.raDeg, 6)}°',
    _arcsec(moon.apparent.raDeg - 134.688470),
  );
  _row(
    '47.a',
    'Moon declination',
    '13.768368°',
    '${_f(moon.apparent.decDeg, 6)}°',
    _arcsec(moon.apparent.decDeg - 13.768368),
  );

  // 48.a: illuminated fraction.
  final k = moonIlluminatedFraction(sunPosition(2448724.5), moon);
  _row('48.a', 'illuminated fraction', '0.6786', _f(k, 4), _f(k - 0.6786, 4));

  // 49.a: new Moon of 1977 February.
  final newMoon = findLunarPhase(2443184.5, LunarPhaseKind.newMoon);
  _row(
    '49.a',
    'new Moon (JDE)',
    '2443192.65118',
    _f(newMoon, 5),
    '${_f((newMoon - 2443192.65118) * 86400, 0)} s',
  );

  // 33.a: Venus from JPL approximate elements, against Meeus's VSOP87 result.
  final venus = planetPosition(Planet.venus, 2448976.5);
  _row(
    '33.a',
    'Venus right ascension',
    '316.17273°',
    '${_f(venus.apparent.raDeg, 5)}°',
    _arcsec(venus.apparent.raDeg - hmsToDegrees(21, 4, 41.454)),
  );
  _row(
    '33.a',
    'Venus declination',
    '−18.88801°',
    '${_f(venus.apparent.decDeg, 5)}°',
    _arcsec(
      venus.apparent.decDeg - dmsToDegrees(18, 53, 16.84, negative: true),
    ),
  );
  _row(
    '33.a',
    'Venus distance',
    '0.910947 AU',
    '${_f(venus.distanceAu, 6)} AU',
    '${_f(venus.distanceAu - 0.910947, 6)} AU',
  );

  // 15.a: Venus at Boston, 1988 March 20.
  final r = riseTransitSet(
    gast0Deg: 177.74208,
    positions: const [
      Equatorial(40.68021, 18.04761),
      Equatorial(41.73129, 18.44092),
      Equatorial(42.78204, 18.82742),
    ],
    h0Deg: h0Stars,
    latitudeDeg: 42.3333,
    longitudeEastDeg: -71.0833,
    deltaTSeconds: 56,
    dayStart: DateTime.utc(1988, 3, 20),
  );
  String minutes(double m) => '${_f(m * 1440, 2)} min';
  _row(
    '15.a',
    'rising',
    '0.51766 d',
    _f(r.rise!, 5),
    minutes(r.rise! - 0.51766),
  );
  _row(
    '15.a',
    'transit',
    '0.81980 d',
    _f(r.transit!, 5),
    minutes(r.transit! - 0.81980),
  );
  _row(
    '15.a',
    'setting',
    '0.12130 d',
    _f(r.set!, 5),
    minutes(r.set! - 0.12130),
  );

  // 30.a: Kepler's equation.
  final e = solveKepler(5 * deg2rad, 0.1) * rad2deg;
  _row(
    '30.a',
    'eccentric anomaly',
    '5.554589°',
    '${_f(e, 6)}°',
    _arcsec(e - 5.554589),
  );

  print('| Meeus | Quantity | Meeus value | Orrery | Difference |');
  print('|---|---|---|---|---|');
  for (final row in _rows) {
    print('| ${row.join(' | ')} |');
  }
}

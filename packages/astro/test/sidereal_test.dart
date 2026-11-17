import 'package:astro/astro.dart';
import 'package:test/test.dart';

const _arcsec = 1 / 3600;

void main() {
  group('nutation and obliquity (Meeus example 22.a, 1987 Apr 10 0h TD)', () {
    const jde = 2446895.5;

    test('mean obliquity is 23°26′27.407″', () {
      expect(
        meanObliquityDegrees(jde),
        closeTo(dmsToDegrees(23, 26, 27.407), 0.01 * _arcsec),
      );
    });

    test('low-precision series is within its stated 0.5″ and 0.1″', () {
      final n = nutation(jde);
      expect(n.deltaPsiDeg, closeTo(-3.788 * _arcsec, 0.5 * _arcsec));
      expect(n.deltaEpsDeg, closeTo(9.443 * _arcsec, 0.1 * _arcsec));
      expect(
        n.trueObliquityDeg,
        closeTo(dmsToDegrees(23, 26, 36.850), 0.1 * _arcsec),
      );
    });
  });

  group('sidereal time (Meeus chapter 12)', () {
    const secondOfTime = 15 / 3600;

    test('example 12.a: mean sidereal time 13h10m46.3668s', () {
      expect(
        greenwichMeanSiderealDegrees(2446895.5),
        closeTo(hmsToDegrees(13, 10, 46.3668), 0.001 * secondOfTime),
      );
    });

    test('example 12.a: apparent sidereal time 13h10m46.1351s', () {
      final t = AstroTime.fromJulianDayTt(2446895.5);
      expect(
        greenwichApparentSiderealDegrees(2446895.5, t.jdTt),
        closeTo(hmsToDegrees(13, 10, 46.1351), 0.05 * secondOfTime),
      );
    });

    test('example 12.b: 1987 Apr 10 19h21m00s UT is 8h34m57.0896s', () {
      final jd = julianDay(1987, 4, 10 + (19 + 21 / 60) / 24);
      expect(
        greenwichMeanSiderealDegrees(jd),
        closeTo(hmsToDegrees(8, 34, 57.0896), 0.001 * secondOfTime),
      );
    });

    test('local sidereal time adds east longitude and wraps', () {
      expect(localSiderealDegrees(350, 20), closeTo(10, 1e-12));
      expect(localSiderealDegrees(10, -77.0656), closeTo(292.9344, 1e-9));
    });
  });
}

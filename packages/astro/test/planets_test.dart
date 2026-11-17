import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('solveKepler (Meeus chapter 30)', () {
    test('example 30.a: e = 0.1, M = 5° gives E = 5.554589°', () {
      expect(solveKepler(5 * deg2rad, 0.1) * rad2deg, closeTo(5.554589, 1e-6));
    });

    test('e = 0.99, M = 2° gives E = 32.361007°', () {
      expect(
        solveKepler(2 * deg2rad, 0.99) * rad2deg,
        closeTo(32.361007, 1e-6),
      );
    });

    test('satisfies the equation for random inputs', () {
      final random = math.Random(3);
      for (var i = 0; i < 500; i++) {
        final m = (random.nextDouble() * 4 - 2) * math.pi;
        final e = random.nextDouble() * 0.98;
        final ecc = solveKepler(m, e);
        expect(ecc - e * math.sin(ecc), closeTo(m, 1e-10));
      }
    });

    test('rejects non-elliptic eccentricities', () {
      expect(() => solveKepler(1, 1), throwsArgumentError);
      expect(() => solveKepler(1, -0.1), throwsArgumentError);
    });
  });

  group('Venus, Meeus example 33.a, 1992 Dec 20.0 TD', () {
    final venus = planetPosition(Planet.venus, 2448976.5);

    test('apparent position 21h04m41.454s, −18°53′16.84″ within 0.01°', () {
      // Meeus uses the full VSOP87 theory; this package uses JPL's
      // approximate elements, whose stated error for Venus is well below 0.01°.
      expect(venus.apparent.raDeg, closeTo(hmsToDegrees(21, 4, 41.454), 0.01));
      expect(
        venus.apparent.decDeg,
        closeTo(dmsToDegrees(18, 53, 16.84, negative: true), 0.01),
      );
    });

    test('distance 0.910947 AU and light time 0.0052612 d', () {
      expect(venus.distanceAu, closeTo(0.910947, 0.001));
      expect(venus.lightTimeDays, closeTo(0.0052612, 0.00001));
    });

    test('illuminated fraction matches the phase angle', () {
      expect(venus.phaseAngleDeg, closeTo(72.96, 0.2));
      expect(
        venus.illuminatedFraction,
        closeTo((1 + math.cos(venus.phaseAngleDeg * deg2rad)) / 2, 1e-12),
      );
    });
  });

  test('Earth from the elements agrees with the solar theory to 0.01°', () {
    for (var jd = 2415020.5; jd < 2469807.5; jd += 1234.5) {
      final earth = earthHeliocentricEclipticJ2000(jd);
      final (lonJ2000, _) = (earth * -1).toSpherical();
      final ofDate = lonJ2000 + generalPrecessionDeg(jd);
      expect(
        normalizeSignedDegrees(ofDate - sunPosition(jd).trueLongitudeDeg),
        closeTo(0, 0.01),
        reason: 'JD $jd',
      );
    }
  });

  test('Mars came closest on 2003 Aug 27 at 0.3727 AU', () {
    var bestJd = 0.0;
    var best = double.infinity;
    final start = AstroTime.fromDateTime(DateTime.utc(2003, 8, 15)).jdTt;
    for (var h = 0; h < 24 * 25; h++) {
      final jd = start + h / 24;
      final d = planetPosition(Planet.mars, jd).distanceAu;
      if (d < best) {
        best = d;
        bestJd = jd;
      }
    }
    final when = AstroTime.fromJulianDayTt(bestJd).toDateTime();
    expect(
      when.difference(DateTime.utc(2003, 8, 27, 9, 51)).inHours.abs(),
      lessThanOrEqualTo(24),
    );
    expect(best, closeTo(0.3727, 0.001));
    expect(planetPosition(Planet.mars, bestJd).magnitude, closeTo(-2.9, 0.15));
  });

  test('Saturn rings: edge-on in March 2025, wide open in October 2017', () {
    final edgeOn = AstroTime.fromDateTime(DateTime.utc(2025, 3, 23)).jdTt;
    final open = AstroTime.fromDateTime(DateTime.utc(2017, 10, 16)).jdTt;
    expect(saturnRingTiltDeg(edgeOn).abs(), lessThan(1));
    expect(saturnRingTiltDeg(open).abs(), inInclusiveRange(25, 27.5));
  });

  test('every planet has a plausible distance and magnitude in 2026', () {
    final jd = AstroTime.fromDateTime(DateTime.utc(2026, 11, 17)).jdTt;
    const ranges = {
      Planet.mercury: (0.5, 1.5, -2.5, 6.0),
      Planet.venus: (0.25, 1.75, -4.9, -3.7),
      Planet.mars: (0.35, 2.7, -3.0, 2.0),
      Planet.jupiter: (3.9, 6.5, -3.0, -1.6),
      Planet.saturn: (7.9, 11.1, -0.6, 1.6),
      Planet.uranus: (17.2, 21.1, 5.3, 6.1),
      Planet.neptune: (28.7, 31.4, 7.7, 8.1),
    };
    for (final entry in ranges.entries) {
      final p = planetPosition(entry.key, jd);
      final (dMin, dMax, mMin, mMax) = entry.value;
      expect(
        p.distanceAu,
        inInclusiveRange(dMin, dMax),
        reason: '${entry.key}',
      );
      expect(p.magnitude, inInclusiveRange(mMin, mMax), reason: '${entry.key}');
    }
  });

  test('elements are documented as valid from 1800 to 2050', () {
    expect(planetElementsValidFrom.year, 1800);
    expect(planetElementsValidUntil.year, 2050);
  });
}

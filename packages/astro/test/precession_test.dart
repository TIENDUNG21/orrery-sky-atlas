import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus example 21.b, theta Persei to 2028 Nov 13.19 TD', () {
    const jde = 2462088.69;
    final j2000Position = Equatorial(
      hmsToDegrees(2, 44, 11.986),
      dmsToDegrees(49, 13, 42.48),
    );
    final years = (jde - j2000) / 365.25;
    // Meeus gives +0.03425 s of time per year in right ascension; this
    // package takes the catalog convention μα·cos δ in milliarcseconds.
    final pmRaCosDec =
        0.03425 * 15 * 1000 * math.cos(j2000Position.decDeg * deg2rad);

    test(
      'proper motion over 28.867 years: +0.9887 s and −2.584″ (to 0.001″)',
      () {
        final moved = applyProperMotion(
          j2000Position,
          pmRaCosDecMasPerYear: pmRaCosDec,
          pmDecMasPerYear: -89.5,
          years: years,
        );
        expect(
          (moved.raDeg - j2000Position.raDeg) * 240,
          closeTo(0.03425 * years, 1e-4),
        );
        expect(
          (moved.decDeg - j2000Position.decDeg) * 3600,
          closeTo(-0.0895 * years, 1e-3),
        );
      },
    );

    test('precession gives 2h46m11.331s, +49°20′54.54″', () {
      final moved = applyProperMotion(
        j2000Position,
        pmRaCosDecMasPerYear: pmRaCosDec,
        pmDecMasPerYear: -89.5,
        years: years,
      );
      final result = precessFromJ2000(moved, jde);
      expect(result.raDeg, closeTo(hmsToDegrees(2, 46, 11.331), 1e-5));
      expect(result.decDeg, closeTo(dmsToDegrees(49, 20, 54.54), 1e-5));
    });

    test('matrix form matches the trigonometric form', () {
      final viaMatrix = Equatorial.fromVector(
        precessionMatrixFromJ2000(jde).transform(j2000Position.toVector()),
      );
      final direct = precessFromJ2000(j2000Position, jde);
      expect(viaMatrix.raDeg, closeTo(direct.raDeg, 1e-9));
      expect(viaMatrix.decDeg, closeTo(direct.decDeg, 1e-9));
    });
  });

  test('precession at J2000.0 is the identity', () {
    const star = Equatorial(101.287155, -16.716116);
    final same = precessFromJ2000(star, j2000);
    expect(same.raDeg, closeTo(star.raDeg, 1e-12));
    expect(same.decDeg, closeTo(star.decDeg, 1e-12));
  });

  test('precession matrix is a rotation (orthonormal)', () {
    final m = precessionMatrixFromJ2000(2488069.5);
    final p = m * m.transpose();
    expect(p.m00, closeTo(1, 1e-14));
    expect(p.m11, closeTo(1, 1e-14));
    expect(p.m22, closeTo(1, 1e-14));
    expect(p.m01, closeTo(0, 1e-14));
    expect(p.m12, closeTo(0, 1e-14));
  });

  test('proper motion near the pole stays finite', () {
    final moved = applyProperMotion(
      const Equatorial(10, 89.9999),
      pmRaCosDecMasPerYear: 50,
      pmDecMasPerYear: 50,
      years: 100,
    );
    expect(moved.raDeg.isFinite, isTrue);
    expect(moved.decDeg, lessThanOrEqualTo(90));
  });
}

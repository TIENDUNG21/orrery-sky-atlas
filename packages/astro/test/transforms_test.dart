import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('equatorial and ecliptic (Meeus example 13.a, Pollux)', () {
    const pollux = Equatorial(116.328942, 28.026183);

    test(
      'converts to ecliptic longitude 113.215630° and latitude 6.684170°',
      () {
        final ecl = equatorialToEcliptic(pollux, 23.4392911);
        expect(ecl.lonDeg, closeTo(113.215630, 1e-6));
        expect(ecl.latDeg, closeTo(6.684170, 1e-6));
      },
    );

    test('round-trips back to equatorial', () {
      final back = eclipticToEquatorial(
        equatorialToEcliptic(pollux, 23.4392911),
        23.4392911,
      );
      expect(back.raDeg, closeTo(pollux.raDeg, 1e-9));
      expect(back.decDeg, closeTo(pollux.decDeg, 1e-9));
    });
  });

  group(
    'equatorial and horizontal (Meeus example 13.b, Venus at Washington)',
    () {
      final venus = Equatorial(
        hmsToDegrees(23, 9, 16.641),
        dmsToDegrees(6, 43, 11.61, negative: true),
      );
      final latitude = dmsToDegrees(38, 55, 17);
      // Meeus derives the local hour angle H = 64.352133° from an unrounded
      // sidereal time (the printed 8h34m56.853s, minus the west longitude
      // 77°03′56″, gives H 0.00014° smaller). Using his H, LST = α + H.
      final lst = normalizeDegrees(venus.raDeg + 64.352133);

      test(
        'printed sidereal time and west longitude give the same H to 0.0002°',
        () {
          final fromPrinted = localSiderealDegrees(
            hmsToDegrees(8, 34, 56.853),
            -dmsToDegrees(77, 3, 56),
          );
          expect(normalizeSignedDegrees(fromPrinted - lst), closeTo(0, 0.0002));
        },
      );

      test(
        'azimuth 68.0337° from south (248.0337° from north), altitude 15.1249°',
        () {
          final h = equatorialToHorizontal(
            venus,
            lstDeg: lst,
            latitudeDeg: latitude,
          );
          expect(h.azDeg, closeTo(68.0337 + 180, 1e-4));
          expect(h.altDeg, closeTo(15.1249, 1e-4));
        },
      );

      test('round-trips back to equatorial', () {
        final h = equatorialToHorizontal(
          venus,
          lstDeg: lst,
          latitudeDeg: latitude,
        );
        final eq = horizontalToEquatorial(
          h,
          lstDeg: lst,
          latitudeDeg: latitude,
        );
        expect(eq.raDeg, closeTo(venus.raDeg, 1e-9));
        expect(eq.decDeg, closeTo(venus.decDeg, 1e-9));
      });

      test('rotation matrix agrees with the trigonometric formulas', () {
        final random = math.Random(7);
        for (var i = 0; i < 200; i++) {
          final eq = Equatorial(
            random.nextDouble() * 360,
            random.nextDouble() * 180 - 90,
          );
          final lstDeg = random.nextDouble() * 360;
          final lat = random.nextDouble() * 180 - 90;
          final expected = equatorialToHorizontal(
            eq,
            lstDeg: lstDeg,
            latitudeDeg: lat,
          );
          final enu = equatorialToHorizontalMatrix(
            lstDeg,
            lat,
          ).transform(eq.toVector());
          final actual = Horizontal.fromVector(enu);
          expect(actual.altDeg, closeTo(expected.altDeg, 1e-9));
          if (expected.altDeg.abs() < 89.999) {
            expect(
              normalizeSignedDegrees(actual.azDeg - expected.azDeg),
              closeTo(0, 1e-7),
            );
          }
        }
      });

      test('celestial pole sits at the latitude, due north, without NaN', () {
        final h = equatorialToHorizontal(
          const Equatorial(0, 90),
          lstDeg: 123,
          latitudeDeg: 21.03,
        );
        expect(h.altDeg, closeTo(21.03, 1e-9));
        expect(h.azDeg, closeTo(0, 1e-9));
        final zenith = equatorialToHorizontal(
          const Equatorial(40, 90),
          lstDeg: 0,
          latitudeDeg: 90,
        );
        expect(zenith.altDeg, closeTo(90, 1e-9));
        expect(zenith.azDeg.isNaN, isFalse);
      });
    },
  );

  test(
    'angular separation of Arcturus and Spica is 32.7930° (Meeus example 17.a)',
    () {
      const arcturus = Equatorial(213.9154, 19.1825);
      const spica = Equatorial(201.2983, -11.1614);
      expect(angularSeparationDeg(arcturus, spica), closeTo(32.7930, 1e-4));
      expect(angularSeparationDeg(spica, spica), 0);
    },
  );

  group('Observer', () {
    test('rejects coordinates outside the globe', () {
      expect(
        () => Observer(latitudeDeg: 90.5, longitudeDeg: 0),
        throwsArgumentError,
      );
      expect(
        () => Observer(latitudeDeg: 0, longitudeDeg: -180.1),
        throwsArgumentError,
      );
      expect(
        () => Observer(latitudeDeg: double.nan, longitudeDeg: 0),
        throwsArgumentError,
      );
    });

    test('accepts the poles and the antimeridian', () {
      expect(Observer(latitudeDeg: -90, longitudeDeg: 180).latitudeDeg, -90);
    });
  });

  group('Vec3 and Mat3', () {
    test('spherical round trip', () {
      final v = Vec3.fromSpherical(250, -33);
      final (lon, lat) = v.toSpherical();
      expect(lon, closeTo(250, 1e-12));
      expect(lat, closeTo(-33, 1e-12));
      expect(v.length, closeTo(1, 1e-15));
    });

    test('rotation about z turns x into y', () {
      final v = Mat3.rotationZ(math.pi / 2).transform(const Vec3(1, 0, 0));
      expect(v.x, closeTo(0, 1e-15));
      expect(v.y, closeTo(1, 1e-15));
    });

    test('transpose inverts a rotation', () {
      final m = Mat3.rotationX(0.3) * Mat3.rotationY(-1.1) * Mat3.rotationZ(2);
      final v = const Vec3(0.2, -0.5, 0.8);
      final back = m.transpose().transform(m.transform(v));
      expect((back - v).length, closeTo(0, 1e-15));
    });
  });
}

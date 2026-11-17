import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeDegrees', () {
    test('wraps negative angles into [0, 360)', () {
      expect(normalizeDegrees(-30), 330);
    });

    test('wraps angles above one turn', () {
      expect(normalizeDegrees(720.5), closeTo(0.5, 1e-12));
    });

    test('signed variant returns (-180, 180]', () {
      expect(normalizeSignedDegrees(190), closeTo(-170, 1e-12));
      expect(normalizeSignedDegrees(-180), 180);
      expect(normalizeSignedDegrees(45), 45);
    });
  });

  group('sexagesimal conversion', () {
    test(
      'hours, minutes, seconds to degrees (Meeus example 21.b, theta Per)',
      () {
        expect(hmsToDegrees(2, 44, 11.986), closeTo(41.049942, 1e-6));
      },
    );

    test('negative declination keeps the sign when degrees are zero', () {
      expect(dmsToDegrees(0, 30, 0, negative: true), closeTo(-0.5, 1e-12));
      expect(dmsToDegrees(49, 13, 42.48), closeTo(49.228467, 1e-6));
    });
  });

  group('formatting', () {
    test('formats right ascension in hours', () {
      expect(formatHms(197.693195), '13h 10m 46.4s');
    });

    test('carries rounded seconds into minutes and hours', () {
      expect(formatHms(hmsToDegrees(5, 59, 59.97)), '6h 00m 00.0s');
      expect(formatHms(359.99999999), '0h 00m 00.0s');
    });

    test('formats declination with an explicit sign', () {
      expect(formatDms(7.406944), '+7° 24′ 25″');
      expect(formatDms(-0.5), '−0° 30′ 00″');
      expect(formatDms(-18.888011, fractionDigits: 1), '−18° 53′ 16.8″');
    });

    test('carries rounded arcseconds into degrees', () {
      expect(formatDms(12.99999), '+13° 00′ 00″');
    });
  });
}

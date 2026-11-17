import 'package:astro/astro.dart';
import 'package:test/test.dart';

const _arcsec = 1 / 3600;

void main() {
  group('Meeus example 47.a, 1992 Apr 12.0 TD', () {
    const jde = 2448724.5;

    test('fundamental arguments', () {
      final a = lunarArguments(jde);
      expect(a.meanLongitudeDeg, closeTo(134.290182, 1e-6));
      expect(a.elongationDeg, closeTo(113.842304, 1e-6));
      expect(a.sunAnomalyDeg, closeTo(97.643514, 1e-6));
      expect(a.moonAnomalyDeg, closeTo(5.150833, 1e-6));
      expect(a.latitudeArgumentDeg, closeTo(219.889721, 1e-6));
      expect(a.eccentricityFactor, closeTo(1.000194, 1e-6));
    });

    test('periodic sums of tables 47.A and 47.B', () {
      final s = lunarSums(jde);
      expect(s.longitude, closeTo(-1127527, 2));
      expect(s.latitude, closeTo(-3229126, 2));
      expect(s.distance, closeTo(-16590875, 2));
    });

    test('geometric longitude 133.162655°, latitude −3.229126°', () {
      final moon = moonPosition(jde);
      expect(moon.geometric.lonDeg, closeTo(133.162655, 1e-6));
      expect(moon.geometric.latDeg, closeTo(-3.229126, 1e-6));
    });

    test('distance 368409.7 km and parallax 0.991990°', () {
      final moon = moonPosition(jde);
      expect(moon.distanceKm, closeTo(368409.7, 0.1));
      expect(moon.parallaxDeg, closeTo(0.991990, 1e-6));
    });

    test('apparent position 134.688470°, +13.768368° within 2″', () {
      // Meeus applies the full nutation series; this package uses the
      // four-term series (0.5″), hence the wider tolerance.
      final moon = moonPosition(jde);
      expect(moon.apparentLongitudeDeg, closeTo(133.167265, 0.5 * _arcsec));
      expect(moon.apparent.raDeg, closeTo(134.688470, 2 * _arcsec));
      expect(moon.apparent.decDeg, closeTo(13.768368, 2 * _arcsec));
    });
  });

  test('distance stays between perigee and apogee limits over a year', () {
    for (var d = 0; d < 366; d += 3) {
      final moon = moonPosition(2461041.5 + d);
      expect(moon.distanceKm, inInclusiveRange(356000, 407000));
      expect(moon.geometric.latDeg.abs(), lessThan(5.4));
    }
  });
}

import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus example 25.a, 1992 Oct 13.0 TD', () {
    final sun = sunPosition(2448908.5);

    test('true longitude 199.90988° and radius vector 0.99766 AU', () {
      expect(sun.trueLongitudeDeg, closeTo(199.90988, 1e-5));
      expect(sun.distanceAu, closeTo(0.99766, 1e-5));
    });

    test('apparent longitude 199.90895°', () {
      expect(sun.apparentLongitudeDeg, closeTo(199.90895, 1e-5));
    });

    test('apparent right ascension 198.38083° and declination −7.78507°', () {
      expect(sun.apparent.raDeg, closeTo(198.38083, 1e-4));
      expect(sun.apparent.decDeg, closeTo(-7.78507, 1e-4));
    });
  });

  test('the Sun is near the March equinox point on 2026 Mar 20 14:46 UTC', () {
    final t = AstroTime.fromDateTime(DateTime.utc(2026, 3, 20, 14, 46));
    final sun = sunPosition(t.jdTt);
    expect(normalizeSignedDegrees(sun.apparentLongitudeDeg), closeTo(0, 0.02));
    expect(sun.apparent.decDeg, closeTo(0, 0.01));
  });
}

import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('Meeus example 15.a, Venus at Boston on 1988 Mar 20', () {
    final result = riseTransitSet(
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

    test('rises at 12h25m UT (0.51766 d)', () {
      expect(result.rise, closeTo(0.51766, 0.0007));
    });

    test('transits at 19h41m UT (0.81980 d)', () {
      expect(result.transit, closeTo(0.81980, 0.0007));
    });

    test('sets at 2h55m UT (0.12130 d)', () {
      expect(result.set, closeTo(0.12130, 0.0007));
      expect(result.alwaysAbove, isFalse);
      expect(result.alwaysBelow, isFalse);
    });
  });

  test('right ascension wrapping through 0h gives the same times', () {
    RiseTransitSet at(double shift) => riseTransitSet(
      gast0Deg: normalizeDegrees(100 + shift),
      positions: [
        Equatorial(normalizeDegrees(359.5 + shift), 10),
        Equatorial(normalizeDegrees(0.5 + shift), 10.3),
        Equatorial(normalizeDegrees(1.5 + shift), 10.6),
      ],
      h0Deg: h0Stars,
      latitudeDeg: 21.03,
      longitudeEastDeg: 105.85,
      deltaTSeconds: 69,
      dayStart: DateTime.utc(2026, 1, 1),
    );
    final wrapped = at(0);
    final plain = at(20);
    expect(wrapped.rise, closeTo(plain.rise!, 1e-9));
    expect(wrapped.transit, closeTo(plain.transit!, 1e-9));
    expect(wrapped.set, closeTo(plain.set!, 1e-9));
  });

  group('the Sun at 80° north', () {
    final observer = Observer(latitudeDeg: 80, longitudeDeg: 15);
    Equatorial sun(double jdTt) => sunPosition(jdTt).apparent;

    test('never sets at the June solstice', () {
      final r = riseTransitSetForDay(
        sun,
        DateTime.utc(2026, 6, 21),
        observer,
        h0Sun,
      );
      expect(r.alwaysAbove, isTrue);
      expect(r.rise, isNull);
      expect(r.set, isNull);
      expect(r.transit, isNotNull);
    });

    test('never rises at the December solstice', () {
      final r = riseTransitSetForDay(
        sun,
        DateTime.utc(2026, 12, 21),
        observer,
        h0Sun,
      );
      expect(r.alwaysBelow, isTrue);
      expect(r.rise, isNull);
    });
  });

  test('day length on the equator at the equinox is about 12h07m', () {
    final r = riseTransitSetForDay(
      (jd) => sunPosition(jd).apparent,
      DateTime.utc(2026, 3, 20),
      Observer(latitudeDeg: 0, longitudeDeg: 0),
      h0Sun,
    );
    final minutes = (r.set! - r.rise!) * 24 * 60;
    expect(minutes, closeTo(12 * 60 + 7, 4));
  });

  test('event times convert to instants within the UT day', () {
    final r = riseTransitSetForDay(
      (jd) => sunPosition(jd).apparent,
      DateTime.utc(2026, 3, 20),
      Observer(latitudeDeg: 21.03, longitudeDeg: 105.85),
      h0Sun,
    );
    final rise = r.riseTime!;
    expect(rise.isUtc, isTrue);
    expect(rise.year, 2026);
    expect(rise.day, anyOf(19, 20));
  });

  test('lunar h0 depends on the parallax (Meeus chapter 15)', () {
    expect(h0Moon(0.95), closeTo(0.7275 * 0.95 - 0.5667, 1e-12));
  });
}

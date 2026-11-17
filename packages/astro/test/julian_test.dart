import 'package:astro/astro.dart';
import 'package:test/test.dart';

void main() {
  group('julianDay (Meeus chapter 7)', () {
    test('example 7.a: launch of Sputnik 1, 1957 Oct 4.81', () {
      expect(julianDay(1957, 10, 4.81), closeTo(2436116.31, 1e-9));
    });

    test('example 7.b: 333 Jan 27.5 in the Julian calendar', () {
      expect(julianDay(333, 1, 27.5), closeTo(1842713.0, 1e-9));
    });

    test('table 7.a reference dates', () {
      const cases = <(int, int, double, double)>[
        (2000, 1, 1.5, 2451545.0),
        (1987, 1, 27.0, 2446822.5),
        (1988, 6, 19.5, 2447332.0),
        (1600, 12, 31.0, 2305812.5),
        (837, 4, 10.3, 2026871.8),
        (-1000, 7, 12.5, 1356001.0),
        (-4712, 1, 1.5, 0.0),
      ];
      for (final (y, m, d, jd) in cases) {
        expect(julianDay(y, m, d), closeTo(jd, 1e-9), reason: '$y-$m-$d');
      }
    });

    test('example 7.c: calendar date from JD 2436116.31', () {
      final date = calendarFromJulianDay(2436116.31);
      expect(date.year, 1957);
      expect(date.month, 10);
      expect(date.day, closeTo(4.81, 1e-6));
    });

    test('calendar conversion round-trips across both calendars', () {
      for (final jd in [0.0, 1356001.0, 1842713.0, 2299160.5, 2299159.5]) {
        final c = calendarFromJulianDay(jd);
        expect(julianDay(c.year, c.month, c.day), closeTo(jd, 1e-6));
      }
    });
  });

  group('DateTime conversion', () {
    test('J2000.0 is 2000-01-01 12:00 UTC', () {
      expect(
        julianDayFromDateTime(DateTime.utc(2000, 1, 1, 12)),
        closeTo(2451545.0, 1e-9),
      );
    });

    test('round-trips with millisecond precision', () {
      final t = DateTime.utc(2026, 11, 17, 21, 34, 56, 789);
      expect(dateTimeFromJulianDay(julianDayFromDateTime(t)), t);
    });

    test('local DateTime values are converted to UTC first', () {
      final utc = DateTime.utc(2026, 1, 1);
      expect(
        julianDayFromDateTime(utc.toLocal()),
        julianDayFromDateTime(utc),
      );
    });
  });

  group('deltaT', () {
    test('1988 value used in Meeus example 15.a is about 56 s', () {
      expect(deltaTSeconds(1988.2), closeTo(56, 1));
    });

    test('is continuous at the 2005 polynomial boundary', () {
      expect(
        deltaTSeconds(2004.9999),
        closeTo(deltaTSeconds(2005.0), 0.1),
      );
    });

    test('AstroTime keeps UT and TT apart by deltaT', () {
      final t = AstroTime.fromDateTime(DateTime.utc(2000, 1, 1, 12));
      expect(t.jdUt, closeTo(2451545.0, 1e-9));
      expect((t.jdTt - t.jdUt) * 86400, closeTo(deltaTSeconds(2000.0), 1e-3));
    });

    test('AstroTime built from TT recovers the same UT', () {
      final a = AstroTime.fromDateTime(DateTime.utc(1992, 4, 12));
      final b = AstroTime.fromJulianDayTt(a.jdTt);
      expect(b.jdUt, closeTo(a.jdUt, 1e-9));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/data/sky_link.dart';
import 'package:orrery_sky_atlas/src/format/format.dart';

void main() {
  group('SkyLink.parse', () {
    test('reads time, preset place, view and night mode', () {
      final link = SkyLink.parse(
        Uri.parse(
          'https://x/orrery-sky-atlas/?t=2026-12-15T21:00:00%2B07:00'
          '&loc=hanoi&az=110&alt=35&fov=120&night=1&select=hr:2061',
        ),
      );
      expect(link.time, DateTime.utc(2026, 12, 15, 14));
      expect(link.location!.name, 'Hanoi');
      expect(link.azDeg, 110);
      expect(link.altDeg, 35);
      expect(link.fovDeg, 120);
      expect(link.night, isTrue);
      expect(link.select, 'hr:2061');
    });

    test('builds a custom place from lat, lon and tz', () {
      final link = SkyLink.parse(Uri.parse('/?lat=-33.86&lon=151.21&tz=10'));
      expect(link.location!.latitudeDeg, -33.86);
      expect(link.location!.utcOffset, const Duration(hours: 10));
    });

    test('times without a zone are read as UTC', () {
      expect(
        SkyLink.parse(Uri.parse('/?t=2026-01-02T03:04')).time,
        DateTime.utc(2026, 1, 2, 3, 4),
      );
    });

    test('ignores malformed or out-of-range values', () {
      final link = SkyLink.parse(
        Uri.parse(
          '/?t=yesterday&loc=atlantis&lat=95&lon=10&az=abc&alt=120'
          '&fov=-5&night=maybe',
        ),
      );
      expect(link.time, isNull);
      expect(link.location, isNull);
      expect(link.azDeg, isNull);
      expect(link.altDeg, isNull);
      expect(link.fovDeg, isNull);
      expect(link.night, isNull);
      expect(link.isEmpty, isTrue);
    });

    test('a latitude without a longitude is ignored', () {
      expect(SkyLink.parse(Uri.parse('/?lat=10')).location, isNull);
    });
  });

  group('formatting', () {
    test('local date and time', () {
      final t = DateTime.utc(2026, 11, 17, 14, 30);
      expect(formatDate(t), 'Tue 17 Nov 2026');
      expect(formatClock(t), '14:30');
      expect(formatDateTime(t), 'Tue 17 Nov 2026, 14:30');
    });

    test('durations of play speed', () {
      expect(formatSpeed(0), 'Paused');
      expect(formatSpeed(1), 'Real time');
      expect(formatSpeed(60), '1 min/s');
      expect(formatSpeed(3600), '1 h/s');
    });

    test('compass direction for an azimuth', () {
      expect(compassPoint(0), 'N');
      expect(compassPoint(44), 'NE');
      expect(compassPoint(181), 'S');
      expect(compassPoint(359), 'N');
    });
  });
}

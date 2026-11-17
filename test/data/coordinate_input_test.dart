import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/data/coordinate_input.dart';
import 'package:orrery_sky_atlas/src/data/locations.dart';

Matcher _error(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  group('parseCoordinate', () {
    test('reads plain and signed decimal degrees', () {
      expect(parseCoordinate('21.0285', latitude: true), 21.0285);
      expect(parseCoordinate('  -33.8688 ', latitude: true), -33.8688);
      expect(parseCoordinate('−70.4042', latitude: false), -70.4042);
    });

    test('accepts a comma as the decimal separator', () {
      expect(parseCoordinate('21,03', latitude: true), closeTo(21.03, 1e-12));
    });

    test('reads hemisphere letters before or after the number', () {
      expect(parseCoordinate('21.03N', latitude: true), closeTo(21.03, 1e-12));
      expect(
        parseCoordinate('33.87 s', latitude: true),
        closeTo(-33.87, 1e-12),
      );
      expect(
        parseCoordinate('105.85 E', latitude: false),
        closeTo(105.85, 1e-12),
      );
      expect(parseCoordinate('W 70.4', latitude: false), closeTo(-70.4, 1e-12));
    });

    test('reads degrees, minutes and seconds', () {
      expect(
        parseCoordinate('21°01′42.6″N', latitude: true),
        closeTo(21 + 1 / 60 + 42.6 / 3600, 1e-9),
      );
      expect(
        parseCoordinate("105 51 15 E", latitude: false),
        closeTo(105 + 51 / 60 + 15 / 3600, 1e-9),
      );
    });

    test('rejects empty and non-numeric input', () {
      expect(() => parseCoordinate('', latitude: true), _error('Enter'));
      expect(() => parseCoordinate('   ', latitude: true), _error('Enter'));
      expect(() => parseCoordinate('abc', latitude: true), _error('number'));
      expect(() => parseCoordinate('12.3.4', latitude: true), _error('number'));
    });

    test('rejects values outside the globe', () {
      expect(() => parseCoordinate('91', latitude: true), _error('between'));
      expect(() => parseCoordinate('-181', latitude: false), _error('between'));
    });

    test('rejects the wrong hemisphere letters and double signs', () {
      expect(() => parseCoordinate('21 E', latitude: true), _error('N or S'));
      expect(() => parseCoordinate('105 N', latitude: false), _error('E or W'));
      expect(() => parseCoordinate('-21 S', latitude: true), _error('either'));
    });

    test('rejects minutes or seconds of 60 and more', () {
      expect(
        () => parseCoordinate('21 75 00', latitude: true),
        _error('minutes'),
      );
    });

    test('does not crash on unusual characters', () {
      expect(
        () => parseCoordinate('21​.5', latitude: true),
        throwsFormatException,
      );
      expect(
        () => parseCoordinate('🌍', latitude: true),
        throwsFormatException,
      );
    });
  });

  group('parseUtcOffset', () {
    test('reads hours and hours:minutes with or without UTC', () {
      expect(parseUtcOffset('7'), const Duration(hours: 7));
      expect(parseUtcOffset('+05:45'), const Duration(hours: 5, minutes: 45));
      expect(
        parseUtcOffset('UTC-3:30'),
        const Duration(hours: -3, minutes: -30),
      );
      expect(parseUtcOffset('-10'), const Duration(hours: -10));
    });

    test('rejects offsets outside −12 h to +14 h and garbage', () {
      expect(() => parseUtcOffset('+15'), _error('between'));
      expect(() => parseUtcOffset('7:99'), _error('minutes'));
      expect(() => parseUtcOffset('seven'), throwsFormatException);
      expect(() => parseUtcOffset(''), throwsFormatException);
    });
  });

  group('locations', () {
    test(
      'presets start with Vietnamese cities and include both hemispheres',
      () {
        expect(locationPresets.first.name, 'Hanoi');
        expect(
          locationPresets.map((l) => l.name),
          contains('Ho Chi Minh City'),
        );
        expect(locationPresets.any((l) => l.latitudeDeg < 0), isTrue);
        expect(
          locationPresets.map((l) => l.slug).toSet().length,
          locationPresets.length,
        );
      },
    );

    test('formats the UTC offset', () {
      expect(formatUtcOffset(const Duration(hours: 7)), 'UTC+7');
      expect(
        formatUtcOffset(const Duration(hours: -3, minutes: -30)),
        'UTC−3:30',
      );
      expect(formatUtcOffset(Duration.zero), 'UTC');
    });

    test('custom locations get a coordinate name', () {
      final l = Location.custom(
        latitudeDeg: -12.5,
        longitudeDeg: 130.84,
        utcOffset: const Duration(hours: 9, minutes: 30),
      );
      expect(l.name, '12.50° S, 130.84° E');
      expect(l.observer.latitudeDeg, -12.5);
    });
  });
}

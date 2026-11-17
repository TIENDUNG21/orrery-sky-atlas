import 'package:astro/astro.dart';

/// A named place with a fixed offset from UTC (standard time; daylight
/// saving time is not modelled).
class Location {
  const Location({
    required this.name,
    required this.slug,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.utcOffset,
  });

  /// A place typed in by the user, named after its coordinates.
  factory Location.custom({
    required double latitudeDeg,
    required double longitudeDeg,
    required Duration utcOffset,
  }) {
    final ns = latitudeDeg < 0 ? 'S' : 'N';
    final ew = longitudeDeg < 0 ? 'W' : 'E';
    return Location(
      name:
          '${latitudeDeg.abs().toStringAsFixed(2)}° $ns, '
          '${longitudeDeg.abs().toStringAsFixed(2)}° $ew',
      slug: 'custom',
      latitudeDeg: latitudeDeg,
      longitudeDeg: longitudeDeg,
      utcOffset: utcOffset,
    );
  }

  final String name;

  /// Short identifier used in sky links, e.g. `hanoi`.
  final String slug;
  final double latitudeDeg;

  /// East-positive longitude.
  final double longitudeDeg;
  final Duration utcOffset;

  Observer get observer =>
      Observer(latitudeDeg: latitudeDeg, longitudeDeg: longitudeDeg);

  /// Local clock time at this place for a UTC instant.
  DateTime localTime(DateTime utc) => utc.toUtc().add(utcOffset);
}

const _vn = Duration(hours: 7);

/// Built-in places: Vietnamese cities first, then observatories and cities
/// on other continents and in the southern hemisphere.
const List<Location> locationPresets = [
  Location(
    name: 'Hanoi',
    slug: 'hanoi',
    latitudeDeg: 21.0285,
    longitudeDeg: 105.8542,
    utcOffset: _vn,
  ),
  Location(
    name: 'Ho Chi Minh City',
    slug: 'hcmc',
    latitudeDeg: 10.8231,
    longitudeDeg: 106.6297,
    utcOffset: _vn,
  ),
  Location(
    name: 'Da Nang',
    slug: 'danang',
    latitudeDeg: 16.0544,
    longitudeDeg: 108.2022,
    utcOffset: _vn,
  ),
  Location(
    name: 'Hue',
    slug: 'hue',
    latitudeDeg: 16.4637,
    longitudeDeg: 107.5909,
    utcOffset: _vn,
  ),
  Location(
    name: 'Da Lat',
    slug: 'dalat',
    latitudeDeg: 11.9404,
    longitudeDeg: 108.4583,
    utcOffset: _vn,
  ),
  Location(
    name: 'Can Tho',
    slug: 'cantho',
    latitudeDeg: 10.0452,
    longitudeDeg: 105.7469,
    utcOffset: _vn,
  ),
  Location(
    name: 'Sa Pa',
    slug: 'sapa',
    latitudeDeg: 22.3364,
    longitudeDeg: 103.8438,
    utcOffset: _vn,
  ),
  Location(
    name: 'Singapore',
    slug: 'singapore',
    latitudeDeg: 1.3521,
    longitudeDeg: 103.8198,
    utcOffset: Duration(hours: 8),
  ),
  Location(
    name: 'Tokyo',
    slug: 'tokyo',
    latitudeDeg: 35.6762,
    longitudeDeg: 139.6503,
    utcOffset: Duration(hours: 9),
  ),
  Location(
    name: 'Sydney',
    slug: 'sydney',
    latitudeDeg: -33.8688,
    longitudeDeg: 151.2093,
    utcOffset: Duration(hours: 10),
  ),
  Location(
    name: 'Greenwich',
    slug: 'greenwich',
    latitudeDeg: 51.4769,
    longitudeDeg: -0.0005,
    utcOffset: Duration.zero,
  ),
  Location(
    name: 'Reykjavik',
    slug: 'reykjavik',
    latitudeDeg: 64.1466,
    longitudeDeg: -21.9426,
    utcOffset: Duration.zero,
  ),
  Location(
    name: 'Mauna Kea',
    slug: 'maunakea',
    latitudeDeg: 19.8207,
    longitudeDeg: -155.4681,
    utcOffset: Duration(hours: -10),
  ),
  Location(
    name: 'Cerro Paranal',
    slug: 'paranal',
    latitudeDeg: -24.6272,
    longitudeDeg: -70.4042,
    utcOffset: Duration(hours: -4),
  ),
];

/// Preset with [slug], or null.
Location? presetBySlug(String slug) {
  for (final l in locationPresets) {
    if (l.slug == slug) return l;
  }
  return null;
}

/// `UTC+7`, `UTC−3:30` or `UTC`.
String formatUtcOffset(Duration offset) {
  if (offset == Duration.zero) return 'UTC';
  final sign = offset.isNegative ? '−' : '+';
  final minutes = offset.inMinutes.abs();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
}

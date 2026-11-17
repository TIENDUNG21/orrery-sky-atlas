import 'locations.dart';

/// Initial state read from a URL, so a view of the sky can be shared:
/// `?t=2026-12-15T21:00+07:00&loc=hanoi&az=110&alt=35&fov=120&night=1`.
///
/// Every parameter is optional and invalid values are ignored rather than
/// reported, because a link may have been edited by hand.
class SkyLink {
  const SkyLink({
    this.time,
    this.location,
    this.azDeg,
    this.altDeg,
    this.fovDeg,
    this.night,
    this.select,
  });

  factory SkyLink.parse(Uri uri) {
    final q = uri.queryParameters;

    double? number(String key, double min, double max) {
      final v = double.tryParse(q[key] ?? '');
      return v != null && v >= min && v <= max ? v : null;
    }

    Location? location = presetBySlug(q['loc'] ?? '');
    final lat = number('lat', -90, 90);
    final lon = number('lon', -180, 180);
    if (lat != null && lon != null) {
      final tz = number('tz', -12, 14) ?? 0;
      location = Location.custom(
        latitudeDeg: lat,
        longitudeDeg: lon,
        utcOffset: Duration(minutes: (tz * 60).round()),
      );
    }

    return SkyLink(
      time: _parseTime(q['t']),
      location: location,
      azDeg: number('az', 0, 360),
      altDeg: number('alt', -90, 90),
      fovDeg: number('fov', 5, 200),
      night: switch (q['night']) {
        '1' || 'true' => true,
        '0' || 'false' => false,
        _ => null,
      },
      select: q['select'],
    );
  }

  final DateTime? time;
  final Location? location;
  final double? azDeg;
  final double? altDeg;
  final double? fovDeg;
  final bool? night;

  /// Object to select, e.g. `hr:2061` or `planet:mars`.
  final String? select;

  bool get isEmpty =>
      time == null &&
      location == null &&
      azDeg == null &&
      altDeg == null &&
      fovDeg == null &&
      night == null &&
      select == null;
}

final _zone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime? _parseTime(String? text) {
  if (text == null || text.isEmpty) return null;
  // An unescaped '+' in a query string arrives as a space.
  var t = text.trim().replaceAll(' ', '+');
  if (!_zone.hasMatch(t)) t = '${t}Z';
  return DateTime.tryParse(t)?.toUtc();
}

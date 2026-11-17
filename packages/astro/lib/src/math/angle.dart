/// Angle helpers shared by every algorithm in the package.
library;

import 'dart:math' as math;

/// Multiply degrees by this to get radians.
const double deg2rad = math.pi / 180.0;

/// Multiply radians by this to get degrees.
const double rad2deg = 180.0 / math.pi;

/// Reduces [degrees] to the range [0, 360).
double normalizeDegrees(double degrees) {
  final r = degrees % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Reduces [degrees] to the range (-180, 180].
double normalizeSignedDegrees(double degrees) {
  final r = normalizeDegrees(degrees);
  return r > 180.0 ? r - 360.0 : r;
}

/// Converts hours, minutes and seconds of right ascension to degrees.
double hmsToDegrees(int hours, int minutes, double seconds) =>
    (hours + minutes / 60.0 + seconds / 3600.0) * 15.0;

/// Converts degrees, arcminutes and arcseconds to decimal degrees.
///
/// The sign is passed separately so that `-0° 30′` can be represented.
double dmsToDegrees(
  int degrees,
  int minutes,
  double seconds, {
  bool negative = false,
}) {
  final value = degrees.abs() + minutes / 60.0 + seconds / 3600.0;
  return negative ? -value : value;
}

/// Formats an angle given in degrees as hours, e.g. `13h 10m 46.4s`.
///
/// Rounding carries into minutes and hours, and 24h wraps to 0h.
String formatHms(double degrees, {int fractionDigits = 1}) {
  final scale = math.pow(10, fractionDigits).toInt();
  final unitsPerDay = 24 * 3600 * scale;
  var units = (normalizeDegrees(degrees) / 15.0 * 3600.0 * scale).round();
  if (units >= unitsPerDay) units -= unitsPerDay;
  final h = units ~/ (3600 * scale);
  final m = (units ~/ (60 * scale)) % 60;
  final s = (units % (60 * scale)) / scale;
  return '${h}h ${_two(m)}m ${_seconds(s, fractionDigits)}s';
}

/// Formats an angle in degrees as signed degrees, arcminutes and arcseconds,
/// e.g. `+7° 24′ 25″` or `−18° 53′ 16.8″`.
String formatDms(double degrees, {int fractionDigits = 0}) {
  final scale = math.pow(10, fractionDigits).toInt();
  final units = (degrees.abs() * 3600.0 * scale).round();
  final d = units ~/ (3600 * scale);
  final m = (units ~/ (60 * scale)) % 60;
  final s = (units % (60 * scale)) / scale;
  final sign = degrees < 0 && units != 0 ? '\u2212' : '+';
  return '$sign$d° ${_two(m)}′ ${_seconds(s, fractionDigits)}″';
}

String _two(int value) => value.toString().padLeft(2, '0');

String _seconds(double seconds, int fractionDigits) {
  final text = seconds.toStringAsFixed(fractionDigits);
  final width = fractionDigits == 0 ? 2 : 3 + fractionDigits;
  return text.padLeft(width, '0');
}

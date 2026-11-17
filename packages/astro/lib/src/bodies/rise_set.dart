/// Rising, transit and setting (Meeus chapter 15).
library;

import 'dart:math' as math;

import '../coords/coordinates.dart';
import '../coords/observer.dart';
import '../math/angle.dart';
import '../time/delta_t.dart';
import '../time/julian.dart';
import '../time/sidereal.dart';

/// Standard altitude h0 for stars and planets: refraction at the horizon.
const double h0Stars = -0.5667;

/// Standard altitude h0 for the Sun: refraction plus the semi-diameter.
const double h0Sun = -0.8333;

/// Standard altitude h0 for the Moon from its horizontal parallax.
double h0Moon(double parallaxDeg) => 0.7275 * parallaxDeg - 0.5667;

/// Times of rising, upper transit and setting as fractions of a UT day.
class RiseTransitSet {
  /// Creates a result for the UT day starting at [dayStart].
  const RiseTransitSet({
    required this.dayStart,
    required this.rise,
    required this.transit,
    required this.set,
    required this.alwaysAbove,
    required this.alwaysBelow,
  });

  /// 0h UT of the day the fractions refer to.
  final DateTime dayStart;

  /// Rising time as a fraction of the day, or null.
  final double? rise;

  /// Upper transit as a fraction of the day.
  final double? transit;

  /// Setting time as a fraction of the day, or null.
  final double? set;

  /// The body stays above the standard altitude all day.
  final bool alwaysAbove;

  /// The body stays below the standard altitude all day.
  final bool alwaysBelow;

  /// Rising as a UTC instant.
  DateTime? get riseTime => _at(rise);

  /// Transit as a UTC instant.
  DateTime? get transitTime => _at(transit);

  /// Setting as a UTC instant.
  DateTime? get setTime => _at(set);

  DateTime? _at(double? fraction) => fraction == null
      ? null
      : dayStart.add(Duration(milliseconds: (fraction * 86400000).round()));
}

/// Meeus's interpolation method.
///
/// [gast0Deg] is the apparent sidereal time at Greenwich at 0h UT of the day;
/// [positions] are apparent positions at 0h TT of the previous day, the day
/// and the next day; [dayStart] is that day's 0h UT. Longitudes are
/// east-positive. The corrections are
/// repeated until they fall below 1e-6 day.
RiseTransitSet riseTransitSet({
  required double gast0Deg,
  required List<Equatorial> positions,
  required double h0Deg,
  required double latitudeDeg,
  required double longitudeEastDeg,
  required double deltaTSeconds,
  required DateTime dayStart,
}) {
  if (positions.length != 3) {
    throw ArgumentError.value(positions, 'positions', 'needs three entries');
  }
  // Unwrap right ascension around the middle value so 359° → 1° interpolates.
  final a2 = positions[1].raDeg;
  double unwrap(double a) => a2 + normalizeSignedDegrees(a - a2);
  final ra = [unwrap(positions[0].raDeg), a2, unwrap(positions[2].raDeg)];
  final dec = [for (final p in positions) p.decDeg];

  final phi = latitudeDeg * deg2rad;
  final d2 = dec[1] * deg2rad;
  final cosH0 =
      (math.sin(h0Deg * deg2rad) - math.sin(phi) * math.sin(d2)) /
      (math.cos(phi) * math.cos(d2));

  double interpolate(List<double> y, double n) {
    final a = y[1] - y[0];
    final b = y[2] - y[1];
    return y[1] + n / 2 * (a + b + n * (b - a));
  }

  double refine(double m, {required bool isTransit}) {
    for (var i = 0; i < 20; i++) {
      final theta = gast0Deg + 360.985647 * m;
      final n = m + deltaTSeconds / 86400.0;
      final alpha = interpolate(ra, n);
      final delta = interpolate(dec, n) * deg2rad;
      final hourAngle = normalizeSignedDegrees(
        theta + longitudeEastDeg - alpha,
      );
      final double dm;
      if (isTransit) {
        dm = -hourAngle / 360.0;
      } else {
        final h = math.asin(
          math.sin(phi) * math.sin(delta) +
              math.cos(phi) * math.cos(delta) * math.cos(hourAngle * deg2rad),
        );
        dm =
            (h * rad2deg - h0Deg) /
            (360.0 *
                math.cos(delta) *
                math.cos(phi) *
                math.sin(hourAngle * deg2rad));
      }
      m += dm;
      if (dm.abs() < 1e-6) break;
    }
    return m;
  }

  double unit(double m) => m - m.floorToDouble();

  final m0 = unit((a2 - longitudeEastDeg - gast0Deg) / 360.0);
  final transit = unit(refine(m0, isTransit: true));
  if (cosH0 < -1 || cosH0 > 1) {
    return RiseTransitSet(
      dayStart: dayStart,
      rise: null,
      transit: transit,
      set: null,
      alwaysAbove: cosH0 < -1,
      alwaysBelow: cosH0 > 1,
    );
  }
  final h0 = math.acos(cosH0) * rad2deg;
  return RiseTransitSet(
    dayStart: dayStart,
    rise: unit(refine(unit(m0 - h0 / 360.0), isTransit: false)),
    transit: transit,
    set: unit(refine(unit(m0 + h0 / 360.0), isTransit: false)),
    alwaysAbove: false,
    alwaysBelow: false,
  );
}

/// Rise, transit and set during the UT day that starts at [utcDay]'s date,
/// for a body whose apparent position is given by [position] (TT).
RiseTransitSet riseTransitSetForDay(
  Equatorial Function(double jdTt) position,
  DateTime utcDay,
  Observer observer,
  double h0Deg,
) {
  final day = DateTime.utc(utcDay.year, utcDay.month, utcDay.day);
  final jd0 = julianDayFromDateTime(day);
  final deltaT = deltaTSeconds(decimalYear(jd0));
  return riseTransitSet(
    gast0Deg: greenwichApparentSiderealDegrees(jd0, jd0 + deltaT / 86400.0),
    positions: [position(jd0 - 1), position(jd0), position(jd0 + 1)],
    h0Deg: h0Deg,
    latitudeDeg: observer.latitudeDeg,
    longitudeEastDeg: observer.longitudeDeg,
    deltaTSeconds: deltaT,
    dayStart: day,
  );
}

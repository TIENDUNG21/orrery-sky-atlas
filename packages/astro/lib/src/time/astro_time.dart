/// An instant expressed in the two time scales the algorithms need.
library;

import 'delta_t.dart';
import 'julian.dart';

/// An instant carrying both Universal Time (for Earth rotation) and
/// Terrestrial Time (for the motion of the Sun, Moon and planets).
class AstroTime {
  /// Creates an instant from Julian days in UT and TT.
  const AstroTime(this.jdUt, this.jdTt);

  /// Instant of a [DateTime]; local values are converted to UTC.
  factory AstroTime.fromDateTime(DateTime time) {
    final jdUt = julianDayFromDateTime(time);
    return AstroTime(jdUt, jdUt + deltaTSeconds(decimalYear(jdUt)) / 86400.0);
  }

  /// Instant of a Julian ephemeris day (TT), as used by Meeus examples.
  factory AstroTime.fromJulianDayTt(double jdTt) {
    final jdUt = jdTt - deltaTSeconds(decimalYear(jdTt)) / 86400.0;
    return AstroTime(jdUt, jdTt);
  }

  /// Julian day in Universal Time.
  final double jdUt;

  /// Julian ephemeris day in Terrestrial Time.
  final double jdTt;

  /// The instant as a UTC [DateTime] (UT1 is treated as UTC).
  DateTime toDateTime() => dateTimeFromJulianDay(jdUt);

  @override
  String toString() => 'AstroTime(jdUt: $jdUt, jdTt: $jdTt)';
}

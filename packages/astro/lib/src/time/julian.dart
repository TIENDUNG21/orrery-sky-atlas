/// Julian day numbers and calendar dates (Meeus chapter 7).
library;

/// Julian day of 1970-01-01T00:00:00Z, the Unix epoch.
const double unixEpochJulianDay = 2440587.5;

/// Julian day of the standard epoch J2000.0 (2000-01-01 12:00 TT).
const double j2000 = 2451545.0;

const double _msPerDay = 86400000.0;

/// A calendar date whose [day] carries the fraction of the day.
class CalendarDate {
  /// Creates a calendar date; [year] uses astronomical numbering (0 = 1 BC).
  const CalendarDate(this.year, this.month, this.day);

  /// Astronomical year (1 BC = 0, 2 BC = -1).
  final int year;

  /// Month, 1 to 12.
  final int month;

  /// Day of the month including the fraction of the day.
  final double day;

  @override
  String toString() => 'CalendarDate($year, $month, $day)';
}

/// Julian day for a calendar date (Meeus 7.1).
///
/// Dates from 1582 October 15 on are Gregorian; earlier dates are Julian.
double julianDay(int year, int month, double day) {
  var y = year;
  var m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final gregorian =
      year > 1582 ||
      (year == 1582 && (month > 10 || (month == 10 && day >= 15)));
  var b = 0;
  if (gregorian) {
    final a = (y / 100).floor();
    b = 2 - a + (a / 4).floor();
  }
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day +
      b -
      1524.5;
}

/// Calendar date for a Julian day (Meeus chapter 7, valid for jd >= 0).
CalendarDate calendarFromJulianDay(double jd) {
  final shifted = jd + 0.5;
  final z = shifted.floor();
  final f = shifted - z;
  var a = z;
  if (z >= 2299161) {
    final alpha = ((z - 1867216.25) / 36524.25).floor();
    a = z + 1 + alpha - (alpha / 4).floor();
  }
  final b = a + 1524;
  final c = ((b - 122.1) / 365.25).floor();
  final d = (365.25 * c).floor();
  final e = ((b - d) / 30.6001).floor();
  final day = b - d - (30.6001 * e).floor() + f;
  final month = e < 14 ? e - 1 : e - 13;
  final year = month > 2 ? c - 4716 : c - 4715;
  return CalendarDate(year, month, day);
}

/// Julian day of an instant; local times are converted to UTC first.
double julianDayFromDateTime(DateTime time) =>
    unixEpochJulianDay + time.toUtc().millisecondsSinceEpoch / _msPerDay;

/// UTC instant for a Julian day, rounded to the millisecond.
DateTime dateTimeFromJulianDay(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(
      ((jd - unixEpochJulianDay) * _msPerDay).round(),
      isUtc: true,
    );

/// Julian centuries of 36525 days since J2000.0.
double julianCenturies(double jd) => (jd - j2000) / 36525.0;

/// Decimal year for a Julian day, accurate enough for slowly varying terms.
double decimalYear(double jd) => 2000.0 + (jd - j2000) / 365.25;

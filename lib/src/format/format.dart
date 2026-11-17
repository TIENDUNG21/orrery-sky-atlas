/// Small, locale-independent formatters for the UI.
library;

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int v) => v.toString().padLeft(2, '0');

/// `Tue 17 Nov 2026` from the date fields of [t] (no time-zone conversion).
String formatDate(DateTime t) =>
    '${_weekdays[t.weekday - 1]} ${t.day} ${_months[t.month - 1]} ${t.year}';

/// `14:30` from the time fields of [t].
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// `Tue 17 Nov 2026, 14:30`.
String formatDateTime(DateTime t) => '${formatDate(t)}, ${formatClock(t)}';

/// Human description of a play speed in simulated seconds per second.
String formatSpeed(double speed) {
  if (speed == 0) return 'Paused';
  if (speed == 1) return 'Real time';
  if (speed < 3600) return '${(speed / 60).round()} min/s';
  return '${(speed / 3600).round()} h/s';
}

/// Eight-point compass direction of an azimuth in degrees.
String compassPoint(double azDeg) {
  const points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final index = ((azDeg % 360) / 45).round() % 8;
  return points[index];
}

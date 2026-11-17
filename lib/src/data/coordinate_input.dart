/// Parsing of coordinates and UTC offsets typed by a person.
///
/// Every failure is a [FormatException] whose message can be shown to the
/// user as it is.
library;

final _number = RegExp(r'^\d+(\.\d+)?$');

/// Parses a latitude or longitude in degrees.
///
/// Accepts `21.0285`, `-33.87`, `21,03` (comma decimal), `21.03N`,
/// `W 70.4`, `21°01′42.6″N` and `105 51 15 E`. A minus sign and a
/// hemisphere letter cannot be combined.
double parseCoordinate(String input, {required bool latitude}) {
  var text = input.trim().toUpperCase();
  if (text.isEmpty) throw const FormatException('Enter a value');

  final allowed = latitude ? 'NS' : 'EW';
  String? hemisphere;
  if (text.isNotEmpty && 'NSEW'.contains(text[text.length - 1])) {
    hemisphere = text[text.length - 1];
    text = text.substring(0, text.length - 1).trim();
  } else if (text.isNotEmpty && 'NSEW'.contains(text[0])) {
    hemisphere = text[0];
    text = text.substring(1).trim();
  }
  if (hemisphere != null && !allowed.contains(hemisphere)) {
    throw FormatException(
      latitude ? 'Use N or S for latitude' : 'Use E or W for longitude',
    );
  }

  var negative = false;
  if (text.startsWith('-') || text.startsWith('−')) {
    negative = true;
    text = text.substring(1).trim();
  } else if (text.startsWith('+')) {
    text = text.substring(1).trim();
  }
  if (negative && hemisphere != null) {
    throw const FormatException(
      'Use either a minus sign or a hemisphere letter, not both',
    );
  }

  // Degree, minute and second marks (typographic or plain) split the parts.
  final parts = text
      .replaceAll(RegExp('[°º′\'″"]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p.contains('.') ? p : p.replaceAll(',', '.'))
      .toList();
  if (parts.isEmpty || parts.length > 3 || !parts.every(_number.hasMatch)) {
    throw const FormatException('Not a number of degrees');
  }
  final values = parts.map(double.parse).toList();
  if (values.length > 1 && values.skip(1).any((v) => v >= 60)) {
    throw const FormatException('Arc minutes and seconds must be below 60');
  }
  var degrees = values[0];
  if (values.length > 1) degrees += values[1] / 60;
  if (values.length > 2) degrees += values[2] / 3600;
  if (negative || hemisphere == 'S' || hemisphere == 'W') degrees = -degrees;

  final limit = latitude ? 90 : 180;
  if (degrees.abs() > limit) {
    throw FormatException(
      latitude
          ? 'Latitude must be between −90° and 90°'
          : 'Longitude must be between −180° and 180°',
    );
  }
  return degrees;
}

/// Parses a UTC offset such as `7`, `+05:45` or `UTC-3:30`.
Duration parseUtcOffset(String input) {
  var text = input.trim().toUpperCase().replaceAll('−', '-');
  if (text.startsWith('UTC')) text = text.substring(3).trim();
  final match = RegExp(r'^([+-]?)(\d{1,2})(?::(\d{2}))?$').firstMatch(text);
  if (match == null) {
    throw const FormatException('Write the offset as +7 or -3:30');
  }
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3) ?? '0');
  if (minutes >= 60) {
    throw const FormatException('Offset minutes must be below 60');
  }
  final sign = match.group(1) == '-' ? -1 : 1;
  final total = sign * (hours * 60 + minutes);
  if (total < -12 * 60 || total > 14 * 60) {
    throw const FormatException('UTC offset must be between −12 and +14');
  }
  return Duration(minutes: total);
}

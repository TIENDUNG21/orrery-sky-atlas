/// Reader for `ConstellationLines.dat` (M. van der Sluys, CC BY 4.0):
/// each data line is an abbreviation, a star count and that many BSC numbers.
library;

/// Highest HR number in the Bright Star Catalogue.
const int maxHr = 9110;

/// Parses the stick-figure file into polylines of HR numbers per
/// constellation abbreviation. A constellation may span several lines.
///
/// Throws [FormatException] with the line number for a malformed line.
Map<String, List<List<int>>> parseConstellationLines(String text) {
  final result = <String, List<List<int>>>{};
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final fields = line.split(RegExp(r'\s+'));
    final where = 'line ${i + 1}';
    if (fields.length < 2) {
      throw FormatException('$where: expected an abbreviation and a count');
    }
    final abbr = fields[0];
    final count = int.tryParse(fields[1]);
    if (count == null || count < 1) {
      throw FormatException('$where: "${fields[1]}" is not a star count');
    }
    final numbers = fields.skip(2).toList();
    if (numbers.length != count) {
      throw FormatException(
        '$where: expected $count stars, found ${numbers.length}',
      );
    }
    final polyline = <int>[];
    for (final n in numbers) {
      final hr = int.tryParse(n);
      if (hr == null || hr < 1 || hr > maxHr) {
        throw FormatException('$where: "$n" is not an HR number');
      }
      polyline.add(hr);
    }
    result.putIfAbsent(abbr, () => []).add(polyline);
  }
  return result;
}

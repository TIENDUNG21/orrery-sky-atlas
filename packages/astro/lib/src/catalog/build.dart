/// Joins the raw sources into a [SkyCatalog]: Bright Star Catalogue records,
/// the constellation table, stick figures and common star names.
library;

import 'bsc5_parser.dart';
import 'designation.dart';
import 'model.dart';

/// One row of the constellation table.
class ConstellationName {
  /// Creates a row.
  const ConstellationName(this.abbr, this.name, this.genitive);

  /// IAU abbreviation.
  final String abbr;

  /// Latin name.
  final String name;

  /// Latin genitive.
  final String genitive;
}

Iterable<(int, String)> _dataLines(String text) sync* {
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    yield (i + 1, line);
  }
}

/// Parses `abbreviation|name|genitive` lines.
List<ConstellationName> parseConstellationNames(String text) => [
  for (final (number, line) in _dataLines(text))
    switch (line.split('|')) {
      [final a, final n, final g] when a.trim().length == 3 =>
        ConstellationName(a.trim(), n.trim(), g.trim()),
      _ => throw FormatException(
        'line $number: expected "abbreviation|name|genitive"',
      ),
    },
];

final _greekSymbols = {for (final g in GreekLetter.values) g.symbol: g};
final _bayerDesignation = RegExp(r'^(\D+?)(\d?)\s+([A-Za-z]{3})$');
final _flamsteedDesignation = RegExp(r'^(\d+)\s+([A-Za-z]{3})$');
final _hrDesignation = RegExp(r'^HR\s*(\d+)$', caseSensitive: false);

/// Resolves `designation|name` lines to HR numbers.
///
/// A designation is a Bayer letter as a catalogue code or Greek symbol with
/// an optional superscript digit (`alp1 Cen`, `γ Ori`), a Flamsteed number
/// (`61 Cyg`) or `HR n`. Throws [FormatException] with the line number when a
/// designation is malformed, unknown, ambiguous or already named.
Map<int, String> resolveStarNames(String text, List<Bsc5Record> records) {
  final names = <int, String>{};
  for (final (number, line) in _dataLines(text)) {
    final parts = line.split('|');
    if (parts.length != 2 || parts[1].trim().isEmpty) {
      throw FormatException('line $number: expected "designation|name"');
    }
    final designation = parts[0].trim();
    final name = parts[1].trim();
    final matches = _matching(designation, records, number);
    if (matches.isEmpty) {
      throw FormatException('line $number: no star matches "$designation"');
    }
    if (matches.length > 1) {
      final candidates = matches.map((r) => 'HR ${r.hr}').join(', ');
      throw FormatException(
        'line $number: "$designation" is ambiguous ($candidates)',
      );
    }
    final hr = matches.single.hr;
    if (names.containsKey(hr)) {
      throw FormatException('line $number: HR $hr is named twice');
    }
    names[hr] = name;
  }
  return names;
}

List<Bsc5Record> _matching(
  String designation,
  List<Bsc5Record> records,
  int lineNumber,
) {
  final hrMatch = _hrDesignation.firstMatch(designation);
  if (hrMatch != null) {
    final hr = int.parse(hrMatch.group(1)!);
    return records.where((r) => r.hr == hr).toList();
  }
  final f = _flamsteedDesignation.firstMatch(designation);
  if (f != null) {
    final flamsteed = int.parse(f.group(1)!);
    final constellation = f.group(2)!;
    return records
        .where(
          (r) =>
              r.designation.flamsteed == flamsteed &&
              r.designation.constellation == constellation,
        )
        .toList();
  }
  final m = _bayerDesignation.firstMatch(designation);
  if (m == null) {
    throw FormatException('line $lineNumber: cannot read "$designation"');
  }
  final head = m.group(1)!;
  final index = int.tryParse(m.group(2)!);
  final constellation = m.group(3)!;
  final letter = _greekSymbols[head] ?? GreekLetter.fromBscCode(head);
  if (letter == null) {
    throw FormatException('line $lineNumber: "$head" is not a Bayer letter');
  }
  return records
      .where(
        (r) =>
            r.designation.bayer == letter &&
            r.designation.constellation == constellation &&
            (index == null || r.designation.bayerIndex == index),
      )
      .toList();
}

/// Builds the catalogue. Stars are sorted by HR number; constellations keep
/// the order of [constellations]. Throws [FormatException] when a figure
/// belongs to a constellation that is not in the table.
SkyCatalog buildCatalog({
  required List<Bsc5Record> records,
  required List<ConstellationName> constellations,
  required Map<String, List<List<int>>> figures,
  required Map<int, String> names,
}) {
  final known = {for (final c in constellations) c.abbr};
  for (final abbr in figures.keys) {
    if (!known.contains(abbr)) {
      throw FormatException('Figure for unknown constellation "$abbr"');
    }
  }
  final sorted = [...records]..sort((a, b) => a.hr.compareTo(b.hr));
  return SkyCatalog(
    stars: [
      for (final r in sorted)
        Star(
          hr: r.hr,
          raTenthsOfSecond: r.raTenthsOfSecond,
          decArcsec: r.decArcsec,
          pmRaMas: r.pmRaMas,
          pmDecMas: r.pmDecMas,
          vmag: r.vmag,
          bv: r.bv,
          parallaxMas: r.parallaxMas,
          designation: r.designation,
          spectralType: r.spectralType,
          properName: names[r.hr],
        ),
    ],
    constellations: [
      for (final c in constellations)
        ConstellationInfo(
          abbr: c.abbr,
          name: c.name,
          genitive: c.genitive,
          polylines: figures[c.abbr] ?? const [],
        ),
    ],
  );
}

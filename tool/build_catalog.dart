// Converts the raw downloads into the compact asset assets/catalog/sky.bin.
//
// Usage: dart run tool/fetch_data.dart && dart run tool/build_catalog.dart
//
// Inputs (see README "Data & credits"):
//   .cache/downloads/bsc5/ybsc5.gz                 Yale Bright Star Catalogue
//   .cache/downloads/lines/ConstellationLines.dat  stick figures (CC BY 4.0)
//   data/constellations.txt                        IAU names and genitives
//   data/star_names.txt                            common star names

import 'dart:convert';
import 'dart:io';

import 'package:astro/catalog.dart';

void main() {
  final bscLines = utf8
      .decode(
        gzip.decode(File('.cache/downloads/bsc5/ybsc5.gz').readAsBytesSync()),
      )
      .split('\n')
      .where((line) => line.trim().isNotEmpty);
  final records = <Bsc5Record>[];
  var removed = 0;
  for (final line in bscLines) {
    final record = parseBsc5Line(line);
    if (record == null) {
      removed++;
    } else {
      records.add(record);
    }
  }

  final catalog = buildCatalog(
    records: records,
    constellations: parseConstellationNames(
      File('data/constellations.txt').readAsStringSync(),
    ),
    figures: parseConstellationLines(
      File('.cache/downloads/lines/ConstellationLines.dat').readAsStringSync(),
    ),
    names: resolveStarNames(
      File('data/star_names.txt').readAsStringSync(),
      records,
    ),
  );

  final bytes = encodeCatalog(catalog);
  // Round-trip before writing so a broken encoder never ships an asset.
  final check = decodeCatalog(bytes);
  if (check.stars.length != catalog.stars.length) {
    throw StateError('Round trip lost stars');
  }
  final out = File('assets/catalog/sky.bin')
    ..parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes);

  final segments = catalog.constellations.fold<int>(
    0,
    (sum, c) => sum + c.polylines.fold<int>(0, (s, p) => s + p.length - 1),
  );
  final named = catalog.stars.where((s) => s.properName != null).length;
  stdout
    ..writeln(
      'stars:           ${catalog.stars.length} ($removed removed objects skipped)',
    )
    ..writeln('named stars:     $named')
    ..writeln('constellations:  ${catalog.constellations.length}')
    ..writeln('figure segments: $segments')
    ..writeln('wrote ${out.path}: ${bytes.length} bytes');
}

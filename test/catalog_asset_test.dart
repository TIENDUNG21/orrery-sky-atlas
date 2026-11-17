import 'dart:io';

import 'package:astro/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the committed asset produced by tool/build_catalog.dart.
void main() {
  final file = File('assets/catalog/sky.bin');
  final catalog = decodeCatalog(file.readAsBytesSync());

  test('holds every star of the Bright Star Catalogue with a position', () {
    expect(catalog.stars.length, 9096);
    expect(file.lengthSync(), lessThan(1024 * 1024));
  });

  test('Sirius is the brightest star, with its designation and name', () {
    final sirius = catalog.starByHr(2491)!;
    expect(sirius.properName, 'Sirius');
    expect(sirius.vmag, -1.46);
    expect(sirius.designation.short, 'α CMa');
    final brightest = catalog.stars.reduce((a, b) => a.vmag < b.vmag ? a : b);
    expect(brightest.hr, 2491);
  });

  test('Betelgeuse is red and Polaris sits near the pole', () {
    expect(catalog.starByHr(2061)!.bv, greaterThan(1.5));
    final polaris = catalog.stars.firstWhere((s) => s.properName == 'Polaris');
    expect(polaris.j2000.decDeg, greaterThan(89));
  });

  test('all 88 constellations have figures whose stars exist', () {
    expect(catalog.constellations.length, 88);
    for (final c in catalog.constellations) {
      expect(c.polylines, isNotEmpty, reason: c.abbr);
      for (final line in c.polylines) {
        for (final hr in line) {
          expect(catalog.starByHr(hr), isNotNull, reason: '${c.abbr} HR $hr');
        }
      }
    }
  });

  test('every designation refers to a known constellation', () {
    final known = {for (final c in catalog.constellations) c.abbr};
    for (final s in catalog.stars) {
      final abbr = s.designation.constellation;
      if (abbr != null) expect(known, contains(abbr), reason: 'HR ${s.hr}');
    }
  });
}

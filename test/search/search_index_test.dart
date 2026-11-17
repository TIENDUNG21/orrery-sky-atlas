import 'dart:io';

import 'package:astro/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/search/search_index.dart';

void main() {
  final catalog = decodeCatalog(
    File('assets/catalog/sky.bin').readAsBytesSync(),
  );
  final index = SearchIndex.build(catalog);

  String first(String query) => index.search(query).first.id;

  group('normalizeQuery', () {
    test('folds case, accents, combining marks and Greek letters', () {
      expect(normalizeQuery('  Bételgeuse '), 'betelgeuse');
      expect(normalizeQuery('Boötes'), 'bootes');
      expect(normalizeQuery('α¹ Cen'), 'alpha1 cen');
      expect(normalizeQuery('HR2061'), 'hr 2061');
      expect(normalizeQuery('ζ-Ori!'), 'zeta ori');
    });

    test('drops emoji and invisible characters without failing', () {
      expect(normalizeQuery('🌟 Vega​'), 'vega');
      expect(normalizeQuery('🌍🌍'), '');
    });
  });

  test('finds stars by proper name', () {
    expect(first('sirius'), 'hr:2491');
    expect(first('Vega'), 'hr:7001');
  });

  test('finds stars by Bayer designation in several spellings', () {
    for (final q in ['alpha ori', 'alp ori', 'α Ori', 'Alpha Orionis']) {
      expect(first(q), 'hr:2061', reason: q);
    }
    expect(first('alpha1 cen'), 'hr:5459');
  });

  test('finds stars by Flamsteed and HR number', () {
    expect(first('61 cyg'), anyOf('hr:8085', 'hr:8086'));
    expect(first('HR 7001'), 'hr:7001');
    expect(first('hr7001'), 'hr:7001');
  });

  test('constellations, planets, the Sun and the Moon', () {
    expect(first('orion'), 'con:Ori');
    expect(first('canis major'), 'con:CMa');
    expect(first('bootes'), 'con:Boo');
    expect(first('mars'), 'planet:mars');
    expect(first('moon'), 'moon');
    expect(first('sun'), 'sun');
  });

  test('prefix queries rank brighter objects first', () {
    final results = index.search('al');
    expect(results.length, lessThanOrEqualTo(30));
    expect(results.map((r) => r.title), contains('Altair'));
    final magnitudes = results
        .where((r) => r.kind == SearchKind.star)
        .map((r) => r.magnitude)
        .toList();
    final sorted = [...magnitudes]..sort();
    expect(magnitudes.take(3), sorted.take(3));
  });

  test('empty, blank and nonsense queries return nothing', () {
    expect(index.search(''), isEmpty);
    expect(index.search('   '), isEmpty);
    expect(index.search('🌍'), isEmpty);
    expect(index.search('qqqqzzzz'), isEmpty);
  });

  test('results carry a readable subtitle', () {
    final betelgeuse = index.search('betelgeuse').first;
    expect(betelgeuse.title, 'Betelgeuse');
    expect(betelgeuse.subtitle, contains('α Ori'));
    expect(betelgeuse.subtitle, contains('HR 2061'));
  });
}

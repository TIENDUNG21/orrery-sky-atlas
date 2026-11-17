import 'package:astro/catalog.dart';
import 'package:test/test.dart';

Bsc5Record _record(
  int hr, {
  int? flamsteed,
  GreekLetter? bayer,
  int? index,
  String? constellation,
  double vmag = 3,
}) => Bsc5Record(
  hr: hr,
  designation: StarDesignation(
    flamsteed: flamsteed,
    bayer: bayer,
    bayerIndex: index,
    constellation: constellation,
  ),
  raTenthsOfSecond: hr * 10,
  decArcsec: hr,
  vmag: vmag,
  bv: null,
  spectralType: 'A0V',
  pmRaMas: 0,
  pmDecMas: 0,
  parallaxMas: null,
);

final _records = [
  _record(2061, flamsteed: 58, bayer: GreekLetter.alpha, constellation: 'Ori'),
  _record(1790, flamsteed: 24, bayer: GreekLetter.gamma, constellation: 'Ori'),
  _record(5459, bayer: GreekLetter.alpha, index: 1, constellation: 'Cen'),
  _record(5460, bayer: GreekLetter.alpha, index: 2, constellation: 'Cen'),
  _record(8085, flamsteed: 61, constellation: 'Cyg'),
  _record(8086, flamsteed: 61, constellation: 'Cyg'),
  _record(4000),
];

Matcher _failsWith(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  group('resolveStarNames', () {
    test('resolves Bayer, superscripted Bayer and HR designations', () {
      final names = resolveStarNames(
        '# comment\nalp Ori|Betelgeuse\nalp1 Cen|Rigil Kentaurus\n'
        'HR 4000|Test star\nγ Ori|Bellatrix\n',
        _records,
      );
      expect(names, {
        2061: 'Betelgeuse',
        5459: 'Rigil Kentaurus',
        4000: 'Test star',
        1790: 'Bellatrix',
      });
    });

    test('reports ambiguous designations with the candidates', () {
      expect(
        () => resolveStarNames('alp Cen|Alpha Centauri\n', _records),
        _failsWith('ambiguous'),
      );
      expect(
        () => resolveStarNames('61 Cyg|Piazzi\n', _records),
        _failsWith('HR 8085'),
      );
    });

    test('reports unknown stars and malformed lines with line numbers', () {
      expect(
        () => resolveStarNames('\nbet Ori|Rigel\n', _records),
        _failsWith('line 2'),
      );
      expect(
        () => resolveStarNames('just text\n', _records),
        _failsWith('line 1'),
      );
      expect(
        () => resolveStarNames('zzz Ori|Nothing\n', _records),
        _failsWith('zzz'),
      );
    });

    test('rejects the same star named twice', () {
      expect(
        () => resolveStarNames('alp Ori|A\nHR 2061|B\n', _records),
        _failsWith('twice'),
      );
    });
  });

  group('parseConstellationNames', () {
    test('reads abbreviation, name and genitive', () {
      final list = parseConstellationNames('# x\nOri|Orion|Orionis\n');
      expect(list.single.abbr, 'Ori');
      expect(list.single.genitive, 'Orionis');
    });

    test('rejects lines without three fields', () {
      expect(
        () => parseConstellationNames('Ori|Orion\n'),
        _failsWith('line 1'),
      );
    });
  });

  group('buildCatalog', () {
    final constellations = parseConstellationNames(
      'Cen|Centaurus|Centauri\nCyg|Cygnus|Cygni\nOri|Orion|Orionis\n',
    );

    test('joins records, names and figures, sorted by HR', () {
      final catalog = buildCatalog(
        records: _records,
        constellations: constellations,
        figures: {
          'Ori': [
            [2061, 1790],
          ],
          'Cen': [
            [5459, 5460],
          ],
          'Cyg': [
            [8085, 8086],
          ],
        },
        names: {2061: 'Betelgeuse'},
      );
      expect(catalog.stars.map((s) => s.hr), [
        1790,
        2061,
        4000,
        5459,
        5460,
        8085,
        8086,
      ]);
      expect(catalog.starByHr(2061)!.properName, 'Betelgeuse');
      expect(catalog.constellation('Ori')!.name, 'Orion');
      expect(decodeCatalog(encodeCatalog(catalog)).stars.length, 7);
    });

    test('fails when a figure belongs to an unknown constellation', () {
      expect(
        () => buildCatalog(
          records: _records,
          constellations: constellations,
          figures: {
            'Xyz': [
              [2061],
            ],
          },
          names: const {},
        ),
        _failsWith('Xyz'),
      );
    });
  });
}

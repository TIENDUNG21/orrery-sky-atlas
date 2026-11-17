import 'dart:convert';
import 'dart:typed_data';

import 'package:astro/catalog.dart';
import 'package:test/test.dart';

SkyCatalog _sample() => SkyCatalog(
  constellations: const [
    ConstellationInfo(
      abbr: 'CMa',
      name: 'Canis Major',
      genitive: 'Canis Majoris',
      polylines: [
        [2491, 2294],
      ],
    ),
    ConstellationInfo(
      abbr: 'Ori',
      name: 'Orion',
      genitive: 'Orionis',
      polylines: [
        [2061, 1790],
        [1713],
      ],
    ),
  ],
  stars: const [
    Star(
      hr: 2491,
      raTenthsOfSecond: 243089,
      decArcsec: -60178,
      pmRaMas: -553,
      pmDecMas: -1205,
      vmag: -1.46,
      bv: 0.0,
      parallaxMas: 375,
      designation: StarDesignation(
        flamsteed: 9,
        bayer: GreekLetter.alpha,
        constellation: 'CMa',
      ),
      spectralType: 'A1Vm',
      properName: 'Sirius',
    ),
    Star(
      hr: 2294,
      raTenthsOfSecond: 229420,
      decArcsec: -64735,
      pmRaMas: -3,
      pmDecMas: -1,
      vmag: 1.98,
      bv: null,
      parallaxMas: null,
      designation: StarDesignation(
        flamsteed: 2,
        bayer: GreekLetter.beta,
        constellation: 'CMa',
      ),
      spectralType: 'B1II-III',
    ),
    Star(
      hr: 2061,
      raTenthsOfSecond: 211103,
      decArcsec: 26665,
      pmRaMas: 26,
      pmDecMas: 9,
      vmag: 0.5,
      bv: 1.85,
      parallaxMas: 5,
      designation: StarDesignation(
        flamsteed: 58,
        bayer: GreekLetter.alpha,
        constellation: 'Ori',
      ),
      spectralType: 'M1-2Ia-Iab',
      properName: 'Betelgeuse',
    ),
    Star(
      hr: 1790,
      raTenthsOfSecond: 194870,
      decArcsec: 22983,
      pmRaMas: -8,
      pmDecMas: -13,
      vmag: 1.64,
      bv: -0.22,
      parallaxMas: 26,
      designation: StarDesignation(
        flamsteed: 24,
        bayer: GreekLetter.gamma,
        constellation: 'Ori',
      ),
      spectralType: 'B2III',
      properName: 'Bellatrix',
    ),
    Star(
      hr: 1713,
      raTenthsOfSecond: 188178,
      decArcsec: -29525,
      pmRaMas: 0,
      pmDecMas: -1,
      vmag: 0.12,
      bv: -0.03,
      parallaxMas: 13,
      designation: StarDesignation(
        flamsteed: 19,
        bayer: GreekLetter.beta,
        constellation: 'Ori',
      ),
      spectralType: 'B8Ia:',
      properName: 'Rigel',
    ),
  ],
);

void main() {
  test('crc32 of "123456789" is 0xCBF43926', () {
    expect(crc32(ascii.encode('123456789')), 0xCBF43926);
    expect(crc32(const []), 0);
  });

  test('encode then decode reproduces the catalogue exactly', () {
    final original = _sample();
    final decoded = decodeCatalog(encodeCatalog(original));
    expect(decoded.stars.length, 5);
    expect(decoded.constellations.map((c) => c.abbr), ['CMa', 'Ori']);
    final sirius = decoded.starByHr(2491)!;
    expect(sirius.properName, 'Sirius');
    expect(sirius.vmag, -1.46);
    expect(sirius.bv, 0.0);
    expect(sirius.raTenthsOfSecond, 243089);
    expect(sirius.decArcsec, -60178);
    expect(sirius.designation.short, 'α CMa');
    expect(decoded.starByHr(2294)!.bv, isNull);
    expect(decoded.starByHr(2294)!.parallaxMas, isNull);
    expect(decoded.starByHr(2294)!.properName, isNull);
    expect(decoded.constellation('Ori')!.polylines, [
      [2061, 1790],
      [1713],
    ]);
  });

  test('derived J2000 coordinates come from the stored integers', () {
    final sirius = _sample().stars.first;
    expect(sirius.j2000.raDeg, closeTo(243089 / 10 / 240, 1e-12));
    expect(sirius.j2000.decDeg, closeTo(-60178 / 3600, 1e-12));
  });

  group('decodeCatalog rejects damaged data', () {
    late Uint8List good;
    setUp(() => good = encodeCatalog(_sample()));

    Matcher failsWith(String text) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

    test('wrong magic', () {
      final bytes = Uint8List.fromList(good)..[0] = 0x58;
      expect(() => decodeCatalog(bytes), failsWith('magic'));
    });

    test('unsupported version', () {
      final bytes = Uint8List.fromList(good)..[4] = 99;
      expect(() => decodeCatalog(bytes), failsWith('version 99'));
    });

    test('file shorter than a header', () {
      expect(() => decodeCatalog(good.sublist(0, 10)), failsWith('truncated'));
      expect(() => decodeCatalog(Uint8List(0)), failsWith('truncated'));
    });

    test('cut-off file fails the checksum', () {
      expect(
        () => decodeCatalog(good.sublist(0, good.length - 7)),
        failsWith('checksum'),
      );
    });

    test('a single flipped bit fails the checksum', () {
      final bytes = Uint8List.fromList(good);
      bytes[bytes.length ~/ 2] ^= 0x10;
      expect(() => decodeCatalog(bytes), failsWith('checksum'));
    });
  });

  test('encoder refuses lines that name unknown stars', () {
    final bad = SkyCatalog(
      constellations: const [
        ConstellationInfo(
          abbr: 'Ori',
          name: 'Orion',
          genitive: 'Orionis',
          polylines: [
            [2061, 9999],
          ],
        ),
      ],
      stars: _sample().stars,
    );
    expect(() => encodeCatalog(bad), throwsArgumentError);
  });

  group('parseConstellationLines', () {
    test('reads multi-line constellations and skips comments', () {
      const text =
          '# comment\n\nCru   2 4730 4763\nCru   2 4853 4656\n'
          'CMi   2 2943 2845\n';
      final lines = parseConstellationLines(text);
      expect(lines['Cru'], [
        [4730, 4763],
        [4853, 4656],
      ]);
      expect(lines['CMi'], [
        [2943, 2845],
      ]);
    });

    test('reports a count mismatch with the line number', () {
      expect(
        () => parseConstellationLines('# c\nAnt   4 4273 4104 3871\n'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('line 2'), contains('expected 4')),
          ),
        ),
      );
    });

    test('rejects HR numbers outside the catalogue', () {
      expect(
        () => parseConstellationLines('Ant   2 4273 99999\n'),
        throwsFormatException,
      );
    });
  });
}

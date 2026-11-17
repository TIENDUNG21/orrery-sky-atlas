import 'package:astro/catalog.dart';
import 'package:test/test.dart';

// Records copied from the Yale Bright Star Catalogue, 5th ed. (V/50). The
// distributed file trims trailing blanks, so lines are shorter than 197.
const _hr3 =
    '   3 33    PscBD-06 6357     281285721002I         Var?     '
    '000013.0-061601000520.1-054227 93.75-65.93 4.61  +1.04 +0.89 +0.54   '
    'K0IIIbCN-0.5       -0.009+0.089 +.014-006SB1O < 17  2.5   0.0     3*';
const _hr2061 =
    '2061 58Alp OriBD+07 1055  39801113271 224I   4506  Alp Ori  '
    '054945.4+072319055510.3+072425199.79-08.96 0.50  +1.85 +2.06 +1.28   '
    'M1-2Ia-Iab        e+0.026+0.009 +.005+021SB         9.9 174.4AE   6*';
const _hr5459 =
    '5459   Alp1CenCP-60 5483 128620252838 538I W     A          '
    '143248.3-602522143935.9-605007315.78-00.71-0.01  +0.71 +0.24 +0.22E  '
    'G2V                -3.642+0.699 +.751-022SBO        1.4  20.9AB   3*';
const _hr92 =
    '  92 NOVA 1572                                     B Cas'
    '                                                    '
    '                                                                     '
    '                           *';

void main() {
  group('parseBsc5Line', () {
    test('reads a Flamsteed-only star (HR 3, 33 Psc)', () {
      final r = parseBsc5Line(_hr3)!;
      expect(r.hr, 3);
      expect(r.designation.flamsteed, 33);
      expect(r.designation.bayer, isNull);
      expect(r.designation.constellation, 'Psc');
      expect(r.raTenthsOfSecond, 3201); // 0h05m20.1s
      expect(r.decArcsec, -(5 * 3600 + 42 * 60 + 27));
      expect(r.vmag, 4.61);
      expect(r.bv, 1.04);
      expect(r.spectralType, 'K0IIIbCN-0.5');
      expect(r.pmRaMas, -9);
      expect(r.pmDecMas, 89);
      expect(r.parallaxMas, 14);
    });

    test('reads Betelgeuse with Bayer and Flamsteed names (HR 2061)', () {
      final r = parseBsc5Line(_hr2061)!;
      expect(r.designation.flamsteed, 58);
      expect(r.designation.bayer, GreekLetter.alpha);
      expect(r.designation.short, 'α Ori');
      expect(r.vmag, 0.50);
      expect(r.bv, 1.85);
    });

    test('reads superscripted Bayer letters (HR 5459, alpha-1 Cen)', () {
      final r = parseBsc5Line(_hr5459)!;
      expect(r.designation.bayer, GreekLetter.alpha);
      expect(r.designation.bayerIndex, 1);
      expect(r.designation.short, 'α¹ Cen');
      expect(r.decArcsec, -(60 * 3600 + 50 * 60 + 7));
      expect(r.pmRaMas, -3642);
    });

    test('skips objects removed from the catalogue (HR 92, Tycho\'s nova)', () {
      expect(parseBsc5Line(_hr92), isNull);
    });

    test('reports malformed numbers with the HR number and field', () {
      final broken = _hr2061.replaceRange(102, 107, ' x.50');
      expect(
        () => parseBsc5Line(broken),
        throwsA(
          isA<FormatException>()
              .having((e) => e.message, 'message', contains('HR 2061'))
              .having((e) => e.message, 'message', contains('Vmag')),
        ),
      );
    });

    test('rejects a line without an HR number', () {
      expect(() => parseBsc5Line('garbage'), throwsFormatException);
      expect(() => parseBsc5Line(''), throwsFormatException);
    });
  });

  group('StarDesignation', () {
    test('formats Flamsteed-only and empty designations', () {
      expect(
        const StarDesignation(flamsteed: 61, constellation: 'Cyg').short,
        '61 Cyg',
      );
      expect(const StarDesignation().short, '');
    });

    test('Greek letters know their catalogue code, symbol and name', () {
      expect(GreekLetter.fromBscCode('Ome'), GreekLetter.omega);
      expect(GreekLetter.fromBscCode('Xyz'), isNull);
      expect(GreekLetter.mu.symbol, 'μ');
      expect(GreekLetter.omicron.label, 'Omicron');
    });
  });
}

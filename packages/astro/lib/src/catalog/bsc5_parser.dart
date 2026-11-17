/// Reader for the fixed-width records of the Yale Bright Star Catalogue,
/// 5th revised edition (CDS catalogue V/50, file `catalog`).
library;

import 'designation.dart';

/// The fields of one catalogue record that the app uses.
class Bsc5Record {
  /// Creates a record.
  const Bsc5Record({
    required this.hr,
    required this.designation,
    required this.raTenthsOfSecond,
    required this.decArcsec,
    required this.vmag,
    required this.bv,
    required this.spectralType,
    required this.pmRaMas,
    required this.pmDecMas,
    required this.parallaxMas,
  });

  /// Harvard Revised (Bright Star) number.
  final int hr;

  /// Bayer and Flamsteed designation.
  final StarDesignation designation;

  /// J2000 right ascension in tenths of a second of time.
  final int raTenthsOfSecond;

  /// J2000 declination in arcseconds.
  final int decArcsec;

  /// Visual magnitude V.
  final double vmag;

  /// B−V colour index, null when not measured.
  final double? bv;

  /// MK spectral type as printed in the catalogue.
  final String spectralType;

  /// Proper motion in right ascension, μα·cos δ, in milliarcseconds per year.
  final int pmRaMas;

  /// Proper motion in declination in milliarcseconds per year.
  final int pmDecMas;

  /// Trigonometric parallax in milliarcseconds; null when absent or when the
  /// catalogue flags it as dynamical.
  final int? parallaxMas;
}

/// Parses one record (byte columns as in the CDS ReadMe, 1-based).
///
/// Returns null for the 14 objects that were removed from the catalogue and
/// carry no position. Throws [FormatException] naming the HR number and field
/// when a column holds something that is not a number.
Bsc5Record? parseBsc5Line(String line) {
  final padded = line.padRight(197);
  String col(int from, int to) => padded.substring(from - 1, to);

  final hrText = col(1, 4).trim();
  final hr = int.tryParse(hrText);
  if (hr == null || hr < 1) {
    throw FormatException('Not a BSC5 record: HR "$hrText" is not a number');
  }
  if (col(76, 90).trim().isEmpty) return null;

  int intField(String name, int from, int to) {
    final text = col(from, to).trim();
    final value = int.tryParse(text);
    if (value == null) {
      throw FormatException('HR $hr: $name "$text" is not an integer');
    }
    return value;
  }

  double? optionalDouble(String name, int from, int to) {
    final text = col(from, to).trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) {
      throw FormatException('HR $hr: $name "$text" is not a number');
    }
    return value;
  }

  double requiredDouble(String name, int from, int to) {
    final value = optionalDouble(name, from, to);
    if (value == null) throw FormatException('HR $hr: $name is missing');
    return value;
  }

  final raSeconds = requiredDouble('RAs', 80, 83);
  final raTenths =
      (intField('RAh', 76, 77) * 3600 + intField('RAm', 78, 79) * 60) * 10 +
      (raSeconds * 10).round();
  final decAbs =
      intField('DEd', 85, 86) * 3600 +
      intField('DEm', 87, 88) * 60 +
      intField('DEs', 89, 90);
  final decSign = col(84, 84);
  if (decSign != '+' && decSign != '-') {
    throw FormatException('HR $hr: DE- sign "$decSign" is not + or -');
  }

  final parallax = optionalDouble('Parallax', 162, 166);
  final dynamical = col(161, 161) == 'D';

  return Bsc5Record(
    hr: hr,
    designation: StarDesignation(
      flamsteed: int.tryParse(col(5, 7).trim()),
      bayer: GreekLetter.fromBscCode(col(8, 10)),
      bayerIndex: int.tryParse(col(11, 11)),
      constellation: _orNull(col(12, 14).trim()),
    ),
    raTenthsOfSecond: raTenths,
    decArcsec: decSign == '-' ? -decAbs : decAbs,
    vmag: requiredDouble('Vmag', 103, 107),
    bv: optionalDouble('B-V', 110, 114),
    spectralType: col(128, 147).trim(),
    pmRaMas: (requiredDouble('pmRA', 149, 154) * 1000).round(),
    pmDecMas: (requiredDouble('pmDE', 155, 160) * 1000).round(),
    parallaxMas: parallax == null || dynamical
        ? null
        : (parallax * 1000).round(),
  );
}

String? _orNull(String s) => s.isEmpty ? null : s;

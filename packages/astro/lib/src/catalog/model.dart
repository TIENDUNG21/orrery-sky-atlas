/// In-memory star catalogue used by the app.
library;

import '../coords/coordinates.dart';
import 'designation.dart';

/// A star with the catalogue precision kept as integers, so that encoding
/// and decoding are lossless.
class Star {
  /// Creates a star.
  const Star({
    required this.hr,
    required this.raTenthsOfSecond,
    required this.decArcsec,
    required this.pmRaMas,
    required this.pmDecMas,
    required this.vmag,
    required this.bv,
    required this.parallaxMas,
    required this.designation,
    required this.spectralType,
    this.properName,
  });

  /// Harvard Revised (Bright Star) number.
  final int hr;

  /// J2000 right ascension in tenths of a second of time.
  final int raTenthsOfSecond;

  /// J2000 declination in arcseconds.
  final int decArcsec;

  /// Proper motion μα·cos δ in milliarcseconds per year.
  final int pmRaMas;

  /// Proper motion in declination in milliarcseconds per year.
  final int pmDecMas;

  /// Visual magnitude.
  final double vmag;

  /// B−V colour index, or null.
  final double? bv;

  /// Trigonometric parallax in milliarcseconds, or null.
  final int? parallaxMas;

  /// Bayer and Flamsteed designation.
  final StarDesignation designation;

  /// MK spectral type.
  final String spectralType;

  /// Common name, e.g. `Sirius`.
  final String? properName;

  /// J2000.0 position in degrees.
  Equatorial get j2000 =>
      Equatorial(raTenthsOfSecond / 2400.0, decArcsec / 3600.0);

  /// Best display name: proper name, designation or `HR n`.
  String get displayName {
    final name = properName;
    if (name != null) return name;
    final d = designation.short;
    return d.isEmpty ? 'HR $hr' : d;
  }
}

/// One IAU constellation and its stick figure.
class ConstellationInfo {
  /// Creates a constellation.
  const ConstellationInfo({
    required this.abbr,
    required this.name,
    required this.genitive,
    required this.polylines,
  });

  /// Three-letter IAU abbreviation.
  final String abbr;

  /// Latin name, e.g. `Canis Major`.
  final String name;

  /// Latin genitive used in designations, e.g. `Canis Majoris`.
  final String genitive;

  /// Polylines of HR numbers to connect in order.
  final List<List<int>> polylines;
}

/// Stars plus constellations, with lookup by HR number and abbreviation.
class SkyCatalog {
  /// Creates a catalogue and indexes it.
  SkyCatalog({required this.stars, required this.constellations})
    : _byHr = {for (final s in stars) s.hr: s},
      _byAbbr = {for (final c in constellations) c.abbr: c};

  /// All stars, in catalogue order.
  final List<Star> stars;

  /// All constellations, in table order.
  final List<ConstellationInfo> constellations;

  final Map<int, Star> _byHr;
  final Map<String, ConstellationInfo> _byAbbr;

  /// Star with HR number [hr], or null.
  Star? starByHr(int hr) => _byHr[hr];

  /// Constellation with abbreviation [abbr], or null.
  ConstellationInfo? constellation(String abbr) => _byAbbr[abbr];
}

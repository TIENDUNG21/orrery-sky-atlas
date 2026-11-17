/// Bayer and Flamsteed star designations.
library;

/// The 24 Greek letters used in Bayer designations, in alphabet order.
enum GreekLetter {
  /// α
  alpha('Alp', 'α', 'Alpha'),

  /// β
  beta('Bet', 'β', 'Beta'),

  /// γ
  gamma('Gam', 'γ', 'Gamma'),

  /// δ
  delta('Del', 'δ', 'Delta'),

  /// ε
  epsilon('Eps', 'ε', 'Epsilon'),

  /// ζ
  zeta('Zet', 'ζ', 'Zeta'),

  /// η
  eta('Eta', 'η', 'Eta'),

  /// θ
  theta('The', 'θ', 'Theta'),

  /// ι
  iota('Iot', 'ι', 'Iota'),

  /// κ
  kappa('Kap', 'κ', 'Kappa'),

  /// λ
  lambda('Lam', 'λ', 'Lambda'),

  /// μ
  mu('Mu', 'μ', 'Mu'),

  /// ν
  nu('Nu', 'ν', 'Nu'),

  /// ξ
  xi('Xi', 'ξ', 'Xi'),

  /// ο
  omicron('Omi', 'ο', 'Omicron'),

  /// π
  pi('Pi', 'π', 'Pi'),

  /// ρ
  rho('Rho', 'ρ', 'Rho'),

  /// σ
  sigma('Sig', 'σ', 'Sigma'),

  /// τ
  tau('Tau', 'τ', 'Tau'),

  /// υ
  upsilon('Ups', 'υ', 'Upsilon'),

  /// φ
  phi('Phi', 'φ', 'Phi'),

  /// χ
  chi('Chi', 'χ', 'Chi'),

  /// ψ
  psi('Psi', 'ψ', 'Psi'),

  /// ω
  omega('Ome', 'ω', 'Omega');

  const GreekLetter(this.bscCode, this.symbol, this.label);

  /// Three-letter code used by the Bright Star Catalogue, e.g. `Alp`.
  final String bscCode;

  /// The Greek letter itself.
  final String symbol;

  /// English name of the letter.
  final String label;

  /// Letter for a catalogue code such as `Alp` or `Mu`, ignoring case and
  /// surrounding blanks; null when unknown.
  static GreekLetter? fromBscCode(String code) {
    final c = code.trim().toLowerCase();
    for (final letter in values) {
      if (letter.bscCode.toLowerCase() == c) return letter;
    }
    return null;
  }
}

const _superscripts = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];

/// A Bayer and/or Flamsteed designation, e.g. 58 α Ori or α¹ Cen.
class StarDesignation {
  /// Creates a designation; every part is optional.
  const StarDesignation({
    this.flamsteed,
    this.bayer,
    this.bayerIndex,
    this.constellation,
  });

  /// Flamsteed number.
  final int? flamsteed;

  /// Bayer letter.
  final GreekLetter? bayer;

  /// Superscript that separates stars sharing a Bayer letter (α¹, α²).
  final int? bayerIndex;

  /// IAU constellation abbreviation, e.g. `Ori`.
  final String? constellation;

  /// Short form preferring the Bayer letter: `α¹ Cen`, `61 Cyg`, or empty.
  String get short {
    final c = constellation;
    if (c == null) return '';
    final b = bayer;
    if (b != null) {
      final i = bayerIndex;
      return '${b.symbol}${i == null ? '' : _superscripts[i % 10]} $c';
    }
    final f = flamsteed;
    return f == null ? '' : '$f $c';
  }

  @override
  String toString() => short;
}

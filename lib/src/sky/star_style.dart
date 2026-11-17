import 'dart:math' as math;

/// Faintest magnitude drawn for a field of view and the Sun's altitude.
///
/// About 6 for a 90° view under a dark sky, gaining 1.2 magnitudes per
/// halving of the field down to the catalogue limit near 8. Twilight brings
/// the limit up towards −1, where only the brightest objects remain.
double limitingMagnitude(double fovDeg, double sunAltDeg) {
  final dark = (6.0 + 1.2 * math.log(90 / fovDeg) / math.ln2).clamp(4.5, 8.0);
  if (sunAltDeg <= -18) return dark;
  if (sunAltDeg >= 0) return -1.0;
  final t = math.pow((sunAltDeg + 18) / 18, 0.7).toDouble();
  return dark + (-1.0 - dark) * t;
}

/// Disk radius in logical pixels for a magnitude, given the current limit.
double starRadiusPx(double magnitude, double limitingMag) =>
    (0.6 + (limitingMag - magnitude) * 0.7).clamp(0.5, 7.0);

/// Opacity that fades stars near the limiting magnitude.
double starOpacity(double magnitude, double limitingMag) =>
    ((limitingMag - magnitude) / 1.5 + 0.35).clamp(0.25, 1.0);

/// Effective temperature from the B−V colour index (Ballesteros 2012,
/// Europhysics Letters 97, 34008).
double bvToTemperatureK(double bv) =>
    4600 * (1 / (0.92 * bv + 1.7) + 1 / (0.92 * bv + 0.62));

/// Approximate sRGB colour of a black body (fit by T. Helland), as ARGB.
int temperatureToArgb(double kelvin) {
  final t = kelvin / 100;
  double r;
  double g;
  double b;
  if (t <= 66) {
    r = 255;
    g = 99.4708025861 * math.log(t) - 161.1195681661;
  } else {
    r = 329.698727446 * math.pow(t - 60, -0.1332047592);
    g = 288.1221695283 * math.pow(t - 60, -0.0755148492);
  }
  if (t >= 66) {
    b = 255;
  } else if (t <= 19) {
    b = 0;
  } else {
    b = 138.5177312231 * math.log(t - 10) - 305.0447927307;
  }
  int channel(double v) => v.clamp(0, 255).round();
  return 0xFF000000 | channel(r) << 16 | channel(g) << 8 | channel(b);
}

/// Display colour for a star: its black-body colour mixed 35 % towards
/// white, because the eye sees star colours far less saturated than the
/// physics says. Unknown colours are drawn white.
int starColorArgb(double? bv) {
  if (bv == null) return 0xFFF4F4F4;
  final base = temperatureToArgb(bvToTemperatureK(bv.clamp(-0.4, 2.0)));
  int soften(int c) => (c + (255 - c) * 0.35).round();
  final r = soften((base >> 16) & 0xFF);
  final g = soften((base >> 8) & 0xFF);
  final b = soften(base & 0xFF);
  return 0xFF000000 | r << 16 | g << 8 | b;
}

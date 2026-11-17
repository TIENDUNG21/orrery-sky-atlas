/// Difference between Terrestrial Time and Universal Time.
library;

/// ΔT = TT − UT in seconds for a decimal year.
///
/// Polynomial expressions by F. Espenak and J. Meeus (NASA, "Five Millennium
/// Canon of Solar Eclipses", 2006). After 2005 the values are extrapolations;
/// the real ΔT has grown more slowly (about 69 s in 2025 against 74 s here),
/// which moves the Moon by less than 3 arcseconds.
double deltaTSeconds(double year) {
  final y = year;
  if (y < -500) {
    final u = (y - 1820) / 100;
    return -20 + 32 * u * u;
  }
  if (y < 500) {
    final u = y / 100;
    return _poly(u, const [
      10583.6,
      -1014.41,
      33.78311,
      -5.952053,
      -0.1798452,
      0.022174192,
      0.0090316521,
    ]);
  }
  if (y < 1600) {
    final u = (y - 1000) / 100;
    return _poly(u, const [
      1574.2,
      -556.01,
      71.23472,
      0.319781,
      -0.8503463,
      -0.005050998,
      0.0083572073,
    ]);
  }
  if (y < 1700) {
    return _poly(y - 1600, const [120, -0.9808, -0.01532, 1 / 7129]);
  }
  if (y < 1800) {
    return _poly(y - 1700, const [
      8.83,
      0.1603,
      -0.0059285,
      0.00013336,
      -1 / 1174000,
    ]);
  }
  if (y < 1860) {
    return _poly(y - 1800, const [
      13.72,
      -0.332447,
      0.0068612,
      0.0041116,
      -0.00037436,
      0.0000121272,
      -0.0000001699,
      0.000000000875,
    ]);
  }
  if (y < 1900) {
    return _poly(y - 1860, const [
      7.62,
      0.5737,
      -0.251754,
      0.01680668,
      -0.0004473624,
      1 / 233174,
    ]);
  }
  if (y < 1920) {
    return _poly(y - 1900, const [
      -2.79,
      1.494119,
      -0.0598939,
      0.0061966,
      -0.000197,
    ]);
  }
  if (y < 1941) {
    return _poly(y - 1920, const [21.20, 0.84493, -0.076100, 0.0020936]);
  }
  if (y < 1961) {
    return _poly(y - 1950, const [29.07, 0.407, -1 / 233, 1 / 2547]);
  }
  if (y < 1986) {
    return _poly(y - 1975, const [45.45, 1.067, -1 / 260, -1 / 718]);
  }
  if (y < 2005) {
    return _poly(y - 2000, const [
      63.86,
      0.3345,
      -0.060374,
      0.0017275,
      0.000651814,
      0.00002373599,
    ]);
  }
  if (y < 2050) {
    return _poly(y - 2000, const [62.92, 0.32217, 0.005589]);
  }
  final u = (y - 1820) / 100;
  if (y < 2150) {
    return -20 + 32 * u * u - 0.5628 * (2150 - y);
  }
  return -20 + 32 * u * u;
}

double _poly(double x, List<double> coefficients) {
  var result = 0.0;
  for (var i = coefficients.length - 1; i >= 0; i--) {
    result = result * x + coefficients[i];
  }
  return result;
}

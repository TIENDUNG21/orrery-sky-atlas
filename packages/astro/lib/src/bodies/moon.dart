/// Position of the Moon (Meeus chapter 47, a truncation of ELP-2000/82).
library;

import 'dart:math' as math;

import '../coords/coordinates.dart';
import '../coords/nutation.dart';
import '../coords/transforms.dart';
import '../math/angle.dart';
import '../time/julian.dart';

/// Mean arguments of the lunar theory at one instant, in degrees.
class LunarArguments {
  /// Creates the argument set.
  const LunarArguments({
    required this.meanLongitudeDeg,
    required this.elongationDeg,
    required this.sunAnomalyDeg,
    required this.moonAnomalyDeg,
    required this.latitudeArgumentDeg,
    required this.eccentricityFactor,
    required this.a1Deg,
    required this.a2Deg,
    required this.a3Deg,
  });

  /// Moon's mean longitude L′.
  final double meanLongitudeDeg;

  /// Mean elongation of the Moon D.
  final double elongationDeg;

  /// Sun's mean anomaly M.
  final double sunAnomalyDeg;

  /// Moon's mean anomaly M′.
  final double moonAnomalyDeg;

  /// Moon's argument of latitude F.
  final double latitudeArgumentDeg;

  /// Factor E for the decreasing eccentricity of Earth's orbit.
  final double eccentricityFactor;

  /// Venus perturbation argument A1.
  final double a1Deg;

  /// Jupiter perturbation argument A2.
  final double a2Deg;

  /// Flattening-of-Earth argument A3.
  final double a3Deg;
}

/// Sums Σl, Σb (units of 1e-6 degree) and Σr (units of 1e-3 km).
class LunarSums {
  /// Creates the sums.
  const LunarSums(this.longitude, this.latitude, this.distance);

  /// Σl in millionths of a degree.
  final double longitude;

  /// Σb in millionths of a degree.
  final double latitude;

  /// Σr in thousandths of a kilometre.
  final double distance;
}

/// Geocentric position of the Moon.
class MoonPosition {
  /// Creates a Moon position.
  const MoonPosition({
    required this.geometric,
    required this.apparentLongitudeDeg,
    required this.apparent,
    required this.distanceKm,
    required this.parallaxDeg,
  });

  /// Geometric ecliptic coordinates, mean equinox of date.
  final Ecliptic geometric;

  /// Apparent longitude (geometric plus nutation in longitude).
  final double apparentLongitudeDeg;

  /// Apparent geocentric right ascension and declination of date.
  final Equatorial apparent;

  /// Distance between the centres of Earth and Moon in kilometres.
  final double distanceKm;

  /// Equatorial horizontal parallax.
  final double parallaxDeg;
}

/// Mean arguments for a Julian ephemeris day (Meeus 47.1 to 47.6).
LunarArguments lunarArguments(double jdTt) {
  final t = julianCenturies(jdTt);
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t3 * t;
  return LunarArguments(
    meanLongitudeDeg: normalizeDegrees(
      218.3164477 +
          481267.88123421 * t -
          0.0015786 * t2 +
          t3 / 538841 -
          t4 / 65194000,
    ),
    elongationDeg: normalizeDegrees(
      297.8501921 +
          445267.1114034 * t -
          0.0018819 * t2 +
          t3 / 545868 -
          t4 / 113065000,
    ),
    sunAnomalyDeg: normalizeDegrees(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000,
    ),
    moonAnomalyDeg: normalizeDegrees(
      134.9633964 +
          477198.8675055 * t +
          0.0087414 * t2 +
          t3 / 69699 -
          t4 / 14712000,
    ),
    latitudeArgumentDeg: normalizeDegrees(
      93.2720950 +
          483202.0175233 * t -
          0.0036539 * t2 -
          t3 / 3526000 +
          t4 / 863310000,
    ),
    eccentricityFactor: 1 - 0.002516 * t - 0.0000074 * t2,
    a1Deg: normalizeDegrees(119.75 + 131.849 * t),
    a2Deg: normalizeDegrees(53.09 + 479264.290 * t),
    a3Deg: normalizeDegrees(313.45 + 481266.484 * t),
  );
}

/// Periodic sums of tables 47.A and 47.B including the additive terms.
LunarSums lunarSums(double jdTt) {
  final a = lunarArguments(jdTt);
  final d = a.elongationDeg * deg2rad;
  final m = a.sunAnomalyDeg * deg2rad;
  final mp = a.moonAnomalyDeg * deg2rad;
  final f = a.latitudeArgumentDeg * deg2rad;
  final e = a.eccentricityFactor;

  double factor(int mMultiple) => switch (mMultiple.abs()) {
    1 => e,
    2 => e * e,
    _ => 1.0,
  };

  var sl = 0.0;
  var sr = 0.0;
  for (var i = 0; i < _lr.length; i += 6) {
    final arg = _lr[i] * d + _lr[i + 1] * m + _lr[i + 2] * mp + _lr[i + 3] * f;
    final k = factor(_lr[i + 1]);
    sl += _lr[i + 4] * k * math.sin(arg);
    sr += _lr[i + 5] * k * math.cos(arg);
  }
  var sb = 0.0;
  for (var i = 0; i < _b.length; i += 5) {
    final arg = _b[i] * d + _b[i + 1] * m + _b[i + 2] * mp + _b[i + 3] * f;
    sb += _b[i + 4] * factor(_b[i + 1]) * math.sin(arg);
  }

  final lp = a.meanLongitudeDeg * deg2rad;
  final a1 = a.a1Deg * deg2rad;
  final a2 = a.a2Deg * deg2rad;
  final a3 = a.a3Deg * deg2rad;
  sl += 3958 * math.sin(a1) + 1962 * math.sin(lp - f) + 318 * math.sin(a2);
  sb +=
      -2235 * math.sin(lp) +
      382 * math.sin(a3) +
      175 * math.sin(a1 - f) +
      175 * math.sin(a1 + f) +
      127 * math.sin(lp - mp) -
      115 * math.sin(lp + mp);
  return LunarSums(sl, sb, sr);
}

/// The Moon's geocentric position for a Julian ephemeris day. Meeus quotes
/// an accuracy of about 10″ in longitude and 4″ in latitude.
MoonPosition moonPosition(double jdTt) {
  final a = lunarArguments(jdTt);
  final s = lunarSums(jdTt);
  final lambda = normalizeDegrees(a.meanLongitudeDeg + s.longitude / 1e6);
  final beta = s.latitude / 1e6;
  final distance = 385000.56 + s.distance / 1000;
  final n = nutation(jdTt);
  final apparentLambda = normalizeDegrees(lambda + n.deltaPsiDeg);
  return MoonPosition(
    geometric: Ecliptic(lambda, beta),
    apparentLongitudeDeg: apparentLambda,
    apparent: eclipticToEquatorial(
      Ecliptic(apparentLambda, beta),
      n.trueObliquityDeg,
    ),
    distanceKm: distance,
    parallaxDeg: math.asin(6378.14 / distance) * rad2deg,
  );
}

// dart format off
/// Table 47.A: D, M, M′, F, Σl coefficient, Σr coefficient.
const List<int> _lr = [
  0, 0, 1, 0, 6288774, -20905355,
  2, 0, -1, 0, 1274027, -3699111,
  2, 0, 0, 0, 658314, -2955968,
  0, 0, 2, 0, 213618, -569925,
  0, 1, 0, 0, -185116, 48888,
  0, 0, 0, 2, -114332, -3149,
  2, 0, -2, 0, 58793, 246158,
  2, -1, -1, 0, 57066, -152138,
  2, 0, 1, 0, 53322, -170733,
  2, -1, 0, 0, 45758, -204586,
  0, 1, -1, 0, -40923, -129620,
  1, 0, 0, 0, -34720, 108743,
  0, 1, 1, 0, -30383, 104755,
  2, 0, 0, -2, 15327, 10321,
  0, 0, 1, 2, -12528, 0,
  0, 0, 1, -2, 10980, 79661,
  4, 0, -1, 0, 10675, -34782,
  0, 0, 3, 0, 10034, -23210,
  4, 0, -2, 0, 8548, -21636,
  2, 1, -1, 0, -7888, 24208,
  2, 1, 0, 0, -6766, 30824,
  1, 0, -1, 0, -5163, -8379,
  1, 1, 0, 0, 4987, -16675,
  2, -1, 1, 0, 4036, -12831,
  2, 0, 2, 0, 3994, -10445,
  4, 0, 0, 0, 3861, -11650,
  2, 0, -3, 0, 3665, 14403,
  0, 1, -2, 0, -2689, -7003,
  2, 0, -1, 2, -2602, 0,
  2, -1, -2, 0, 2390, 10056,
  1, 0, 1, 0, -2348, 6322,
  2, -2, 0, 0, 2236, -9884,
  0, 1, 2, 0, -2120, 5751,
  0, 2, 0, 0, -2069, 0,
  2, -2, -1, 0, 2048, -4950,
  2, 0, 1, -2, -1773, 4130,
  2, 0, 0, 2, -1595, 0,
  4, -1, -1, 0, 1215, -3958,
  0, 0, 2, 2, -1110, 0,
  3, 0, -1, 0, -892, 3258,
  2, 1, 1, 0, -810, 2616,
  4, -1, -2, 0, 759, -1897,
  0, 2, -1, 0, -713, -2117,
  2, 2, -1, 0, -700, 2354,
  2, 1, -2, 0, 691, 0,
  2, -1, 0, -2, 596, 0,
  4, 0, 1, 0, 549, -1423,
  0, 0, 4, 0, 537, -1117,
  4, -1, 0, 0, 520, -1571,
  1, 0, -2, 0, -487, -1739,
  2, 1, 0, -2, -399, 0,
  0, 0, 2, -2, -381, -4421,
  1, 1, 1, 0, 351, 0,
  3, 0, -2, 0, -340, 0,
  4, 0, -3, 0, 330, 0,
  2, -1, 2, 0, 327, 0,
  0, 2, 1, 0, -323, 1165,
  1, 1, -1, 0, 299, 0,
  2, 0, 3, 0, 294, 0,
  2, 0, -1, -2, 0, 8752,
];

/// Table 47.B: D, M, M′, F, Σb coefficient.
const List<int> _b = [
  0, 0, 0, 1, 5128122,
  0, 0, 1, 1, 280602,
  0, 0, 1, -1, 277693,
  2, 0, 0, -1, 173237,
  2, 0, -1, 1, 55413,
  2, 0, -1, -1, 46271,
  2, 0, 0, 1, 32573,
  0, 0, 2, 1, 17198,
  2, 0, 1, -1, 9266,
  0, 0, 2, -1, 8822,
  2, -1, 0, -1, 8216,
  2, 0, -2, -1, 4324,
  2, 0, 1, 1, 4200,
  2, 1, 0, -1, -3359,
  2, -1, -1, 1, 2463,
  2, -1, 0, 1, 2211,
  2, -1, -1, -1, 2065,
  0, 1, -1, -1, -1870,
  4, 0, -1, -1, 1828,
  0, 1, 0, 1, -1794,
  0, 0, 0, 3, -1749,
  0, 1, -1, 1, -1565,
  1, 0, 0, 1, -1491,
  0, 1, 1, 1, -1475,
  0, 1, 1, -1, -1410,
  0, 1, 0, -1, -1344,
  1, 0, 0, -1, -1335,
  0, 0, 3, 1, 1107,
  4, 0, 0, -1, 1021,
  4, 0, -1, 1, 833,
  0, 0, 1, -3, 777,
  4, 0, -2, 1, 671,
  2, 0, 0, -3, 607,
  2, 0, 2, -1, 596,
  2, -1, 1, -1, 491,
  2, 0, -2, 1, -451,
  0, 0, 3, -1, 439,
  2, 0, 2, 1, 422,
  2, 0, -3, -1, 421,
  2, 1, -1, 1, -366,
  2, 1, 0, 1, -351,
  4, 0, 0, 1, 331,
  2, -1, 1, 1, 315,
  2, -2, 0, -1, 302,
  0, 0, 1, 3, -283,
  2, 1, 1, -1, -229,
  1, 1, 0, -1, 223,
  1, 1, 0, 1, 223,
  0, 1, -2, -1, -220,
  2, 1, -1, -1, -220,
  1, 0, 1, 1, -185,
  2, -1, -2, -1, 181,
  0, 1, 2, 1, -177,
  4, 0, -2, -1, 176,
  4, -1, -1, -1, 166,
  1, 0, 1, -1, -164,
  4, 0, 1, -1, 132,
  1, 0, -1, -1, -119,
  4, -1, 0, -1, 115,
  2, -2, 0, 1, 107,
];
// dart format on

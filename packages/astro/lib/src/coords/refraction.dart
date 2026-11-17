/// Atmospheric refraction (Meeus chapter 16), for 1010 mbar and 10 °C.
library;

import 'dart:math' as math;

import '../math/angle.dart';

/// Refraction in arcminutes for an apparent (observed) altitude, after
/// G. G. Bennett (Meeus 16.3).
double refractionBennettArcmin(double apparentAltDeg) =>
    1.0 / math.tan((apparentAltDeg + 7.31 / (apparentAltDeg + 4.4)) * deg2rad);

/// Refraction in arcminutes for a true (geometric) altitude, after
/// Sæmundsson (Meeus 16.4), with Meeus's constant that makes it zero at the
/// zenith.
double refractionSaemundssonArcmin(double trueAltDeg) =>
    1.02 / math.tan((trueAltDeg + 10.3 / (trueAltDeg + 5.11)) * deg2rad) +
    0.0019279;

/// Altitude as seen through the atmosphere for a true altitude.
///
/// The formula is used down to −1°; below that the correction fades out
/// linearly to zero at −5° so that setting objects move continuously.
double apparentAltitudeDeg(double trueAltDeg) {
  const fullFrom = -1.0;
  const zeroAt = -5.0;
  if (trueAltDeg >= fullFrom) {
    return trueAltDeg + refractionSaemundssonArcmin(trueAltDeg) / 60.0;
  }
  if (trueAltDeg <= zeroAt) return trueAltDeg;
  final weight = (trueAltDeg - zeroAt) / (fullFrom - zeroAt);
  return trueAltDeg + weight * refractionSaemundssonArcmin(fullFrom) / 60.0;
}

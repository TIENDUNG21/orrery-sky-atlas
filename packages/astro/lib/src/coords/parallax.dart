/// Diurnal parallax: the shift between the geocentric and the observed
/// (topocentric) direction, which matters only for the Moon.
library;

import 'dart:math' as math;

import '../math/angle.dart';

/// Topocentric altitude for a geocentric altitude and horizontal parallax.
///
/// Treats the Earth as a sphere: the observer stands one Earth radius from
/// the centre and the body is 1/sin π radii away. The error from ignoring
/// the flattening stays below 0.01° for the Moon.
double topocentricAltitudeDeg(double geocentricAltDeg, double parallaxDeg) {
  final h = geocentricAltDeg * deg2rad;
  final p = math.sin(parallaxDeg * deg2rad);
  return math.atan2(math.sin(h) - p, math.cos(h)) * rad2deg;
}

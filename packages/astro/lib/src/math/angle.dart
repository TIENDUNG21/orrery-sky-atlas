/// Angle helpers shared by every algorithm in the package.
library;

import 'dart:math' as math;

/// Multiply degrees by this to get radians.
const double deg2rad = math.pi / 180.0;

/// Multiply radians by this to get degrees.
const double rad2deg = 180.0 / math.pi;

/// Reduces [degrees] to the range [0, 360).
double normalizeDegrees(double degrees) {
  final r = degrees % 360.0;
  return r < 0 ? r + 360.0 : r;
}

import 'dart:math' as math;

import 'package:astro/astro.dart';

/// Where the observer looks and how wide the view is.
class SkyView {
  const SkyView({
    required this.centerAzDeg,
    required this.centerAltDeg,
    required this.fovDeg,
  });

  /// Azimuth of the view centre, from north through east.
  final double centerAzDeg;

  /// Altitude of the view centre.
  final double centerAltDeg;

  /// Field of view across the shorter side of the screen.
  final double fovDeg;

  SkyView copyWith({
    double? centerAzDeg,
    double? centerAltDeg,
    double? fovDeg,
  }) => SkyView(
    centerAzDeg: centerAzDeg ?? this.centerAzDeg,
    centerAltDeg: centerAltDeg ?? this.centerAltDeg,
    fovDeg: fovDeg ?? this.fovDeg,
  );
}

/// A point on the screen in logical pixels.
class ScreenPoint {
  const ScreenPoint(this.x, this.y);

  final double x;
  final double y;
}

/// The horizon's image: a circle (a great circle stays a circle under a
/// stereographic projection) and on which side of it the ground lies.
class HorizonCircle {
  const HorizonCircle({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.groundInside,
  });

  final double centerX;
  final double centerY;
  final double radius;

  /// True when the ground is the inside of the circle (looking downward).
  final bool groundInside;
}

/// Stereographic projection of east-north-up directions onto the screen,
/// seen from inside the celestial sphere (east is right when facing north).
///
/// The stereographic projection is conformal: constellations keep their
/// shapes even near the edges of a wide view.
class StereographicProjection {
  StereographicProjection(this.view, this.width, this.height) {
    final az = view.centerAzDeg * deg2rad;
    _forward = Horizontal(view.centerAzDeg, view.centerAltDeg).toVector();
    // Right is horizontal and perpendicular to the azimuth, which stays
    // defined even when looking straight up or down.
    _right = Vec3(math.cos(az), -math.sin(az), 0);
    _up = _right.cross(_forward);
    _scale =
        (math.min(width, height) / 2) /
        (2 * math.tan(view.fovDeg * deg2rad / 4));
  }

  final SkyView view;
  final double width;
  final double height;
  late final Vec3 _forward;
  late final Vec3 _right;
  late final Vec3 _up;
  late final double _scale;

  /// Points further than this from the view centre are not projected; their
  /// images would be far off screen and numerically unstable.
  static const double maxAngleDeg = 150;
  static final double _minForward = math.cos(maxAngleDeg * deg2rad);

  /// Screen pixels per radian at the view centre.
  double get pixelsPerRadian => _scale;

  /// Screen pixels per degree at the view centre.
  double get pixelsPerDegree => _scale * deg2rad;

  /// Screen position of a unit direction in the east-north-up frame, or
  /// null when it lies more than [maxAngleDeg] from the view centre.
  ScreenPoint? project(Vec3 enu) {
    final cz = enu.dot(_forward);
    if (cz < _minForward) return null;
    final k = 2 / (1 + cz) * _scale;
    return ScreenPoint(
      width / 2 + enu.dot(_right) * k,
      height / 2 - enu.dot(_up) * k,
    );
  }

  /// Unit direction (east-north-up) under a screen position.
  Vec3 unproject(double x, double y) {
    final px = (x - width / 2) / _scale;
    final py = (height / 2 - y) / _scale;
    final rho2 = px * px + py * py;
    final d = 4 + rho2;
    final cx = 4 * px / d;
    final cy = 4 * py / d;
    final cz = (4 - rho2) / d;
    return _right * cx + _up * cy + _forward * cz;
  }

  /// Image of the horizon. Its centre and radius follow from the pole of the
  /// horizon (the zenith) expressed in camera coordinates.
  HorizonCircle horizon() {
    const zenith = Vec3(0, 0, 1);
    final nx = zenith.dot(_right);
    final ny = zenith.dot(_up);
    var nz = zenith.dot(_forward);
    // Looking exactly at the horizon turns the circle into a line; a tiny
    // offset keeps the radius finite and the drawing indistinguishable.
    if (nz.abs() < 1e-6) nz = nz.isNegative ? -1e-6 : 1e-6;
    return HorizonCircle(
      centerX: width / 2 + 2 * nx / nz * _scale,
      centerY: height / 2 - 2 * ny / nz * _scale,
      radius: 2 / nz.abs() * _scale,
      groundInside: nz < 0,
    );
  }
}

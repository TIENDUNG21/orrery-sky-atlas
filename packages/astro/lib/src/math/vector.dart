/// Small 3-D vector and matrix types for rotations between frames.
library;

import 'dart:math' as math;

import 'angle.dart';

/// An immutable 3-D vector.
class Vec3 {
  /// Creates a vector from its components.
  const Vec3(this.x, this.y, this.z);

  /// Unit vector for a longitude and latitude in degrees, with x toward
  /// longitude 0 and z toward latitude +90°.
  factory Vec3.fromSpherical(double lonDeg, double latDeg) {
    final lon = lonDeg * deg2rad;
    final lat = latDeg * deg2rad;
    final c = math.cos(lat);
    return Vec3(c * math.cos(lon), c * math.sin(lon), math.sin(lat));
  }

  /// X component.
  final double x;

  /// Y component.
  final double y;

  /// Z component.
  final double z;

  /// Longitude in [0, 360) and latitude in [-90, 90] of this direction.
  (double, double) toSpherical() {
    final lon = normalizeDegrees(math.atan2(y, x) * rad2deg);
    final lat = math.atan2(z, math.sqrt(x * x + y * y)) * rad2deg;
    return (lon, lat);
  }

  /// Euclidean length.
  double get length => math.sqrt(x * x + y * y + z * z);

  /// This vector scaled to unit length.
  Vec3 normalized() {
    final l = length;
    return Vec3(x / l, y / l, z / l);
  }

  /// Dot product.
  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  /// Cross product.
  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  /// Sum.
  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);

  /// Difference.
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);

  /// Scalar product.
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// An immutable 3×3 matrix stored row by row.
class Mat3 {
  /// Creates a matrix from nine values in row-major order.
  const Mat3(
    this.m00,
    this.m01,
    this.m02,
    this.m10,
    this.m11,
    this.m12,
    this.m20,
    this.m21,
    this.m22,
  );

  /// Active rotation by [angleRad] about the x axis.
  factory Mat3.rotationX(double angleRad) {
    final c = math.cos(angleRad);
    final s = math.sin(angleRad);
    return Mat3(1, 0, 0, 0, c, -s, 0, s, c);
  }

  /// Active rotation by [angleRad] about the y axis.
  factory Mat3.rotationY(double angleRad) {
    final c = math.cos(angleRad);
    final s = math.sin(angleRad);
    return Mat3(c, 0, s, 0, 1, 0, -s, 0, c);
  }

  /// Active rotation by [angleRad] about the z axis.
  factory Mat3.rotationZ(double angleRad) {
    final c = math.cos(angleRad);
    final s = math.sin(angleRad);
    return Mat3(c, -s, 0, s, c, 0, 0, 0, 1);
  }

  /// The identity matrix.
  static const identity = Mat3(1, 0, 0, 0, 1, 0, 0, 0, 1);

  /// Row 0, column 0.
  final double m00;

  /// Row 0, column 1.
  final double m01;

  /// Row 0, column 2.
  final double m02;

  /// Row 1, column 0.
  final double m10;

  /// Row 1, column 1.
  final double m11;

  /// Row 1, column 2.
  final double m12;

  /// Row 2, column 0.
  final double m20;

  /// Row 2, column 1.
  final double m21;

  /// Row 2, column 2.
  final double m22;

  /// Matrix product `this × o`.
  Mat3 operator *(Mat3 o) => Mat3(
    m00 * o.m00 + m01 * o.m10 + m02 * o.m20,
    m00 * o.m01 + m01 * o.m11 + m02 * o.m21,
    m00 * o.m02 + m01 * o.m12 + m02 * o.m22,
    m10 * o.m00 + m11 * o.m10 + m12 * o.m20,
    m10 * o.m01 + m11 * o.m11 + m12 * o.m21,
    m10 * o.m02 + m11 * o.m12 + m12 * o.m22,
    m20 * o.m00 + m21 * o.m10 + m22 * o.m20,
    m20 * o.m01 + m21 * o.m11 + m22 * o.m21,
    m20 * o.m02 + m21 * o.m12 + m22 * o.m22,
  );

  /// Applies the matrix to a vector.
  Vec3 transform(Vec3 v) => Vec3(
    m00 * v.x + m01 * v.y + m02 * v.z,
    m10 * v.x + m11 * v.y + m12 * v.z,
    m20 * v.x + m21 * v.y + m22 * v.z,
  );

  /// The transpose, which is the inverse for a rotation.
  Mat3 transpose() => Mat3(m00, m10, m20, m01, m11, m21, m02, m12, m22);
}

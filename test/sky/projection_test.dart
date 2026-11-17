import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/sky/projection.dart';

void main() {
  const width = 800.0;
  const height = 600.0;

  StereographicProjection make(double az, double alt, double fov) =>
      StereographicProjection(
        SkyView(centerAzDeg: az, centerAltDeg: alt, fovDeg: fov),
        width,
        height,
      );

  test('the view centre maps to the screen centre', () {
    final p = make(123, 34, 90).project(const Horizontal(123, 34).toVector())!;
    expect(p.x, closeTo(width / 2, 1e-9));
    expect(p.y, closeTo(height / 2, 1e-9));
  });

  test('half the field of view reaches the edge of the short side', () {
    final p = make(0, 0, 90).project(const Horizontal(45, 0).toVector())!;
    expect(p.x, closeTo(width / 2 + height / 2, 1e-9));
    expect(p.y, closeTo(height / 2, 1e-9));
  });

  test('facing north, east is to the right and up is up', () {
    final proj = make(0, 20, 90);
    final east = proj.project(const Horizontal(10, 20).toVector())!;
    final higher = proj.project(const Horizontal(0, 30).toVector())!;
    expect(east.x, greaterThan(width / 2));
    expect(higher.y, lessThan(height / 2));
  });

  test('unproject inverts project (500 seeded points)', () {
    final random = math.Random(11);
    for (var i = 0; i < 500; i++) {
      final proj = make(
        random.nextDouble() * 360,
        random.nextDouble() * 180 - 90,
        5 + random.nextDouble() * 195,
      );
      final az = random.nextDouble() * 360;
      final alt = random.nextDouble() * 180 - 90;
      final v = Horizontal(az, alt).toVector();
      final p = proj.project(v);
      if (p == null) continue;
      final back = proj.unproject(p.x, p.y);
      expect((back - v).length, lessThan(1e-9));
    }
  });

  test('points almost behind the viewer are not projected', () {
    expect(make(0, 0, 90).project(const Horizontal(180, 0).toVector()), isNull);
  });

  test('projected horizon points lie on the horizon circle', () {
    for (final alt in [-60.0, -10.0, 20.0, 60.0, 89.0]) {
      final proj = make(30, alt, 120);
      final circle = proj.horizon();
      for (var az = 0.0; az < 360; az += 5) {
        final p = proj.project(Horizontal(az, 0).toVector());
        if (p == null) continue;
        final d = math.sqrt(
          math.pow(p.x - circle.centerX, 2) + math.pow(p.y - circle.centerY, 2),
        );
        expect(
          d,
          closeTo(circle.radius, circle.radius * 1e-9),
          reason: 'alt $alt az $az',
        );
      }
      expect(circle.groundInside, alt < 0);
    }
  });

  test('zenith and nadir views produce finite coordinates', () {
    for (final alt in [90.0, -90.0]) {
      final proj = make(77, alt, 180);
      final p = proj.project(const Horizontal(200, 45).toVector())!;
      expect(p.x.isFinite && p.y.isFinite, isTrue);
      expect(proj.horizon().radius.isFinite, isTrue);
    }
  });

  test('pixels per degree grow as the field narrows', () {
    expect(
      make(0, 0, 30).pixelsPerDegree,
      greaterThan(make(0, 0, 90).pixelsPerDegree),
    );
  });
}

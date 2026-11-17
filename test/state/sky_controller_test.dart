import 'package:astro/astro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/data/locations.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';
import 'package:orrery_sky_atlas/src/state/sky_controller.dart';

import '../support/fixtures.dart';

void main() {
  final field = StarField(tinyCatalog());
  final now = DateTime.utc(2026, 11, 17, 14, 30);

  SkyController make() => SkyController(field: field, clock: () => now);

  test('starts live at the clock time in Hanoi', () {
    final c = make();
    expect(c.time, now);
    expect(c.isLive, isTrue);
    expect(c.location.name, 'Hanoi');
  });

  test('shifting time leaves live mode and notifies', () {
    final c = make();
    var notified = 0;
    c.addListener(() => notified++);
    c.shiftTime(const Duration(days: 1));
    expect(c.time, now.add(const Duration(days: 1)));
    expect(c.isLive, isFalse);
    expect(notified, 1);
    c.resetToNow();
    expect(c.time, now);
    expect(c.isLive, isTrue);
  });

  test('time is clamped to the range of the planetary elements', () {
    final c = make();
    c.setTime(DateTime.utc(1700));
    expect(c.time, SkyController.minTime);
    c.setTime(DateTime.utc(2100));
    expect(c.time, SkyController.maxTime);
  });

  test('local time-of-day changes keep the local date', () {
    final c = make(); // 21:30 in Hanoi
    c.setLocalMinuteOfDay(5 * 60);
    expect(c.location.localTime(c.time).hour, 5);
    expect(c.location.localTime(c.time).day, 17);
  });

  test('play speed advances time by elapsed real time', () {
    final c = make();
    c.playSpeed = 600;
    c.advance(const Duration(seconds: 2));
    expect(c.time, now.add(const Duration(minutes: 20)));
    expect(c.isLive, isFalse);
  });

  test('panning wraps azimuth and clamps altitude', () {
    final c = make();
    c.lookAt(const Horizontal(350, 80));
    c.pan(20, 30);
    expect(c.view.centerAzDeg, closeTo(10, 1e-9));
    expect(c.view.centerAltDeg, 90);
    c.pan(0, -500);
    expect(c.view.centerAltDeg, -90);
  });

  test('zoom stays within 5° and 200°', () {
    final c = make();
    c.zoomBy(1000);
    expect(c.view.fovDeg, SkyController.minFovDeg);
    c.zoomBy(0.0001);
    expect(c.view.fovDeg, SkyController.maxFovDeg);
  });

  test('the scene is cached until time or place changes', () {
    final c = make();
    final first = c.scene;
    c.pan(5, 0);
    expect(identical(c.scene, first), isTrue);
    c.setLocation(locationPresets[1]);
    expect(identical(c.scene, first), isFalse);
    expect(c.scene.observer.latitudeDeg, locationPresets[1].latitudeDeg);
  });

  test('selection and layers notify listeners', () {
    final c = make();
    var notified = 0;
    c.addListener(() => notified++);
    c.select('hr:2491');
    c.setLayers(c.layers.copyWith(grid: false));
    expect(c.selectedId, 'hr:2491');
    expect(c.layers.grid, isFalse);
    expect(notified, 2);
  });
}

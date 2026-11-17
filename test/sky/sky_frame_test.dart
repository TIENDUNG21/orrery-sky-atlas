import 'dart:io';

import 'package:astro/astro.dart';
import 'package:astro/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/sky/hit_test.dart';
import 'package:orrery_sky_atlas/src/sky/projection.dart';
import 'package:orrery_sky_atlas/src/sky/sky_frame.dart';
import 'package:orrery_sky_atlas/src/sky/sky_scene.dart';

void main() {
  final catalog = decodeCatalog(
    File('assets/catalog/sky.bin').readAsBytesSync(),
  );
  final field = StarField(catalog);
  final hanoi = Observer(latitudeDeg: 21.0285, longitudeDeg: 105.8542);
  // 2026 Dec 15, 21:00 in Hanoi: Orion stands in the east.
  final scene = computeScene(
    field,
    AstroTime.fromDateTime(DateTime.utc(2026, 12, 15, 14)),
    hanoi,
  );
  final betelgeuseIndex = catalog.stars.indexWhere((s) => s.hr == 2061);
  final orion = Horizontal.fromVector(scene.starVector(betelgeuseIndex));
  final view = SkyView(
    centerAzDeg: orion.azDeg,
    centerAltDeg: orion.altDeg,
    fovDeg: 90,
  );
  final frame = layoutFrame(
    scene: scene,
    field: field,
    view: view,
    width: 1000,
    height: 700,
    layers: SkyLayers.all,
  );

  test('Orion is up and Betelgeuse sits at the centre of the frame', () {
    expect(orion.altDeg, greaterThan(15));
    final star = frame.stars.firstWhere((s) => s.index == betelgeuseIndex);
    expect(star.x, closeTo(500, 1));
    expect(star.y, closeTo(350, 1));
  });

  test('only stars within the limiting magnitude and the screen are drawn', () {
    for (final s in frame.stars) {
      expect(catalog.stars[s.index].vmag, lessThanOrEqualTo(frame.limitingMag));
      expect(s.x, inInclusiveRange(-10, 1010));
      expect(s.y, inInclusiveRange(-10, 710));
    }
    expect(frame.stars.length, greaterThan(300));
  });

  test('labels are placed without overlapping each other', () {
    final labels = frame.labels;
    expect(
      labels.map((l) => l.text),
      containsAll(['Betelgeuse', 'Rigel', 'ORION']),
    );
    for (var i = 0; i < labels.length; i++) {
      for (var j = i + 1; j < labels.length; j++) {
        expect(
          labels[i].rect.overlaps(labels[j].rect),
          isFalse,
          reason: '${labels[i].text} / ${labels[j].text}',
        );
      }
    }
  });

  test('constellation segments join visible stars', () {
    expect(frame.segments, isNotEmpty);
    for (final s in frame.segments) {
      expect((s.x2 - s.x1).abs() + (s.y2 - s.y1).abs(), lessThan(1000));
    }
  });

  test('hiding layers removes their geometry', () {
    final bare = layoutFrame(
      scene: scene,
      field: field,
      view: view,
      width: 1000,
      height: 700,
      layers: const SkyLayers(
        constellationLines: false,
        constellationNames: false,
        labels: false,
        grid: false,
        ground: false,
      ),
    );
    expect(bare.segments, isEmpty);
    expect(bare.labels, isEmpty);
    expect(bare.stars.length, frame.stars.length);
  });

  test('hit candidates cover the drawn stars and bodies', () {
    final candidates = frame.hitCandidates.toList();
    expect(
      candidates.where((c) => c.rank == HitRank.star).length,
      frame.stars.length,
    );
    expect(pickObject(candidates, 500, 350), starId(2061));
  });

  test('with the ground shown, star and constellation names stay above it', () {
    final low = layoutFrame(
      scene: scene,
      field: field,
      view: SkyView(centerAzDeg: orion.azDeg, centerAltDeg: 0, fovDeg: 120),
      width: 1000,
      height: 700,
      layers: SkyLayers.all,
    );
    for (final l in low.labels) {
      if (l.kind != LabelKind.constellation && l.kind != LabelKind.star) {
        continue;
      }
      final anchor = l.kind == LabelKind.star
          ? low.projection.unproject(l.rect.left - 4, l.rect.bottom - 7)
          : low.projection.unproject(
              (l.rect.left + l.rect.right) / 2,
              (l.rect.top + l.rect.bottom) / 2,
            );
      expect(anchor.z, greaterThan(-0.05), reason: l.text);
    }
  });
}

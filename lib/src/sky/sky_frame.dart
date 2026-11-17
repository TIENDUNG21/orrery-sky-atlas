import 'dart:math' as math;

import 'package:astro/astro.dart';

import 'hit_test.dart';
import 'projection.dart';
import 'sky_scene.dart';
import 'star_style.dart';

/// Which optional layers are drawn.
class SkyLayers {
  const SkyLayers({
    required this.constellationLines,
    required this.constellationNames,
    required this.labels,
    required this.grid,
    required this.ground,
  });

  static const all = SkyLayers(
    constellationLines: true,
    constellationNames: true,
    labels: true,
    grid: true,
    ground: true,
  );

  final bool constellationLines;
  final bool constellationNames;
  final bool labels;
  final bool grid;
  final bool ground;

  SkyLayers copyWith({
    bool? constellationLines,
    bool? constellationNames,
    bool? labels,
    bool? grid,
    bool? ground,
  }) => SkyLayers(
    constellationLines: constellationLines ?? this.constellationLines,
    constellationNames: constellationNames ?? this.constellationNames,
    labels: labels ?? this.labels,
    grid: grid ?? this.grid,
    ground: ground ?? this.ground,
  );

  @override
  bool operator ==(Object other) =>
      other is SkyLayers &&
      other.constellationLines == constellationLines &&
      other.constellationNames == constellationNames &&
      other.labels == labels &&
      other.grid == grid &&
      other.ground == ground;

  @override
  int get hashCode =>
      Object.hash(constellationLines, constellationNames, labels, grid, ground);
}

/// An axis-aligned box in screen pixels.
class Box {
  const Box(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool overlaps(Box o) =>
      left < o.right && o.left < right && top < o.bottom && o.top < bottom;
}

class ProjectedStar {
  const ProjectedStar(
    this.index,
    this.x,
    this.y,
    this.radius,
    this.opacity,
    this.color,
  );

  final int index;
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final int color;
}

class ProjectedBody {
  const ProjectedBody(this.body, this.x, this.y, this.radius);

  final BodyState body;
  final double x;
  final double y;
  final double radius;
}

class Segment {
  const Segment(this.x1, this.y1, this.x2, this.y2);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

enum LabelKind { body, compass, constellation, star }

class PlacedLabel {
  const PlacedLabel(this.text, this.kind, this.rect);

  final String text;
  final LabelKind kind;
  final Box rect;
}

/// Everything the painter draws for one view, already projected. Kept free
/// of Flutter types so that it can be tested without rendering.
class SkyFrame {
  const SkyFrame({
    required this.projection,
    required this.field,
    required this.limitingMag,
    required this.stars,
    required this.bodies,
    required this.segments,
    required this.labels,
  });

  final StereographicProjection projection;
  final StarField field;
  final double limitingMag;
  final List<ProjectedStar> stars;
  final List<ProjectedBody> bodies;
  final List<Segment> segments;
  final List<PlacedLabel> labels;

  /// Every drawn object as a tap target.
  Iterable<HitCandidate> get hitCandidates sync* {
    for (final b in bodies) {
      yield HitCandidate(b.body.id, b.x, b.y, HitRank.body, b.body.magnitude);
    }
    for (final s in stars) {
      final star = field.catalog.stars[s.index];
      yield HitCandidate(starId(star.hr), s.x, s.y, HitRank.star, star.vmag);
    }
  }
}

/// Approximate text sizes; the painter uses 11-12 px labels.
const double _labelHeight = 14;
double _labelWidth(String text, LabelKind kind) =>
    text.length * (kind == LabelKind.constellation ? 7.6 : 6.6) + 2;

/// Projects the scene for [view] on a [width] × [height] screen.
SkyFrame layoutFrame({
  required SkyScene scene,
  required StarField field,
  required SkyView view,
  required double width,
  required double height,
  required SkyLayers layers,
}) {
  final projection = StereographicProjection(view, width, height);
  final sunAlt = scene.body('sun').horizontal.altDeg;
  final lim = limitingMagnitude(view.fovDeg, sunAlt);
  final stars = field.catalog.stars;

  bool onScreen(double x, double y, double margin) =>
      x >= -margin &&
      x <= width + margin &&
      y >= -margin &&
      y <= height + margin;

  final projectedStars = <ProjectedStar>[];
  final positions = <int, ScreenPoint>{};
  for (var i = 0; i < stars.length; i++) {
    final vmag = stars[i].vmag;
    if (vmag > lim) continue;
    final p = projection.project(scene.starVector(i));
    if (p == null) continue;
    final r = starRadiusPx(vmag, lim);
    if (!onScreen(p.x, p.y, r)) continue;
    positions[i] = p;
    projectedStars.add(
      ProjectedStar(i, p.x, p.y, r, starOpacity(vmag, lim), field.colors[i]),
    );
  }

  final pxPerDeg = projection.pixelsPerDegree;
  final bodies = <ProjectedBody>[];
  for (final b in scene.bodies) {
    final p = projection.project(b.enu);
    if (p == null) continue;
    final double radius = switch (b.kind) {
      BodyKind.sun => math.max(7.0, b.angularDiameterDeg / 2 * pxPerDeg),
      BodyKind.moon => math.max(8.0, b.angularDiameterDeg / 2 * pxPerDeg),
      BodyKind.planet =>
        (starRadiusPx(b.magnitude, math.max(lim, 6)) + 0.6)
            .clamp(2.5, 6.5)
            .toDouble(),
    };
    if (!onScreen(p.x, p.y, radius)) continue;
    bodies.add(ProjectedBody(b, p.x, p.y, radius));
  }

  final segments = <Segment>[];
  if (layers.constellationLines) {
    final maxLength = 0.7 * math.max(width, height);
    for (final c in field.catalog.constellations) {
      for (final line in c.polylines) {
        ScreenPoint? previous;
        for (final hr in line) {
          final index = field.indexOfHr(hr);
          final p = index == null
              ? null
              : positions[index] ?? projection.project(scene.starVector(index));
          if (p != null && previous != null) {
            final dx = p.x - previous.x;
            final dy = p.y - previous.y;
            final bothOff =
                (p.x < 0 && previous.x < 0) ||
                (p.x > width && previous.x > width) ||
                (p.y < 0 && previous.y < 0) ||
                (p.y > height && previous.y > height);
            if (!bothOff && math.sqrt(dx * dx + dy * dy) < maxLength) {
              segments.add(Segment(previous.x, previous.y, p.x, p.y));
            }
          }
          previous = p;
        }
      }
    }
  }

  final labels = <PlacedLabel>[];
  bool place(String text, LabelKind kind, double left, double top) {
    final box = Box(
      left,
      top,
      left + _labelWidth(text, kind),
      top + _labelHeight,
    );
    if (box.right < 0 ||
        box.left > width ||
        box.bottom < 0 ||
        box.top > height) {
      return false;
    }
    for (final l in labels) {
      if (l.rect.overlaps(box)) return false;
    }
    labels.add(PlacedLabel(text, kind, box));
    return true;
  }

  if (layers.labels) {
    for (final b in bodies) {
      place(b.body.name, LabelKind.body, b.x + b.radius + 4, b.y - 7);
    }
  }
  if (layers.grid || layers.ground) {
    const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    for (var i = 0; i < names.length; i++) {
      final p = projection.project(Horizontal(i * 45.0, 0.6).toVector());
      if (p == null) continue;
      final w = _labelWidth(names[i], LabelKind.compass);
      place(names[i], LabelKind.compass, p.x - w / 2, p.y - _labelHeight - 2);
    }
  }
  if (layers.constellationNames) {
    for (final (c, centroid) in field.centroids) {
      final enu = scene.enuOfJ2000(centroid);
      if (layers.ground && enu.z < 0) continue;
      final p = projection.project(enu);
      if (p == null) continue;
      final text = c.name.toUpperCase();
      final w = _labelWidth(text, LabelKind.constellation);
      place(text, LabelKind.constellation, p.x - w / 2, p.y - _labelHeight / 2);
    }
  }
  if (layers.labels) {
    final labelLimit = math.min(
      lim - 3.0,
      2.0 + 1.2 * math.log(90 / view.fovDeg) / math.ln2,
    );
    final candidates =
        projectedStars
            .where(
              (s) =>
                  stars[s.index].properName != null &&
                  stars[s.index].vmag <= labelLimit &&
                  !(layers.ground && scene.starVector(s.index).z < 0),
            )
            .toList()
          ..sort((a, b) => stars[a.index].vmag.compareTo(stars[b.index].vmag));
    for (final s in candidates) {
      place(
        stars[s.index].properName!,
        LabelKind.star,
        s.x + s.radius + 3,
        s.y - 7,
      );
    }
  }

  return SkyFrame(
    projection: projection,
    field: field,
    limitingMag: lim,
    stars: projectedStars,
    bodies: bodies,
    segments: segments,
    labels: labels,
  );
}

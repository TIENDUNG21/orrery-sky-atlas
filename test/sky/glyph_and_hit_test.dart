import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:orrery_sky_atlas/src/sky/hit_test.dart';
import 'package:orrery_sky_atlas/src/sky/moon_glyph.dart';

double _area(List<(double, double)> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final (x1, y1) = polygon[i];
    final (x2, y2) = polygon[(i + 1) % polygon.length];
    sum += x1 * y2 - x2 * y1;
  }
  return sum.abs() / 2;
}

void main() {
  group('moonLitPolygon', () {
    test('lit area equals the illuminated fraction of the disk', () {
      for (final k in [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]) {
        final polygon = moonLitPolygon(k, samples: 64);
        expect(_area(polygon) / math.pi, closeTo(k, 0.01), reason: 'k = $k');
      }
    });

    test('the lit side faces +x (the bright limb)', () {
      final crescent = moonLitPolygon(0.2, samples: 32);
      final meanX =
          crescent.map((p) => p.$1).reduce((a, b) => a + b) / crescent.length;
      expect(meanX, greaterThan(0));
    });

    test('fractions outside 0..1 are clamped', () {
      expect(
        _area(moonLitPolygon(1.4, samples: 64)) / math.pi,
        closeTo(1, 0.01),
      );
      expect(_area(moonLitPolygon(-0.2, samples: 64)), closeTo(0, 1e-9));
    });
  });

  group('pickObject', () {
    test('returns null when nothing is within reach', () {
      expect(
        pickObject(
          const [HitCandidate('hr:1', 100, 100, HitRank.star, 4)],
          0,
          0,
        ),
        isNull,
      );
    });

    test('a planet wins over a star at the same distance', () {
      const candidates = [
        HitCandidate('hr:1', 10, 0, HitRank.star, 1),
        HitCandidate('planet:mars', -10, 0, HitRank.body, 1),
      ];
      expect(pickObject(candidates, 0, 0), 'planet:mars');
    });

    test('a star right under the finger beats a distant planet', () {
      const candidates = [
        HitCandidate('hr:1', 1, 0, HitRank.star, 2),
        HitCandidate('planet:mars', 20, 0, HitRank.body, 1),
      ];
      expect(pickObject(candidates, 0, 0), 'hr:1');
    });

    test('brighter stars win ties', () {
      const candidates = [
        HitCandidate('hr:1', 5, 0, HitRank.star, 5),
        HitCandidate('hr:2', -5, 0, HitRank.star, 0.5),
      ];
      expect(pickObject(candidates, 0, 0), 'hr:2');
    });
  });
}

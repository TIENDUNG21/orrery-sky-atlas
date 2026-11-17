import 'dart:math' as math;

/// How eager an object is to be picked by a tap.
enum HitRank {
  /// Sun, Moon and planets.
  body(0),

  /// Stars.
  star(6);

  const HitRank(this.penaltyPx);

  /// Extra distance charged when competing with other candidates.
  final double penaltyPx;
}

/// An object drawn at a screen position.
class HitCandidate {
  const HitCandidate(this.id, this.x, this.y, this.rank, this.magnitude);

  final String id;
  final double x;
  final double y;
  final HitRank rank;
  final double magnitude;
}

/// The object a tap at ([x], [y]) most likely meant, or null.
///
/// Candidates within [radiusPx] compete on distance plus a penalty for
/// stars and for faintness, so a planet beside a faint star wins but a star
/// directly under the finger still beats a planet further away.
String? pickObject(
  Iterable<HitCandidate> candidates,
  double x,
  double y, {
  double radiusPx = 24,
}) {
  String? best;
  var bestScore = double.infinity;
  for (final c in candidates) {
    final d = math.sqrt((c.x - x) * (c.x - x) + (c.y - y) * (c.y - y));
    if (d > radiusPx) continue;
    final score = d + c.rank.penaltyPx + math.max(0, c.magnitude) * 0.8;
    if (score < bestScore) {
      bestScore = score;
      best = c.id;
    }
  }
  return best;
}

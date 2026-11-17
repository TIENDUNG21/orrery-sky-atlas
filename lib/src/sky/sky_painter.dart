import 'dart:math' as math;

import 'package:astro/astro.dart';
import 'package:flutter/rendering.dart';

import 'moon_glyph.dart';
import 'projection.dart';
import 'sky_frame.dart';
import 'sky_scene.dart';

/// Colours of the sky view; night mode is applied on top as a filter.
abstract final class SkyColors {
  static const night = Color(0xFF0A0A0A);
  static const text = Color(0xFFEDEDED);
  static const accent = Color(0xFFE3B341);
  static const ground = Color(0xFF14110C);
  static const moonDark = Color(0xFF2A2926);
  static const moonLit = Color(0xFFECE6D6);
  static const sun = Color(0xFFFFD27A);

  static const planets = {
    Planet.mercury: Color(0xFFBDB5AC),
    Planet.venus: Color(0xFFF6EBCF),
    Planet.mars: Color(0xFFE5865A),
    Planet.jupiter: Color(0xFFEBD3AA),
    Planet.saturn: Color(0xFFE6CD8F),
    Planet.uranus: Color(0xFFA3D9E0),
    Planet.neptune: Color(0xFF86A6F2),
  };
}

/// Background colour for the Sun's altitude: black night, deep blue
/// twilight, daylight blue.
Color skyBackground(double sunAltDeg) {
  const stops = <(double, Color)>[
    (-18, SkyColors.night),
    (-12, Color(0xFF0B1320)),
    (-6, Color(0xFF14263D)),
    (0, Color(0xFF2B4D73)),
    (8, Color(0xFF3E6E9C)),
  ];
  if (sunAltDeg <= stops.first.$1) return stops.first.$2;
  for (var i = 1; i < stops.length; i++) {
    if (sunAltDeg <= stops[i].$1) {
      final (a0, c0) = stops[i - 1];
      final (a1, c1) = stops[i];
      return Color.lerp(c0, c1, (sunAltDeg - a0) / (a1 - a0))!;
    }
  }
  return stops.last.$2;
}

/// Paints one [SkyFrame].
class SkyPainter extends CustomPainter {
  SkyPainter({
    required this.scene,
    required this.frame,
    required this.layers,
    this.selectedId,
  });

  final SkyScene scene;
  final SkyFrame frame;
  final SkyLayers layers;
  final String? selectedId;

  static final Map<String, TextPainter> _textCache = {};

  StereographicProjection get _projection => frame.projection;

  @override
  void paint(Canvas canvas, Size size) {
    final sunAlt = scene.body('sun').horizontal.altDeg;
    canvas.drawRect(Offset.zero & size, Paint()..color = skyBackground(sunAlt));
    if (layers.grid) _paintGrid(canvas, size);
    _paintSegments(canvas);
    _paintStars(canvas);
    _paintBodies(canvas);
    if (layers.ground) _paintGround(canvas, size);
    _paintLabels(canvas);
    _paintSelection(canvas);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SkyColors.text.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var alt = 15.0; alt < 90; alt += 15) {
      _polyline(canvas, paint, size, [
        for (var az = 0.0; az <= 360; az += 2) Horizontal(az, alt),
      ]);
    }
    for (var az = 0.0; az < 360; az += 30) {
      _polyline(canvas, paint, size, [
        for (var alt = 0.0; alt <= 76; alt += 2) Horizontal(az, alt),
      ]);
    }
  }

  void _polyline(Canvas canvas, Paint paint, Size size, List<Horizontal> pts) {
    final path = Path();
    ScreenPoint? previous;
    final maxJump = math.max(size.width, size.height);
    for (final h in pts) {
      final p = _projection.project(h.toVector());
      if (p == null) {
        previous = null;
        continue;
      }
      if (previous == null ||
          (p.x - previous.x).abs() + (p.y - previous.y).abs() > maxJump) {
        path.moveTo(p.x, p.y);
      } else {
        path.lineTo(p.x, p.y);
      }
      previous = p;
    }
    canvas.drawPath(path, paint);
  }

  void _paintSegments(Canvas canvas) {
    if (frame.segments.isEmpty) return;
    final paint = Paint()
      ..color = SkyColors.accent.withValues(alpha: 0.34)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (final s in frame.segments) {
      canvas.drawLine(Offset(s.x1, s.y1), Offset(s.x2, s.y2), paint);
    }
  }

  void _paintStars(Canvas canvas) {
    final paint = Paint();
    final glow = Paint();
    for (final s in frame.stars) {
      final color = Color(s.color);
      if (s.radius > 3.5) {
        glow.color = color.withValues(alpha: 0.12 * s.opacity);
        canvas.drawCircle(Offset(s.x, s.y), s.radius * 2.4, glow);
      }
      paint.color = color.withValues(alpha: s.opacity);
      canvas.drawCircle(Offset(s.x, s.y), s.radius, paint);
    }
  }

  void _paintBodies(Canvas canvas) {
    for (final b in frame.bodies) {
      final center = Offset(b.x, b.y);
      switch (b.body.kind) {
        case BodyKind.sun:
          canvas.drawCircle(
            center,
            b.radius * 4,
            Paint()
              ..shader =
                  RadialGradient(
                    colors: [
                      SkyColors.sun.withValues(alpha: 0.45),
                      SkyColors.sun.withValues(alpha: 0),
                    ],
                  ).createShader(
                    Rect.fromCircle(center: center, radius: b.radius * 4),
                  ),
          );
          canvas.drawCircle(center, b.radius, Paint()..color = SkyColors.sun);
        case BodyKind.moon:
          _paintMoon(canvas, center, b.radius);
        case BodyKind.planet:
          final color = SkyColors.planets[b.body.planet] ?? SkyColors.text;
          canvas.drawCircle(
            center,
            b.radius + 2.5,
            Paint()
              ..color = color.withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          canvas.drawCircle(center, b.radius, Paint()..color = color);
      }
    }
  }

  void _paintMoon(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = SkyColors.moonDark);
    // Direction of the bright limb on screen: step from the Moon towards
    // position angle χ on the sky and project both points.
    final moon = scene.moon.apparent;
    final chi = scene.moonBrightLimbDeg * deg2rad;
    const step = 0.5;
    final cosDec = math.max(math.cos(moon.decDeg * deg2rad), 1e-6);
    final towards = Equatorial(
      normalizeDegrees(moon.raDeg + step * math.sin(chi) / cosDec),
      (moon.decDeg + step * math.cos(chi)).clamp(-90.0, 90.0),
    );
    final a = _projection.project(scene.enuOfDate(moon));
    final b = _projection.project(scene.enuOfDate(towards));
    final angle = a == null || b == null
        ? 0.0
        : math.atan2(b.y - a.y, b.x - a.x);
    final polygon = moonLitPolygon(scene.moonPhase.illuminatedFraction);
    final c = math.cos(angle);
    final s = math.sin(angle);
    final path = Path();
    for (var i = 0; i < polygon.length; i++) {
      final (x, y) = polygon[i];
      // Polygon y points up; the screen's y points down.
      final px = center.dx + radius * (x * c + y * s);
      final py = center.dy + radius * (x * s - y * c);
      i == 0 ? path.moveTo(px, py) : path.lineTo(px, py);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = SkyColors.moonLit);
  }

  void _paintGround(Canvas canvas, Size size) {
    final h = _projection.horizon();
    final groundPaint = Paint()
      ..color = SkyColors.ground.withValues(alpha: 0.9);
    final linePaint = Paint()
      ..color = SkyColors.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    if (h.radius < 200 * diagonal) {
      final circle = Rect.fromCircle(
        center: Offset(h.centerX, h.centerY),
        radius: h.radius,
      );
      final ground = h.groundInside
          ? (Path()..addOval(circle))
          : (Path()
              ..fillType = PathFillType.evenOdd
              ..addRect(Offset.zero & size)
              ..addOval(circle));
      canvas.drawPath(ground, groundPaint);
      canvas.drawOval(circle, linePaint);
      return;
    }
    // A huge circle is a straight line on screen: draw a half plane.
    final toCenter = Offset(
      h.centerX - size.width / 2,
      h.centerY - size.height / 2,
    );
    final normal = toCenter / toCenter.distance;
    final nearest = Offset(h.centerX, h.centerY) - normal * h.radius;
    canvas.save();
    canvas.translate(nearest.dx, nearest.dy);
    canvas.rotate(math.atan2(normal.dy, normal.dx) - math.pi / 2);
    final big = diagonal * 2;
    canvas.drawRect(
      h.groundInside
          ? Rect.fromLTRB(-big, 0, big, big)
          : Rect.fromLTRB(-big, -big, big, 0),
      groundPaint,
    );
    canvas.drawLine(Offset(-big, 0), Offset(big, 0), linePaint);
    canvas.restore();
  }

  void _paintLabels(Canvas canvas) {
    if (_textCache.length > 600) _textCache.clear();
    for (final l in frame.labels) {
      final painter = _textCache.putIfAbsent('${l.kind.name}|${l.text}', () {
        final style = switch (l.kind) {
          LabelKind.body => const TextStyle(
            color: SkyColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          LabelKind.compass => TextStyle(
            color: l.text == 'N'
                ? SkyColors.accent
                : SkyColors.text.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          LabelKind.constellation => TextStyle(
            color: SkyColors.accent.withValues(alpha: 0.6),
            fontSize: 10.5,
            letterSpacing: 1.4,
          ),
          LabelKind.star => TextStyle(
            color: SkyColors.text.withValues(alpha: 0.72),
            fontSize: 11,
          ),
        };
        return TextPainter(
          text: TextSpan(text: l.text, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
      });
      final dy = (l.rect.bottom - l.rect.top - painter.height) / 2;
      final dx =
          l.kind == LabelKind.constellation || l.kind == LabelKind.compass
          ? (l.rect.right - l.rect.left - painter.width) / 2
          : 0.0;
      painter.paint(canvas, Offset(l.rect.left + dx, l.rect.top + dy));
    }
  }

  void _paintSelection(Canvas canvas) {
    final id = selectedId;
    if (id == null) return;
    ScreenPoint? point;
    var radius = 4.0;
    for (final b in frame.bodies) {
      if (b.body.id == id) {
        point = ScreenPoint(b.x, b.y);
        radius = b.radius;
      }
    }
    final hr = hrFromId(id);
    if (point == null && hr != null) {
      final index = frame.field.indexOfHr(hr);
      if (index != null) point = _projection.project(scene.starVector(index));
    }
    if (point == null) return;
    final paint = Paint()
      ..color = SkyColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = math.max(radius + 6, 10.0);
    final c = Offset(point.x, point.y);
    canvas.drawCircle(c, r, paint);
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      canvas.drawLine(c + d * (r + 3), c + d * (r + 9), paint);
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.frame != frame ||
      old.scene != scene ||
      old.layers != layers ||
      old.selectedId != selectedId;
}

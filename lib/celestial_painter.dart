import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:celestial_chronometer/models/planet_data.dart';

class CelestialPainter extends CustomPainter {
  final double elapsedMilliseconds;
  final List<PlanetData> planets;
  final double rotationX;
  final double rotationY;

  CelestialPainter({
    required this.elapsedMilliseconds,
    required this.planets,
    this.rotationX = math.pi / 2,
    this.rotationY = 0.0,
  });

  
  static const double planetTrackStrokeWidth = 1;

  final Paint sunPaint = Paint()
    ..color = Color(0xFFb9db0d).withValues(alpha: 0.7)
    ..style = PaintingStyle.fill;

  final Paint orbitPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = planetTrackStrokeWidth;

  final Paint planetPaint = Paint()
    ..style = PaintingStyle.fill;

  final Paint trailPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;


  static const List<Color> _planetColors = [
    Color(0xFFFFE090), // warm gold — innermost, hottest
    Color(0xFFFFB060), // amber
    Color(0xFFFF7050), // coral-red
    Color(0xFFFFD8A0), // pale gold (jupiter-like)
    Color(0xFF90FFE8), // seafoam teal
    Color(0xFF80A8FF), // periwinkle blue
  ];

  static const List<Color> _ringColors = [
    Color(0xFFFFD870), // bright gold
    Color(0xFFFFAA50), // amber
    Color(0xFFFF6878), // coral
    Color(0xFFFFD4A0), // peach
    Color(0xFF70FFE0), // teal
    Color(0xFF9898FF), // lavender
  ];

  ({Offset pos, double depth}) _project(
      double planarX, double planarZ, Offset center) {
    final double y = planarZ * math.sin(rotationX);
    final double zTilt = planarZ * math.cos(rotationX);
    final double x = planarX * math.cos(rotationY) + zTilt * math.sin(rotationY);
    final double depth = -planarX * math.sin(rotationY) + zTilt * math.cos(rotationY);
    return (pos: Offset(center.dx + x, center.dy + y), depth: depth);
  }

  Path _orbitPath(double radius, Offset center) {
    final Path path = Path();
    const int segments = 100;
    for (int i = 0; i <= segments; i++) {
      final double a = (i / segments) * 2 * math.pi;
      final p = _project(radius * math.cos(a), radius * math.sin(a), center);
      if (i == 0) {
        path.moveTo(p.pos.dx, p.pos.dy);
      } else {
        path.lineTo(p.pos.dx, p.pos.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, (size.height / 2) - 200);
    const double sunRadius = 10.0;
    Color trackColor = Color.fromARGB(255, 53, 53, 53).withValues(alpha: 0.3);

    canvas.drawCircle(center, sunRadius, sunPaint);
    final double seconds = elapsedMilliseconds / 1000.0;

    for (final planet in planets) {
      orbitPaint.color = planet.color.withValues(alpha: 0.2);
      canvas.drawPath(_orbitPath(planet.orbitRadius, center), orbitPaint);
    }

    final List<_PlanetRender> items = [];
    for (final planet in planets) {

      final double angle = (seconds * (2 * math.pi / 10.0)) * planet.speedMultiplier;

      const double trailAngleLength = 0.5;
      final double startAngle = angle - trailAngleLength;

      final Path trailPath = Path();
      const int sampleSegments = 20;

      for (int step = 0; step <= sampleSegments; step++) {
        final double t = step / sampleSegments;
        final double stepAngle = startAngle + (trailAngleLength * t);

        final projected = _project(
          planet.orbitRadius * math.cos(-stepAngle),
          planet.orbitRadius * math.sin(-stepAngle),
          center,
        );

        if (step == 0) {
          trailPath.moveTo(projected.pos.dx, projected.pos.dy);
        } else {
          trailPath.lineTo(projected.pos.dx, projected.pos.dy);
        }
      }

      final head = _project(
        planet.orbitRadius * math.cos(-angle),
        planet.orbitRadius * math.sin(-angle),
        center,
      );

      final tail = _project(
        planet.orbitRadius * math.cos(-startAngle),
        planet.orbitRadius * math.sin(-startAngle),
        center,
      );

      items.add(_PlanetRender(
        trailPath: trailPath,
        headPos: head.pos,
        tailPos: tail.pos,
        depth: head.depth,
        color: planet.color,
        radius: planet.planetRadius,
      ));
    }

    items.sort((a, b) => a.depth.compareTo(b.depth));

    void drawPlanet(_PlanetRender it) {
      final double distance = (it.headPos - it.tailPos).distance;
      if (distance > 0.1) {
        trailPaint.strokeWidth = it.radius * 1;
        trailPaint.shader = ui.Gradient.linear(
          it.tailPos,
          it.headPos,
          [
            it.color.withValues(alpha: 0.0),
            it.color.withValues(alpha: 0.6)
          ]
        );
        canvas.drawPath(it.trailPath, trailPaint);
      }
      planetPaint.color = it.color;
      canvas.drawCircle(it.headPos, it.radius, planetPaint);
    }

    for (final it in items.where((e) => e.depth <= 0)) {
      drawPlanet(it);
    }
    canvas.drawCircle(center, sunRadius,  sunPaint);
    for (final it in items.where((e) => e.depth > 0)) {
      drawPlanet(it);
    }

  }

  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) {
    return oldDelegate.elapsedMilliseconds != elapsedMilliseconds ||
      oldDelegate.planets != planets ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY;
  }
}


class _PlanetRender {
  final Path trailPath;
  final Offset headPos;
  final Offset tailPos;
  final double depth;
  final Color color;
  final double radius;

  _PlanetRender({
    required this.trailPath,
    required this.headPos,
    required this.tailPos,
    required this.depth,
    required this.color,
    required this.radius,
  });
}
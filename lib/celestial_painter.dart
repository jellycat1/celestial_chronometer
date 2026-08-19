import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:celestial_chronometer/models/planet_data.dart';

class CelestialPainter extends CustomPainter {
  final double elapsedMilliseconds;
  final List<PlanetData> planets;

  CelestialPainter({
    required this.elapsedMilliseconds,
    required this.planets,
  });

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

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, (size.height / 2) - 200);
    const double sunRadius = 10.0;
    const double planetTrackStrokeWidth = 1;
    Color trackColor = Color.fromARGB(255, 53, 53, 53).withValues(alpha: 0.3);

    final Paint sunPaint = Paint()
      ..color = Color(0xFFb9db0d).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, sunRadius, sunPaint);

    final double seconds = elapsedMilliseconds / 1000.0;

    for (final planet in planets) {
      final Paint orbitPaint = Paint()
        ..color = planet.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = planetTrackStrokeWidth;

      canvas.drawCircle(center, planet.orbitRadius, orbitPaint);

      final double angle = (seconds * (2 * math.pi / 10.0)) * planet.speedMultiplier;

      final Offset planetPos = Offset(
        center.dx + planet.orbitRadius * math.cos(-angle * planet.speedMultiplier),
        center.dy + planet.orbitRadius * math.sin(-angle * planet.speedMultiplier),
      );

      final Paint planetPaint = Paint()
        ..color = planet.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(planetPos, planet.planetRadius, planetPaint);
    }

  }

  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) {
    return oldDelegate.elapsedMilliseconds != elapsedMilliseconds ||
      oldDelegate.planets != planets;
  }
}
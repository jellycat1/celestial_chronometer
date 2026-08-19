import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:celestial_chronometer/models/planet_data.dart';

class CelestialPainter extends CustomPainter {
  final double animationValue;
  final List<PlanetData> planets;

  CelestialPainter({
    required this.animationValue,
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

    for (final planet in planets) {
      final Paint orbitPaint = Paint()
        ..color = planet.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = planetTrackStrokeWidth;

      canvas.drawCircle(center, planet.orbitRadius, orbitPaint);

      
      final double angle = animationValue * 2 * math.pi;

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


  // @override
  // void paint(Canvas canvas, Size size) {
  //   final Offset center = Offset(size.width / 2, (size.height / 2) - 200);
  //   const double sunRadius = 10.0;
  //   const double planetTrackStrokeWidth = 1;
  //   Color trackColor = Color.fromARGB(255, 53, 53, 53).withValues(alpha: 0.3);
    

  //   final Paint sunPaint = Paint()
  //     ..color = Color(0xFFb9db0d).withValues(alpha: 0.7)
  //     ..style = PaintingStyle.fill;
      
  //   final Paint ringOnePaint = Paint()
  //     ..color = trackColor
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = planetTrackStrokeWidth;

  //   final Paint ringTwoPaint = Paint()
  //     ..color = trackColor
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = planetTrackStrokeWidth;

  //   final Paint ringThreePaint = Paint()
  //     ..color = trackColor
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = planetTrackStrokeWidth;

  //   final Paint ringFourPaint = Paint()
  //     ..color = trackColor
  //     ..style = PaintingStyle.stroke
  //     ..strokeWidth = planetTrackStrokeWidth;

  //   // Ring 1
  //   canvas.drawCircle(center, 90.0, ringOnePaint);

  //   // Ring 2
  //   canvas.drawCircle(center, 50.0, ringTwoPaint);

  //   // Ring 3
  //   canvas.drawCircle(center, 130.0, ringThreePaint);

  //   // Ring 4
  //   canvas.drawCircle(center, 170.0, ringFourPaint);

  //   // Sun
  //   canvas.drawCircle(center, sunRadius, sunPaint);

  //   final double angle = animationValue * 2 * math.pi;

  //   final Offset planetOnePos = Offset(
  //     center.dx + 50 * math.cos(-angle * 2),
  //     center.dy + 50 * math.sin(-angle * 2),
  //   );

  //   final Paint planetOnePaint = Paint()
  //     ..color = Colors.cyan
  //     ..style = PaintingStyle.fill;

  //   canvas.drawCircle(planetOnePos, 8.0, planetOnePaint);
  // }
  @override
  bool shouldRepaint(covariant CelestialPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
      oldDelegate.planets != planets;
  }
}
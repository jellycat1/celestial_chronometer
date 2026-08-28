import 'package:celestial_chronometer/celestial_painter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:celestial_chronometer/models/focus_session.dart';

class FocusSessionPainter extends CustomPainter {
  final double elapsedMilliseconds;
  final double rotationX;
  final double rotationY;
  final FocusSession session;

  FocusSessionPainter({
    required this.session,
    required this.elapsedMilliseconds,
    this.rotationX = math.pi / 2,
    this.rotationY = 0.0,
  });

  ({Offset pos, double depth}) _project(
      double planarX, double planarZ, Offset center) {
    final double y = planarZ * math.sin(rotationX);
    final double zTilt = planarZ * math.cos(rotationX);
    final double x = planarX * math.cos(rotationY) + zTilt * math.sin(rotationY);
    final double depth = -planarX * math.sin(rotationY) + zTilt * math.cos(rotationY);
    return (pos: Offset(center.dx + x, center.dy + y), depth: depth);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = session.baseColor;
    final double seconds = elapsedMilliseconds / 1000.0;

    switch (session.stage) {
      case PlanetStage.dustCloud:
        _drawDustCloud(canvas, center, seconds);
        break;
      case PlanetStage.protoplanet:
        break;
      case PlanetStage.planet:
        break;
      case PlanetStage.ringedPlanet:
        break;
      case PlanetStage.fullyEvolved:
        break;
    }
  }

  void _drawDustCloud(Canvas canvas, Offset center, double seconds) {
    const int particleCount = 80;
    final List<_DustParticle> particles = [];

    for (int i = 0; i < particleCount; i++) {
      final double seedRadius = (math.sin(i * 99.0) * 0.5 + 0.5);
      final double seedSpread = (math.cos(i * 57.0) * 0.5 + 0.5);
      final double seedSpeed = (math.cos(i * 33.0) * 0.5 + 0.5);
      final double seedAlpha = (math.sin(i * 77.0) * 0.5 + 0.5);

      // final double radius = session.orbitRadius + (seedRadius - 0.5) * 30.0;
      // final double initialAngle = (i / particleCount) * 2 * math.pi;

      final double distance = session.orbitRadius * math.sqrt(seedSpread);
      final double heightSeed = math.sin(i * 41.0) * 0.5 + 0.5;
      final double height = (heightSeed - 0.5) * session.orbitRadius * 0.6;

      // final double speed = 0.8 + seedSpeed * 0.4;
      final double initialAngle = (i / particleCount) * 2 * math.pi;
      final double speed = 0.15 + seedSpeed * 0.15;
      final double angle = initialAngle + (seconds * speed);

      // final projected = _project(
      //   radius * math.cos(-angle),
      //   radius * math.sin(-angle),
      //   center,
      // );

      final double planarX = distance * math.cos(-angle);
      final double planarZ = distance * math.sin(-angle);

      final projected = _project(planarX, planarZ, center);
      final Offset pos = Offset(
        projected.pos.dx,
        projected.pos.dy + height,
      );

      particles.add(_DustParticle(
        pos: pos,
        depth: projected.depth,
        radius: 0.6 + seedRadius * 1.0,
        alpha: 0.2 + seedAlpha * 0.5,
      ));
    }

    particles.sort((a, b) => a.depth.compareTo(b.depth));

    final projectedCore = _project(0, 0, center);
    final Paint coreGlow = Paint()
      ..color = session.baseColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(projectedCore.pos, 12, coreGlow);

    final Paint dustGlowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final Paint dustPaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      dustGlowPaint.color = session.baseColor.withValues(alpha: p.alpha * 0.5);
      canvas.drawCircle(p.pos, p.radius * 2.5, dustGlowPaint);

      dustPaint.color = session.baseColor.withValues(alpha: p.alpha);
      canvas.drawCircle(p.pos, p.radius, dustPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant FocusSessionPainter oldDelegate) {
    return 
      oldDelegate.elapsedMilliseconds != elapsedMilliseconds ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY ||
      oldDelegate.session != session;
  }
}

class _DustParticle {
  final Offset pos;
  final double depth;
  final double radius;
  final double alpha;

  _DustParticle({
    required this.pos,
    required this.depth,
    required this.radius,
    required this.alpha
  });
}
import 'dart:ui' as ui;

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
    double planarX, double planarY, double planarZ, Offset center) {
      final double rotY = planarY * math.cos(rotationX) - planarZ * math.sin(rotationX);
      final double rotZ = planarY * math.sin(rotationX) + planarZ * math.cos(rotationX);

      final double x = planarX * math.cos(rotationY) + rotZ * math.sin(rotationY);
      final double depth = -planarX * math.sin(rotationY) + rotZ * math.cos(rotationY);

      return (pos: Offset(center.dx + x, center.dy + rotY), depth: depth);
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
        _drawProtoPlanet(canvas, center, seconds);
        break;
      case PlanetStage.planet:
      _drawLivingPlanet(canvas, center, seconds);
        break;
      case PlanetStage.planetWithMoon:
        _drawPlanetWithMoon(canvas, center, seconds);
        break;
      case PlanetStage.planetWithRings:
        break;
      case PlanetStage.fullyEvolved:
        break;
    }
  }

  void _drawSolidPlanet(Canvas canvas, Offset center, double seconds) {
    final planetProjected = _project(0, 0, 0, center);
    const double planetRadius = 14.0;

    final Paint paint = Paint()..style = PaintingStyle.fill;


    final Paint atmosphereGlow = Paint()
      ..color = session.baseColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(planetProjected.pos, planetRadius * 1.2, atmosphereGlow);

    final Paint atmosphereRim = Paint()
      ..color = session.baseColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(planetProjected.pos, planetRadius * 1.1, atmosphereRim);

    paint.color = session.baseColor;
    canvas.drawCircle(planetProjected.pos, planetRadius, paint);

    final Paint surfaceDetail = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(planetProjected.pos.dx - 3, planetProjected.pos.dy - 3),
      planetRadius * 0.6,
      surfaceDetail
    );
  }

  void _drawLivingPlanet(Canvas canvas, Offset center, double seconds) {
    final planetProjected = _project(0, 0, 0, center);
    const double planetRadius = 14.0;

    final Paint atmosphereGlow = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(planetProjected.pos, planetRadius * 1.8, atmosphereGlow);

    canvas.save();

    final Path planetPath = Path()
      ..addOval(Rect.fromCircle(center: planetProjected.pos, radius: planetRadius));
    canvas.clipPath(planetPath);

    final Paint oceanPaint = Paint()..color = const Color(0xFF1E88E5);
    canvas.drawRect(
      Rect.fromCircle(center: planetProjected.pos, radius: planetRadius),
      oceanPaint,
    );

    final Paint landPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;

    const double rotationSpeed = 0.4;
    final double currentRotation = seconds * rotationSpeed;

    const continents = [
      (0.3, 0.0, 6.0),
      (-0.4, 2.1, 4.5),
      (0.1, 4.2, 5.0),
      (-0.2, -1.8, 3.5),
      (0.6, 3.1, 3.0),
    ];

    // Only the hemisphere facing the camera should render land, and it
    // should fade out smoothly as it nears the limb of the sphere rather
    // than popping in/out.
    for (final land in continents) {
      final double lat = land.$1;
      final double baseLong = land.$2;
      final double landRadius = land.$3;

      final double longAngle = baseLong + currentRotation;

      final double x = planetRadius * math.cos(lat) * math.sin(longAngle);
      final double y = planetRadius * math.sin(lat);
      final double z = planetRadius * math.cos(lat) * math.cos(longAngle);

      final projectedLand = _project(x, y, z, center);
      final double facing = (projectedLand.depth - planetProjected.depth) / planetRadius;

      if (facing > 0) {
        final double horizonScale = (facing * 1.2).clamp(0.15, 1.0);

        canvas.drawCircle(
          projectedLand.pos,
          landRadius * horizonScale,
          landPaint,
        );
      }
    }

    // A thin, slowly drifting cloud layer to make the planet feel alive.
    final math.Random cloudRng = math.Random(2024);
    final Paint cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const int cloudCount = 10;
    for (int i = 0; i < cloudCount; i++) {
      final double lat = (cloudRng.nextDouble() - 0.5) * math.pi * 0.8;
      final double baseLong = cloudRng.nextDouble() * 2 * math.pi;
      final double cloudRadius = 2.0 + cloudRng.nextDouble() * 2.5;
      final double speed = 0.7 + cloudRng.nextDouble() * 0.4;

      final double longAngle = baseLong + currentRotation * speed;

      final double x = (planetRadius + 0.6) * math.cos(lat) * math.sin(longAngle);
      final double y = (planetRadius + 0.6) * math.sin(lat);
      final double z = (planetRadius + 0.6) * math.cos(lat) * math.cos(longAngle);

      final projectedCloud = _project(x, y, z, center);
      final double facing = (projectedCloud.depth - planetProjected.depth) / planetRadius;

      if (facing > 0) {
        final double horizonScale = (facing * 1.2).clamp(0.15, 1.0);
        canvas.drawCircle(projectedCloud.pos, cloudRadius * horizonScale, cloudPaint);
      }
    }

    final Paint shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(planetProjected.pos.dx - planetRadius, planetProjected.pos.dy - planetRadius),
        Offset(planetProjected.pos.dx + planetRadius, planetProjected.pos.dy + planetRadius),
        [
          Colors.white.withValues(alpha: 0.2),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.6),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(planetProjected.pos, planetRadius, shadowPaint);

    canvas.restore();
  }

  void _drawMoonTrack(Canvas canvas, Offset center, double radius) {
    final Paint trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final Path orbitPath = Path();

    const int segments = 60;
    for (int i = 0; i <= segments; i++) {
      final double a = (i / segments) * 2 * math.pi;
      final double x = radius * math.cos(a);
      final double z = radius * math.sin(a);
      // final double y = math.sin(a * 2) * 4.0;
      final double y = 0.0;

      final p = _project(x, y, z, center);
      if (i == 0) {
        orbitPath.moveTo(p.pos.dx, p.pos.dy);
      } else {
        if (i % 2 == 0) {
          orbitPath.lineTo(p.pos.dx, p.pos.dy);
        } else {
          orbitPath.moveTo(p.pos.dx, p.pos.dy);
        }
      }
    }
    canvas.drawPath(orbitPath, trackPaint);
  }

  void _drawPlanetWithMoon(Canvas canvas, Offset center, double seconds) {
    final planetProjected = _project(0, 0, 0, center);
    const double planetRadius = 14.0;

    const double moonOrbitRadius = 32.0;
    final double moonAngle = seconds * 1.2;

    final double moonX = moonOrbitRadius * math.cos(moonAngle);
    final double moonZ = moonOrbitRadius * math.sin(moonAngle);
    // final double moonY = (math.sin(moonAngle * 2) * 4.0);
    final double moonY = 0.0;

    final moonProjected = _project(moonX, moonY, moonZ, center);
    const double moonRadius = 3.5;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    _drawMoonTrack(canvas, center, moonOrbitRadius);

    if (moonProjected.depth <= planetProjected.depth) {
      canvas.save();

      final Path occludedPath = Path()
        ..addRect(Rect.fromLTWH(0, 0, canvas.getLocalClipBounds().width, canvas.getLocalClipBounds().height))
        ..addOval(Rect.fromCircle(center: planetProjected.pos, radius: planetRadius));

      occludedPath.fillType = PathFillType.evenOdd;
      canvas.clipPath(occludedPath);

      _drawMoonBody(canvas, moonProjected.pos, moonRadius);

      canvas.restore();
    }

    final Paint atmosphereGlow = Paint()
      ..color = session.baseColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(planetProjected.pos, planetRadius * 1.8, atmosphereGlow);

    final Paint atmosphereRim = Paint()
      ..color = session.baseColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(planetProjected.pos, planetRadius * 1.1, atmosphereRim);

    paint.color = session.baseColor;
    canvas.drawCircle(planetProjected.pos, planetRadius, paint);

    final Paint surfaceDetail = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(
      Offset(planetProjected.pos.dx - 3, planetProjected.pos.dy - 3),
      planetRadius * 0.6,
      surfaceDetail
    );

    if (moonProjected.depth > planetProjected.depth) {
      _drawMoonBody(canvas, moonProjected.pos, moonRadius);
    }
  }

  void _drawMoonBody(Canvas canvas, Offset moonPos, double moonRadius) {
    final Paint moonPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final Paint moonGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(moonPos, moonRadius * 1.4, moonGlow);
    canvas.drawCircle(moonPos, moonRadius, moonPaint);
  }

  void _drawDustCloud(Canvas canvas, Offset center, double seconds) {
    const int particleCount = 100;
    final List<_DustParticle> particles = [];
    final math.Random rng = math.Random(1337);

    for (int i = 0; i < particleCount; i++) {
      final double seedRadius = rng.nextDouble();
      final double seedSpread = rng.nextDouble();
      final double seedSpeed = rng.nextDouble();
      final double seedAlpha = rng.nextDouble();

      final double heightSeed = rng.nextDouble();
      final double r = session.orbitRadius * math.pow(seedSpread, 1/3);
      final double costheta = 2 * heightSeed - 1;
      final double sintheta = math.sqrt(1 - costheta * costheta);

      final double height = r * costheta;
      final double distance = r * sintheta;

      final double angleSeed = rng.nextDouble();
      final double initialAngle = angleSeed * 2 * math.pi;
      final double speed = 0.05 + seedSpeed * 0.05;
      final double angle = initialAngle + (seconds * speed);


      final double planarX = distance * math.cos(-angle);
      final double planarZ = distance * math.sin(-angle);
      final double planarY = height;

      final projected = _project(planarX, planarY, planarZ, center);

      particles.add(_DustParticle(
        pos: projected.pos,
        depth: projected.depth,
        radius: 0.6 + seedRadius * 1.0,
        alpha: 0.2 + seedAlpha * 0.5,
      ));
    }

    particles.sort((a, b) => a.depth.compareTo(b.depth));

    final projectedCore = _project(0, 0, 0, center);
    final Paint coreGlow = Paint()
      ..color = session.baseColor.withValues(alpha: 0.55)
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

  void _drawProtoPlanet(Canvas canvas, Offset center, double seconds) {
    final math.Random rng = math.Random(1337);
    final List<_DustParticle> elements = [];

    const int ringParticles = 60;
    for (int i = 0; i < ringParticles; i++) {
      final double seedRadius = rng.nextDouble();
      final double seedSpread = rng.nextDouble();
      final double seedSpeed = rng.nextDouble();
      final double seedAlpha = rng.nextDouble();

      final double r = session.orbitRadius * (0.3 + seedSpread * 0.4);
      final double height = (rng.nextDouble() - 0.5) * session.orbitRadius * 0.15;

      final double initialAngle = rng.nextDouble() * 2 * math.pi;
      final double speed = 0.1 + seedSpeed * 0.07;
      final double angle = initialAngle + (seconds * speed);

      final double planarX = r * math.cos(-angle);
      final double planarZ = r * math.sin(-angle);

      final projected = _project(planarX, height, planarZ, center);

      elements.add(_DustParticle(
        pos: projected.pos,
        depth: projected.depth,
        radius: 0.8 + seedRadius * 1.2,
        alpha: 0.3 + seedAlpha * 0.6,
      ));
    }

    elements.sort((a, b) => a.depth.compareTo(b.depth));

    final coreProjected = _project(0, 0, 0, center);
    const double coreRadius = 8.0;

    final backElements = elements.where((e) => e.depth <= coreProjected.depth);
    final frontElements = elements.where((e) => e.depth > coreProjected.depth);

    final Paint glowPaint = Paint()..style = PaintingStyle.fill;
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in backElements) {
      glowPaint
        ..color = session.baseColor.withValues(alpha: p.alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(p.pos, p.radius * 2.0, glowPaint);

      particlePaint
        ..color = session.baseColor.withValues(alpha: p.alpha)
        ..maskFilter = null;
      canvas.drawCircle(p.pos, p.radius, particlePaint);
    }

    final Paint atmosphereGlow = Paint()
      ..color = session.baseColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(coreProjected.pos, coreRadius * 1.3, atmosphereGlow);

    final Paint coreBody = Paint()
      ..color = Color.lerp(session.baseColor, Colors.white, 0.3)!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(coreProjected.pos, coreRadius, coreBody);

    final Paint moltenSurface = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(coreProjected.pos, coreRadius * 0.9, moltenSurface);

    for (final p in frontElements) {
      glowPaint
        ..color = session.baseColor.withValues(alpha: p.alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(p.pos, p.radius * 2.0, glowPaint);

      particlePaint
        ..color = session.baseColor.withValues(alpha: p.alpha)
        ..maskFilter = null;
      canvas.drawCircle(p.pos, p.radius, particlePaint);
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
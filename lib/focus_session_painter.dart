import 'dart:ui' as ui;
import 'dart:typed_data';

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
    const double planetRadius = 14.0;
    final surface = _LivingSurface.instance(5500);

    final cosX = math.cos(rotationX), sinX = math.sin(rotationX);
    final cosY = math.cos(rotationY), sinY = math.sin(rotationY);
    final spin = seconds * 0.35;
    final cosS = math.cos(spin), sinS = math.sin(spin);

    const lx = -0.42, ly = -0.55, lz = 0.72;
    const lwx = 0.25, lwy = -0.30, lwz = 0.92;

    final oceanR = (session.baseColor.r * 255).round();
    final oceanG = (session.baseColor.g * 255).round();
    final oceanB = (session.baseColor.b * 255).round();

    canvas.drawCircle(
      center,
      planetRadius * 1.7,
      Paint()
        ..color = session.baseColor.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final dot = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final dotR = planetRadius * 2.2 / math.sqrt(surface.count);

    for (var i = 0; i < surface.count; i++) {
      final ux = surface.xs[i], uy = surface.ys[i], uz = surface.zs[i];
      final sx = ux * cosS + uz * sinS;
      final sz = -ux * sinS + uz * cosS;

      final rotZ = uy * sinX + sz * cosX;
      final nx = sx * cosY + rotZ * sinY;
      final nz = -sx * sinY + rotZ * cosY;
      final ny = uy * cosX - sz * sinX;

      if (nz <= 0.02) continue;

      final b = sx * lwx + uy * lwy + sz * lwz;
      final day = _smooth01(-0.30, 0.35, b);

      int ar, ag, ab;
      final ice = surface.absY[i] > 0.86;
      final ocean = !ice && surface.elev[i] < 0.5;
      if (ice) {
        ar = 228; ag = 244; ab = 255;
      } else if (ocean) {
        ar = oceanR; ag = oceanG; ab = oceanB;
      } else {
        ar = 64; ag = 150; ab = 84;
      }

      final wrap = ((b + 0.35) / 1.35).clamp(0.0, 1.0);
      final shade = 0.30 + 0.70 * wrap;
      var dr = ar * shade, dg = ag * shade, db = ab * shade;
      if (ocean && b > 0) {
        final s = b * b * b * b;
        dr += 70 * s; dg += 80 * s; db += 90 * s;
      }

      var nr = ar * 0.05, ng = ag * 0.06, nb = ab * 0.09;
      if (!ocean && !ice && surface.city[i] < 0.16) {
        final glow = 1.0 - surface.city[i] / 0.16 * 0.45;
        nr = 255 * glow; ng = 208 * glow; nb = 130 * glow;
      }

      final cr = (nr + (dr - nr) * day).clamp(0.0, 255.0);
      final cg = (ng + (dg - ng) * day).clamp(0.0, 255.0);
      final cb = (nb + (db - nb) * day).clamp(0.0, 255.0);
      dot.color = Color.fromARGB(255, cr.round(), cg.round(), cb.round());

      final px = center.dx + nx * planetRadius;
      final py = center.dy + ny * planetRadius;
      canvas.drawCircle(Offset(px, py), dotR * (0.85 + 0.30 * nz), dot);
    }

    canvas.drawCircle(
      center,
      planetRadius * 0.99,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = planetRadius * 0.05
        ..color = session.ringColor.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, planetRadius * 0.04),
    );
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

double _smooth01(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

class _LivingSurface {
  _LivingSurface(this.count) {
    xs = Float32List(count);
    ys = Float32List(count);
    zs = Float32List(count);
    elev = Float32List(count);
    city = Float32List(count);
    absY = Float32List(count);

    final golden = math.pi * (3 -  math.sqrt(5));
    final raw = List<double>.filled(count, 0);
    var lo = double.infinity, hi = -double.infinity;

    for (var i = 0; i < count; i++) {
      final y = 1 - (i / (count - 1)) * 2;
      final r = math.sqrt(math.max(0.0, 1 - y * y));
      final theta = golden * i;
      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;

      xs[i] = x; ys[i] = y; zs[i] = z;
      absY[i] = y.abs();
      city[i] = _hash01(i * 12.9898 + 7.13);

      final f = _continent(x, y, z);
      raw[i] = f;
      if (f < lo) lo = f;
      if (f > hi) hi = f;
    }

    final span = (hi - lo).abs() < 1e-6 ? 1.0 : (hi - lo);
    for (var i = 0; i < count; i++) {
      elev[i] = (raw[i] - lo) / span;
    }

  }

  final int count;
  late final Float32List xs, ys, zs, elev, city, absY;

  static _LivingSurface? _cached;
  static _LivingSurface instance(int count) =>
    (_cached != null && _cached!.count == count)
      ? _cached!
      : (_cached = _LivingSurface(count));

  static double _continent(double x, double y, double z) {
    var v = math.sin(1.7 * x + 0.3) * math.sin(1.9 * y - 1.1) * math.sin(2.1 * z + 0.7);
    v += 0.50 * math.sin(3.3 * x - 2.0) * math.sin(3.7 * y + 0.5) * math.sin(3.1 * z - 1.4);
    v += 0.25 * math.sin(6.1 * x + 1.2) * math.sin(5.7 * y + 2.3) * math.sin(6.9 * z + 0.2);
    return v;
  }

  static double _hash01(double n) {
    final s = math.sin(n) * 43758.5453;
    return s - s.floorToDouble();
  }
}
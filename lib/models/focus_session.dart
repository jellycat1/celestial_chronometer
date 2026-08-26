import 'package:flutter/material.dart';

enum PlanetStage { dustCloud, protoplanet, planet, ringedPlanet, fullyEvolved }

class FocusSession {
  final String id;
  final Duration targetDuration;

  Duration elapsed = Duration.zero;
  PlanetStage stage = PlanetStage.dustCloud;

  final Color baseColor;
  final Color ringColor;
  final double orbitRadius;

  FocusSession({
    required this.id,
    required this.targetDuration,
    required this.baseColor,
    required this.ringColor,
    required this.orbitRadius,
  });

  void updateProgress(Duration newElapsed) {
    elapsed = newElapsed;
    final double progress = elapsed.inMilliseconds / targetDuration.inMilliseconds;

    if (progress < 0.25) {
      stage = PlanetStage.dustCloud;
    } else if (progress < 0.5) {
      stage = PlanetStage.protoplanet;
    } else if (progress < 0.75) {
      stage = PlanetStage.planet;
    } else if (progress < 1.0) {
      stage = PlanetStage.ringedPlanet;
    } else {
      stage = PlanetStage.fullyEvolved;
    }
  }
}
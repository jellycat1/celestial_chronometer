import 'package:flutter/material.dart';

class PlanetData {
  final double orbitRadius;
  final double planetRadius;
  final Color color;
  final double speedMultiplier;
  
  const PlanetData({
    required this.orbitRadius,
    required this.planetRadius,
    required this.color,
    this.speedMultiplier = 1.0,
  });
}
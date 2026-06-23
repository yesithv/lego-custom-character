import 'package:flutter/material.dart';

class WorldColors {
  final Color sky;
  final Color midground;
  final Color ground;
  final Color accent;

  const WorldColors({
    required this.sky,
    required this.midground,
    required this.ground,
    required this.accent,
  });
}

const worldConfigs = <String, WorldColors>{
  'lego_city': WorldColors(
    sky: Color(0xFF87CEEB),
    midground: Color(0xFFB0C4DE),
    ground: Color(0xFF808080),
    accent: Color(0xFFFFD700),
  ),
  'medieval': WorldColors(
    sky: Color(0xFF4A7FB5),
    midground: Color(0xFF6B8E23),
    ground: Color(0xFF8B7355),
    accent: Color(0xFFCD853F),
  ),
  'galaxy': WorldColors(
    sky: Color(0xFF0D0D2B),
    midground: Color(0xFF1A1A4B),
    ground: Color(0xFF2E2E6B),
    accent: Color(0xFF00FFFF),
  ),
  'jungle': WorldColors(
    sky: Color(0xFF228B22),
    midground: Color(0xFF2D6A4F),
    ground: Color(0xFF5C4033),
    accent: Color(0xFF7FFF00),
  ),
  'dark_city': WorldColors(
    sky: Color(0xFF1A1A2E),
    midground: Color(0xFF2D2D4E),
    ground: Color(0xFF0D0D1A),
    accent: Color(0xFFE94560),
  ),
  'ocean': WorldColors(
    sky: Color(0xFF006994),
    midground: Color(0xFF0099CC),
    ground: Color(0xFF003D5C),
    accent: Color(0xFF00FFCC),
  ),
  'tundra': WorldColors(
    sky: Color(0xFFB0E0FF),
    midground: Color(0xFF87CEEB),
    ground: Color(0xFFDFF0FF),
    accent: Color(0xFFFFFFFF),
  ),
  'robot_city': WorldColors(
    sky: Color(0xFF1C1C1C),
    midground: Color(0xFF2D2D2D),
    ground: Color(0xFF111111),
    accent: Color(0xFF00FF41),
  ),
};

WorldColors colorsFor(String worldId) =>
    worldConfigs[worldId] ?? worldConfigs['lego_city']!;

import 'package:flutter/material.dart';

class WorldColors {
  final Color sky;
  final Color midground;
  final Color ground;
  final Color accent;
  final Color obstacleBlock;
  final Color obstacleBarrier;
  final Color obstacleSpike;

  const WorldColors({
    required this.sky,
    required this.midground,
    required this.ground,
    required this.accent,
    required this.obstacleBlock,
    required this.obstacleBarrier,
    required this.obstacleSpike,
  });
}

const worldConfigs = <String, WorldColors>{
  'brix_city': WorldColors(
    sky: Color(0xFF87CEEB),
    midground: Color(0xFFB0C4DE),
    ground: Color(0xFF808080),
    accent: Color(0xFFFFD700),
    obstacleBlock: Color(0xFFD32F2F),
    obstacleBarrier: Color(0xFFF57C00),
    obstacleSpike: Color(0xFFFF6F00),
  ),
  'medieval': WorldColors(
    sky: Color(0xFF4A7FB5),
    midground: Color(0xFF6B8E23),
    ground: Color(0xFF8B7355),
    accent: Color(0xFFCD853F),
    obstacleBlock: Color(0xFF8D8D8D),
    obstacleBarrier: Color(0xFF795548),
    obstacleSpike: Color(0xFF9E9E9E),
  ),
  'galaxy': WorldColors(
    sky: Color(0xFF0D0D2B),
    midground: Color(0xFF1A1A4B),
    ground: Color(0xFF2E2E6B),
    accent: Color(0xFF00FFFF),
    obstacleBlock: Color(0xFF5E4B8B),
    obstacleBarrier: Color(0xFF00E5FF),
    obstacleSpike: Color(0xFF7C4DFF),
  ),
  'jungle': WorldColors(
    sky: Color(0xFF228B22),
    midground: Color(0xFF2D6A4F),
    ground: Color(0xFF5C4033),
    accent: Color(0xFF7FFF00),
    obstacleBlock: Color(0xFF6B8E23),
    obstacleBarrier: Color(0xFF8B5A2B),
    obstacleSpike: Color(0xFF2E7D32),
  ),
  'dark_city': WorldColors(
    sky: Color(0xFF1A1A2E),
    midground: Color(0xFF2D2D4E),
    ground: Color(0xFF0D0D1A),
    accent: Color(0xFFE94560),
    obstacleBlock: Color(0xFF37474F),
    obstacleBarrier: Color(0xFFC62828),
    obstacleSpike: Color(0xFF7B1FA2),
  ),
  'ocean': WorldColors(
    sky: Color(0xFF006994),
    midground: Color(0xFF0099CC),
    ground: Color(0xFF003D5C),
    accent: Color(0xFF00FFCC),
    obstacleBlock: Color(0xFFFF7043),
    obstacleBarrier: Color(0xFF2E7D6E),
    obstacleSpike: Color(0xFF37474F),
  ),
  'tundra': WorldColors(
    sky: Color(0xFFB0E0FF),
    midground: Color(0xFF87CEEB),
    ground: Color(0xFFDFF0FF),
    accent: Color(0xFFFFFFFF),
    obstacleBlock: Color(0xFF81C7E8),
    obstacleBarrier: Color(0xFF9FD8EF),
    obstacleSpike: Color(0xFFB3E5FC),
  ),
  'robot_city': WorldColors(
    sky: Color(0xFF1C1C1C),
    midground: Color(0xFF2D2D2D),
    ground: Color(0xFF111111),
    accent: Color(0xFF00FF41),
    obstacleBlock: Color(0xFF546E7A),
    obstacleBarrier: Color(0xFF00C853),
    obstacleSpike: Color(0xFF78909C),
  ),
};

WorldColors colorsFor(String worldId) =>
    worldConfigs[worldId] ?? worldConfigs['brix_city']!;

/// Longitud de la pista de cada mundo, en metros. Es la distancia que hay que
/// recorrer antes de que aparezca el jefe, y también lo que se anuncia en la
/// tarjeta del mundo: única fuente de verdad para ambos.
///
/// **Estos valores salen de una duración objetivo, no de un recorte a ojo.** La
/// velocidad del corredor sube con el tiempo (220 px/s +12 cada 5 s, ver
/// `BrixRunGame.update`), así que los metros del final se recorren mucho más
/// rápido que los del principio y la duración **no** es proporcional a la
/// distancia: recortar un 20 % la pista solo quitaba un 14 % de tiempo.
///
/// Objetivo de esta tabla: partidas de **2,2 min en la pista inicial hasta
/// 3,8 min en la última** (media ≈ 3 min), frente a los 4-6,5 min del diseño
/// original. Progresión conservada: cada mundo dura algo más que el anterior.
///
/// | mundo | metros | duración aprox. |
/// |---|---|---|
/// | brix_city | 500 | 2,2 min |
/// | medieval | 600 | 2,5 min |
/// | ocean | 700 | 2,8 min |
/// | jungle | 800 | 3,1 min |
/// | galaxy | 850 | 3,2 min |
/// | tundra | 900 | 3,3 min |
/// | dark_city | 1000 | 3,6 min |
/// | robot_city | 1100 | 3,8 min |
///
/// Al tocar estos números hay que reescalar con ellos las dos cosas que
/// dependen de la distancia: los **umbrales de zona** en
/// `BrixRunGame.currentZone` y los **objetivos de las misiones de distancia**
/// (`mission_repository_impl.dart`).
const worldTrackMeters = <String, int>{
  'brix_city': 500,
  'medieval': 600,
  'galaxy': 850,
  'jungle': 800,
  'dark_city': 1000,
  'ocean': 700,
  'tundra': 900,
  'robot_city': 1100,
};

int trackMetersFor(String worldId) => worldTrackMeters[worldId] ?? 500;

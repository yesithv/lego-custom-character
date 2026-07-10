import 'package:flutter/material.dart';

/// Tipos de ataque del jefe. Cada uno se contrarresta con un control existente:
/// - [projectile]: viaja por un carril → esquivar cambiando de carril (o saltar)
/// - [shockwave]: onda baja a lo ancho de la pista → saltar
/// - [sweep]: barrido alto a lo ancho de la pista → deslizarse
enum BossAttackKind { projectile, shockwave, sweep }

class BossConfig {
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color attackColor;

  /// Pesos relativos de cada tipo de ataque — dan "personalidad" al jefe.
  final int projectileWeight;
  final int shockwaveWeight;
  final int sweepWeight;

  const BossConfig({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.attackColor,
    required this.projectileWeight,
    required this.shockwaveWeight,
    required this.sweepWeight,
  });

  /// Elige un tipo de ataque según los pesos usando [roll] en [0, 1).
  BossAttackKind attackForRoll(double roll) {
    final total = projectileWeight + shockwaveWeight + sweepWeight;
    final r = roll * total;
    if (r < projectileWeight) return BossAttackKind.projectile;
    if (r < projectileWeight + shockwaveWeight) return BossAttackKind.shockwave;
    return BossAttackKind.sweep;
  }
}

const bossConfigs = <String, BossConfig>{
  'lego_city': BossConfig(
    name: 'Capataz Demoledor',
    emoji: '🏗️',
    primary: Color(0xFFF57C00),
    secondary: Color(0xFFFFD700),
    attackColor: Color(0xFF616161),
    projectileWeight: 60,
    shockwaveWeight: 25,
    sweepWeight: 15,
  ),
  'medieval': BossConfig(
    name: 'Dragón Oscuro',
    emoji: '🐉',
    primary: Color(0xFF2F4538),
    secondary: Color(0xFFC62828),
    attackColor: Color(0xFFFF6F00),
    projectileWeight: 55,
    shockwaveWeight: 15,
    sweepWeight: 30,
  ),
  'galaxy': BossConfig(
    name: 'Overlord Zenth',
    emoji: '👾',
    primary: Color(0xFF5E4B8B),
    secondary: Color(0xFF00FFFF),
    attackColor: Color(0xFF00E5FF),
    projectileWeight: 45,
    shockwaveWeight: 15,
    sweepWeight: 40,
  ),
  'jungle': BossConfig(
    name: 'Gran Gorila',
    emoji: '🦍',
    primary: Color(0xFF4E342E),
    secondary: Color(0xFFD7B899),
    attackColor: Color(0xFF795548),
    projectileWeight: 40,
    shockwaveWeight: 45,
    sweepWeight: 15,
  ),
  'dark_city': BossConfig(
    name: 'Señor Sombra',
    emoji: '🦹',
    primary: Color(0xFF2D2D4E),
    secondary: Color(0xFFE94560),
    attackColor: Color(0xFF9C27B0),
    projectileWeight: 60,
    shockwaveWeight: 15,
    sweepWeight: 25,
  ),
  'ocean': BossConfig(
    name: 'Kraken Abisal',
    emoji: '🐙',
    primary: Color(0xFF6A1B9A),
    secondary: Color(0xFF00FFCC),
    attackColor: Color(0xFF0099CC),
    projectileWeight: 45,
    shockwaveWeight: 20,
    sweepWeight: 35,
  ),
  'tundra': BossConfig(
    name: 'Yeti Glacial',
    emoji: '❄️',
    primary: Color(0xFFF5F9FF),
    secondary: Color(0xFF81C7E8),
    attackColor: Color(0xFFE1F5FE),
    projectileWeight: 55,
    shockwaveWeight: 30,
    sweepWeight: 15,
  ),
  'robot_city': BossConfig(
    name: 'Mega-Bot X9',
    emoji: '🤖',
    primary: Color(0xFF546E7A),
    secondary: Color(0xFF00FF41),
    attackColor: Color(0xFFFF1744),
    projectileWeight: 50,
    shockwaveWeight: 20,
    sweepWeight: 30,
  ),
};

BossConfig bossFor(String worldId) =>
    bossConfigs[worldId] ?? bossConfigs['lego_city']!;

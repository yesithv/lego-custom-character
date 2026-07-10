import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/boss_config.dart';
import '../brix_run_game.dart';
import 'boss_painters.dart';

/// El jefe del mundo: entra desde el horizonte, flota delante del jugador
/// balanceándose entre carriles y encaja las embestidas hasta caer.
class BossComponent extends PositionComponent with HasGameRef<BrixRunGame> {
  static const double baseW = 175.0;
  static const double baseH = 190.0;

  /// Profundidad a la que se detiene para pelear (delante del jugador).
  static const double fightDepth = 0.52;
  static const double _introSpeed = 0.20; // profundidad/s durante la entrada

  double depth = 0.06;
  double _animT = 0;
  double _hitFlash = 0;
  double _defeatT = -1; // ≥0 cuando está derrotado (anima caída)

  bool get introDone => depth >= fightDepth;
  bool get isDefeated => _defeatT >= 0;
  bool get defeatAnimDone => _defeatT >= 1.4;

  BossComponent() : super(size: Vector2(1, 1), priority: 60);

  /// Destello blanco al recibir una embestida.
  void onDashHit() => _hitFlash = 0.45;

  /// Inicia la animación de derrota (gira, cae y se encoge).
  void startDefeat() {
    if (_defeatT < 0) _defeatT = 0;
  }

  @override
  void update(double dt) {
    _animT += dt;
    if (_hitFlash > 0) _hitFlash = max(0, _hitFlash - dt);
    if (_defeatT >= 0) _defeatT += dt;

    if (!isDefeated && depth < fightDepth) {
      depth = min(fightDepth, depth + _introSpeed * dt);
    }
    _syncTransform();
  }

  void _syncTransform() {
    final defeatShrink =
        isDefeated ? (1.0 - (_defeatT / 1.4).clamp(0.0, 1.0) * 0.85) : 1.0;
    final s = game.perspectiveScale(depth) * 1.18 * defeatShrink;
    size = Vector2(baseW * s, baseH * s);

    // Balanceo lateral entre carriles + flotación vertical
    final sway =
        isDefeated ? 0.0 : sin(_animT * 0.75) * game.laneSep * 0.85 * depth;
    final hover = isDefeated ? 0.0 : sin(_animT * 2.3) * 6.0 * depth;
    final fall = isDefeated ? _defeatT * game.size.y * 0.25 : 0.0;

    final ground = game.perspectivePos(1, depth);
    position = Vector2(
      game.vanishX + sway - size.x / 2,
      ground.y - size.y - 12 * s - hover + fall,
    );
    priority = (200 * depth).floor() + 8;
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) {
      // Gira mientras cae
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(_defeatT * 5.0);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    paintBoss(
      canvas,
      Size(size.x, size.y),
      game.worldId,
      animT: _animT,
      enrage: isDefeated ? 0 : (3 - game.bossHearts).clamp(0, 2),
      hitFlash: _hitFlash > 0 ? (_hitFlash / 0.45) * 0.7 : 0,
    );
    if (isDefeated) canvas.restore();
  }
}

/// Ataque lanzado por el jefe: nace a la profundidad del jefe y viaja hacia
/// el jugador con la misma lógica de perspectiva que los obstáculos.
class BossAttackComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  final BossAttackKind kind;

  /// Carril del proyectil; los ataques a lo ancho (onda/barrido) lo ignoran.
  final int lane;

  double depth;
  bool dodged = false;
  bool collided = false;
  double _animT = 0;

  static const double _projSize = 48.0;
  static const double _waveH = 32.0;
  static const double _sweepH = 34.0;

  /// Separación del suelo del barrido: se pasa por debajo deslizándose.
  static const double _sweepLift = 42.0;

  BossAttackComponent({
    required this.kind,
    this.lane = 1,
    this.depth = BossComponent.fightDepth,
  }) : super(size: Vector2(1, 1), priority: 40);

  @override
  void update(double dt) {
    _animT += dt;
    depth += game.depthRate * dt * 1.12;
    _syncTransform();
    if (depth > 1.30) removeFromParent();
  }

  void _syncTransform() {
    final s = game.perspectiveScale(depth);
    if (kind == BossAttackKind.projectile) {
      size = Vector2(_projSize * s, _projSize * s);
      final ground = game.perspectivePos(lane, depth);
      // Vuela ligeramente por encima del suelo
      position =
          Vector2(ground.x - size.x / 2, ground.y - size.y - 10 * s);
    } else {
      // A lo ancho de los 3 carriles a esta profundidad
      final left = game.perspectivePos(0, depth);
      final right = game.perspectivePos(2, depth);
      final width = (right.x - left.x) + 74 * s;
      final height =
          (kind == BossAttackKind.shockwave ? _waveH : _sweepH) * s;
      final lift = kind == BossAttackKind.sweep ? _sweepLift * s : 0.0;
      position = Vector2(game.vanishX - width / 2, left.y - height - lift);
      size = Vector2(width, height);
    }
    priority = (200 * depth).floor() + 6;
  }

  @override
  void render(Canvas canvas) {
    paintBossAttack(
      canvas,
      Size(size.x, size.y),
      kind,
      game.worldId,
      animT: _animT,
    );
  }
}

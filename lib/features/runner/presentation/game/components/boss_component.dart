import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/boss_config.dart';
import '../brix_run_game.dart';
import 'boss_painters.dart';

/// El jefe del mundo: entra desde el horizonte, flota delante del jugador
/// balanceándose entre carriles y encaja las embestidas hasta caer.
class BossComponent extends PositionComponent with HasGameReference<BrixRunGame> {
  static const double baseW = 175.0;
  static const double baseH = 190.0;

  /// Profundidad a la que se detiene para pelear (delante del jugador).
  static const double fightDepth = 0.52;
  static const double _introSpeed = 0.20; // profundidad/s durante la entrada
  static const double _lungeDur = 0.38; // duración de la embestida al atacar

  double depth = 0.06;
  double _animT = 0;
  double _hitFlash = 0;
  double _defeatT = -1; // ≥0 cuando está derrotado (anima caída)
  double _lungeT = -1; // ≥0 mientras embiste hacia el jugador (al atacar)
  double _leanAngle = 0; // inclinación actual (se ladea al balancearse)

  bool get introDone => depth >= fightDepth;
  bool get isDefeated => _defeatT >= 0;
  bool get defeatAnimDone => _defeatT >= 1.4;

  BossComponent() : super(size: Vector2(1, 1), priority: 60);

  /// Destello blanco al recibir una embestida.
  void onDashHit() => _hitFlash = 0.45;

  /// Arranca una embestida: el jefe se lanza hacia el jugador (se usa al
  /// lanzar un ataque para que la pelea tenga más movimiento).
  void lunge() => _lungeT = 0;

  /// Inicia la animación de derrota (gira, cae y se encoge).
  void startDefeat() {
    if (_defeatT < 0) _defeatT = 0;
  }

  @override
  void update(double dt) {
    _animT += dt;
    if (_hitFlash > 0) _hitFlash = max(0, _hitFlash - dt);
    if (_defeatT >= 0) _defeatT += dt;
    if (_lungeT >= 0) {
      _lungeT += dt;
      if (_lungeT > _lungeDur) _lungeT = -1;
    }

    if (!isDefeated && depth < fightDepth) {
      depth = min(fightDepth, depth + _introSpeed * dt);
    }
    _syncTransform();
  }

  void _syncTransform() {
    final defeatShrink =
        isDefeated ? (1.0 - (_defeatT / 1.4).clamp(0.0, 1.0) * 0.85) : 1.0;

    // Movimiento en pelea: respiración (pulso de escala) + embestida al atacar.
    final breathing = isDefeated ? 0.0 : sin(_animT * 3.0) * 0.045;
    final lunge = (!isDefeated && _lungeT >= 0)
        ? sin((_lungeT / _lungeDur) * pi)
        : 0.0;

    final s = game.perspectiveScale(depth) *
        1.18 *
        defeatShrink *
        (1 + breathing + lunge * 0.12);
    size = Vector2(baseW * s, baseH * s);

    // Balanceo lateral entre carriles + flotación vertical (con un bob lento
    // secundario para que no se sienta plano).
    final sway =
        isDefeated ? 0.0 : sin(_animT * 0.75) * game.laneSep * 0.85 * depth;
    final hover = isDefeated
        ? 0.0
        : (sin(_animT * 2.3) * 6.0 + sin(_animT * 1.1) * 3.0) * depth;
    // La embestida lo empuja hacia abajo (hacia el jugador).
    final lungePush = lunge * 30 * depth;
    final fall = isDefeated ? _defeatT * game.size.y * 0.25 : 0.0;

    // Se ladea hacia donde se balancea, y un poco más al embestir.
    _leanAngle =
        isDefeated ? 0.0 : sin(_animT * 0.75) * 0.13 + lunge * 0.10;

    final ground = game.perspectivePos(1, depth);
    position = Vector2(
      game.vanishX + sway - size.x / 2,
      ground.y - size.y - 12 * s - hover + lungePush + fall,
    );
    priority = (200 * depth).floor() + 8;
  }

  @override
  void render(Canvas canvas) {
    final defeated = isDefeated;
    if (defeated) {
      // Se desvanece mientras gira y cae.
      final fade = (1.0 - ((_defeatT - 0.5) / 0.9)).clamp(0.0, 1.0);
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: fade),
      );
    } else {
      canvas.save();
    }
    // Pivote en el centro: inclinación durante la pelea, giro en la derrota.
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(defeated ? _defeatT * 5.0 : _leanAngle);
    canvas.translate(-size.x / 2, -size.y / 2);
    paintBoss(
      canvas,
      Size(size.x, size.y),
      game.worldId,
      animT: _animT,
      enrage: defeated ? 0 : (3 - game.bossHearts).clamp(0, 2),
      hitFlash: _hitFlash > 0 ? (_hitFlash / 0.45) * 0.7 : 0,
    );
    canvas.restore();
  }
}

/// Estallido al derrotar al jefe: destello central, ondas de choque, chispas
/// y escombros de bloques que salen despedidos con gravedad. Se autodestruye
/// al terminar. Nace en el centro del jefe en el momento de la derrota.
class BossDefeatEffect extends PositionComponent {
  final Color primary;
  final Color secondary;

  /// Escala de referencia (el ancho del jefe en pantalla).
  final double baseSize;

  static const double _duration = 1.4;

  double _t = 0;
  final Random _rng = Random();
  late final List<_Debris> _debris;
  late final List<_Spark> _sparks;

  BossDefeatEffect({
    required Vector2 center,
    required this.primary,
    required this.secondary,
    required this.baseSize,
  }) : super(position: center, priority: 320) {
    _debris = List.generate(18, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      final spd = baseSize * (1.1 + _rng.nextDouble() * 2.2);
      return _Debris(
        vx: cos(ang) * spd,
        vy: sin(ang) * spd - baseSize * 1.6, // sesgo hacia arriba
        size: baseSize * (0.10 + _rng.nextDouble() * 0.16),
        color: _rng.nextBool() ? primary : secondary,
        rot: _rng.nextDouble() * pi,
        spin: (_rng.nextDouble() - 0.5) * 14,
      );
    });
    _sparks = List.generate(14, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      final spd = baseSize * (2.2 + _rng.nextDouble() * 3.2);
      return _Spark(
        vx: cos(ang) * spd,
        vy: sin(ang) * spd,
        size: baseSize * (0.03 + _rng.nextDouble() * 0.05),
      );
    });
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t;
    final grav = baseSize * 3.4;

    // Destello central inicial.
    if (t < 0.18) {
      final f = 1 - (t / 0.18);
      canvas.drawCircle(
        Offset.zero,
        baseSize * (0.5 + t * 3.2),
        Paint()..color = Colors.white.withValues(alpha: 0.85 * f),
      );
    }

    // Dos ondas de choque expansivas.
    for (int i = 0; i < 2; i++) {
      final rt = t - i * 0.12;
      if (rt > 0 && rt < 0.6) {
        final p = rt / 0.6;
        canvas.drawCircle(
          Offset.zero,
          baseSize * (0.3 + p * 1.7),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = baseSize * 0.09 * (1 - p)
            ..color = (i == 0 ? secondary : Colors.white)
                .withValues(alpha: 0.7 * (1 - p)),
        );
      }
    }

    // Chispas rápidas que se apagan pronto.
    for (final s in _sparks) {
      final life = (1 - t / 0.7).clamp(0.0, 1.0);
      if (life <= 0) continue;
      final x = s.vx * t;
      final y = s.vy * t + 0.5 * grav * 0.4 * t * t;
      canvas.drawCircle(
        Offset(x, y),
        s.size * life,
        Paint()..color = Colors.amber.withValues(alpha: life),
      );
    }

    // Escombros de bloques con gravedad y giro.
    for (final d in _debris) {
      final life = (1 - t / _duration).clamp(0.0, 1.0);
      final x = d.vx * t;
      final y = d.vy * t + 0.5 * grav * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(d.rot + d.spin * t);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: d.size, height: d.size),
        Paint()..color = d.color.withValues(alpha: life),
      );
      // Tetón del bloque.
      canvas.drawCircle(
        Offset(0, -d.size * 0.12),
        d.size * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.28 * life),
      );
      canvas.restore();
    }
  }
}

class _Debris {
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final double rot;
  final double spin;

  _Debris({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rot,
    required this.spin,
  });
}

class _Spark {
  final double vx;
  final double vy;
  final double size;

  _Spark({required this.vx, required this.vy, required this.size});
}

/// Ataque lanzado por el jefe: nace a la profundidad del jefe y viaja hacia
/// el jugador con la misma lógica de perspectiva que los obstáculos.
class BossAttackComponent extends PositionComponent
    with HasGameReference<BrixRunGame> {
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

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// Nube de polvo al agacharse (deslizar): varias volutas claras que se
/// expanden y se disipan a los pies del corredor, arrastrándose hacia atrás.
class SlideDustEffect extends PositionComponent {
  static const double _duration = 0.42;

  final Random _rng = Random();
  double _t = 0;
  late final List<_Puff> _puffs;

  SlideDustEffect({required Vector2 center})
      : super(position: center, priority: 45) {
    _puffs = List.generate(6, (_) {
      return _Puff(
        // Se arrastran hacia atrás (hacia la cámara) y un poco hacia los lados.
        vx: (_rng.nextDouble() * 2 - 1) * 60,
        vy: 20 + _rng.nextDouble() * 40,
        startR: 4 + _rng.nextDouble() * 5,
        growth: 26 + _rng.nextDouble() * 20,
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
    final p = (_t / _duration).clamp(0.0, 1.0);
    for (final puff in _puffs) {
      final r = puff.startR + puff.growth * p;
      canvas.drawCircle(
        Offset(puff.vx * _t, puff.vy * _t),
        r,
        Paint()
          ..color = const Color(0xFFEBE2D0).withValues(alpha: 0.45 * (1 - p)),
      );
    }
  }
}

class _Puff {
  final double vx;
  final double vy;
  final double startR;
  final double growth;

  _Puff({
    required this.vx,
    required this.vy,
    required this.startR,
    required this.growth,
  });
}

/// Destello de atracción al recoger el imán: partículas que se precipitan
/// hacia el centro (metáfora de "succión") y un anillo naranja que se expande.
/// Se dibuja sobre el jugador para reforzar que el imán acaba de activarse.
class MagnetPickupEffect extends PositionComponent {
  static const double _duration = 0.6;
  static const Color _color = Color(0xFFFF6B35);

  final double baseRadius;
  double _t = 0;
  final Random _rng = Random();
  late final List<_InParticle> _particles;

  MagnetPickupEffect({required Vector2 center, this.baseRadius = 60})
      : super(position: center, priority: 300) {
    _particles = List.generate(12, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      return _InParticle(
        angle: ang,
        startDist: baseRadius * (1.1 + _rng.nextDouble() * 0.8),
        size: 3.0 + _rng.nextDouble() * 3.0,
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
    final p = (_t / _duration).clamp(0.0, 1.0);

    // Anillo que se expande y se desvanece.
    canvas.drawCircle(
      Offset.zero,
      baseRadius * (0.3 + p * 1.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - p)
        ..color = _color.withValues(alpha: 0.8 * (1 - p)),
    );

    // Partículas que se precipitan hacia el centro (succión del imán).
    for (final part in _particles) {
      final dist = part.startDist * (1 - p);
      canvas.drawCircle(
        Offset(cos(part.angle) * dist, sin(part.angle) * dist),
        part.size * (0.4 + 0.6 * (1 - p)),
        Paint()..color = _color.withValues(alpha: (1 - p).clamp(0.0, 1.0)),
      );
    }

    // Núcleo brillante al inicio.
    if (p < 0.5) {
      final f = 1 - p / 0.5;
      canvas.drawCircle(
        Offset.zero,
        baseRadius * 0.18 * (0.5 + f),
        Paint()..color = Colors.white.withValues(alpha: 0.7 * f),
      );
    }
  }
}

class _InParticle {
  final double angle;
  final double startDist;
  final double size;

  _InParticle({
    required this.angle,
    required this.startDist,
    required this.size,
  });
}

/// Rotura del escudo al absorber un golpe: destello blanco, anillo de energía
/// expansivo y fragmentos azules del escudo que salen despedidos con gravedad.
class ShieldBreakEffect extends PositionComponent {
  static const double _duration = 0.7;
  static const Color _color = Color(0xFF00AAFF);

  final double baseRadius;
  double _t = 0;
  final Random _rng = Random();
  late final List<_Shard> _shards;

  ShieldBreakEffect({required Vector2 center, this.baseRadius = 60})
      : super(position: center, priority: 310) {
    _shards = List.generate(10, (_) {
      final ang = _rng.nextDouble() * pi * 2;
      final spd = baseRadius * (2.0 + _rng.nextDouble() * 2.5);
      return _Shard(
        vx: cos(ang) * spd,
        vy: sin(ang) * spd - baseRadius * 0.8, // leve sesgo hacia arriba
        size: baseRadius * (0.10 + _rng.nextDouble() * 0.12),
        rot: _rng.nextDouble() * pi,
        spin: (_rng.nextDouble() - 0.5) * 12,
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
    final p = (t / _duration).clamp(0.0, 1.0);

    // Destello inicial.
    if (t < 0.15) {
      final f = 1 - t / 0.15;
      canvas.drawCircle(
        Offset.zero,
        baseRadius * (0.6 + t * 3),
        Paint()..color = Colors.white.withValues(alpha: 0.8 * f),
      );
    }

    // Anillo de energía expansivo.
    canvas.drawCircle(
      Offset.zero,
      baseRadius * (0.4 + p * 1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseRadius * 0.12 * (1 - p)
        ..color = _color.withValues(alpha: 0.75 * (1 - p)),
    );

    // Fragmentos del escudo que salen despedidos con gravedad y giro.
    final grav = baseRadius * 2.0;
    for (final s in _shards) {
      final life = (1 - p).clamp(0.0, 1.0);
      final x = s.vx * t;
      final y = s.vy * t + 0.5 * grav * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(s.rot + s.spin * t);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s.size, height: s.size),
        Radius.circular(s.size * 0.25),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = _color.withValues(alpha: 0.85 * life),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.6 * life),
      );
      canvas.restore();
    }
  }
}

class _Shard {
  final double vx;
  final double vy;
  final double size;
  final double rot;
  final double spin;

  _Shard({
    required this.vx,
    required this.vy,
    required this.size,
    required this.rot,
    required this.spin,
  });
}

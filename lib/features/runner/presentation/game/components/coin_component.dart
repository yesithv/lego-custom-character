import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

class CoinComponent extends PositionComponent with HasGameReference<BrixRunGame> {
  final int lane;

  double _depth = 0.0;
  bool _collected = false;
  double _age = 0.0;

  /// Cuando el imán está activo y la moneda está cerca, deja de avanzar por
  /// perspectiva y vuela directa hacia el jugador (efecto de atracción).
  bool _magnetized = false;

  static const _baseRadius = 15.0;

  /// A partir de esta profundidad las monedas empiezan a ser atraídas.
  static const _magnetPullDepth = 0.5;

  double get depth => _depth;
  bool get collected => _collected;
  set collected(bool v) => _collected = v;

  /// El juego omite estas monedas en su detección de colisión: se recogen solas
  /// al llegar al jugador.
  bool get magnetized => _magnetized;

  CoinComponent({required this.lane})
      : super(size: Vector2(_baseRadius * 2, _baseRadius * 2), priority: 4);

  @override
  void update(double dt) {
    _age += dt;

    if (_magnetized) {
      _flyToPlayer(dt);
      return;
    }

    _depth += game.depthRate * dt;

    // El imán atrae las monedas del carril propio y los adyacentes.
    if (game.magnetActive &&
        _depth >= _magnetPullDepth &&
        (lane - game.playerLane).abs() <= 1) {
      _magnetized = true;
      _syncTransform(); // fija posición/tamaño de partida antes de volar
      return;
    }

    _syncTransform();
    if (_depth > 1.30) removeFromParent();
  }

  /// Persigue al pecho del jugador con velocidad creciente; al alcanzarlo se
  /// recoge sola. La estela y el brillo naranja los aporta [render].
  void _flyToPlayer(double dt) {
    final target = Vector2(game.playerX, game.playerY + 30);
    final center = position + size / 2;
    final toTarget = target - center;
    final dist = toTarget.length;

    if (dist < 16) {
      _collected = true;
      game.collectCoin();
      removeFromParent();
      return;
    }

    final step = min(720 * dt, dist);
    position += toTarget.normalized() * step;
  }

  void _syncTransform() {
    final s = game.perspectiveScale(_depth);
    final groundPos = game.perspectivePos(lane, _depth);
    final r = _baseRadius * s;
    size = Vector2(r * 2, r * 2);
    // Float slightly above the ground
    final floatOffset = sin(_age * 4.5) * 5.0 * s;
    position = Vector2(
      groundPos.x - r,
      groundPos.y - r * 2.8 - floatOffset,
    );
    priority = (200 * _depth).floor() + 4;
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final pulse = 0.7 + 0.3 * sin(_age * 4.5);

    // Estela naranja del imán mientras la moneda es atraída.
    if (_magnetized) {
      canvas.drawCircle(
        Offset(r, r),
        r + 9 * pulse,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.35 * pulse),
      );
    }

    // Glow
    canvas.drawCircle(
      Offset(r, r),
      r + 4 * pulse,
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.22 * pulse),
    );

    // Coin body
    canvas.drawCircle(Offset(r, r), r, Paint()..color = const Color(0xFFFFD700));

    // Inner shine
    canvas.drawCircle(
      Offset(r - r * 0.22, r - r * 0.22),
      r * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );

    // Border
    canvas.drawCircle(
      Offset(r, r),
      r,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, r * 0.14),
    );

    // Brix stud on coin face
    if (r > 6) {
      canvas.drawCircle(
        Offset(r, r),
        r * 0.32,
        Paint()..color = const Color(0xFF8B6914),
      );
      canvas.drawCircle(
        Offset(r, r),
        r * 0.32,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }
}

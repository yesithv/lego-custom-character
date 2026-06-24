import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

class CoinComponent extends PositionComponent with HasGameRef<BrixRunGame> {
  final int lane;

  double _depth = 0.0;
  bool _collected = false;
  double _age = 0.0;

  static const _baseRadius = 15.0;

  double get depth => _depth;
  bool get collected => _collected;
  set collected(bool v) => _collected = v;

  CoinComponent({required this.lane})
      : super(size: Vector2(_baseRadius * 2, _baseRadius * 2), priority: 4);

  @override
  void update(double dt) {
    _depth += game.depthRate * dt;
    _age += dt;
    _syncTransform();
    if (_depth > 1.30) removeFromParent();
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

    // LEGO stud on coin face
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

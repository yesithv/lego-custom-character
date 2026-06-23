import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

class CoinComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrixRunGame> {
  double _age = 0;
  static const double _radius = 14.0;

  CoinComponent({
    required int lane,
    required double laneY,
    required double startX,
  }) : super(
          position: Vector2(startX, laneY - _radius * 2 - 4),
          size: Vector2(_radius * 2, _radius * 2),
          priority: 4,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: _radius, isSolid: false));
  }

  @override
  void update(double dt) {
    position.x -= game.speed * dt;
    _age += dt;
    if (position.x < -size.x - 10) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Pulsing glow
    final pulse = 0.7 + 0.3 * sin(_age * 4);

    // Glow ring
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius + 4,
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.25 * pulse),
    );

    // Coin body
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()..color = const Color(0xFFFFD700),
    );

    // Inner shine
    canvas.drawCircle(
      Offset(_radius - 3, _radius - 3),
      _radius * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Coin border
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // "₿" or "$" symbol
    final tp = TextPainter(
      text: const TextSpan(
        text: '✦',
        style: TextStyle(
          color: Color(0xFF8B6914),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(_radius - tp.width / 2, _radius - tp.height / 2));
  }
}

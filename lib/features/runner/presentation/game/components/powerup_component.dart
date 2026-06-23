import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';
import 'player_component.dart';

enum PowerupType { shield, magnet }

class PowerupComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrixRunGame> {
  final PowerupType type;
  double _age = 0;
  late double _baseY;
  static const double _radius = 18.0;

  PowerupComponent({
    required int lane,
    required double laneY,
    required double startX,
    required this.type,
  }) : super(
          position: Vector2(startX, laneY - _radius * 2 - 10),
          size: Vector2(_radius * 2, _radius * 2),
          priority: 4,
        );

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
    add(CircleHitbox(radius: _radius, isSolid: false));
  }

  @override
  void update(double dt) {
    position.x -= game.speed * dt;
    _age += dt;
    position.y = _baseY + sin(_age * 3) * 6;
    if (position.x < -size.x - 10) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      game.activatePowerup(type);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.6 + 0.4 * sin(_age * 4);
    final (color, icon) = switch (type) {
      PowerupType.shield => (const Color(0xFF00AAFF), '🛡'),
      PowerupType.magnet => (const Color(0xFFFF6B35), '🧲'),
    };

    // Glow ring
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius + 6,
      Paint()..color = color.withValues(alpha: 0.25 * pulse),
    );

    // Body
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()..color = color,
    );

    // Inner shine
    canvas.drawCircle(
      Offset(_radius - 4, _radius - 4),
      _radius * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Border
    canvas.drawCircle(
      Offset(_radius, _radius),
      _radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Icon
    final tp = TextPainter(
      text: TextSpan(text: icon, style: const TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(_radius - tp.width / 2, _radius - tp.height / 2));
  }
}

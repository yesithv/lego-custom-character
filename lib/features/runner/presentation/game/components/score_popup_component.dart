import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

class ScorePopupComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  final String text;
  final Color color;
  double _life = 0;
  static const double _maxLife = 0.75;

  ScorePopupComponent(
    this.text, {
    required Vector2 spawnPosition,
    this.color = const Color(0xFFFFD700),
  }) : super(position: spawnPosition.clone(), priority: 30);

  @override
  void update(double dt) {
    _life += dt;
    position.y -= 55 * dt;
    if (_life >= _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - (_life / _maxLife)).clamp(0.0, 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: 17,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha * 0.6),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 0));
  }
}

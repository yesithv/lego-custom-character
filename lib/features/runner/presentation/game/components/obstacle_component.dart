import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

enum ObstacleType { block, barrier, spike }

class ObstacleComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrixRunGame> {
  final int lane;
  final ObstacleType type;
  bool _evaded = false;

  static const double _blockW = 48;
  static const double _blockH = 64;
  static const double _barrierW = 64;
  static const double _barrierH = 32;
  static const double _spikeW = 42;
  static const double _spikeH = 52;

  ObstacleComponent({
    required this.lane,
    required double laneY,
    required double startX,
    this.type = ObstacleType.block,
  }) : super(
          position: Vector2(
            startX,
            switch (type) {
              ObstacleType.barrier => laneY - _barrierH + 10,
              ObstacleType.spike => laneY - _spikeH,
              _ => laneY - _blockH,
            },
          ),
          size: switch (type) {
            ObstacleType.barrier => Vector2(_barrierW, _barrierH),
            ObstacleType.spike => Vector2(_spikeW, _spikeH),
            _ => Vector2(_blockW, _blockH),
          },
          priority: 5,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= game.speed * dt;
    if (!_evaded && position.x + size.x < game.playerX - 10) {
      _evaded = true;
      game.evadedObstacle();
    }
    if (position.x < -size.x - 10) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (type == ObstacleType.spike) {
      _renderSpike(canvas);
      return;
    }

    final color = switch (type) {
      ObstacleType.block => Colors.red.shade600,
      ObstacleType.barrier => Colors.orange.shade700,
      _ => Colors.red.shade600,
    };

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      Paint()..color = color,
    );

    // LEGO stud on top
    final studCount = (size.x / 18).floor().clamp(1, 3);
    final studSpacing = size.x / studCount;
    for (int i = 0; i < studCount; i++) {
      final cx = studSpacing * i + studSpacing / 2;
      canvas.drawCircle(Offset(cx, 6), 7, Paint()..color = color.withValues(alpha: 0.7));
      canvas.drawCircle(
        Offset(cx, 6),
        7,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Side shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Label icon
    final icon = type == ObstacleType.barrier ? '━' : '■';
    final tp = TextPainter(
      text: TextSpan(
        text: icon,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(size.x / 2 - tp.width / 2, size.y / 2 - tp.height / 2));
  }

  void _renderSpike(Canvas canvas) {
    final color = Colors.purple.shade700;
    final half = size.x / 2;

    // Main spike triangle
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(0, size.y)
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    // Left face highlight
    final highlight = Path()
      ..moveTo(half, 0)
      ..lineTo(0, size.y)
      ..lineTo(half * 0.6, size.y)
      ..close();
    canvas.drawPath(
        highlight, Paint()..color = Colors.purple.shade400.withValues(alpha: 0.45));

    // Tip glow
    canvas.drawCircle(
      Offset(half, 4),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Outline
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

enum ObstacleType { block, barrier, spike }

class ObstacleComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  final int lane;
  final ObstacleType type;

  double _depth = 0.0;
  bool _evaded = false;
  bool _collided = false;

  // Base dimensions at full scale (depth = 1)
  static const _blockW = 52.0;
  static const _blockH = 68.0;
  static const _barrierW = 80.0;
  static const _barrierH = 34.0;
  static const _spikeW = 48.0;
  static const _spikeH = 58.0;

  double get _baseW => switch (type) {
        ObstacleType.barrier => _barrierW,
        ObstacleType.spike => _spikeW,
        _ => _blockW,
      };

  double get _baseH => switch (type) {
        ObstacleType.barrier => _barrierH,
        ObstacleType.spike => _spikeH,
        _ => _blockH,
      };

  double get depth => _depth;
  bool get evaded => _evaded;
  set evaded(bool v) => _evaded = v;
  bool get collided => _collided;
  set collided(bool v) => _collided = v;

  ObstacleComponent({required this.lane, required this.type})
      : super(size: Vector2(1, 1), priority: 5);

  @override
  void update(double dt) {
    _depth += game.depthRate * dt;
    _syncTransform();
    if (_depth > 1.30) removeFromParent();
  }

  void _syncTransform() {
    final s = game.perspectiveScale(_depth);
    final groundPos = game.perspectivePos(lane, _depth);
    size = Vector2(_baseW * s, _baseH * s);
    // groundPos.y is where the object's bottom touches the ground
    position = Vector2(groundPos.x - size.x / 2, groundPos.y - size.y);
    priority = (200 * _depth).floor() + 5;
  }

  @override
  void render(Canvas canvas) {
    switch (type) {
      case ObstacleType.block:
        _renderBlock(canvas, Colors.red.shade600);
      case ObstacleType.barrier:
        _renderBarrier(canvas);
      case ObstacleType.spike:
        _renderSpike(canvas);
    }
  }

  // Pseudo-3D LEGO brick
  void _renderBlock(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final topH = h * 0.14;
    final sideW = w * 0.13;
    final lighter = _lighten(color, 0.15);
    final darker = _darken(color, 0.30);

    // Front face
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topH, w - sideW, h - topH), Radius.circular(4)),
      Paint()..color = color,
    );

    // Top face
    final top = Path()
      ..moveTo(0, topH)
      ..lineTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(sideW, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = lighter);

    // Right side face
    final side = Path()
      ..moveTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(w, h - topH)
      ..lineTo(w - sideW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);

    // LEGO studs on top
    final studCount = max(1, (w / 20).floor());
    final studW = (w - sideW) / studCount;
    for (int i = 0; i < studCount; i++) {
      final cx = i * studW + studW / 2;
      canvas.drawCircle(Offset(cx + sideW * 0.5, topH - 4 * (h / _blockH)),
          5.0 * (w / _blockW), Paint()..color = lighter);
      canvas.drawCircle(
        Offset(cx + sideW * 0.5, topH - 4 * (h / _blockH)),
        5.0 * (w / _blockW),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topH, w - sideW, h - topH), Radius.circular(4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Barrier: wide horizontal bar with pseudo-3D depth
  void _renderBarrier(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final color = Colors.orange.shade700;
    final topH = h * 0.18;
    final sideW = w * 0.06;

    // Front face (orange horizontal bar)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topH, w - sideW, h - topH),
          Radius.circular(5)),
      Paint()..color = color,
    );

    // Top face
    final top = Path()
      ..moveTo(0, topH)
      ..lineTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(sideW, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = _lighten(color, 0.12));

    // Right side
    final side = Path()
      ..moveTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w - sideW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = _darken(color, 0.28));

    // Warning stripes on front face
    final stripeH = (h - topH) / 5;
    for (int i = 0; i < 3; i++) {
      if (i.isEven) continue;
      canvas.drawRect(
        Rect.fromLTWH(0, topH + i * stripeH, w - sideW, stripeH),
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
    }

    // Support poles (left and right)
    final poleColor = Colors.grey.shade700;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.04, h, w * 0.07, h * 0.28),
        Paint()..color = poleColor);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.82, h, w * 0.07, h * 0.28),
        Paint()..color = poleColor);
  }

  // Spike: pyramid shape with glow tip
  void _renderSpike(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final color = Colors.purple.shade700;
    final half = w / 2;

    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    // Left face highlight
    final highlight = Path()
      ..moveTo(half, 0)
      ..lineTo(0, h)
      ..lineTo(half * 0.55, h)
      ..close();
    canvas.drawPath(highlight,
        Paint()..color = Colors.purple.shade400.withValues(alpha: 0.45));

    // Right face (darker)
    final darkFace = Path()
      ..moveTo(half, 0)
      ..lineTo(w, h)
      ..lineTo(half * 1.45, h)
      ..close();
    canvas.drawPath(darkFace,
        Paint()..color = Colors.black.withValues(alpha: 0.22));

    // Tip glow
    canvas.drawCircle(Offset(half, 3),
        max(2.0, 4.5 * (w / _spikeW)), Paint()..color = Colors.white.withValues(alpha: 0.45));

    // Outline
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

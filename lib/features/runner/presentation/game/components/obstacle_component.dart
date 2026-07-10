import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
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
    final colors = colorsFor(game.worldId);
    switch (type) {
      case ObstacleType.block:
        _renderBlock(canvas, colors.obstacleBlock);
      case ObstacleType.barrier:
        _renderBarrier(canvas, colors.obstacleBarrier);
      case ObstacleType.spike:
        _renderSpike(canvas, colors.obstacleSpike);
    }
  }

  // Pseudo-3D LEGO brick, decorated per world
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

    _decorateBlock(canvas, w, h, topH, sideW, color);

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

  // World-specific texture on the block's front face
  void _decorateBlock(
      Canvas canvas, double w, double h, double topH, double sideW, Color color) {
    final faceW = w - sideW;
    switch (game.worldId) {
      case 'medieval':
        // Stone cracks
        final crack = Paint()
          ..color = Colors.black.withValues(alpha: 0.30)
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;
        final p1 = Path()
          ..moveTo(faceW * 0.30, topH + h * 0.15)
          ..lineTo(faceW * 0.45, topH + h * 0.38)
          ..lineTo(faceW * 0.32, topH + h * 0.58);
        final p2 = Path()
          ..moveTo(faceW * 0.72, topH + h * 0.30)
          ..lineTo(faceW * 0.60, topH + h * 0.52);
        canvas.drawPath(p1, crack);
        canvas.drawPath(p2, crack);
      case 'galaxy':
        // Meteor craters
        final crater = Paint()..color = Colors.black.withValues(alpha: 0.25);
        canvas.drawCircle(
            Offset(faceW * 0.30, topH + h * 0.28), w * 0.10, crater);
        canvas.drawCircle(
            Offset(faceW * 0.68, topH + h * 0.55), w * 0.07, crater);
        canvas.drawCircle(
            Offset(faceW * 0.45, topH + h * 0.72), w * 0.05, crater);
      case 'jungle':
        // Moss patches on the upper edge
        final moss = Paint()
          ..color = Colors.green.shade900.withValues(alpha: 0.55);
        canvas.drawOval(
            Rect.fromLTWH(faceW * 0.05, topH, faceW * 0.45, h * 0.14), moss);
        canvas.drawOval(
            Rect.fromLTWH(faceW * 0.55, topH, faceW * 0.38, h * 0.10), moss);
      case 'tundra':
        // Ice shine streaks
        final shine = Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(faceW * 0.25, topH + h * 0.20),
            Offset(faceW * 0.55, topH + h * 0.60), shine);
        canvas.drawLine(Offset(faceW * 0.45, topH + h * 0.15),
            Offset(faceW * 0.70, topH + h * 0.45), shine);
      case 'ocean':
        // Coral pores
        final pore = Paint()..color = _lighten(color, 0.22);
        canvas.drawCircle(Offset(faceW * 0.28, topH + h * 0.32), w * 0.05, pore);
        canvas.drawCircle(Offset(faceW * 0.62, topH + h * 0.48), w * 0.06, pore);
        canvas.drawCircle(Offset(faceW * 0.40, topH + h * 0.66), w * 0.04, pore);
      case 'robot_city':
        // Rivets and a neon stripe
        final rivet = Paint()..color = Colors.black.withValues(alpha: 0.45);
        for (final dx in [0.12, 0.88]) {
          for (final dy in [0.22, 0.78]) {
            canvas.drawCircle(
                Offset(faceW * dx, topH + (h - topH) * dy), w * 0.035, rivet);
          }
        }
        canvas.drawRect(
          Rect.fromLTWH(0, topH + (h - topH) * 0.46, faceW, h * 0.06),
          Paint()..color = const Color(0xFF00FF41).withValues(alpha: 0.75),
        );
      case 'dark_city':
        // Hazard corner marks
        final mark = Paint()..color = const Color(0xFFE94560).withValues(alpha: 0.85);
        canvas.drawRect(Rect.fromLTWH(0, topH, faceW * 0.18, h * 0.06), mark);
        canvas.drawRect(
            Rect.fromLTWH(faceW * 0.82, h - h * 0.06, faceW * 0.18, h * 0.06),
            mark);
      default:
        break;
    }
  }

  // Barrier: wide horizontal bar with pseudo-3D depth, themed per world
  void _renderBarrier(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final world = game.worldId;
    final isLaser = world == 'galaxy' || world == 'robot_city';
    final topH = h * 0.18;
    final sideW = w * 0.06;

    // Support poles (left and right)
    final poleColor = isLaser ? Colors.blueGrey.shade800 : Colors.grey.shade700;
    canvas.drawRect(
        Rect.fromLTWH(w * 0.04, h, w * 0.07, h * 0.28),
        Paint()..color = poleColor);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.82, h, w * 0.07, h * 0.28),
        Paint()..color = poleColor);

    if (isLaser) {
      _renderLaserBar(canvas, w, h, color);
      return;
    }

    // Front face
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

    switch (world) {
      case 'medieval':
      case 'jungle':
        // Wooden log: grain lines and end ring
        final grain = Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (int i = 1; i <= 2; i++) {
          final gy = topH + (h - topH) * i / 3;
          canvas.drawLine(Offset(w * 0.04, gy), Offset(w - sideW, gy), grain);
        }
        canvas.drawCircle(Offset(w * 0.06, topH + (h - topH) / 2),
            (h - topH) * 0.30, Paint()..color = _lighten(color, 0.18));
        if (world == 'jungle') {
          // Hanging leaves
          final leaf = Paint()..color = Colors.green.shade700;
          for (final dx in [0.22, 0.52, 0.76]) {
            canvas.drawOval(
                Rect.fromLTWH(w * dx, h - 2, w * 0.09, h * 0.24), leaf);
          }
        }
      case 'tundra':
        // Hanging icicles
        final ice = Paint()..color = Colors.white.withValues(alpha: 0.85);
        for (final dx in [0.15, 0.38, 0.60, 0.80]) {
          final icicle = Path()
            ..moveTo(w * dx, h - 1)
            ..lineTo(w * dx + w * 0.035, h - 1)
            ..lineTo(w * dx + w * 0.017, h + h * 0.30)
            ..close();
          canvas.drawPath(icicle, ice);
        }
        canvas.drawRect(
          Rect.fromLTWH(0, topH, w - sideW, (h - topH) * 0.25),
          Paint()..color = Colors.white.withValues(alpha: 0.40),
        );
      case 'ocean':
        // Seaweed wraps and bubbles
        final wrapPaint = Paint()..color = _darken(color, 0.15);
        for (final dx in [0.25, 0.60]) {
          canvas.drawRect(
              Rect.fromLTWH(w * dx, topH, w * 0.07, h - topH), wrapPaint);
        }
        final bubble = Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(Offset(w * 0.45, topH - 6), 3.5, bubble);
        canvas.drawCircle(Offset(w * 0.52, topH - 12), 2.2, bubble);
      default:
        // Warning stripes (lego_city, dark_city, fallback)
        final stripeH = (h - topH) / 5;
        for (int i = 0; i < 3; i++) {
          if (i.isEven) continue;
          canvas.drawRect(
            Rect.fromLTWH(0, topH + i * stripeH, w - sideW, stripeH),
            Paint()..color = Colors.black.withValues(alpha: 0.18),
          );
        }
    }
  }

  // Glowing energy beam between two emitter poles (galaxy / robot_city)
  void _renderLaserBar(Canvas canvas, double w, double h, Color color) {
    final beamY = h * 0.42;
    final beamH = h * 0.24;
    final pulse = 0.75 + 0.25 * sin(game.elapsedSeconds * 8);

    // Outer glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.02, beamY - beamH * 0.7, w * 0.96, beamH * 2.4),
          Radius.circular(beamH)),
      Paint()..color = color.withValues(alpha: 0.22 * pulse),
    );
    // Beam core
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, beamY, w * 0.90, beamH),
          Radius.circular(beamH / 2)),
      Paint()..color = color.withValues(alpha: 0.95 * pulse),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, beamY + beamH * 0.25, w * 0.90, beamH * 0.4),
          Radius.circular(beamH / 4)),
      Paint()..color = Colors.white.withValues(alpha: 0.80 * pulse),
    );

    // Emitter nodes
    final node = Paint()..color = _lighten(color, 0.20);
    canvas.drawCircle(Offset(w * 0.075, beamY + beamH / 2), beamH * 0.85, node);
    canvas.drawCircle(Offset(w * 0.925, beamY + beamH / 2), beamH * 0.85, node);
  }

  // Spike: themed pointed obstacle per world
  void _renderSpike(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final world = game.worldId;
    final half = w / 2;

    if (world == 'lego_city') {
      _renderCone(canvas, w, h, color);
      return;
    }

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
        Paint()..color = _lighten(color, 0.14).withValues(alpha: 0.45));

    // Right face (darker)
    final darkFace = Path()
      ..moveTo(half, 0)
      ..lineTo(w, h)
      ..lineTo(half * 1.45, h)
      ..close();
    canvas.drawPath(darkFace,
        Paint()..color = Colors.black.withValues(alpha: 0.22));

    switch (world) {
      case 'galaxy':
        // Crystal facet lines + strong glow
        final facet = Paint()
          ..color = Colors.white.withValues(alpha: 0.50)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(half, 0), Offset(half * 0.55, h), facet);
        canvas.drawLine(Offset(half, 0), Offset(half * 1.45, h), facet);
        canvas.drawCircle(Offset(half, 3), max(3.0, 7.0 * (w / _spikeW)),
            Paint()..color = const Color(0xFF00FFFF).withValues(alpha: 0.40));
      case 'jungle':
        // Carnivorous plant: red tip + leaves at the base
        final tip = Path()
          ..moveTo(half, 0)
          ..lineTo(half - w * 0.14, h * 0.28)
          ..lineTo(half + w * 0.14, h * 0.28)
          ..close();
        canvas.drawPath(tip, Paint()..color = Colors.red.shade700);
        final leaf = Paint()..color = Colors.green.shade800;
        canvas.drawOval(
            Rect.fromLTWH(-w * 0.06, h - h * 0.16, w * 0.36, h * 0.16), leaf);
        canvas.drawOval(
            Rect.fromLTWH(w * 0.70, h - h * 0.16, w * 0.36, h * 0.16), leaf);
      case 'tundra':
        // Icicle shine
        final shine = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
            Offset(half * 0.85, h * 0.18), Offset(half * 0.62, h * 0.72), shine);
      case 'ocean':
        // Sea urchin: thin spines out the sides
        final spine = Paint()
          ..color = _darken(color, 0.10)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        for (final t in [0.35, 0.55, 0.75]) {
          final sy = h * t;
          final sx = half * (1 - t) * 0.9;
          canvas.drawLine(Offset(half - sx, sy),
              Offset(half - sx - w * 0.16, sy - h * 0.06), spine);
          canvas.drawLine(Offset(half + sx, sy),
              Offset(half + sx + w * 0.16, sy - h * 0.06), spine);
        }
      case 'medieval':
        // Stone cracks
        final crack = Paint()
          ..color = Colors.black.withValues(alpha: 0.30)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        final p = Path()
          ..moveTo(half * 0.9, h * 0.35)
          ..lineTo(half * 1.1, h * 0.55)
          ..lineTo(half * 0.95, h * 0.75);
        canvas.drawPath(p, crack);
      case 'robot_city':
        // Blinking antenna tip
        final blink = (sin(game.elapsedSeconds * 6) + 1) / 2;
        canvas.drawCircle(Offset(half, 3), max(2.5, 5.0 * (w / _spikeW)),
            Paint()
              ..color = const Color(0xFF00FF41)
                  .withValues(alpha: 0.35 + 0.60 * blink));
      case 'dark_city':
        canvas.drawCircle(Offset(half, 3), max(2.0, 4.5 * (w / _spikeW)),
            Paint()
              ..color = const Color(0xFFE94560).withValues(alpha: 0.60));
      default:
        canvas.drawCircle(Offset(half, 3), max(2.0, 4.5 * (w / _spikeW)),
            Paint()..color = Colors.white.withValues(alpha: 0.45));
    }

    // Outline
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Traffic cone for lego_city
  void _renderCone(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    final cone = Path()
      ..moveTo(half - w * 0.10, h * 0.06)
      ..lineTo(half + w * 0.10, h * 0.06)
      ..lineTo(half + w * 0.34, h * 0.88)
      ..lineTo(half - w * 0.34, h * 0.88)
      ..close();
    canvas.drawPath(cone, Paint()..color = color);

    // Reflective white band
    final band = Path()
      ..moveTo(half - w * 0.17, h * 0.36)
      ..lineTo(half + w * 0.17, h * 0.36)
      ..lineTo(half + w * 0.22, h * 0.54)
      ..lineTo(half - w * 0.22, h * 0.54)
      ..close();
    canvas.drawPath(band, Paint()..color = Colors.white.withValues(alpha: 0.90));

    // Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(half - w * 0.44, h * 0.86, w * 0.88, h * 0.14),
          Radius.circular(3)),
      Paint()..color = _darken(color, 0.12),
    );

    // Side shading
    final shade = Path()
      ..moveTo(half + w * 0.02, h * 0.06)
      ..lineTo(half + w * 0.10, h * 0.06)
      ..lineTo(half + w * 0.34, h * 0.88)
      ..lineTo(half + w * 0.14, h * 0.88)
      ..close();
    canvas.drawPath(
        shade, Paint()..color = Colors.black.withValues(alpha: 0.15));

    canvas.drawPath(
      cone,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
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

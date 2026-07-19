import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
import '../brix_run_game.dart';

enum ObstacleType { block, barrier, spike }

class ObstacleComponent extends PositionComponent
    with HasGameReference<BrixRunGame> {
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

  // ─────────────────────────────────────────────────────────────────
  //  BLOCK RENDERING (Mini objects / themes per world)
  // ─────────────────────────────────────────────────────────────────
  void _renderBlock(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final world = game.worldId;

    if (world == 'brix_city') {
      _renderBrixBuilding(canvas, w, h, color);
      return;
    } else if (world == 'medieval') {
      _renderCastleTower(canvas, w, h, color);
      return;
    } else if (world == 'jungle') {
      _renderFallenLog(canvas, w, h, color);
      return;
    } else if (world == 'dark_city') {
      _renderTombstone(canvas, w, h, color);
      return;
    } else if (world == 'ocean') {
      _renderCoralRock(canvas, w, h, color);
      return;
    } else if (world == 'tundra') {
      _renderIceBlock(canvas, w, h, color);
      return;
    } else if (world == 'robot_city') {
      _renderPcbBlock(canvas, w, h, color);
      return;
    } else if (world == 'galaxy') {
      _renderAsteroid(canvas, w, h, color);
      return;
    }

    // Fallback block
    _renderDefaultBlock(canvas, w, h, color);
  }

  // 1. Brix Building (brix_city)
  void _renderBrixBuilding(Canvas canvas, double w, double h, Color color) {
    final lighter = _lighten(color, 0.15);
    final darker = _darken(color, 0.25);
    final topH = h * 0.12;
    final sideW = w * 0.12;

    // Main building body
    canvas.drawRect(Rect.fromLTWH(0, topH, w - sideW, h - topH), Paint()..color = color);
    // Roof top
    final top = Path()
      ..moveTo(0, topH)
      ..lineTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(sideW, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = lighter);
    // Side
    final side = Path()
      ..moveTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(w, h - topH)
      ..lineTo(w - sideW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);

    // Windows (yellow glowing grids)
    final winPaint = Paint()..color = const Color(0xFFFFEB3B);
    final winW = (w - sideW) * 0.22;
    final winH = (h - topH) * 0.18;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final wx = (w - sideW) * 0.15 + col * (winW + (w - sideW) * 0.15);
        final wy = topH + (h - topH) * 0.12 + row * (winH + (h - topH) * 0.12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(wx, wy, winW, winH), Radius.circular(2)),
          winPaint,
        );
      }
    }

    // Antenna on roof
    final antPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset((w - sideW) / 2, topH), Offset((w - sideW) / 2, -h * 0.15), antPaint);
    canvas.drawCircle(Offset((w - sideW) / 2, -h * 0.15), 4.0, Paint()..color = Colors.red);
  }

  // 2. Castle Tower (medieval)
  void _renderCastleTower(Canvas canvas, double w, double h, Color color) {
    final darker = _darken(color, 0.25);
    final lighter = _lighten(color, 0.15);
    final faceW = w * 0.88;

    // Draw main stone tower base
    canvas.drawRect(Rect.fromLTWH(0, h * 0.20, faceW, h * 0.80), Paint()..color = color);
    
    // Draw tower side depth
    final side = Path()
      ..moveTo(faceW, h * 0.20)
      ..lineTo(w, h * 0.10)
      ..lineTo(w, h * 0.90)
      ..lineTo(faceW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);

    // Draw crenellations (castle battlements) on top
    final battlementPaint = Paint()..color = color;
    final mWidth = faceW / 5;
    for (int i = 0; i < 5; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(i * mWidth, 0, mWidth, h * 0.22),
          battlementPaint,
        );
      }
    }
    // Draw top stone platform line
    canvas.drawLine(
      Offset(0, h * 0.20),
      Offset(faceW, h * 0.20),
      Paint()
        ..color = lighter
        ..strokeWidth = 2.0,
    );

    // Archway door
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(faceW * 0.30, h * 0.55, faceW * 0.40, h * 0.45),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()..color = darker,
    );

    // Stone cracks
    final crack = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(faceW * 0.15, h * 0.40), Offset(faceW * 0.25, h * 0.48), crack);
    canvas.drawLine(Offset(faceW * 0.80, h * 0.60), Offset(faceW * 0.70, h * 0.72), crack);
  }

  // 3. Fallen Log (jungle)
  void _renderFallenLog(Canvas canvas, double w, double h, Color color) {
    final darkBrown = _darken(color, 0.25);
    final lightBrown = _lighten(color, 0.15);

    // Main horizontal log shape
    final logRect = Rect.fromLTWH(0, h * 0.15, w * 0.85, h * 0.70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(logRect, Radius.circular(h * 0.15)),
      Paint()..color = color,
    );

    // End wood rings (on the right)
    final ringCenter = Offset(w * 0.85, h * 0.50);
    canvas.drawOval(
      Rect.fromCenter(center: ringCenter, width: w * 0.15, height: h * 0.60),
      Paint()..color = darkBrown,
    );
    canvas.drawOval(
      Rect.fromCenter(center: ringCenter, width: w * 0.09, height: h * 0.36),
      Paint()..color = lightBrown,
    );

    // Bark texture lines
    final barkPaint = Paint()
      ..color = darkBrown
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.15, h * 0.35), Offset(w * 0.60, h * 0.35), barkPaint);
    canvas.drawLine(Offset(w * 0.25, h * 0.65), Offset(w * 0.70, h * 0.65), barkPaint);

    // Growing moss patch on top of the log
    final mossPaint = Paint()..color = Colors.green.shade700;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.10, h * 0.08, w * 0.40, h * 0.18),
      mossPaint,
    );
  }

  // 4. Tombstone (dark_city)
  void _renderTombstone(Canvas canvas, double w, double h, Color color) {
    final darker = _darken(color, 0.25);
    final faceW = w * 0.88;

    // Rounded top arch for tombstone
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.35)
      ..arcToPoint(Offset(faceW, h * 0.35), radius: Radius.circular(faceW / 2))
      ..lineTo(faceW, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // Side depth
    final sidePath = Path()
      ..moveTo(faceW, h * 0.35)
      ..arcToPoint(Offset(w, h * 0.30), radius: Radius.circular(faceW / 2))
      ..lineTo(w, h * 0.90)
      ..lineTo(faceW, h)
      ..lineTo(faceW, h * 0.35)
      ..close();
    canvas.drawPath(sidePath, Paint()..color = darker);

    // Cross engraving
    final engrave = Paint()
      ..color = Colors.black.withValues(alpha: 0.50)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(faceW * 0.50, h * 0.38), Offset(faceW * 0.50, h * 0.78), engrave);
    canvas.drawLine(Offset(faceW * 0.32, h * 0.50), Offset(faceW * 0.68, h * 0.50), engrave);

    // RIP Text
    const textStyle = TextStyle(
      color: Colors.black45,
      fontSize: 10,
      fontWeight: FontWeight.w900,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: 'R I P', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((faceW - textPainter.width) / 2, h * 0.82 - textPainter.height),
    );
  }

  // 5. Coral Rock (ocean)
  void _renderCoralRock(Canvas canvas, double w, double h, Color color) {
    final lighter = _lighten(color, 0.20);
    final darker = _darken(color, 0.25);

    // Organic wavy shape
    final path = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.10, h * 0.30, w * 0.35, h * 0.20)
      ..quadraticBezierTo(w * 0.55, 0, w * 0.70, h * 0.35)
      ..quadraticBezierTo(w * 0.95, h * 0.45, w * 0.90, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // Shading
    final shade = Path()
      ..moveTo(w * 0.70, h * 0.35)
      ..quadraticBezierTo(w * 0.95, h * 0.45, w * 0.90, h)
      ..lineTo(w * 0.68, h)
      ..quadraticBezierTo(w * 0.75, h * 0.55, w * 0.60, h * 0.42)
      ..close();
    canvas.drawPath(shade, Paint()..color = darker);

    // Coral pores (circles)
    final porePaint = Paint()..color = lighter;
    canvas.drawCircle(Offset(w * 0.30, h * 0.45), w * 0.08, porePaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.55), w * 0.06, porePaint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.75), w * 0.09, porePaint);

    // Tiny pink anemone tentacle on top
    final tentaclePaint = Paint()
      ..color = const Color(0xFFFF4081)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.35, h * 0.20), Offset(w * 0.30, h * 0.08), tentaclePaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.18), Offset(w * 0.45, h * 0.06), tentaclePaint);
  }

  // 6. Ice Block (tundra)
  void _renderIceBlock(Canvas canvas, double w, double h, Color color) {
    final lighter = _lighten(color, 0.25);
    final darker = _darken(color, 0.25);
    final faceW = w * 0.88;

    // Semi-translucent body
    final iceRect = Rect.fromLTWH(0, h * 0.12, faceW, h * 0.88);
    canvas.drawRect(
      iceRect,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill,
    );

    // Ice shine top and side
    final top = Path()
      ..moveTo(0, h * 0.12)
      ..lineTo(faceW, h * 0.12)
      ..lineTo(w, 0)
      ..lineTo(w * 0.12, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = lighter);

    final side = Path()
      ..moveTo(faceW, h * 0.12)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.88)
      ..lineTo(faceW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);

    // Inner frozen star/shatter lines
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(faceW * 0.25, h * 0.35), Offset(faceW * 0.75, h * 0.75), crackPaint);
    canvas.drawLine(Offset(faceW * 0.70, h * 0.30), Offset(faceW * 0.30, h * 0.80), crackPaint);
  }

  // 7. PCB block (robot_city)
  void _renderPcbBlock(Canvas canvas, double w, double h, Color color) {
    final darker = _darken(color, 0.25);
    final faceW = w * 0.88;

    // Green/dark grey metal plate
    canvas.drawRect(Rect.fromLTWH(0, h * 0.12, faceW, h * 0.88), Paint()..color = color);

    // Edge
    final side = Path()
      ..moveTo(faceW, h * 0.12)
      ..lineTo(w, 0)
      ..lineTo(w, h - h * 0.12)
      ..lineTo(faceW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);

    // Circuit board lines (neon green)
    final pcbPaint = Paint()
      ..color = const Color(0xFF00FF41)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(faceW * 0.20, h * 0.80)
      ..lineTo(faceW * 0.20, h * 0.50)
      ..lineTo(faceW * 0.50, h * 0.35)
      ..lineTo(faceW * 0.80, h * 0.35);
    canvas.drawPath(path, pcbPaint);

    // Nodes (soldering circles)
    final nodePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(faceW * 0.20, h * 0.80), 3, nodePaint);
    canvas.drawCircle(Offset(faceW * 0.80, h * 0.35), 3, nodePaint);
  }

  // 8. Asteroid (galaxy)
  void _renderAsteroid(Canvas canvas, double w, double h, Color color) {
    final darker = _darken(color, 0.25);
    final lighter = _lighten(color, 0.15);

    // Jagged hexagonal shape
    final path = Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w, h * 0.35)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.15, h)
      ..lineTo(0, h * 0.45)
      ..close();
    canvas.drawPath(path, Paint()..color = color);

    // Crater highlights
    final crater = Paint()..color = darker;
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), w * 0.12, crater);
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), w * 0.05, Paint()..color = const Color(0xFF00FFFF)); // cyan center

    canvas.drawCircle(Offset(w * 0.65, h * 0.65), w * 0.10, crater);
    canvas.drawCircle(Offset(w * 0.65, h * 0.65), w * 0.04, Paint()..color = const Color(0xFF00FFFF));

    // Outer rock facets
    final facetPaint = Paint()
      ..color = lighter.withValues(alpha: 0.40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.25, 0), Offset(w * 0.35, h * 0.35), facetPaint);
    canvas.drawLine(Offset(0, h * 0.45), Offset(w * 0.35, h * 0.35), facetPaint);
  }

  // Fallback / default block
  void _renderDefaultBlock(Canvas canvas, double w, double h, Color color) {
    final topH = h * 0.14;
    final sideW = w * 0.13;
    final lighter = _lighten(color, 0.15);
    final darker = _darken(color, 0.30);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topH, w - sideW, h - topH), Radius.circular(4)),
      Paint()..color = color,
    );

    final top = Path()
      ..moveTo(0, topH)
      ..lineTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(sideW, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = lighter);

    final side = Path()
      ..moveTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(w, h - topH)
      ..lineTo(w - sideW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = darker);
  }

  // ─────────────────────────────────────────────────────────────────
  //  BARRIER RENDERING (Traffic lights, portcullis, lianas, etc.)
  // ─────────────────────────────────────────────────────────────────
  void _renderBarrier(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final world = game.worldId;
    final isLaser = world == 'galaxy' || world == 'robot_city';
    final topH = h * 0.18;
    final sideW = w * 0.06;

    // Support poles (left and right)
    final poleColor = isLaser ? Colors.blueGrey.shade800 : Colors.grey.shade700;
    canvas.drawRect(Rect.fromLTWH(w * 0.04, h, w * 0.07, h * 0.28), Paint()..color = poleColor);
    canvas.drawRect(Rect.fromLTWH(w * 0.82, h, w * 0.07, h * 0.28), Paint()..color = poleColor);

    if (isLaser) {
      _renderLaserBar(canvas, w, h, color);
      return;
    }

    if (world == 'brix_city') {
      _renderTrafficLightBarrier(canvas, w, h, color);
      return;
    } else if (world == 'medieval') {
      _renderPortcullis(canvas, w, h, color);
      return;
    } else if (world == 'jungle') {
      _renderLianaBarrier(canvas, w, h, color);
      return;
    } else if (world == 'dark_city') {
      _renderRustyChainBarrier(canvas, w, h, color);
      return;
    } else if (world == 'ocean') {
      _renderKelpBarrier(canvas, w, h, color);
      return;
    } else if (world == 'tundra') {
      _renderSnowyBarrier(canvas, w, h, color);
      return;
    }

    // Default bar
    _renderDefaultBar(canvas, w, h, color, topH, sideW);
  }

  // 1. Brix Traffic Light Barrier (brix_city)
  void _renderTrafficLightBarrier(Canvas canvas, double w, double h, Color color) {
    final topH = h * 0.18;
    final sideW = w * 0.06;
    // Draw yellow/black striped warning bar
    _renderDefaultBar(canvas, w, h, color, topH, sideW);

    // Render traffic light box in the center
    final boxW = w * 0.16;
    final boxH = h * 0.90;
    final boxX = (w - sideW - boxW) / 2;
    final boxY = topH - boxH * 0.10;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxW, boxH), Radius.circular(3)),
      Paint()..color = Colors.black87,
    );

    // Lights: Red, Yellow, Green
    final lightR = boxW * 0.26;
    final pulse = 0.5 + 0.5 * sin(game.elapsedSeconds * 6);

    // Red light (active/blinking)
    canvas.drawCircle(
      Offset(boxX + boxW / 2, boxY + boxH * 0.22),
      lightR,
      Paint()..color = Colors.red.withValues(alpha: 0.3 + 0.7 * pulse),
    );
    // Yellow light (faint)
    canvas.drawCircle(
      Offset(boxX + boxW / 2, boxY + boxH * 0.50),
      lightR,
      Paint()..color = Colors.amber.withValues(alpha: 0.2),
    );
    // Green light (faint)
    canvas.drawCircle(
      Offset(boxX + boxW / 2, boxY + boxH * 0.78),
      lightR,
      Paint()..color = Colors.green.withValues(alpha: 0.2),
    );
  }

  // 2. Portcullis (medieval)
  void _renderPortcullis(Canvas canvas, double w, double h, Color color) {
    // Draw iron horizontal bar
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.25), Paint()..color = color);

    // Vertical metal iron spikes going down
    final metalPaint = Paint()
      ..color = color
      ..strokeWidth = 3.0;
    final tipPaint = Paint()..color = _darken(color, 0.20);

    const count = 7;
    for (int i = 0; i < count; i++) {
      final dx = w * 0.08 + i * (w * 0.84 / (count - 1));
      // Draw vertical rod
      canvas.drawLine(Offset(dx, h * 0.20), Offset(dx, h * 0.88), metalPaint);

      // Draw spiked tips at bottom of rods
      final tip = Path()
        ..moveTo(dx - 3, h * 0.88)
        ..lineTo(dx + 3, h * 0.88)
        ..lineTo(dx, h)
        ..close();
      canvas.drawPath(tip, tipPaint);
    }
  }

  // 3. Liana Barrier (jungle)
  void _renderLianaBarrier(Canvas canvas, double w, double h, Color color) {
    // Wavy green vine going across
    final vinePaint = Paint()
      ..color = Colors.green.shade800
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    
    final vine = Path()
      ..moveTo(0, h * 0.30)
      ..quadraticBezierTo(w * 0.25, h * 0.65, w * 0.50, h * 0.35)
      ..quadraticBezierTo(w * 0.75, h * 0.10, w, h * 0.40);
    canvas.drawPath(vine, vinePaint);

    // Hanging leaves
    final leafPaint = Paint()..color = Colors.green.shade600;
    for (int i = 1; i <= 4; i++) {
      final dx = w * 0.20 * i;
      final dy = h * 0.45;
      canvas.drawOval(Rect.fromLTWH(dx - 6, dy, 12, 16), leafPaint);
    }
  }

  // 4. Rusty iron chains (dark_city)
  void _renderRustyChainBarrier(Canvas canvas, double w, double h, Color color) {
    final chainPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // Draw hanging chain paths
    final path = Path()
      ..moveTo(0, h * 0.30)
      ..quadraticBezierTo(w * 0.50, h * 0.90, w, h * 0.30);
    canvas.drawPath(path, chainPaint);

    // Draw chain links
    final linkPaint = Paint()
      ..color = _lighten(color, 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      final t = i / 7.0;
      final cx = w * t;
      final cy = h * 0.30 + (h * 0.60) * (4 * (t - 0.5) * (t - 0.5)); // parabola
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 10, height: 6),
        linkPaint,
      );
    }
  }

  // 5. Giant Kelp Algae (ocean)
  void _renderKelpBarrier(Canvas canvas, double w, double h, Color color) {
    final kelpPaint = Paint()..color = color;
    
    // Multiple wavy vertical kelp stems
    for (int i = 0; i < 4; i++) {
      final base = w * 0.18 + i * (w * 0.64 / 3);
      final offset = sin(game.elapsedSeconds * 4 + i) * 6;
      final path = Path()
        ..moveTo(base + offset, 0)
        ..quadraticBezierTo(base - 10 + offset, h * 0.50, base + offset, h)
        ..lineTo(base + w * 0.08 + offset, h)
        ..quadraticBezierTo(base + w * 0.08 - 10 + offset, h * 0.50, base + w * 0.08 + offset, 0)
        ..close();
      canvas.drawPath(path, kelpPaint);
    }
  }

  // 6. Snowy Barrier (tundra)
  void _renderSnowyBarrier(Canvas canvas, double w, double h, Color color) {
    final topH = h * 0.18;
    final sideW = w * 0.06;

    // Draw base ice bar
    _renderDefaultBar(canvas, w, h, color, topH, sideW);

    // Draw white fluffy snow pile on top of the bar
    final snowPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, topH - 4, w - sideW, h * 0.22), const Radius.circular(5)),
      snowPaint,
    );

    // Hanging icicles
    final icePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final dx in [0.20, 0.45, 0.70]) {
      final icicle = Path()
        ..moveTo(w * dx, topH + h * 0.18)
        ..lineTo(w * dx + 5, topH + h * 0.18)
        ..lineTo(w * dx + 2.5, topH + h * 0.45)
        ..close();
      canvas.drawPath(icicle, icePaint);
    }
  }

  // Emitter energy beams (galaxy / robot_city)
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

  void _renderDefaultBar(Canvas canvas, double w, double h, Color color, double topH, double sideW) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topH, w - sideW, h - topH),
          Radius.circular(5)),
      Paint()..color = color,
    );

    final top = Path()
      ..moveTo(0, topH)
      ..lineTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(sideW, 0)
      ..close();
    canvas.drawPath(top, Paint()..color = _lighten(color, 0.12));

    final side = Path()
      ..moveTo(w - sideW, topH)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w - sideW, h)
      ..close();
    canvas.drawPath(side, Paint()..color = _darken(color, 0.28));
  }

  // ─────────────────────────────────────────────────────────────────
  //  SPIKE RENDERING (Cones, spears, crystals, etc.)
  // ─────────────────────────────────────────────────────────────────
  void _renderSpike(Canvas canvas, Color color) {
    final w = size.x;
    final h = size.y;
    final world = game.worldId;
    final half = w / 2;

    if (world == 'brix_city') {
      _renderCone(canvas, w, h, color);
      return;
    } else if (world == 'medieval') {
      _renderSpearBarricade(canvas, w, h, color);
      return;
    } else if (world == 'galaxy') {
      _renderSpaceCrystal(canvas, w, h, color);
      return;
    } else if (world == 'jungle') {
      _renderBambooSpikes(canvas, w, h, color);
      return;
    } else if (world == 'dark_city') {
      _renderObsidianSpike(canvas, w, h, color);
      return;
    } else if (world == 'ocean') {
      _renderSeaUrchin(canvas, w, h, color);
      return;
    } else if (world == 'tundra') {
      _renderIceSpike(canvas, w, h, color);
      return;
    } else if (world == 'robot_city') {
      _renderMechanicalDrill(canvas, w, h, color);
      return;
    }

    // Default spike shape
    _renderDefaultSpike(canvas, w, h, color, half);
  }

  // 1. Medieval Spears (medieval)
  void _renderSpearBarricade(Canvas canvas, double w, double h, Color color) {
    final spearPaint = Paint()
      ..color = color
      ..strokeWidth = 4.0;
    final tipPaint = Paint()..color = Colors.grey.shade400;

    // Draw three cross spikes
    for (int i = 0; i < 3; i++) {
      final dx = w * 0.20 + i * (w * 0.60 / 2);
      // Main shaft
      canvas.drawLine(Offset(dx, h), Offset(dx, h * 0.25), spearPaint);

      // Spear head
      final head = Path()
        ..moveTo(dx - 5, h * 0.25)
        ..lineTo(dx + 5, h * 0.25)
        ..lineTo(dx, 0)
        ..close();
      canvas.drawPath(head, tipPaint);
    }
  }

  // 2. Space Crystal (galaxy)
  void _renderSpaceCrystal(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    // Glowing diamond shape crystal
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(w * 0.15, h * 0.50)
      ..lineTo(half, h)
      ..lineTo(w * 0.85, h * 0.50)
      ..close();
    
    // Pulse aura glow
    final pulse = 0.6 + 0.4 * sin(game.elapsedSeconds * 7);
    canvas.drawPath(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.3 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(body, Paint()..color = color);

    // Highlight facets
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(half, 0), Offset(half, h), shine);
    canvas.drawLine(Offset(w * 0.15, h * 0.50), Offset(w * 0.85, h * 0.50), shine);
  }

  // 3. Bamboo Spikes (jungle)
  void _renderBambooSpikes(Canvas canvas, double w, double h, Color color) {
    final bambooPaint = Paint()..color = color;
    final shadowPaint = Paint()..color = _darken(color, 0.20);

    for (int i = 0; i < 3; i++) {
      final dx = w * 0.18 + i * (w * 0.55 / 2);
      final bh = h * (0.65 + 0.35 * (i % 2)); // varying heights
      final rect = Rect.fromLTWH(dx - 5, h - bh, 10, bh);
      
      // Stem
      canvas.drawRect(rect, bambooPaint);

      // Bamboo segment horizontal lines
      canvas.drawLine(Offset(dx - 5, h - bh * 0.33), Offset(dx + 5, h - bh * 0.33), shadowPaint);
      canvas.drawLine(Offset(dx - 5, h - bh * 0.66), Offset(dx + 5, h - bh * 0.66), shadowPaint);

      // Sharp diagonal cut on top
      final tip = Path()
        ..moveTo(dx - 5, h - bh)
        ..lineTo(dx + 5, h - bh)
        ..lineTo(dx - 5, h - bh + 10)
        ..close();
      canvas.drawPath(tip, shadowPaint);
    }
  }

  // 4. Obsidian Spike (dark_city)
  void _renderObsidianSpike(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    // Jagged volcano-like spike
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(w * 0.20, h * 0.40)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w * 0.80, h * 0.40)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    // Glowing tip
    final glowPaint = Paint()
      ..color = const Color(0xFFE94560)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(half, h * 0.10), 6, glowPaint);
  }

  // 5. Sea Urchin (ocean)
  void _renderSeaUrchin(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    final cy = h * 0.60;
    final r = w * 0.28;

    // Center dark body
    canvas.drawCircle(Offset(half, cy), r, Paint()..color = color);

    // Spike lines radiating from center
    final spinePaint = Paint()
      ..color = _lighten(color, 0.20)
      ..strokeWidth = 2.0;

    const count = 10;
    for (int i = 0; i < count; i++) {
      final a = (2 * pi / count) * i + game.elapsedSeconds;
      canvas.drawLine(
        Offset(half + cos(a) * r, cy + sin(a) * r),
        Offset(half + cos(a) * r * 1.7, cy + sin(a) * r * 1.7),
        spinePaint,
      );
    }
  }

  // 6. Ice Spike (tundra)
  void _renderIceSpike(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    // Pointy ice spike
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(w * 0.10, h)
      ..lineTo(w * 0.90, h)
      ..close();
    canvas.drawPath(body, Paint()..color = color.withValues(alpha: 0.80));

    // Shine highlights
    final shine = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(half, 0), Offset(w * 0.35, h), shine);
  }

  // 7. Mechanical Drill (robot_city)
  void _renderMechanicalDrill(Canvas canvas, double w, double h, Color color) {
    final half = w / 2;
    
    // Rotating thread effect based on game elapsed time
    final spiralOffset = (game.elapsedSeconds * 40) % h;

    // Draw main drill cone
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    // Draw metallic screw thread diagonals
    final threadPaint = Paint()
      ..color = _lighten(color, 0.18)
      ..strokeWidth = 2.0;
    
    canvas.save();
    canvas.clipPath(body);
    for (int i = 0; i < 4; i++) {
      final ty = (spiralOffset + i * (h / 3)) % h;
      canvas.drawLine(Offset(0, ty), Offset(w, ty - 12), threadPaint);
    }
    canvas.restore();
  }

  // Traffic cone for brix_city
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

  void _renderDefaultSpike(Canvas canvas, double w, double h, Color color, double half) {
    final body = Path()
      ..moveTo(half, 0)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    final highlight = Path()
      ..moveTo(half, 0)
      ..lineTo(0, h)
      ..lineTo(half * 0.55, h)
      ..close();
    canvas.drawPath(highlight,
        Paint()..color = _lighten(color, 0.14).withValues(alpha: 0.45));

    final darkFace = Path()
      ..moveTo(half, 0)
      ..lineTo(w, h)
      ..lineTo(half * 1.45, h)
      ..close();
    canvas.drawPath(darkFace,
        Paint()..color = Colors.black.withValues(alpha: 0.22));

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

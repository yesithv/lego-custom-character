import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
import '../brix_run_game.dart';

class BackgroundComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  final String worldId;

  double _scrollFar = 0;
  double _scrollMid = 0;

  late final List<_Deco> _farDecos;
  late final List<_Deco> _midDecos;

  BackgroundComponent({required this.worldId})
      : super(position: Vector2.zero(), priority: -10);

  @override
  Future<void> onLoad() async {
    final rng = Random(worldId.hashCode);
    _farDecos = List.generate(8, (i) => _Deco(rng.nextDouble() * 800, rng));
    _midDecos = List.generate(6, (i) => _Deco(rng.nextDouble() * 800, rng));
  }

  @override
  void update(double dt) {
    _scrollFar += game.speed * 0.15 * dt;
    _scrollMid += game.speed * 0.35 * dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final colors = colorsFor(worldId);
    final groundY = h * 0.65;

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, groundY),
      Paint()..color = colors.sky,
    );

    // Sky special decorations
    _drawSkyDecoration(canvas, w, h, groundY, colors);

    // Far decorations (slow scroll)
    for (final d in _farDecos) {
      _drawFarDeco(canvas, d, w, h, groundY, colors);
    }

    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h * 0.35),
      Paint()..color = colors.ground,
    );

    // Ground accent line
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, 4),
      Paint()..color = colors.accent.withValues(alpha: 0.6),
    );

    // Mid decorations (faster scroll)
    for (final d in _midDecos) {
      _drawMidDeco(canvas, d, w, h, groundY, colors);
    }

    // Lane dividers
    _drawLaneDividers(canvas, w);
  }

  void _drawSkyDecoration(
      Canvas canvas, double w, double h, double groundY, WorldColors c) {
    switch (worldId) {
      case 'galaxy':
        for (final d in _farDecos) {
          final sx = (d.baseX - _scrollFar * 0.08) % w;
          canvas.drawCircle(
            Offset(sx, d.height * groundY * 0.85),
            d.width * 2 + 0.5,
            Paint()
              ..color = Colors.white.withValues(alpha: d.width * 0.7 + 0.3),
          );
        }
      case 'dark_city':
        canvas.drawCircle(
          Offset(w * 0.82, h * 0.14),
          22,
          Paint()..color = const Color(0xFFFFF8DC),
        );
        canvas.drawCircle(
          Offset(w * 0.85, h * 0.12),
          17,
          Paint()..color = c.sky,
        );
      case 'ocean':
        final rayPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
        for (int i = 0; i < 5; i++) {
          final rx = (i * w / 5 + (_scrollFar * 0.05) % (w / 5));
          canvas.drawRect(Rect.fromLTWH(rx, 0, 16, groundY * 0.8), rayPaint);
        }
      case 'tundra':
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.08, w, h * 0.06),
          Paint()..color = Colors.green.withValues(alpha: 0.12),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.16, w, h * 0.04),
          Paint()..color = Colors.purple.withValues(alpha: 0.08),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.22, w, h * 0.03),
          Paint()..color = Colors.teal.withValues(alpha: 0.07),
        );
      default:
        break;
    }
  }

  void _drawFarDeco(Canvas canvas, _Deco d, double w, double h, double groundY,
      WorldColors c) {
    final x = (d.baseX - _scrollFar * 0.5) % (w + 80) - 40;
    final bh = d.height * groundY * 0.45;
    final bw = d.width * 40 + 22;

    switch (worldId) {
      case 'lego_city':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - bh, bw, bh),
          Paint()..color = c.midground,
        );
        for (int row = 0; row < (bh / 16).floor(); row++) {
          for (int col = 0; col < (bw / 14).floor(); col++) {
            canvas.drawRect(
              Rect.fromLTWH(
                  x + col * 14 + 3, groundY - bh + row * 16 + 4, 6, 8),
              Paint()..color = c.accent.withValues(alpha: 0.7),
            );
          }
        }
      case 'medieval':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - bh, bw, bh),
          Paint()..color = c.midground,
        );
        for (int i = 0; i < (bw / 10).floor(); i++) {
          if (i.isEven) {
            canvas.drawRect(
              Rect.fromLTWH(x + i * 10, groundY - bh - 10, 8, 10),
              Paint()..color = c.midground,
            );
          }
        }
      case 'galaxy':
        final r = bh * 0.45;
        canvas.drawCircle(
          Offset(x + bw / 2, groundY - bh - 10),
          r,
          Paint()..color = c.midground,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + bw / 2, groundY - bh - 6),
            width: r * 2.8,
            height: r * 0.35,
          ),
          Paint()
            ..color = c.accent.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case 'jungle':
        canvas.drawRect(
          Rect.fromLTWH(x + bw / 2 - 8, groundY - bh * 0.65, 16, bh * 0.65),
          Paint()..color = Colors.brown.shade800,
        );
        canvas.drawCircle(
          Offset(x + bw / 2, groundY - bh * 0.75),
          bw * 0.65,
          Paint()..color = Colors.green.shade700,
        );
        canvas.drawCircle(
          Offset(x + bw / 2 - bw * 0.32, groundY - bh * 0.58),
          bw * 0.48,
          Paint()..color = Colors.green.shade800,
        );
        canvas.drawCircle(
          Offset(x + bw / 2 + bw * 0.32, groundY - bh * 0.58),
          bw * 0.48,
          Paint()..color = Colors.green.shade600,
        );
      case 'dark_city':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - bh, bw, bh),
          Paint()..color = c.midground,
        );
        final spireCount = (bw / 14).floor().clamp(1, 3);
        for (int i = 0; i < spireCount; i++) {
          final sx = x + i * (bw / spireCount) + bw / spireCount / 2;
          final spire = Path()
            ..moveTo(sx, groundY - bh - 22)
            ..lineTo(sx - 5, groundY - bh)
            ..lineTo(sx + 5, groundY - bh)
            ..close();
          canvas.drawPath(spire, Paint()..color = c.accent.withValues(alpha: 0.85));
        }
        for (int row = 0; row < (bh / 20).floor(); row++) {
          for (int col = 0; col < (bw / 16).floor(); col++) {
            canvas.drawRect(
              Rect.fromLTWH(
                  x + col * 16 + 3, groundY - bh + row * 20 + 5, 8, 10),
              Paint()..color = c.accent.withValues(alpha: 0.28),
            );
          }
        }
      case 'ocean':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + bw * 0.1, groundY - bh, bw * 0.38, bh),
            const Radius.circular(8),
          ),
          Paint()..color = c.accent.withValues(alpha: 0.75),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                x + bw * 0.55, groundY - bh * 0.65, bw * 0.35, bh * 0.65),
            const Radius.circular(6),
          ),
          Paint()..color = c.midground,
        );
      case 'tundra':
        final mPath = Path()
          ..moveTo(x, groundY)
          ..lineTo(x + bw / 2, groundY - bh)
          ..lineTo(x + bw, groundY)
          ..close();
        canvas.drawPath(mPath, Paint()..color = c.midground);
        final snowCap = Path()
          ..moveTo(x + bw * 0.28, groundY - bh * 0.52)
          ..lineTo(x + bw / 2, groundY - bh)
          ..lineTo(x + bw * 0.72, groundY - bh * 0.52)
          ..close();
        canvas.drawPath(snowCap, Paint()..color = Colors.white);
      case 'robot_city':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - bh, bw, bh),
          Paint()..color = c.midground,
        );
        final circuitP = Paint()
          ..color = c.accent.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x + 4, groundY - bh + 8),
            Offset(x + bw - 4, groundY - bh + 8), circuitP);
        canvas.drawLine(Offset(x + 4, groundY - bh + 22),
            Offset(x + bw * 0.6, groundY - bh + 22), circuitP);
        canvas.drawLine(
          Offset(x + bw / 2, groundY - bh),
          Offset(x + bw / 2, groundY - bh - 16),
          circuitP,
        );
        canvas.drawCircle(
          Offset(x + bw / 2, groundY - bh - 19),
          3,
          Paint()..color = c.accent,
        );
      default:
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - bh, bw, bh),
          Paint()..color = c.midground.withValues(alpha: 0.7),
        );
    }
  }

  void _drawMidDeco(Canvas canvas, _Deco d, double w, double h, double groundY,
      WorldColors c) {
    final x = (d.baseX - _scrollMid) % (w + 60) - 30;

    switch (worldId) {
      case 'lego_city':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - 50, 4, 50),
          Paint()..color = Colors.grey.shade700,
        );
        canvas.drawCircle(
          Offset(x + 2, groundY - 52),
          6,
          Paint()..color = c.accent,
        );
      case 'medieval':
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - 40, 12, 40),
          Paint()..color = Colors.brown.shade700,
        );
        canvas.drawCircle(
          Offset(x + 6, groundY - 45),
          16,
          Paint()..color = Colors.green.shade700,
        );
      case 'galaxy':
        canvas.drawCircle(
          Offset(x, groundY - d.height * 35 - 10),
          5 + d.width * 7,
          Paint()..color = c.midground.withValues(alpha: 0.75),
        );
      case 'jungle':
        final vinePaint = Paint()
          ..color = Colors.green.shade600
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x, 0), Offset(x + 4, groundY - 30), vinePaint);
        canvas.drawCircle(
          Offset(x + 4, groundY - 22),
          9,
          Paint()..color = Colors.green.shade500,
        );
      case 'dark_city':
        final batY = groundY - 55 - d.height * 35;
        canvas.drawCircle(Offset(x, batY), 4, Paint()..color = Colors.black87);
        final wings = Path()
          ..moveTo(x - 13, batY + 2)
          ..quadraticBezierTo(x - 6, batY - 7, x, batY)
          ..quadraticBezierTo(x + 6, batY - 7, x + 13, batY + 2);
        canvas.drawPath(wings, Paint()..color = Colors.black87);
      case 'ocean':
        canvas.drawCircle(
          Offset(x, groundY - d.height * 55),
          3 + d.width * 5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case 'tundra':
        canvas.drawCircle(
          Offset(x, groundY - d.height * 45),
          2 + d.width * 2,
          Paint()..color = Colors.white.withValues(alpha: 0.65),
        );
      case 'robot_city':
        final gearR = 9.0 + d.width * 7;
        final gearPath = Path();
        const teeth = 8;
        for (int i = 0; i < teeth * 2; i++) {
          final angle = (i / (teeth * 2)) * 2 * pi;
          final r = i.isEven ? gearR : gearR * 0.68;
          final gx = x + r * cos(angle);
          final gy = groundY - 28 + r * sin(angle);
          if (i == 0) gearPath.moveTo(gx, gy);
          else gearPath.lineTo(gx, gy);
        }
        gearPath.close();
        canvas.drawPath(gearPath,
            Paint()..color = c.accent.withValues(alpha: 0.38));
      default:
        canvas.drawCircle(
          Offset(x, groundY - 20),
          10,
          Paint()..color = c.accent.withValues(alpha: 0.5),
        );
    }
  }

  void _drawLaneDividers(Canvas canvas, double w) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final laneY in game.lanePositions) {
      canvas.drawLine(Offset(0, laneY + 5), Offset(w, laneY + 5), paint);
    }
  }
}

class _Deco {
  final double baseX;
  final double height;
  final double width;

  _Deco(this.baseX, Random rng)
      : height = 0.4 + rng.nextDouble() * 0.6,
        width = rng.nextDouble();
}

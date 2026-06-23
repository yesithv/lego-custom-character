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

  // Decoration positions generated once
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

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.65),
      Paint()..color = colors.sky,
    );

    // Far buildings / decorations (slow scroll)
    for (final d in _farDecos) {
      _drawFarDeco(canvas, d, w, h, colors);
    }

    // Ground strip
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.65, w, h * 0.35),
      Paint()..color = colors.ground,
    );

    // Ground line detail
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.65, w, 4),
      Paint()..color = colors.accent.withValues(alpha: 0.6),
    );

    // Mid decorations (faster scroll)
    for (final d in _midDecos) {
      _drawMidDeco(canvas, d, w, h, colors);
    }

    // Lane dividers (subtle dashes)
    _drawLaneDividers(canvas, w, h);
  }

  void _drawFarDeco(
      Canvas canvas, _Deco d, double w, double h, WorldColors c) {
    final x = (d.baseX - _scrollFar * 0.5) % (w + 80) - 40;
    final bh = d.height * h * 0.3;
    final bw = d.width * 40 + 20;

    switch (worldId) {
      case 'lego_city':
        // Building
        canvas.drawRect(
          Rect.fromLTWH(x, h * 0.65 - bh, bw, bh),
          Paint()..color = c.midground,
        );
        // Windows
        for (int row = 0; row < (bh / 16).floor(); row++) {
          for (int col = 0; col < (bw / 14).floor(); col++) {
            canvas.drawRect(
              Rect.fromLTWH(x + col * 14 + 3, h * 0.65 - bh + row * 16 + 4, 6, 8),
              Paint()..color = c.accent.withValues(alpha: 0.7),
            );
          }
        }
      case 'medieval':
        // Tower
        canvas.drawRect(
          Rect.fromLTWH(x, h * 0.65 - bh, bw, bh),
          Paint()..color = c.midground,
        );
        // Battlements
        for (int i = 0; i < (bw / 10).floor(); i++) {
          if (i.isEven) {
            canvas.drawRect(
              Rect.fromLTWH(x + i * 10, h * 0.65 - bh - 10, 8, 10),
              Paint()..color = c.midground,
            );
          }
        }
      default:
        canvas.drawRect(
          Rect.fromLTWH(x, h * 0.65 - bh, bw, bh),
          Paint()..color = c.midground.withValues(alpha: 0.7),
        );
    }
  }

  void _drawMidDeco(
      Canvas canvas, _Deco d, double w, double h, WorldColors c) {
    final x = (d.baseX - _scrollMid) % (w + 60) - 30;
    final groundY = h * 0.65;

    switch (worldId) {
      case 'lego_city':
        // Lamp post
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
        // Tree stump
        canvas.drawRect(
          Rect.fromLTWH(x, groundY - 40, 12, 40),
          Paint()..color = Colors.brown.shade700,
        );
        canvas.drawCircle(
          Offset(x + 6, groundY - 45),
          16,
          Paint()..color = Colors.green.shade700,
        );
      default:
        canvas.drawCircle(
          Offset(x, groundY - 20),
          10,
          Paint()..color = c.accent.withValues(alpha: 0.5),
        );
    }
  }

  void _drawLaneDividers(Canvas canvas, double w, double h) {
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

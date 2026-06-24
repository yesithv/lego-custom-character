import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
import '../brix_run_game.dart';

class BackgroundComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  final String worldId;

  double _groundScroll = 0.0;
  double _buildingScroll = 0.0;

  late List<_Building> _buildings;

  BackgroundComponent({required this.worldId})
      : super(position: Vector2.zero(), priority: -10);

  @override
  Future<void> onLoad() async {
    final rng = Random(worldId.hashCode);
    _buildings = List.generate(14, (_) => _Building(rng));
  }

  @override
  void update(double dt) {
    _groundScroll += game.depthRate * dt;
    _buildingScroll += game.speed * 0.36 * dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final c = colorsFor(worldId);
    final hy = game.horizonY;
    final py = game.playerBaseY;
    final vx = game.vanishX;
    final sep = game.laneSep;

    // 1 — Sky
    _drawSky(canvas, w, hy, c);

    // 2 — City silhouette behind track (above horizon)
    _drawCitySilhouette(canvas, w, hy, vx, c);

    // 3 — Sky decorations (stars, moon, etc.)
    _drawSkyDecorations(canvas, w, h, hy, c);

    // 4 — Ground plane with perspective grid
    _drawGround(canvas, w, h, hy, py, vx, sep, c);
  }

  // ── Sky ─────────────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, double w, double hy, WorldColors c) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, hy), Paint()..color = c.sky);
    // Horizon warm glow
    canvas.drawRect(
      Rect.fromLTWH(0, hy * 0.70, w, hy * 0.30),
      Paint()..color = c.accent.withValues(alpha: 0.09),
    );
  }

  // ── City silhouette scrolling above horizon ──────────────────────────────────

  void _drawCitySilhouette(
      Canvas canvas, double w, double hy, double vx, WorldColors c) {
    final scrolled = _buildingScroll % (w * 0.85);

    for (final b in _buildings) {
      final rawX = (b.relX * w * 0.85 - scrolled) % (w * 0.85);

      // Skip buildings near the center vanishing corridor
      final distFromCenter = (rawX - vx).abs();
      if (distFromCenter < w * 0.10) continue;

      final bh = b.heightFraction * hy * 0.80 + hy * 0.10;
      final bw = 24.0 + b.widthFraction * 34.0;
      final bx = rawX - bw / 2;

      // Building body
      canvas.drawRect(
        Rect.fromLTWH(bx, hy - bh, bw, bh),
        Paint()..color = c.midground,
      );

      // Windows
      _drawWindows(canvas, bx, hy - bh, bw, bh, c);

      // World-specific roof
      _drawRoof(canvas, bx, hy - bh, bw, c);
    }
  }

  void _drawWindows(Canvas canvas, double bx, double bTop, double bw,
      double bh, WorldColors c) {
    if (bw < 12 || bh < 18) return;
    final cols = (bw / 13).floor().clamp(1, 3);
    final rows = (bh / 18).floor().clamp(1, 7);
    final wPaint = Paint()..color = c.accent.withValues(alpha: 0.30);
    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        canvas.drawRect(
          Rect.fromLTWH(bx + col * (bw / cols) + 3, bTop + r * 18 + 5, 7, 10),
          wPaint,
        );
      }
    }
  }

  void _drawRoof(Canvas canvas, double bx, double bTop, double bw,
      WorldColors c) {
    switch (worldId) {
      case 'medieval':
        final cols = (bw / 10).floor();
        for (int i = 0; i < cols; i++) {
          if (i.isEven) {
            canvas.drawRect(Rect.fromLTWH(bx + i * 10, bTop - 10, 8, 10),
                Paint()..color = c.midground);
          }
        }
      case 'dark_city':
        final cx = bx + bw / 2;
        final spire = Path()
          ..moveTo(cx, bTop - 20)
          ..lineTo(cx - 4, bTop)
          ..lineTo(cx + 4, bTop)
          ..close();
        canvas.drawPath(spire, Paint()..color = c.accent.withValues(alpha: 0.80));
      case 'galaxy':
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(bx + bw / 2, bTop),
              width: bw * 0.70,
              height: bw * 0.25),
          Paint()..color = c.accent.withValues(alpha: 0.25),
        );
      case 'robot_city':
        canvas.drawRect(
            Rect.fromLTWH(bx + bw / 2 - 1.5, bTop - 16, 3, 16),
            Paint()..color = c.midground);
        canvas.drawCircle(Offset(bx + bw / 2, bTop - 18), 4,
            Paint()..color = c.accent);
      case 'jungle':
        canvas.drawCircle(Offset(bx + bw / 2, bTop - 12), bw * 0.42,
            Paint()..color = Colors.green.shade700.withValues(alpha: 0.75));
      case 'tundra':
        final mPath = Path()
          ..moveTo(bx, bTop)
          ..lineTo(bx + bw / 2, bTop - bw * 0.55)
          ..lineTo(bx + bw, bTop)
          ..close();
        canvas.drawPath(
            mPath, Paint()..color = Colors.white.withValues(alpha: 0.55));
      default:
        break;
    }
  }

  // ── Sky decorations ──────────────────────────────────────────────────────────

  void _drawSkyDecorations(
      Canvas canvas, double w, double h, double hy, WorldColors c) {
    switch (worldId) {
      case 'galaxy':
        final rng = Random(77);
        for (int i = 0; i < 60; i++) {
          final sx = rng.nextDouble() * w;
          final sy = rng.nextDouble() * hy * 0.95;
          final sr = rng.nextDouble() * 1.6 + 0.4;
          canvas.drawCircle(Offset(sx, sy), sr,
              Paint()..color = Colors.white.withValues(alpha: rng.nextDouble() * 0.5 + 0.4));
        }
      case 'dark_city':
        canvas.drawCircle(
            Offset(w * 0.80, h * 0.11), 24, Paint()..color = const Color(0xFFFFF8DC));
        canvas.drawCircle(
            Offset(w * 0.84, h * 0.09), 18, Paint()..color = c.sky);
      case 'tundra':
        for (int i = 0; i < 3; i++) {
          canvas.drawRect(
            Rect.fromLTWH(0, hy * (0.10 + i * 0.10), w, hy * 0.05),
            Paint()..color = [Colors.green, Colors.purple, Colors.teal][i]
                .withValues(alpha: 0.10),
          );
        }
      case 'ocean':
        final rayP = Paint()..color = Colors.white.withValues(alpha: 0.04);
        for (int i = 0; i < 6; i++) {
          final rx = (i * w / 6 + (_buildingScroll * 0.04) % (w / 6));
          canvas.drawRect(Rect.fromLTWH(rx, 0, 16, hy * 0.90), rayP);
        }
      case 'jungle':
        for (int i = 0; i < 5; i++) {
          final cx = (i * w * 0.22 - _buildingScroll * 0.06) % (w + 40) - 20;
          canvas.drawCircle(Offset(cx, hy * 0.72), 24,
              Paint()..color = Colors.green.shade900.withValues(alpha: 0.45));
        }
      default:
        break;
    }
  }

  // ── Perspective ground ───────────────────────────────────────────────────────

  void _drawGround(Canvas canvas, double w, double h, double hy, double py,
      double vx, double sep, WorldColors c) {
    // Base ground fill
    canvas.drawRect(Rect.fromLTWH(0, hy, w, h - hy), Paint()..color = c.ground);

    // Track surface (slightly different shade)
    final trackPath = Path()
      ..moveTo(vx, hy)
      ..lineTo(vx + sep * 1.60, h)
      ..lineTo(vx - sep * 1.60, h)
      ..close();
    canvas.drawPath(
        trackPath, Paint()..color = c.midground.withValues(alpha: 0.38));

    // Horizon accent
    canvas.drawRect(
        Rect.fromLTWH(0, hy - 1.5, w, 3), Paint()..color = c.accent.withValues(alpha: 0.50));

    // Scrolling cross-lines (depth motion grid)
    _drawCrossLines(canvas, hy, py, vx, sep, c);

    // Rail perspective lines (converging to vanish point)
    _drawRailLines(canvas, hy, py, vx, sep, c);
  }

  void _drawCrossLines(Canvas canvas, double hy, double py, double vx,
      double sep, WorldColors c) {
    const dz = 0.135;
    final phase = _groundScroll % dz;
    final linePaint = Paint()
      ..color = c.accent.withValues(alpha: 0.16)
      ..strokeWidth = 1.5;
    final studPaint = Paint()..color = c.accent.withValues(alpha: 0.09);

    for (double base = 0.0; base <= 1.0 + dz; base += dz) {
      final t = (base - phase).clamp(0.0, 1.5);
      if (t < 0.02 || t > 1.0) continue;
      final ly = hy + (py - hy) * t;
      final halfW = sep * 1.60 * t;

      // Cross line
      canvas.drawLine(Offset(vx - halfW, ly), Offset(vx + halfW, ly), linePaint);

      // LEGO stud dots on every other line
      if ((base / dz).round().isEven) {
        final dotR = 3.5 * t;
        for (int lane = 0; lane < 3; lane++) {
          final offsets = [-sep, 0.0, sep];
          canvas.drawCircle(
              Offset(vx + offsets[lane] * t, ly - dotR), dotR, studPaint);
        }
      }
    }
  }

  void _drawRailLines(Canvas canvas, double hy, double py, double vx,
      double sep, WorldColors c) {
    final outerPaint = Paint()
      ..color = c.accent.withValues(alpha: 0.48)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rails = [
      (-sep * 1.60, outerPaint),
      (-sep * 0.53, innerPaint),
      (sep * 0.53, innerPaint),
      (sep * 1.60, outerPaint),
    ];
    for (final (offset, paint) in rails) {
      canvas.drawLine(
        Offset(vx, hy),
        Offset(vx + offset, py + (py * 0.26)),
        paint,
      );
    }
  }
}

class _Building {
  final double relX;
  final double heightFraction;
  final double widthFraction;

  _Building(Random rng)
      : relX = rng.nextDouble(),
        heightFraction = 0.15 + rng.nextDouble() * 0.75,
        widthFraction = rng.nextDouble();
}

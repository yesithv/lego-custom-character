import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../domain/entities/world_config.dart';
import '../brix_run_game.dart';

/// Decorative trackside object. Spawns at the horizon on one side of the
/// track and rushes toward the camera like obstacles, but never collides.
/// Each world draws its own set of 3 variants.
class SceneryComponent extends PositionComponent
    with HasGameRef<BrixRunGame> {
  /// -1 = left of the track, 1 = right of the track.
  final int side;

  /// Which of the world's 3 designs to draw.
  final int variant;

  /// Distance from the track center at player level, in laneSep multiples.
  final double lateral;

  double _depth;

  // Variant 0 is the tallest design, 2 the shortest.
  static const _heights = [132.0, 104.0, 78.0];
  static const _baseW = 84.0;

  double get depth => _depth;

  SceneryComponent({
    required this.side,
    required this.variant,
    required this.lateral,
    double startDepth = 0.0,
  })  : _depth = startDepth,
        super(size: Vector2(1, 1), priority: 3);

  @override
  void update(double dt) {
    _depth += game.depthRate * dt;
    _syncTransform();
    if (_depth > 1.45) removeFromParent();
  }

  @override
  void onMount() {
    super.onMount();
    _syncTransform();
  }

  void _syncTransform() {
    final s = game.perspectiveScale(_depth);
    final groundX =
        game.vanishX + side * lateral * game.laneSep * _depth;
    final groundY =
        game.horizonY + (game.playerBaseY - game.horizonY) * _depth;
    size = Vector2(_baseW * s, _heights[variant] * s);
    position = Vector2(groundX - size.x / 2, groundY - size.y);
    priority = (200 * _depth).floor() + 3;
  }

  @override
  void render(Canvas canvas) {
    final c = colorsFor(game.worldId);
    switch (game.worldId) {
      case 'medieval':
        _renderMedieval(canvas, c);
      case 'galaxy':
        _renderGalaxy(canvas, c);
      case 'jungle':
        _renderJungle(canvas, c);
      case 'dark_city':
        _renderDarkCity(canvas, c);
      case 'ocean':
        _renderOcean(canvas, c);
      case 'tundra':
        _renderTundra(canvas, c);
      case 'robot_city':
        _renderRobotCity(canvas, c);
      default:
        _renderLegoCity(canvas, c);
    }
  }

  // ── LEGO City: streetlamp / tree / traffic sign ─────────────────────────────

  void _renderLegoCity(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Streetlamp
        _pole(canvas, w, h, Colors.grey.shade600);
        canvas.drawCircle(Offset(w / 2, h * 0.08), w * 0.16,
            Paint()..color = const Color(0xFFFFF59D));
        canvas.drawCircle(
            Offset(w / 2, h * 0.08),
            w * 0.30,
            Paint()
              ..color = const Color(0xFFFFF59D).withValues(alpha: 0.25));
      case 1: // Blocky LEGO tree
        _trunk(canvas, w, h, const Color(0xFF6D4C41));
        final leaf = Paint()..color = const Color(0xFF2E7D32);
        canvas.drawCircle(Offset(w * 0.50, h * 0.28), w * 0.30, leaf);
        canvas.drawCircle(Offset(w * 0.30, h * 0.44), w * 0.24, leaf);
        canvas.drawCircle(Offset(w * 0.70, h * 0.44), w * 0.24, leaf);
        canvas.drawCircle(Offset(w * 0.50, h * 0.16), w * 0.10,
            Paint()..color = const Color(0xFF43A047));
      default: // Traffic sign
        _pole(canvas, w, h, Colors.grey.shade500);
        final sign = Rect.fromCenter(
            center: Offset(w / 2, h * 0.18), width: w * 0.52, height: w * 0.52);
        canvas.drawRRect(
            RRect.fromRectAndRadius(sign, const Radius.circular(4)),
            Paint()..color = const Color(0xFF1565C0));
        final arrow = Path()
          ..moveTo(w * 0.38, h * 0.18)
          ..lineTo(w * 0.62, h * 0.18)
          ..lineTo(w * 0.52, h * 0.10);
        canvas.drawPath(
            arrow,
            Paint()
              ..color = Colors.white
              ..strokeWidth = 2.2
              ..style = PaintingStyle.stroke);
    }
  }

  // ── Medieval: tower / torch / bush ──────────────────────────────────────────

  void _renderMedieval(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Stone watchtower with flag
        final stone = Paint()..color = const Color(0xFF9E9E9E);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.22, h * 0.16, w * 0.56, h * 0.84), stone);
        // Crenellations
        for (int i = 0; i < 3; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * (0.22 + i * 0.22), h * 0.10, w * 0.12, h * 0.08),
              stone);
        }
        // Window slit
        canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.36, w * 0.12, h * 0.16),
            Paint()..color = Colors.black.withValues(alpha: 0.55));
        // Flag
        canvas.drawRect(Rect.fromLTWH(w * 0.48, 0, w * 0.04, h * 0.12),
            Paint()..color = const Color(0xFF5D4037));
        final flag = Path()
          ..moveTo(w * 0.52, 0)
          ..lineTo(w * 0.80, h * 0.04)
          ..lineTo(w * 0.52, h * 0.08)
          ..close();
        canvas.drawPath(flag, Paint()..color = const Color(0xFFC62828));
      case 1: // Torch with flickering flame
        _pole(canvas, w, h, const Color(0xFF5D4037));
        final flick = 0.8 + 0.2 * sin(game.elapsedSeconds * 11 + side * 3);
        canvas.drawCircle(Offset(w / 2, h * 0.10), w * 0.20 * flick,
            Paint()..color = const Color(0xFFFF9800));
        canvas.drawCircle(Offset(w / 2, h * 0.07), w * 0.11 * flick,
            Paint()..color = const Color(0xFFFFEB3B));
        canvas.drawCircle(
            Offset(w / 2, h * 0.10),
            w * 0.36 * flick,
            Paint()
              ..color = const Color(0xFFFF9800).withValues(alpha: 0.20));
      default: // Round bush
        _trunk(canvas, w, h, const Color(0xFF5D4037));
        canvas.drawCircle(Offset(w / 2, h * 0.42), w * 0.36,
            Paint()..color = const Color(0xFF33691E));
        canvas.drawCircle(Offset(w * 0.38, h * 0.34), w * 0.12,
            Paint()..color = const Color(0xFF558B2F));
    }
  }

  // ── Galaxy: crystal cluster / satellite / glowing rock ──────────────────────

  void _renderGalaxy(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Crystal cluster
        final glow = Paint()
          ..color = const Color(0xFF00FFFF).withValues(alpha: 0.18);
        canvas.drawCircle(Offset(w / 2, h * 0.55), w * 0.55, glow);
        _crystal(canvas, w * 0.50, h, w * 0.30, h * 0.95,
            const Color(0xFF7C4DFF));
        _crystal(canvas, w * 0.24, h, w * 0.22, h * 0.55,
            const Color(0xFF00E5FF));
        _crystal(canvas, w * 0.78, h, w * 0.22, h * 0.65,
            const Color(0xFF00E5FF));
      case 1: // Satellite dish
        _pole(canvas, w, h, Colors.blueGrey.shade600);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.20),
                width: w * 0.64,
                height: w * 0.40),
            Paint()..color = Colors.blueGrey.shade300);
        final blink = (sin(game.elapsedSeconds * 5 + side) + 1) / 2;
        canvas.drawCircle(Offset(w / 2, h * 0.20), w * 0.07,
            Paint()
              ..color = const Color(0xFFFF1744)
                  .withValues(alpha: 0.3 + 0.7 * blink));
      default: // Alien boulder with glowing ring
        canvas.drawOval(
            Rect.fromLTWH(w * 0.12, h * 0.38, w * 0.76, h * 0.62),
            Paint()..color = const Color(0xFF3A3A6B));
        canvas.drawOval(
            Rect.fromLTWH(w * 0.06, h * 0.60, w * 0.88, h * 0.18),
            Paint()
              ..color = const Color(0xFF00FFFF).withValues(alpha: 0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
    }
  }

  // ── Jungle: palm / fern / totem ─────────────────────────────────────────────

  void _renderJungle(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Palm tree
        final trunk = Path()
          ..moveTo(w * 0.46, h)
          ..quadraticBezierTo(w * 0.40, h * 0.5, w * 0.54, h * 0.16)
          ..lineTo(w * 0.62, h * 0.20)
          ..quadraticBezierTo(w * 0.52, h * 0.55, w * 0.58, h)
          ..close();
        canvas.drawPath(trunk, Paint()..color = const Color(0xFF795548));
        final frond = Paint()..color = const Color(0xFF2E7D32);
        for (final a in [-0.9, -0.35, 0.35, 0.9, 1.5]) {
          canvas.save();
          canvas.translate(w * 0.58, h * 0.16);
          canvas.rotate(a);
          canvas.drawOval(
              Rect.fromLTWH(0, -w * 0.07, w * 0.46, w * 0.14), frond);
          canvas.restore();
        }
      case 1: // Giant fern
        final fern = Paint()
          ..color = const Color(0xFF388E3C)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        for (final dx in [-0.30, -0.15, 0.0, 0.15, 0.30]) {
          final p = Path()
            ..moveTo(w / 2, h)
            ..quadraticBezierTo(
                w * (0.5 + dx), h * 0.45, w * (0.5 + dx * 2.2), h * 0.30);
          canvas.drawPath(p, fern);
        }
      default: // Tiki totem
        final tiers = [
          const Color(0xFF8D6E63),
          const Color(0xFF6D4C41),
          const Color(0xFF5D4037),
        ];
        final tierH = h * 0.30;
        for (int i = 0; i < 3; i++) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                      w * 0.24, h - (i + 1) * tierH, w * 0.52, tierH - 2),
                  const Radius.circular(4)),
              Paint()..color = tiers[i]);
        }
        // Eyes on top tier
        final eye = Paint()..color = const Color(0xFFFFEB3B);
        canvas.drawCircle(Offset(w * 0.38, h - 2.5 * tierH), w * 0.06, eye);
        canvas.drawCircle(Offset(w * 0.62, h - 2.5 * tierH), w * 0.06, eye);
    }
  }

  // ── Dark City: flickering lamppost / ruined wall / neon sign ────────────────

  void _renderDarkCity(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Lamppost with unstable red light
        _pole(canvas, w, h, const Color(0xFF37474F));
        final flick =
            (sin(game.elapsedSeconds * 13 + side * 7) > -0.3) ? 1.0 : 0.15;
        canvas.drawCircle(Offset(w / 2, h * 0.08), w * 0.13,
            Paint()
              ..color =
                  const Color(0xFFE94560).withValues(alpha: 0.9 * flick));
        canvas.drawCircle(Offset(w / 2, h * 0.08), w * 0.30,
            Paint()
              ..color =
                  const Color(0xFFE94560).withValues(alpha: 0.20 * flick));
      case 1: // Ruined wall
        final brick = Paint()..color = const Color(0xFF2D2D4E);
        final wall = Path()
          ..moveTo(w * 0.10, h)
          ..lineTo(w * 0.10, h * 0.35)
          ..lineTo(w * 0.38, h * 0.28)
          ..lineTo(w * 0.52, h * 0.48)
          ..lineTo(w * 0.90, h * 0.42)
          ..lineTo(w * 0.90, h)
          ..close();
        canvas.drawPath(wall, brick);
        final mortar = Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..strokeWidth = 1.0;
        for (int i = 1; i <= 3; i++) {
          canvas.drawLine(Offset(w * 0.10, h - i * h * 0.14),
              Offset(w * 0.90, h - i * h * 0.14), mortar);
        }
      default: // Neon sign pillar
        canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.05, w * 0.24, h * 0.95),
            Paint()..color = const Color(0xFF16162A));
        final pulse = 0.6 + 0.4 * sin(game.elapsedSeconds * 4 + side * 2);
        final neon = Paint()
          ..color = const Color(0xFFE94560).withValues(alpha: pulse);
        for (int i = 0; i < 3; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * 0.42, h * (0.14 + i * 0.22), w * 0.16, h * 0.10),
              neon);
        }
    }
  }

  // ── Ocean: coral fan / seaweed / starfish rock ──────────────────────────────

  void _renderOcean(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    final sway = sin(game.elapsedSeconds * 2.2 + side * 3 + lateral) * w * 0.06;
    switch (variant) {
      case 0: // Coral fan
        final coral = Paint()
          ..color = const Color(0xFFFF7043)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        for (final dx in [-0.32, -0.16, 0.0, 0.16, 0.32]) {
          final p = Path()
            ..moveTo(w / 2, h)
            ..quadraticBezierTo(w * (0.5 + dx * 0.4), h * 0.55,
                w * (0.5 + dx) + sway, h * 0.14);
          canvas.drawPath(p, coral);
          canvas.drawCircle(Offset(w * (0.5 + dx) + sway, h * 0.14), w * 0.05,
              Paint()..color = const Color(0xFFFFAB91));
        }
      case 1: // Swaying seaweed
        final weed = Paint()
          ..color = const Color(0xFF2E7D6E)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        for (final dx in [0.30, 0.50, 0.70]) {
          final p = Path()
            ..moveTo(w * dx, h)
            ..quadraticBezierTo(
                w * dx - sway, h * 0.55, w * dx + sway, h * 0.10);
          canvas.drawPath(p, weed);
        }
      default: // Rock with a starfish
        canvas.drawOval(Rect.fromLTWH(w * 0.10, h * 0.40, w * 0.80, h * 0.60),
            Paint()..color = const Color(0xFF34515E));
        final star = Paint()..color = const Color(0xFFFFCA28);
        final cx = w * 0.55;
        final cy = h * 0.55;
        for (int i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5 - pi / 2;
          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(a);
          canvas.drawOval(
              Rect.fromLTWH(0, -w * 0.035, w * 0.18, w * 0.07), star);
          canvas.restore();
        }
        canvas.drawCircle(Offset(cx, cy), w * 0.06, star);
    }
  }

  // ── Tundra: snowy pine / snowman / ice shards ───────────────────────────────

  void _renderTundra(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Snowy pine
        _trunk(canvas, w, h, const Color(0xFF4E342E));
        final pine = Paint()..color = const Color(0xFF1B5E20);
        final snow = Paint()..color = Colors.white.withValues(alpha: 0.90);
        for (int i = 0; i < 3; i++) {
          final ty = h * (0.10 + i * 0.24);
          final tw = w * (0.30 + i * 0.14);
          final tri = Path()
            ..moveTo(w / 2, ty)
            ..lineTo(w / 2 - tw, ty + h * 0.28)
            ..lineTo(w / 2 + tw, ty + h * 0.28)
            ..close();
          canvas.drawPath(tri, pine);
          canvas.drawLine(Offset(w / 2, ty), Offset(w / 2 - tw * 0.6, ty + h * 0.16),
              snow..strokeWidth = 3.0..style = PaintingStyle.stroke);
        }
        canvas.drawCircle(Offset(w / 2, h * 0.08), w * 0.06, snow..style = PaintingStyle.fill);
      case 1: // Snowman
        final body = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(w / 2, h * 0.80), w * 0.30, body);
        canvas.drawCircle(Offset(w / 2, h * 0.48), w * 0.23, body);
        canvas.drawCircle(Offset(w / 2, h * 0.22), w * 0.16, body);
        final eye = Paint()..color = Colors.black87;
        canvas.drawCircle(Offset(w * 0.44, h * 0.19), w * 0.025, eye);
        canvas.drawCircle(Offset(w * 0.56, h * 0.19), w * 0.025, eye);
        final carrot = Path()
          ..moveTo(w * 0.50, h * 0.23)
          ..lineTo(w * 0.68, h * 0.25)
          ..lineTo(w * 0.50, h * 0.27)
          ..close();
        canvas.drawPath(carrot, Paint()..color = const Color(0xFFFF6F00));
      default: // Ice shard cluster
        _crystal(canvas, w * 0.50, h, w * 0.28, h * 0.95,
            const Color(0xFFB3E5FC));
        _crystal(canvas, w * 0.26, h, w * 0.20, h * 0.55,
            const Color(0xFFE1F5FE));
        _crystal(canvas, w * 0.76, h, w * 0.20, h * 0.62,
            const Color(0xFFE1F5FE));
    }
  }

  // ── Robot City: antenna tower / pipe column / neon pillar ───────────────────

  void _renderRobotCity(Canvas canvas, WorldColors c) {
    final w = size.x;
    final h = size.y;
    switch (variant) {
      case 0: // Lattice antenna tower
        final strut = Paint()
          ..color = const Color(0xFF616161)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(w * 0.30, h), Offset(w * 0.48, h * 0.05), strut);
        canvas.drawLine(Offset(w * 0.70, h), Offset(w * 0.52, h * 0.05), strut);
        for (int i = 1; i <= 4; i++) {
          final ly = h - i * h * 0.20;
          final lw = w * (0.20 - i * 0.03);
          canvas.drawLine(
              Offset(w / 2 - lw, ly), Offset(w / 2 + lw, ly), strut);
        }
        final blink = (sin(game.elapsedSeconds * 6 + lateral * 5) + 1) / 2;
        canvas.drawCircle(Offset(w / 2, h * 0.04), w * 0.07,
            Paint()
              ..color = const Color(0xFF00FF41)
                  .withValues(alpha: 0.3 + 0.7 * blink));
      case 1: // Industrial pipe with valve
        canvas.drawRect(Rect.fromLTWH(w * 0.36, 0, w * 0.28, h),
            Paint()..color = const Color(0xFF546E7A));
        canvas.drawRect(Rect.fromLTWH(w * 0.36, 0, w * 0.08, h),
            Paint()..color = Colors.white.withValues(alpha: 0.18));
        for (int i = 0; i < 3; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * 0.32, h * (0.12 + i * 0.32), w * 0.36, h * 0.05),
              Paint()..color = const Color(0xFF37474F));
        }
        canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.14,
            Paint()
              ..color = const Color(0xFFEF6C00)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4.0);
      default: // Neon pillar
        canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.05, w * 0.28, h * 0.95),
            Paint()..color = const Color(0xFF1C1C1C));
        final pulse = 0.5 + 0.5 * sin(game.elapsedSeconds * 3 + lateral * 4);
        final neon = Paint()
          ..color = const Color(0xFF00FF41).withValues(alpha: 0.4 + 0.5 * pulse);
        for (int i = 0; i < 4; i++) {
          canvas.drawRect(
              Rect.fromLTWH(w * 0.40, h * (0.12 + i * 0.20), w * 0.20, h * 0.07),
              neon);
        }
    }
  }

  // ── Shared drawing helpers ──────────────────────────────────────────────────

  void _pole(Canvas canvas, double w, double h, Color color) {
    canvas.drawRect(
        Rect.fromLTWH(w * 0.46, h * 0.10, w * 0.08, h * 0.90),
        Paint()..color = color);
  }

  void _trunk(Canvas canvas, double w, double h, Color color) {
    canvas.drawRect(
        Rect.fromLTWH(w * 0.44, h * 0.55, w * 0.12, h * 0.45),
        Paint()..color = color);
  }

  void _crystal(Canvas canvas, double cx, double baseY, double halfW,
      double height, Color color) {
    final body = Path()
      ..moveTo(cx, baseY - height)
      ..lineTo(cx - halfW, baseY)
      ..lineTo(cx + halfW, baseY)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    final shine = Path()
      ..moveTo(cx, baseY - height)
      ..lineTo(cx - halfW, baseY)
      ..lineTo(cx - halfW * 0.3, baseY)
      ..close();
    canvas.drawPath(
        shine, Paint()..color = Colors.white.withValues(alpha: 0.35));
  }
}

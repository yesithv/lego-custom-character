import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../brix_run_game.dart';

enum PowerupType { shield, magnet }

class PowerupComponent extends PositionComponent with HasGameReference<BrixRunGame> {
  final int lane;
  final PowerupType type;

  double _depth = 0.0;
  bool _collected = false;
  double _age = 0.0;

  static const _baseRadius = 20.0;

  double get depth => _depth;
  bool get collected => _collected;
  set collected(bool v) => _collected = v;

  PowerupComponent({required this.lane, required this.type})
      : super(size: Vector2(_baseRadius * 2, _baseRadius * 2), priority: 4);

  @override
  void update(double dt) {
    _depth += game.depthRate * dt;
    _age += dt;
    _syncTransform();
    if (_depth > 1.30) removeFromParent();
  }

  void _syncTransform() {
    final s = game.perspectiveScale(_depth);
    final groundPos = game.perspectivePos(lane, _depth);
    final r = _baseRadius * s;
    size = Vector2(r * 2, r * 2);
    final bob = sin(_age * 3.5) * 7.0 * s;
    position = Vector2(
      groundPos.x - r,
      groundPos.y - r * 2.6 - bob,
    );
    priority = (200 * _depth).floor() + 4;
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final pulse = 0.60 + 0.40 * sin(_age * 4.0);
    final Color color;
    final String icon;

    if (type == PowerupType.shield) {
      color = const Color(0xFF00AAFF);
      icon = '🛡';
    } else {
      color = const Color(0xFFFF6B35);
      icon = '🧲';
    }

    // Outer glow ring
    canvas.drawCircle(
      Offset(r, r),
      r + 7 * pulse,
      Paint()..color = color.withValues(alpha: 0.22 * pulse),
    );

    // Body
    canvas.drawCircle(Offset(r, r), r, Paint()..color = color);

    // Inner shine
    canvas.drawCircle(
      Offset(r - r * 0.22, r - r * 0.22),
      r * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.32),
    );

    // Border
    canvas.drawCircle(
      Offset(r, r),
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, r * 0.12),
    );

    // Emoji icon — only draw when large enough to be readable
    if (r > 10) {
      final fontSize = (r * 0.95).clamp(8.0, 22.0);
      final tp = TextPainter(
        text: TextSpan(text: icon, style: TextStyle(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));
    }
  }
}

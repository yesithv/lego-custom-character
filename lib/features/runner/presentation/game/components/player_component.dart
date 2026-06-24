import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../../character_editor/domain/entities/character.dart';
import '../brix_run_game.dart';

enum PlayerState { running, jumping, sliding, dead }

class PlayerComponent extends PositionComponent with HasGameRef<BrixRunGame> {
  final CharacterAppearance appearance;
  int currentLane;

  PlayerState _state = PlayerState.running;
  double _jumpProgress = 0;
  double _slideTimer = 0;
  double _targetX = 0;
  double _runAnimTimer = 0;

  static const double _w = 58.0;
  static const double _h = 86.0;
  static const double _slideH = 46.0;
  static const double _jumpHeight = 95.0;
  static const double _jumpDuration = 0.62;
  static const double _slideDuration = 0.50;
  static const double _laneSpeed = 14.0;

  bool get isJumping => _state == PlayerState.jumping;
  bool get isSliding => _state == PlayerState.sliding;
  double get jumpProgress => _jumpProgress;

  PlayerComponent({required this.appearance, required int initialLane})
      : currentLane = initialLane,
        super(size: Vector2(_w, _h), priority: 50);

  @override
  Future<void> onLoad() async {
    _targetX = game.laneXPositions[currentLane];
    position = Vector2(_targetX - _w / 2, game.playerBaseY - _h);
  }

  @override
  void update(double dt) {
    _runAnimTimer += dt;

    // Smooth lane slide
    final absTargetX = _targetX - size.x / 2;
    position.x += (absTargetX - position.x) * _laneSpeed * dt;

    switch (_state) {
      case PlayerState.running:
        position.y = game.playerBaseY - size.y;

      case PlayerState.jumping:
        _jumpProgress += dt / _jumpDuration;
        if (_jumpProgress >= 1.0) {
          _state = PlayerState.running;
          _jumpProgress = 0;
          position.y = game.playerBaseY - _h;
          size = Vector2(_w, _h);
        } else {
          final arc = sin(_jumpProgress * pi);
          position.y = game.playerBaseY - _h - arc * _jumpHeight;
        }

      case PlayerState.sliding:
        _slideTimer += dt;
        if (_slideTimer >= _slideDuration) {
          _state = PlayerState.running;
          _slideTimer = 0;
          size = Vector2(_w, _h);
          position.y = game.playerBaseY - _h;
        }

      case PlayerState.dead:
        break;
    }
  }

  void jump() {
    if (_state != PlayerState.running) return;
    _state = PlayerState.jumping;
    _jumpProgress = 0;
  }

  void slide() {
    if (_state == PlayerState.sliding || _state == PlayerState.dead) return;
    if (_state == PlayerState.jumping) return;
    _state = PlayerState.sliding;
    _slideTimer = 0;
    size = Vector2(_w, _slideH);
    position.y = game.playerBaseY - _slideH;
  }

  void changeLane(int direction, List<double> laneXPositions) {
    final next = (currentLane + direction).clamp(0, 2);
    if (next == currentLane) return;
    currentLane = next;
    _targetX = laneXPositions[currentLane];
  }

  void kill() => _state = PlayerState.dead;

  @override
  void render(Canvas canvas) {
    _drawGroundShadow(canvas);

    if (game.hasShield) _drawShieldAura(canvas);

    switch (_state) {
      case PlayerState.dead:
        _drawDead(canvas);
      case PlayerState.sliding:
        _drawSliding(canvas);
      default:
        _drawRunning(canvas);
        if (game.magnetActive) _drawMagnetAura(canvas);
    }
  }

  // Shadow stays on the ground even while jumping.
  void _drawGroundShadow(Canvas canvas) {
    // groundLocalY: y-coordinate of the ground in component-local space
    final groundLocalY = game.playerBaseY - position.y;
    final lift = _state == PlayerState.jumping ? sin(_jumpProgress * pi) : 0.0;
    final shrink = (1.0 - lift * 0.55).clamp(0.25, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, groundLocalY + 5),
        width: size.x * 0.68 * shrink,
        height: 9.0 * shrink,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.28 * shrink),
    );
  }

  void _drawShieldAura(Canvas canvas) {
    const c = Color(0xFF00AAFF);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x + 22,
          height: size.y + 22),
      Paint()..color = c.withValues(alpha: 0.14),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x + 22,
          height: size.y + 22),
      Paint()
        ..color = c.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawMagnetAura(Canvas canvas) {
    const c = Color(0xFFFF6B35);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x + 26,
          height: size.y + 26),
      Paint()
        ..color = c.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  // ── Back-view running character ─────────────────────────────────────────────

  void _drawRunning(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    final torso = _torsoColor(appearance.torso);
    final leg = _legColor(appearance.legDesign);
    final shoe = _shoeColor(appearance.shoes);
    final legBob = sin(_runAnimTimer * 8.5) * 5.5;
    final armSwing = sin(_runAnimTimer * 8.5) * 10.0;

    // Cape (drawn behind character — very prominent from back view)
    if (appearance.hasCape) _drawCape(canvas, w, h);

    // Left leg
    _rr(canvas, Rect.fromLTWH(w * 0.13, h * 0.60, w * 0.31, h * 0.37 + legBob), leg, 6);
    // Right leg (opposite phase)
    _rr(canvas, Rect.fromLTWH(w * 0.56, h * 0.60, w * 0.31, h * 0.37 - legBob), leg, 6);

    // Left shoe
    _rr(canvas,
        Rect.fromLTWH(w * 0.07, h * 0.90 + legBob * 0.55, w * 0.38, h * 0.12), shoe, 5);
    // Right shoe
    _rr(canvas,
        Rect.fromLTWH(w * 0.55, h * 0.90 - legBob * 0.55, w * 0.38, h * 0.12), shoe, 5);

    // Torso (back view — solid color with subtle spine stripe)
    _rr(canvas, Rect.fromLTWH(w * 0.07, h * 0.25, w * 0.86, h * 0.37), torso, 8);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.29, w * 0.14, h * 0.30),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Left arm swinging
    _rr(canvas,
        Rect.fromLTWH(-6, h * 0.27 + armSwing, 13, h * 0.28), skin, 5);
    // Right arm
    _rr(canvas,
        Rect.fromLTWH(w - 7, h * 0.27 - armSwing, 13, h * 0.28), skin, 5);

    // Head (back of head)
    _rr(canvas, Rect.fromLTWH(w * 0.15, 0, w * 0.70, h * 0.27), skin, 10);

    _drawHeadwear(canvas, w, h);
  }

  void _drawCape(Canvas canvas, double w, double h) {
    final capeColor = Colors.red.shade700;
    final wave = sin(_runAnimTimer * 6.0) * 5.0;
    final path = Path()
      ..moveTo(w * 0.20, h * 0.26)
      ..lineTo(w * 0.06, h * 0.74 + wave)
      ..quadraticBezierTo(-6, h * 0.82, w * 0.16, h * 0.78)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.84, h * 0.78)
      ..quadraticBezierTo(w + 6, h * 0.82, w * 0.94, h * 0.74 - wave)
      ..lineTo(w * 0.80, h * 0.26)
      ..close();
    canvas.drawPath(path, Paint()..color = capeColor.withValues(alpha: 0.90));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawHeadwear(Canvas canvas, double w, double h) {
    switch (appearance.headwearType) {
      case HeadwearType.none:
        break;
      case HeadwearType.hair:
        _rr(canvas,
            Rect.fromLTWH(w * 0.09, -5, w * 0.82, h * 0.16), Colors.brown.shade700, 8);
      case HeadwearType.helmet:
        _rr(canvas,
            Rect.fromLTWH(w * 0.05, -7, w * 0.90, h * 0.22), Colors.grey.shade600, 8);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.26, h * 0.16, w * 0.48, 5),
          Paint()..color = Colors.grey.shade800,
        );
      case HeadwearType.hat:
        // Brim
        _rr(canvas, Rect.fromLTWH(-3, h * 0.07, w + 6, h * 0.07), Colors.black87, 2);
        // Crown
        _rr(canvas,
            Rect.fromLTWH(w * 0.13, -11, w * 0.74, h * 0.21), Colors.black87, 8);
    }
  }

  // ── Sliding (crouched) ──────────────────────────────────────────────────────

  void _drawSliding(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    final torso = _torsoColor(appearance.torso);
    final leg = _legColor(appearance.legDesign);
    final shoe = _shoeColor(appearance.shoes);

    // Low torso
    _rr(canvas, Rect.fromLTWH(w * 0.0, h * 0.30, w, h * 0.46), torso, 9);
    // Head peeking
    _rr(canvas, Rect.fromLTWH(w * 0.16, 0, w * 0.68, h * 0.38), skin, 9);
    _drawHeadwear(canvas, w, h);
    // Legs splayed wide
    _rr(canvas, Rect.fromLTWH(-w * 0.12, h * 0.56, w * 0.54, h * 0.44), leg, 5);
    _rr(canvas, Rect.fromLTWH(w * 0.58, h * 0.56, w * 0.54, h * 0.44), leg, 5);
    // Shoes
    _rr(canvas,
        Rect.fromLTWH(-w * 0.14, h * 0.80, w * 0.46, h * 0.20), shoe, 5);
    _rr(canvas,
        Rect.fromLTWH(w * 0.68, h * 0.80, w * 0.46, h * 0.20), shoe, 5);
  }

  // ── Dead ───────────────────────────────────────────────────────────────────

  void _drawDead(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    final torso = _torsoColor(appearance.torso);
    final p = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    _rr(canvas, Rect.fromLTWH(0, h * 0.48, w, h * 0.52), torso, 7);
    _rr(canvas, Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.36), skin, 9);
    // X eyes
    canvas.drawLine(Offset(w * 0.28, h * 0.24), Offset(w * 0.42, h * 0.38), p);
    canvas.drawLine(Offset(w * 0.42, h * 0.24), Offset(w * 0.28, h * 0.38), p);
    canvas.drawLine(Offset(w * 0.58, h * 0.24), Offset(w * 0.72, h * 0.38), p);
    canvas.drawLine(Offset(w * 0.72, h * 0.24), Offset(w * 0.58, h * 0.38), p);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _rr(Canvas canvas, Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  Color _skinColor(SkinTone t) => switch (t) {
        SkinTone.light => const Color(0xFFFFDBAC),
        SkinTone.medium => const Color(0xFFD4A574),
        SkinTone.dark => const Color(0xFF8D5524),
        SkinTone.blue => Colors.blue.shade400,
        SkinTone.green => Colors.green.shade400,
        SkinTone.purple => Colors.purple.shade400,
        SkinTone.orange => Colors.orange.shade400,
        SkinTone.silver => Colors.grey.shade400,
        SkinTone.gold => const Color(0xFFFFD700),
      };

  Color _torsoColor(TorsoDesign d) => switch (d) {
        TorsoDesign.plain => Colors.red.shade400,
        TorsoDesign.police => Colors.blue.shade800,
        TorsoDesign.firefighter => Colors.red.shade800,
        TorsoDesign.ninja => Colors.black,
        TorsoDesign.pirate => Colors.brown.shade700,
        TorsoDesign.superhero => Colors.blue.shade600,
        TorsoDesign.medieval => Colors.grey.shade600,
        TorsoDesign.robot => Colors.blueGrey.shade400,
        _ => Colors.teal.shade400,
      };

  Color _legColor(LegDesign d) => switch (d) {
        LegDesign.plain => Colors.blue.shade700,
        LegDesign.camouflage => Colors.green.shade700,
        LegDesign.armor => Colors.grey.shade600,
        LegDesign.flames => Colors.orange.shade700,
        _ => Colors.indigo.shade600,
      };

  Color _shoeColor(ShoeType t) => switch (t) {
        ShoeType.sneakers => Colors.white,
        ShoeType.military => Colors.brown.shade800,
        ShoeType.cowboy => Colors.brown.shade600,
        ShoeType.witchBoots => Colors.black,
        _ => Colors.grey.shade800,
      };
}

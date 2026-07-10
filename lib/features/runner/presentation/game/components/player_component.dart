import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../../character_editor/domain/entities/character.dart';
import '../../../../character_editor/presentation/widgets/appearance_colors.dart';
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
  double _dashTimer = 0;

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
    if (_dashTimer > 0) _dashTimer -= dt;

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

  /// Embestida contra el jefe: ráfaga visual breve de velocidad.
  void dash() => _dashTimer = 0.5;

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
        if (_dashTimer > 0) _drawDashLines(canvas);
        if (game.magnetActive) _drawMagnetAura(canvas);
    }
  }

  // Líneas de velocidad durante la embestida al jefe
  void _drawDashLines(Canvas canvas) {
    final strength = (_dashTimer / 0.5).clamp(0.0, 1.0);
    final line = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.85 * strength)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = size.y * (0.15 + i * 0.22);
      final len = size.x * (0.35 + (i % 2) * 0.2);
      canvas.drawLine(Offset(-len - 4, y + size.y * 0.10),
          Offset(-4, y), line);
      canvas.drawLine(Offset(size.x + 4, y),
          Offset(size.x + len + 4, y + size.y * 0.10), line);
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
    final skin = skinColorFor(appearance.skinTone);
    final torso = torsoColorFor(appearance.torso);
    final shoe = shoeColorFor(appearance.shoes, skin);
    final legBob = sin(_runAnimTimer * 8.5) * 5.5;
    final armSwing = sin(_runAnimTimer * 8.5) * 10.0;

    // Cape (drawn behind character — very prominent from back view)
    if (appearance.hasCape) _drawCape(canvas, w, h);

    // Legs
    _drawLeg(canvas, Rect.fromLTWH(w * 0.13, h * 0.60, w * 0.31, h * 0.37 + legBob), skin);
    _drawLeg(canvas, Rect.fromLTWH(w * 0.56, h * 0.60, w * 0.31, h * 0.37 - legBob), skin);

    if (appearance.legType == LegType.skirt) {
      final skirt = Path()
        ..moveTo(w * 0.10, h * 0.58)
        ..lineTo(w * 0.90, h * 0.58)
        ..lineTo(w * 0.96, h * 0.74)
        ..lineTo(w * 0.04, h * 0.74)
        ..close();
      drawShadedPath(canvas, skirt, legColorFor(appearance.legDesign));
    }

    // Shoes (flippers extend outwards)
    final shoeStretch = appearance.shoes == ShoeType.flippers ? w * 0.12 : 0.0;
    _rr(canvas,
        Rect.fromLTWH(w * 0.07 - shoeStretch, h * 0.90 + legBob * 0.55,
            w * 0.38 + shoeStretch, h * 0.12),
        shoe, 5);
    _rr(canvas,
        Rect.fromLTWH(w * 0.55, h * 0.90 - legBob * 0.55,
            w * 0.38 + shoeStretch, h * 0.12),
        shoe, 5);

    // Torso (back view — solid color with subtle spine stripe)
    _rr(canvas, Rect.fromLTWH(w * 0.07, h * 0.25, w * 0.86, h * 0.37), torso, 8);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.29, w * 0.14, h * 0.30),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Equipped back accessory sits over the torso from this angle
    _drawBackAccessory(canvas, w, h);

    // Left arm swinging
    _rr(canvas,
        Rect.fromLTWH(-6, h * 0.27 + armSwing, 13, h * 0.28), skin, 5);
    // Right arm
    _rr(canvas,
        Rect.fromLTWH(w - 7, h * 0.27 - armSwing, 13, h * 0.28), skin, 5);

    // Fists — colored by glove type
    final glove = gloveColorFor(appearance.gloves, skin);
    final fistR = appearance.gloves == GloveType.boxing ? 8.5 : 6.5;
    drawPlasticSphere(
        canvas, Offset(0.5, h * 0.27 + armSwing + h * 0.28 + 3), fistR, glove);
    drawPlasticSphere(
        canvas, Offset(w - 0.5, h * 0.27 - armSwing + h * 0.28 + 3), fistR, glove);

    // Head (back of head)
    _rr(canvas, Rect.fromLTWH(w * 0.15, 0, w * 0.70, h * 0.27), skin, 10);
    // Contact shadow cast by the head onto the shoulders
    drawContactShadow(
        canvas,
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.27),
            width: w * 0.60,
            height: h * 0.035));

    _drawHeadwear(canvas, w, h);
  }

  void _drawLeg(Canvas canvas, Rect rect, Color skin) {
    final legColor = legColorFor(appearance.legDesign);
    switch (appearance.legType) {
      case LegType.pants:
        _rr(canvas, rect, legColor, 6);
        paintLegPattern(canvas, rect, appearance.legDesign);
      case LegType.shorts:
        _rr(canvas, rect, skin, 6);
        final upper = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.48);
        _rr(canvas, upper, legColor, 6);
        paintLegPattern(canvas, upper, appearance.legDesign);
      case LegType.skirt:
        _rr(canvas, rect, skin, 6);
      case LegType.legArmor:
        _rr(canvas, rect, legColor, 6);
        paintLegPattern(canvas, rect, appearance.legDesign);
        _rr(canvas,
            Rect.fromLTWH(rect.left + rect.width * 0.12,
                rect.top + rect.height * 0.5, rect.width * 0.76, rect.height * 0.4),
            Colors.grey.shade500, 3);
      case LegType.spacesuit:
        _rr(canvas, rect.inflate(1.0), Colors.white, 6);
        final band = Paint()..color = legColor;
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + rect.height * 0.25,
                rect.width, rect.height * 0.12),
            band);
        canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top + rect.height * 0.68,
                rect.width, rect.height * 0.12),
            band);
    }
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
    drawShadedPath(canvas, path, capeColor);
    // Inner fold shading follows the flutter of the cape
    final fold = Paint()
      ..color = darkenColor(capeColor, 0.18).withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.32, h * 0.32), Offset(w * 0.20, h * 0.70 + wave), fold);
    canvas.drawLine(Offset(w * 0.68, h * 0.32), Offset(w * 0.80, h * 0.70 - wave), fold);
  }

  void _drawBackAccessory(Canvas canvas, double w, double h) {
    final id = appearance.accessories.back;
    if (id == null) return;
    switch (id) {
      case 'mochila':
        _rr(canvas, Rect.fromLTWH(w * 0.18, h * 0.28, w * 0.64, h * 0.30),
            Colors.green.shade800, 7);
        final strap = Paint()
          ..color = Colors.green.shade900
          ..strokeWidth = 3;
        canvas.drawLine(Offset(w * 0.28, h * 0.26), Offset(w * 0.28, h * 0.58), strap);
        canvas.drawLine(Offset(w * 0.72, h * 0.26), Offset(w * 0.72, h * 0.58), strap);
      case 'jetpack':
        final body = Colors.grey.shade600;
        final flame = Paint()..color = Colors.orange.shade600;
        for (final x in [w * 0.22, w * 0.56]) {
          _rr(canvas, Rect.fromLTWH(x, h * 0.27, w * 0.22, h * 0.30), body, 7);
          final path = Path()
            ..moveTo(x + w * 0.04, h * 0.57)
            ..lineTo(x + w * 0.11, h * 0.66)
            ..lineTo(x + w * 0.18, h * 0.57)
            ..close();
          canvas.drawPath(path, flame);
        }
      case 'alas':
        final wing = Paint()..color = Colors.grey.shade100;
        final flap = sin(_runAnimTimer * 6.0) * h * 0.02;
        final leftWing = Path()
          ..moveTo(w * 0.30, h * 0.30)
          ..quadraticBezierTo(-w * 0.35, h * 0.10 + flap, -w * 0.28, h * 0.48 + flap)
          ..quadraticBezierTo(-w * 0.02, h * 0.46, w * 0.30, h * 0.45)
          ..close();
        final rightWing = Path()
          ..moveTo(w * 0.70, h * 0.30)
          ..quadraticBezierTo(w * 1.35, h * 0.10 + flap, w * 1.28, h * 0.48 + flap)
          ..quadraticBezierTo(w * 1.02, h * 0.46, w * 0.70, h * 0.45)
          ..close();
        canvas.drawPath(leftWing, wing);
        canvas.drawPath(rightWing, wing);
        final wingOutline = Paint()
          ..color = Colors.grey.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        canvas.drawPath(leftWing, wingOutline);
        canvas.drawPath(rightWing, wingOutline);
      case 'alas mariposa':
        // Alas de mariposa que aletean al correr — muy visibles de espaldas
        final flapAngle = 0.30 + sin(_runAnimTimer * 8.0) * 0.12;
        final upper = Colors.pink.shade300;
        final lower = Colors.purple.shade200;
        final spot = Paint()..color = Colors.white.withValues(alpha: 0.75);
        for (final side in [-1, 1]) {
          canvas.save();
          canvas.translate(w * (0.5 + side * 0.10), h * 0.33);
          canvas.rotate(side * flapAngle);
          final upperR = Rect.fromCenter(
              center: Offset(side * w * 0.22, -h * 0.03),
              width: w * 0.36,
              height: h * 0.22);
          drawShadedPath(canvas, Path()..addOval(upperR), upper);
          final lowerR = Rect.fromCenter(
              center: Offset(side * w * 0.16, h * 0.14),
              width: w * 0.26,
              height: h * 0.15);
          drawShadedPath(canvas, Path()..addOval(lowerR), lower);
          canvas.drawCircle(upperR.center, w * 0.05, spot);
          canvas.drawCircle(lowerR.center, w * 0.032, spot);
          canvas.restore();
        }
      case 'capa corta':
        final path = Path()
          ..moveTo(w * 0.12, h * 0.26)
          ..lineTo(w * 0.88, h * 0.26)
          ..lineTo(w * 0.94, h * 0.62)
          ..quadraticBezierTo(w * 0.5, h * 0.65, w * 0.06, h * 0.62)
          ..close();
        drawShadedPath(canvas, path, Colors.blue.shade800);
      case 'capa vampiro':
        final wave = sin(_runAnimTimer * 6.0) * 4.0;
        // Jagged bat-wing hem
        final path = Path()
          ..moveTo(w * 0.10, h * 0.24)
          ..lineTo(w * 0.90, h * 0.24)
          ..lineTo(w * 1.0, h * 0.80 + wave);
        const points = 4;
        for (var i = 1; i <= points; i++) {
          final x = w * (1.0 - i / points);
          final dip = h * 0.80 + wave * (1 - 2 * i / points);
          path
            ..lineTo(x + w / points / 2, dip - h * 0.035)
            ..lineTo(x, dip);
        }
        path.close();
        drawShadedPath(canvas, path, Colors.grey.shade900);
    }
  }

  void _drawHeadwear(Canvas canvas, double w, double h) {
    switch (appearance.headwearType) {
      case HeadwearType.none:
        break;
      case HeadwearType.hair:
        _drawHair(canvas, w, h);
      case HeadwearType.helmet:
        _drawHelmet(canvas, w, h);
      case HeadwearType.hat:
        _drawHat(canvas, w, h);
    }
  }

  void _drawHair(Canvas canvas, double w, double h) {
    final style = appearance.hairStyle ?? HairStyle.straight;
    if (style == HairStyle.bald) return;
    final color = hairColorFor(style);
    final paint = Paint()..color = color;

    switch (style) {
      case HairStyle.straight:
        _rr(canvas, Rect.fromLTWH(w * 0.09, -5, w * 0.82, h * 0.16), color, 8);
      case HairStyle.curly:
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
              Offset(w * (0.20 + i * 0.20), h * 0.015), w * 0.13, paint);
        }
      case HairStyle.afro:
        canvas.drawCircle(Offset(w * 0.5, h * 0.05), w * 0.40, paint);
      case HairStyle.mohawk:
        _rr(canvas, Rect.fromLTWH(w * 0.12, -3, w * 0.76, h * 0.09),
            Colors.grey.shade800, 4);
        _rr(canvas, Rect.fromLTWH(w * 0.44, -h * 0.10, w * 0.12, h * 0.22), color, 3);
      case HairStyle.ponytail:
        _rr(canvas, Rect.fromLTWH(w * 0.09, -5, w * 0.82, h * 0.16), color, 8);
        // Long tail swaying down the back — fully visible from behind
        final sway = sin(_runAnimTimer * 7.0) * w * 0.04;
        final tail = Path()
          ..moveTo(w * 0.42, h * 0.10)
          ..lineTo(w * 0.58, h * 0.10)
          ..quadraticBezierTo(
              w * 0.58 + sway, h * 0.34, w * 0.54 + sway, h * 0.52)
          ..quadraticBezierTo(
              w * 0.50 + sway, h * 0.58, w * 0.46 + sway, h * 0.52)
          ..quadraticBezierTo(w * 0.42 + sway, h * 0.34, w * 0.42, h * 0.10)
          ..close();
        drawShadedPath(canvas, tail, color);
        // Coletero
        _rr(canvas,
            Rect.fromLTWH(w * 0.415, h * 0.155, w * 0.17, h * 0.030),
            Colors.pink.shade400, 2);
        // Puntita
        drawPlasticSphere(
            canvas, Offset(w * 0.50 + sway, h * 0.545), w * 0.055, color);
      case HairStyle.braids:
        _rr(canvas, Rect.fromLTWH(w * 0.09, -5, w * 0.82, h * 0.16), color, 8);
        // Long segmented braids reaching the mid-back
        for (final bx in [w * 0.17, w * 0.83]) {
          for (var i = 0; i < 5; i++) {
            drawPlasticSphere(canvas,
                Offset(bx, h * (0.11 + i * 0.085)), w * (0.075 - i * 0.005), color);
          }
          _rr(canvas,
              Rect.fromLTWH(bx - w * 0.055, h * 0.48, w * 0.11, h * 0.028),
              Colors.red.shade400, 2);
          drawPlasticSphere(canvas, Offset(bx, h * 0.535), w * 0.04, color);
        }
      case HairStyle.shaved:
        _rr(canvas, Rect.fromLTWH(w * 0.11, -3, w * 0.78, h * 0.10), color, 5);
      case HairStyle.bald:
        break;
    }
  }

  void _drawHelmet(Canvas canvas, double w, double h) {
    final style = appearance.helmetStyle ?? HelmetStyle.medieval;
    final color = helmetColorFor(style);

    _rr(canvas, Rect.fromLTWH(w * 0.05, -7, w * 0.90, h * 0.22), color, 8);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.26, h * 0.16, w * 0.48, 5),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    switch (style) {
      case HelmetStyle.roman:
        _rr(canvas, Rect.fromLTWH(w * 0.44, -h * 0.14, w * 0.12, h * 0.20),
            Colors.red.shade900, 4);
      case HelmetStyle.viking:
        final horn = Paint()..color = const Color(0xFFF5F0E0);
        final leftHorn = Path()
          ..moveTo(w * 0.08, h * 0.06)
          ..lineTo(-w * 0.06, -h * 0.10)
          ..lineTo(w * 0.16, -h * 0.02)
          ..close();
        final rightHorn = Path()
          ..moveTo(w * 0.92, h * 0.06)
          ..lineTo(w * 1.06, -h * 0.10)
          ..lineTo(w * 0.84, -h * 0.02)
          ..close();
        drawShadedPath(canvas, leftHorn, horn.color);
        drawShadedPath(canvas, rightHorn, horn.color);
      case HelmetStyle.firefighter:
        _rr(canvas, Rect.fromLTWH(w * 0.0, h * 0.13, w, h * 0.06),
            Colors.yellow.shade800, 3);
      default:
        break;
    }
  }

  void _drawHat(Canvas canvas, double w, double h) {
    final style = appearance.hatStyle ?? HatStyle.cap;
    final color = hatColorFor(style);

    switch (style) {
      case HatStyle.wizard:
        _rr(canvas, Rect.fromLTWH(w * 0.02, h * 0.07, w * 0.96, h * 0.06),
            Colors.indigo.shade800, 2);
        final cone = Path()
          ..moveTo(w * 0.15, h * 0.08)
          ..lineTo(w * 0.5, -h * 0.22)
          ..lineTo(w * 0.85, h * 0.08)
          ..close();
        drawShadedPath(canvas, cone, color);
      case HatStyle.cowboy:
        _rr(canvas, Rect.fromLTWH(-w * 0.06, h * 0.07, w * 1.12, h * 0.07), color, 4);
        _rr(canvas, Rect.fromLTWH(w * 0.20, -h * 0.08, w * 0.60, h * 0.16), color, 6);
      case HatStyle.cap:
        _rr(canvas, Rect.fromLTWH(w * 0.13, -6, w * 0.74, h * 0.18), color, 8);
      case HatStyle.crown:
        final path = Path()
          ..moveTo(w * 0.18, h * 0.08)
          ..lineTo(w * 0.18, -h * 0.09)
          ..lineTo(w * 0.34, -h * 0.02)
          ..lineTo(w * 0.5, -h * 0.12)
          ..lineTo(w * 0.66, -h * 0.02)
          ..lineTo(w * 0.82, -h * 0.09)
          ..lineTo(w * 0.82, h * 0.08)
          ..close();
        drawShadedPath(canvas, path, color);
      case HatStyle.tiara:
        final path = Path()
          ..moveTo(w * 0.28, h * 0.05)
          ..lineTo(w * 0.28, -h * 0.02)
          ..lineTo(w * 0.42, h * 0.0)
          ..lineTo(w * 0.5, -h * 0.07)
          ..lineTo(w * 0.58, h * 0.0)
          ..lineTo(w * 0.72, -h * 0.02)
          ..lineTo(w * 0.72, h * 0.05)
          ..close();
        drawShadedPath(canvas, path, color);
      case HatStyle.topHat:
        _rr(canvas, Rect.fromLTWH(-3, h * 0.07, w + 6, h * 0.07), color, 2);
        _rr(canvas, Rect.fromLTWH(w * 0.18, -h * 0.20, w * 0.64, h * 0.28), color, 4);
      case HatStyle.pirate:
        final tricorn = Path()
          ..moveTo(-w * 0.08, h * 0.10)
          ..lineTo(w * 0.02, -h * 0.08)
          ..quadraticBezierTo(w * 0.5, -h * 0.18, w * 0.98, -h * 0.08)
          ..lineTo(w * 1.08, h * 0.10)
          ..close();
        drawShadedPath(canvas, tricorn, color);
    }
  }

  // ── Sliding (crouched) ──────────────────────────────────────────────────────

  void _drawSliding(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = skinColorFor(appearance.skinTone);
    final torso = torsoColorFor(appearance.torso);
    final leg = legColorFor(appearance.legDesign);
    final shoe = shoeColorFor(appearance.shoes, skin);

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
    final skin = skinColorFor(appearance.skinTone);
    final torso = torsoColorFor(appearance.torso);
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
    drawPlasticRect(canvas, rect, color, radius);
  }
}

import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

import '../../../../character_editor/domain/entities/character.dart';
import '../brix_run_game.dart';
import 'coin_component.dart';
import 'obstacle_component.dart';

enum PlayerState { running, jumping, sliding, dead }

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BrixRunGame> {
  final CharacterAppearance appearance;
  int currentLane;

  PlayerState _state = PlayerState.running;
  double _jumpProgress = 0;
  double _slideTimer = 0;
  double _targetY = 0;
  double _runAnimTimer = 0;

  static const double _w = 48.0;
  static const double _h = 72.0;
  static const double _slideH = 38.0;
  static const double _jumpHeight = 115.0;
  static const double _jumpDuration = 0.58;
  static const double _slideDuration = 0.5;
  static const double _laneSpeed = 10.0;

  late RectangleHitbox _hitbox;

  PlayerComponent({required this.appearance, required int initialLane})
      : currentLane = initialLane,
        super(size: Vector2(_w, _h), priority: 10);

  @override
  Future<void> onLoad() async {
    _targetY = game.lanePositions[currentLane] - _h;
    position = Vector2(80, _targetY);
    _hitbox = RectangleHitbox(size: size);
    add(_hitbox);
  }

  @override
  void update(double dt) {
    _runAnimTimer += dt;

    switch (_state) {
      case PlayerState.running:
        position.y += (_targetY - position.y) * _laneSpeed * dt;

      case PlayerState.jumping:
        _jumpProgress += dt / _jumpDuration;
        if (_jumpProgress >= 1.0) {
          _state = PlayerState.running;
          _jumpProgress = 0;
          position.y = _targetY;
        } else {
          position.y = _targetY - sin(_jumpProgress * pi) * _jumpHeight;
        }

      case PlayerState.sliding:
        _slideTimer += dt;
        if (_slideTimer >= _slideDuration) {
          _state = PlayerState.running;
          _slideTimer = 0;
          size = Vector2(_w, _h);
          _hitbox.size = size;
          _hitbox.position = Vector2.zero();
          position.y = _targetY;
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
    _hitbox.size = size;
    // Align hitbox to bottom of original height
    position.y = _targetY + (_h - _slideH);
  }

  void changeLane(int direction, List<double> lanePositions) {
    final next = (currentLane + direction).clamp(0, 2);
    if (next == currentLane) return;
    currentLane = next;
    _targetY = lanePositions[currentLane] - _h;
  }

  void kill() {
    _state = PlayerState.dead;
  }

  @override
  void render(Canvas canvas) {
    if (game.hasShield) _drawShieldAura(canvas);

    if (_state == PlayerState.dead) {
      _drawDead(canvas);
      return;
    }
    if (_state == PlayerState.sliding) {
      _drawSliding(canvas);
      return;
    }
    _drawRunning(canvas);

    if (game.magnetActive) _drawMagnetAura(canvas);
  }

  void _drawShieldAura(Canvas canvas) {
    const shieldColor = Color(0xFF00AAFF);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x + 18,
        height: size.y + 18,
      ),
      Paint()..color = shieldColor.withValues(alpha: 0.18),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x + 18,
        height: size.y + 18,
      ),
      Paint()
        ..color = shieldColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawMagnetAura(Canvas canvas) {
    const magnetColor = Color(0xFFFF6B35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x + 22,
        height: size.y + 22,
      ),
      Paint()
        ..color = magnetColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Drawing helpers ────────────────────────────────────────────────────────

  void _drawRunning(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    final torso = _torsoColor(appearance.torso);
    final leg = _legColor(appearance.legDesign);

    // Leg bob animation
    final legBob = sin(_runAnimTimer * 8) * 3;

    // Head
    _rr(canvas, Rect.fromLTWH(w * 0.18, 0, w * 0.64, h * 0.28), skin, 6);
    _drawFace(canvas, w, h);

    // Hair / headwear
    _drawHeadwear(canvas, w, h);

    // Torso
    _rr(canvas, Rect.fromLTWH(w * 0.1, h * 0.29, w * 0.8, h * 0.35), torso, 5);

    // Arms (swinging)
    final armSwing = sin(_runAnimTimer * 8) * 6;
    _rr(canvas, Rect.fromLTWH(-4, h * 0.31 + armSwing, 10, h * 0.22), skin, 4);
    _rr(canvas, Rect.fromLTWH(w - 6, h * 0.31 - armSwing, 10, h * 0.22), skin, 4);

    // Left leg
    _rr(canvas,
        Rect.fromLTWH(w * 0.12, h * 0.65, w * 0.3, h * 0.35 + legBob), leg, 4);
    // Right leg (opposite phase)
    _rr(canvas,
        Rect.fromLTWH(w * 0.54, h * 0.65, w * 0.3, h * 0.35 - legBob), leg, 4);

    // Shoe dots
    final shoe = _shoeColor(appearance.shoes);
    canvas.drawCircle(Offset(w * 0.27, h * 0.97 + legBob * 0.5), 6,
        Paint()..color = shoe);
    canvas.drawCircle(Offset(w * 0.69, h * 0.97 - legBob * 0.5), 6,
        Paint()..color = shoe);
  }

  void _drawSliding(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    final torso = _torsoColor(appearance.torso);

    // Crouched body
    _rr(canvas, Rect.fromLTWH(0, h * 0.1, w, h * 0.5), torso, 8);
    // Head peeking
    _rr(canvas, Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.35), skin, 6);
    _drawFace(canvas, w, h * 0.5);
  }

  void _drawDead(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skin = _skinColor(appearance.skinTone);
    _rr(canvas, Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.6), skin, 8);
    // X eyes
    final p = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.3, h * 0.35), Offset(w * 0.45, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.45, h * 0.35), Offset(w * 0.3, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.55, h * 0.35), Offset(w * 0.7, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.7, h * 0.35), Offset(w * 0.55, h * 0.5), p);
  }

  void _drawFace(Canvas canvas, double w, double h) {
    final eyeColor = switch (appearance.eyes) {
      EyeStyle.laser => Colors.red,
      EyeStyle.robot => Colors.cyan,
      _ => Colors.black87,
    };
    final eyeR = h * 0.06;
    canvas.drawCircle(
        Offset(w * 0.35, h * 0.12), eyeR, Paint()..color = eyeColor);
    canvas.drawCircle(
        Offset(w * 0.65, h * 0.12), eyeR, Paint()..color = eyeColor);

    // Smile
    if (appearance.mouth == MouthStyle.smile) {
      final path = Path()
        ..moveTo(w * 0.35, h * 0.19)
        ..quadraticBezierTo(w * 0.5, h * 0.26, w * 0.65, h * 0.19);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawHeadwear(Canvas canvas, double w, double h) {
    switch (appearance.headwearType) {
      case HeadwearType.none:
        break;
      case HeadwearType.hair:
        _rr(canvas, Rect.fromLTWH(w * 0.12, -4, w * 0.76, h * 0.14),
            Colors.brown.shade700, 5);
      case HeadwearType.helmet:
        _rr(canvas, Rect.fromLTWH(w * 0.08, -6, w * 0.84, h * 0.18),
            Colors.grey.shade600, 5);
      case HeadwearType.hat:
        _rr(canvas, Rect.fromLTWH(w * 0.05, -10, w * 0.9, h * 0.22),
            Colors.black87, 4);
    }
  }

  void _rr(Canvas canvas, Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  // ── Color helpers (mirrors CharacterPreview) ───────────────────────────────

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

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ObstacleComponent && _state != PlayerState.dead) {
      game.hitObstacle();
    } else if (other is CoinComponent) {
      other.removeFromParent();
      game.collectCoin();
    }
  }
}

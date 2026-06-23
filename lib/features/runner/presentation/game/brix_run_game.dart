import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../../character_editor/domain/entities/character.dart';
import 'components/background_component.dart';
import 'components/coin_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';

class BrixRunGame extends FlameGame
    with HasCollisionDetection, ChangeNotifier {
  final CharacterAppearance appearance;
  final String worldId;

  // Runtime state — read by HUD overlay
  double speed = 220.0;
  int score = 0;
  int coins = 0;
  int meters = 0;
  double multiplier = 1.0;
  int obstacleStreak = 0;
  bool isAlive = true;

  double _distanceTraveled = 0;
  double _speedTimer = 0;
  double _obstacleTimer = 0;
  double _coinTimer = 0;

  late PlayerComponent _player;
  final Random _rng = Random();

  // Expose for obstacle evade check
  double get playerX => _player.position.x + _player.size.x;

  // Lane Y positions (computed after size is known)
  List<double> get lanePositions => [
        size.y * 0.40,
        size.y * 0.57,
        size.y * 0.74,
      ];

  static const String _overlayHud = 'hud';
  static const String _overlayGameOver = 'gameOver';

  BrixRunGame({required this.appearance, required this.worldId});

  @override
  Future<void> onLoad() async {
    add(BackgroundComponent(worldId: worldId));
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);
    overlays.add(_overlayHud);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    // Distance → meters → score
    _distanceTraveled += speed * dt;
    meters = (_distanceTraveled / 100).floor();
    score = meters + (coins * 5) + (obstacleStreak * 2);
    score = (score * multiplier).floor();

    // Speed ramp: +12 px/s every 5 seconds, capped at 900
    _speedTimer += dt;
    if (_speedTimer >= 5.0) {
      speed = (speed + 12).clamp(220, 900);
      _speedTimer = 0;
    }

    // Obstacle spawning — interval shrinks as speed grows
    _obstacleTimer += dt;
    final spawnInterval = (2.2 - speed / 900).clamp(0.75, 2.2);
    if (_obstacleTimer >= spawnInterval) {
      _spawnObstacle();
      _obstacleTimer = 0;
    }

    // Coin spawning
    _coinTimer += dt;
    if (_coinTimer >= 0.9) {
      _spawnCoin();
      _coinTimer = 0;
    }

    notifyListeners();
  }

  void _spawnObstacle() {
    final lane = _rng.nextInt(3);
    final type = _rng.nextDouble() < 0.25 ? ObstacleType.barrier : ObstacleType.block;
    add(ObstacleComponent(
      lane: lane,
      laneY: lanePositions[lane],
      startX: size.x + 60,
      type: type,
    ));
  }

  void _spawnCoin() {
    // Skip a coin if there's an obstacle in that lane recently
    final lane = _rng.nextInt(3);
    add(CoinComponent(
      lane: lane,
      laneY: lanePositions[lane],
      startX: size.x + 80 + _rng.nextDouble() * 60,
    ));
  }

  // ── Input handlers (called from RunnerPage gesture detector) ──────────────

  void onSwipeUp() => _player.jump();
  void onSwipeDown() => _player.slide();
  void onSwipeLeft() => _player.changeLane(-1, lanePositions);
  void onSwipeRight() => _player.changeLane(1, lanePositions);
  void onTap() => _player.jump(); // tap also jumps (easier for kids)

  // ── Game events ────────────────────────────────────────────────────────────

  void collectCoin() {
    coins++;
    notifyListeners();
  }

  void evadedObstacle() {
    obstacleStreak++;
    multiplier = obstacleStreak >= 50
        ? 5.0
        : obstacleStreak >= 25
            ? 3.0
            : obstacleStreak >= 10
                ? 2.0
                : 1.0;
    notifyListeners();
  }

  void hitObstacle() {
    if (!isAlive) return;
    isAlive = false;
    _player.kill();
    overlays.remove(_overlayHud);
    overlays.add(_overlayGameOver);
    // Short delay then pause so player sees impact
    Future.delayed(const Duration(milliseconds: 600), pauseEngine);
  }

  void restart() {
    score = 0;
    coins = 0;
    meters = 0;
    multiplier = 1.0;
    obstacleStreak = 0;
    speed = 220.0;
    _distanceTraveled = 0;
    _speedTimer = 0;
    _obstacleTimer = 0;
    _coinTimer = 0;
    isAlive = true;

    // Remove all obstacles and coins
    children.whereType<ObstacleComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<CoinComponent>().toList().forEach((c) => c.removeFromParent());

    // Rebuild player
    _player.removeFromParent();
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

    overlays.remove(_overlayGameOver);
    overlays.add(_overlayHud);
    resumeEngine();
    notifyListeners();
  }
}

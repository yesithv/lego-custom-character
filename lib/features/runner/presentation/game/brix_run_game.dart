import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/audio_service.dart';
import '../../../character_editor/domain/entities/character.dart';
import 'components/background_component.dart';
import 'components/coin_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';
import 'components/powerup_component.dart';
import 'components/score_popup_component.dart';

enum RunnerZone { inicio, nucleo, caos }

class BrixRunGame extends FlameGame
    with HasCollisionDetection, ChangeNotifier {
  final CharacterAppearance appearance;
  final CharacterType characterType;
  final String worldId;
  final void Function(int coins)? onRunComplete;
  final VoidCallback? onHit;

  // Runtime state — read by HUD
  double speed = 220.0;
  int score = 0;
  int coins = 0;
  int meters = 0;
  double multiplier = 1.0;
  int obstacleStreak = 0;
  int maxObstacleStreak = 0;
  int jumpCount = 0;
  double elapsedSeconds = 0.0;
  bool isAlive = true;

  // Power-up state
  bool _heroShieldActive = false;
  bool shieldPowerupActive = false;
  bool magnetActive = false;
  double _shieldTimer = 0;
  double _magnetTimer = 0;
  double _powerupTimer = 0;

  static const double _shieldPowerupDuration = 5.0;
  static const double _magnetDuration = 5.0;
  static const double _powerupSpawnInterval = 12.0;

  bool get hasShield => _heroShieldActive || shieldPowerupActive;

  double _distanceTraveled = 0;
  double _speedTimer = 0;
  double _obstacleTimer = 0;
  double _coinTimer = 0;

  late PlayerComponent _player;
  final Random _rng = Random();

  double get playerX => _player.position.x + _player.size.x;
  double get playerY => _player.position.y + _player.size.y / 2;

  List<double> get lanePositions => [
        size.y * 0.50,
        size.y * 0.65,
        size.y * 0.78,
      ];

  static const String _overlayHud = 'hud';
  static const String _overlayGameOver = 'gameOver';

  RunnerZone get currentZone {
    if (meters < 500) return RunnerZone.inicio;
    if (meters < 1500) return RunnerZone.nucleo;
    return RunnerZone.caos;
  }

  double get _zoneSpeedBonus {
    if (currentZone == RunnerZone.nucleo) return 60;
    if (currentZone == RunnerZone.caos) return 160;
    return 0;
  }

  BrixRunGame({
    required this.appearance,
    required this.characterType,
    required this.worldId,
    this.onRunComplete,
    this.onHit,
  });

  @override
  Future<void> onLoad() async {
    add(BackgroundComponent(worldId: worldId));
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

    // Character type starting bonuses
    switch (characterType) {
      case CharacterType.hero:
        _heroShieldActive = true;
      case CharacterType.mysterious:
        obstacleStreak = 10;
        multiplier = 2.0;
      default:
        break;
    }

    overlays.add(_overlayHud);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    elapsedSeconds += dt;
    _distanceTraveled += speed * dt;
    meters = (_distanceTraveled / 100).floor();
    score = meters + (coins * 5) + (obstacleStreak * 2);
    score = (score * multiplier).floor();

    // Speed ramp: +12 px/s every 5s, capped at 900
    _speedTimer += dt;
    if (_speedTimer >= 5.0) {
      speed = (speed + 12).clamp(220, 900);
      _speedTimer = 0;
    }
    final effectiveSpeed = speed + _zoneSpeedBonus;

    // Obstacle spawning
    _obstacleTimer += dt;
    final spawnInterval = (2.2 - effectiveSpeed / 900).clamp(0.65, 2.2);
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

    // Power-up spawning
    _powerupTimer += dt;
    if (_powerupTimer >= _powerupSpawnInterval) {
      _spawnPowerup();
      _powerupTimer = 0;
    }

    // Magnet timer
    if (magnetActive) {
      _magnetTimer -= dt;
      if (_magnetTimer <= 0) magnetActive = false;
    }

    // Shield powerup timer
    if (shieldPowerupActive) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) shieldPowerupActive = false;
    }

    notifyListeners();
  }

  void _spawnObstacle() {
    final lane = _rng.nextInt(3);
    final roll = _rng.nextDouble();
    final type = roll < 0.20
        ? ObstacleType.barrier
        : roll < 0.35
            ? ObstacleType.spike
            : ObstacleType.block;
    add(ObstacleComponent(
      lane: lane,
      laneY: lanePositions[lane],
      startX: size.x + 60,
      type: type,
    ));

    // Double obstacle in caos zone (20% chance, different lane)
    if (currentZone == RunnerZone.caos && _rng.nextDouble() < 0.20) {
      final otherLane = (lane + 1 + _rng.nextInt(2)) % 3;
      final t2 = _rng.nextDouble() < 0.3 ? ObstacleType.barrier : ObstacleType.block;
      add(ObstacleComponent(
        lane: otherLane,
        laneY: lanePositions[otherLane],
        startX: size.x + 60,
        type: t2,
      ));
    }
  }

  void _spawnCoin() {
    final lane = _rng.nextInt(3);
    add(CoinComponent(
      lane: lane,
      laneY: lanePositions[lane],
      startX: size.x + 80 + _rng.nextDouble() * 60,
    ));
  }

  void _spawnPowerup() {
    final lane = _rng.nextInt(3);
    final type = _rng.nextBool() ? PowerupType.shield : PowerupType.magnet;
    add(PowerupComponent(
      lane: lane,
      laneY: lanePositions[lane],
      startX: size.x + 80,
      type: type,
    ));
  }

  // ── Input (called from RunnerPage gesture detector) ────────────────────────

  void onSwipeUp() {
    _player.jump();
    if (isAlive) {
      jumpCount++;
      AudioService.instance.playJump();
    }
  }

  void onSwipeDown() => _player.slide();
  void onSwipeLeft() => _player.changeLane(-1, lanePositions);
  void onSwipeRight() => _player.changeLane(1, lanePositions);

  void onTap() {
    _player.jump();
    if (isAlive) {
      jumpCount++;
      AudioService.instance.playJump();
    }
  }

  // ── Game events ────────────────────────────────────────────────────────────

  void collectCoin() {
    final value = characterType == CharacterType.villain ? 2 : 1;
    coins += value;
    AudioService.instance.playCoin();
    add(ScorePopupComponent(
      '+$value',
      spawnPosition: Vector2(playerX - 30, playerY - 55),
    ));
    notifyListeners();
  }

  void activatePowerup(PowerupType type) {
    AudioService.instance.playPowerup();
    switch (type) {
      case PowerupType.shield:
        shieldPowerupActive = true;
        _shieldTimer = _shieldPowerupDuration;
      case PowerupType.magnet:
        magnetActive = true;
        _magnetTimer = _magnetDuration;
    }
    notifyListeners();
  }

  void evadedObstacle() {
    obstacleStreak++;
    if (obstacleStreak > maxObstacleStreak) maxObstacleStreak = obstacleStreak;
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

    // Shield absorbs the hit
    if (hasShield) {
      _heroShieldActive = false;
      shieldPowerupActive = false;
      _shieldTimer = 0;
      AudioService.instance.playHit();
      onHit?.call();
      notifyListeners();
      return;
    }

    isAlive = false;
    _player.kill();
    AudioService.instance.playHit();
    onHit?.call();
    overlays.remove(_overlayHud);
    overlays.add(_overlayGameOver);
    Future.delayed(const Duration(milliseconds: 500), () {
      pauseEngine();
      onRunComplete?.call(coins);
    });
  }

  void restart() {
    score = 0;
    coins = 0;
    meters = 0;
    multiplier = characterType == CharacterType.mysterious ? 2.0 : 1.0;
    obstacleStreak = characterType == CharacterType.mysterious ? 10 : 0;
    maxObstacleStreak = 0;
    jumpCount = 0;
    elapsedSeconds = 0.0;
    speed = 220.0;
    _distanceTraveled = 0;
    _speedTimer = 0;
    _obstacleTimer = 0;
    _coinTimer = 0;
    _powerupTimer = 0;
    _heroShieldActive = characterType == CharacterType.hero;
    shieldPowerupActive = false;
    magnetActive = false;
    _magnetTimer = 0;
    _shieldTimer = 0;
    isAlive = true;

    children.whereType<ObstacleComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<CoinComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<PowerupComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<ScorePopupComponent>().toList().forEach((c) => c.removeFromParent());

    _player.removeFromParent();
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

    overlays.remove(_overlayGameOver);
    overlays.add(_overlayHud);
    resumeEngine();
    notifyListeners();
  }
}

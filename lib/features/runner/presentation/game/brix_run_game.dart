import 'dart:math';
import 'dart:ui' show Canvas;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/test_mode/test_mode.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/boss_config.dart';
import '../../domain/entities/world_config.dart';
import 'components/background_component.dart';
import 'components/boss_component.dart';
import 'components/coin_component.dart';
import 'components/obstacle_component.dart';
import 'components/player_component.dart';
import 'components/powerup_component.dart';
import 'components/powerup_effects.dart';
import 'components/scenery_component.dart';
import 'components/score_popup_component.dart';
import 'components/tutorial_hint_component.dart';

enum RunnerZone { inicio, nucleo, caos }

/// Fases de la partida: carrera normal → entrada del jefe → pelea →
/// animación de derrota del jefe → victoria.
enum GamePhase { running, bossIntro, bossFight, bossDefeated, victory }

class BrixRunGame extends FlameGame with ChangeNotifier, KeyboardEvents {
  final CharacterAppearance appearance;
  final CharacterType characterType;
  final String worldId;
  final void Function(int coins)? onRunComplete;
  final VoidCallback? onHit;

  /// Se dispara cuando un golpe mortal ofrece **retomar la carrera** (revive):
  /// la partida queda pausada esperando que el jugador pague o rechace. La
  /// página lo usa para hacer `setState` y pintar el overlay de continuación.
  final VoidCallback? onOfferContinue;

  /// Multiplicador de monedas ganadas (VIP: 1.5; normal: 1.0). Se aplica de
  /// forma suave con un acumulador fraccionario para no dar saltos raros.
  final double coinMultiplier;
  double _coinFraction = 0;

  /// Si esta carrera arranca con el **tutorial guiado** de controles (solo en
  /// las pistas gratis y durante las primeras carreras). Lo decide la página.
  final bool showTutorial;

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

  /// Cuántas veces se ha retomado ya la carrera pagando en esta partida. Sube
  /// con cada [continueRun]; determina el coste de la siguiente continuación
  /// (ver `continueOfferFor` en `domain/entities/continue_cost.dart`). Efímero:
  /// se reinicia en cada [restart], no se persiste.
  int continuesUsed = 0;

  /// `true` mientras la partida está pausada tras un golpe mortal, esperando a
  /// que el jugador decida si paga por continuar o se rinde. Lo lee la UI.
  bool awaitingContinue = false;

  // Boss fight state — read by HUD
  GamePhase phase = GamePhase.running;

  /// Corazones máximos del jefe en esta partida. Normalmente [maxBossHearts];
  /// en modo de prueba baja a [TestMode.weakBossHearts] (jefe muy débil).
  final int bossMaxHearts;

  late int bossHearts = bossMaxHearts;

  /// Carga de embestida (0–1): sube con cada ataque esquivado; al llenarse
  /// el jugador embiste al jefe automáticamente.
  double dashCharge = 0.0;
  int bossBonusScore = 0;

  static const int maxBossHearts = 3;
  static const double _chargePerDodge = 0.2;
  // Recompensa por derrotar al jefe (el mayor logro de la partida). Antes eran
  // 500, pero eso inflaba la economía (una sola victoria compraba cualquier
  // cosmético y desbloqueaba el 2.º mundo). Con 200 la victoria sigue siendo un
  // premio claro, pero los cosméticos épicos cuestan ~2 victorias: hay meta.
  static const int victoryCoinBonus = 200;
  static const int _dashScoreBonus = 400;
  static const int _victoryScoreBonus = 2500;

  /// Metros a los que aparece el jefe. Por defecto es la longitud de pista
  /// del mundo (ver [trackMetersFor]), que es la misma que se anuncia en la
  /// pantalla de selección. En modo de prueba se acorta a
  /// [TestMode.shortTrackMeters]. Se puede forzar un valor para tests.
  final int bossTriggerMeters;

  BossComponent? _boss;
  double _attackTimer = 0;
  double _defeatTimer = 0;

  BossConfig get bossConfig => bossFor(worldId);

  // Power-up state
  bool _heroShieldActive = false;
  bool shieldPowerupActive = false;
  bool magnetActive = false;
  bool boostActive = false;
  double _shieldTimer = 0;
  double _magnetTimer = 0;
  double _boostTimer = 0;
  double _powerupTimer = 0;

  static const double _shieldPowerupDuration = 10.0;
  static const double _magnetDuration = 5.0;
  static const double _boostDuration = 4.0;
  static const double _boostSpeedBonus = 230.0;
  static const double _powerupSpawnInterval = 12.0;

  bool get hasShield => _heroShieldActive || shieldPowerupActive;

  /// Segundos restantes del escudo de power-up (0 si no está activo).
  double get shieldTimeLeft => shieldPowerupActive ? _shieldTimer : 0;

  /// Segundos restantes del imán (0 si no está activo).
  double get magnetTimeLeft => magnetActive ? _magnetTimer : 0;

  /// Segundos restantes del turbo (0 si no está activo).
  double get boostTimeLeft => boostActive ? _boostTimer : 0;

  /// Si el escudo innato del héroe sigue disponible (absorbe un golpe).
  bool get heroShieldReady => _heroShieldActive;

  /// Progreso del corredor a lo largo de la pista (0–1). La meta es la
  /// aparición del jefe; durante la pelea/victoria la barra queda llena.
  double get trackProgress => phase == GamePhase.running
      ? ((_distanceTraveled / 100) / bossTriggerMeters).clamp(0.0, 1.0)
      : 1.0;

  double _distanceTraveled = 0;
  double _speedTimer = 0;
  double _obstacleTimer = 0;
  double _coinTimer = 0;
  double _sceneryTimer = 0;

  static const double _scenerySpawnInterval = 0.55;

  /// Profundidad a la que un obstáculo cruza el plano del corredor. La colisión
  /// se decide en este único punto (no en una ventana), para que saltar o
  /// deslizarse justo cuando el obstáculo llega baste para librarlo.
  static const double _collisionDepth = 1.0;

  late PlayerComponent _player;
  final Random _rng = Random();

  // ── Tutorial guiado ─────────────────────────────────────────────────────────
  // Secuencia scripted al inicio de las pistas gratis: 4 obstáculos "de frente",
  // uno por control (izquierda, derecha, saltar, agacharse), cada uno con su
  // flecha. Fuerza la acción y nunca es letal (ver `_checkDepthCollisions`).
  bool _tutorialActive = false;
  int _tutorialStep = 0;
  bool _tutorialStepSpawned = false;
  double _tutorialGap = 0;
  final List<ObstacleComponent> _tutorialObstacles = [];
  TutorialHintComponent? _tutorialHint;

  static const int _tutorialStepCount = 4;
  static const double _tutorialStartDelay = 1.0; // respiro antes del 1.er paso
  static const double _tutorialStepGap = 0.7; // pausa entre pasos

  // ── Screen shake ────────────────────────────────────────────────────────────
  double _shakeTimer = 0;
  double _shakeDuration = 0;
  double _shakeMagnitude = 0;

  /// Dispara una sacudida de pantalla de [magnitude] píxeles durante
  /// [duration] s (decae hasta 0). Se aplica solo al mundo del juego, no al HUD.
  void shake({double magnitude = 8, double duration = 0.35}) {
    if (magnitude >= _shakeMagnitude || _shakeTimer <= 0) {
      _shakeMagnitude = magnitude;
      _shakeDuration = duration;
      _shakeTimer = duration;
    }
  }

  // ── Perspective system ──────────────────────────────────────────────────────
  // Pseudo-3D: objects spawn at the horizon (depth 0) and rush toward the
  // camera (depth 1 = player level).

  double get horizonY => size.y * 0.37;
  double get playerBaseY => size.y * 0.81;
  double get vanishX => size.x / 2;
  double get laneSep => size.x * 0.265;

  /// X positions of the 3 lanes at player level (bottom of screen).
  List<double> get laneXPositions => [
        vanishX - laneSep,
        vanishX,
        vanishX + laneSep,
      ];

  /// Screen position for a lane+depth combination.
  /// depth 0 = horizon, depth 1 = player level.
  Vector2 perspectivePos(int lane, double depth) {
    final lx = laneXPositions[lane];
    return Vector2(
      vanishX + (lx - vanishX) * depth,
      horizonY + (playerBaseY - horizonY) * depth,
    );
  }

  /// Scale factor for objects at a given depth (tiny at horizon, full at player).
  double perspectiveScale(double depth) =>
      (0.07 + 0.93 * depth).clamp(0.0, 1.5);

  /// Velocidad real de avance: la base más el empujón del turbo si está activo.
  double get _movementSpeed => speed + (boostActive ? _boostSpeedBonus : 0);

  /// Depth units per second at current speed.
  double get depthRate => 0.42 * (_movementSpeed / 220.0);

  double get playerX => _player.position.x + _player.size.x / 2;
  double get playerY => _player.position.y;

  /// Carril actual del jugador (0–2). Lo usan las monedas para saber si el imán
  /// puede atraerlas.
  int get playerLane => _player.currentLane;

  /// Centro aproximado del pecho del jugador en pantalla (ancla de efectos).
  Vector2 get playerCenter => Vector2(playerX, playerY + 30);

  static const String _overlayHud = 'hud';
  static const String _overlayGameOver = 'gameOver';
  static const String _overlayVictory = 'victory';
  static const String _overlayContinue = 'continue';

  /// Segundos de invulnerabilidad que se conceden al retomar la carrera, para
  /// que el jugador no muera de inmediato por el mismo obstáculo. Reutiliza el
  /// escudo de power-up como mecanismo de "absorber un golpe".
  static const double _reviveShieldDuration = 1.5;

  /// Zona de dificultad según la distancia. Los umbrales se mueven con la
  /// longitud de las pistas (`worldTrackMeters`) para que la progresión
  /// inicio → núcleo → caos caiga siempre en el mismo punto relativo: `inicio`
  /// cubre el primer ~40 % de la pista inicial y `caos` empieza pasado el largo
  /// de esa pista, así que solo lo ven los mundos avanzados. Valores previos:
  /// 500/1500 (pistas de 1200-2500 m) y 400/1200 (pistas de 960-2000 m).
  RunnerZone get currentZone {
    if (meters < 200) return RunnerZone.inicio;
    if (meters < 600) return RunnerZone.nucleo;
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
    this.onOfferContinue,
    this.coinMultiplier = 1.0,
    this.showTutorial = false,
    int? bossTriggerMeters,
  })  : bossTriggerMeters = bossTriggerMeters ??
            (TestMode.instance.isOn
                ? TestMode.shortTrackMeters
                : trackMetersFor(worldId)),
        bossMaxHearts = TestMode.instance.isOn
            ? TestMode.weakBossHearts
            : maxBossHearts;

  @override
  Future<void> onLoad() async {
    add(BackgroundComponent(worldId: worldId));
    _seedScenery();
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

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
    _tutorialActive = showTutorial;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTimer > 0) _shakeTimer -= dt;
    if (!isAlive) return;

    elapsedSeconds += dt;
    _distanceTraveled += _movementSpeed * dt;
    meters = (_distanceTraveled / 100).floor();
    _recomputeScore();

    // Speed ramp: +12 px/s every 5 s, capped at 900
    _speedTimer += dt;
    if (_speedTimer >= 5.0) {
      speed = (speed + 12).clamp(220, 900);
      _speedTimer = 0;
    }
    final effectiveSpeed = speed + _zoneSpeedBonus;

    if (phase == GamePhase.running) {
      if (_tutorialActive) {
        // Durante el tutorial guiado se sustituye el spawn aleatorio de
        // obstáculos/power-ups por la secuencia scripted (las monedas siguen).
        _advanceTutorial(dt);
      } else {
        // Obstacle spawning
        _obstacleTimer += dt;
        final spawnInterval = (2.2 - effectiveSpeed / 900).clamp(0.65, 2.2);
        if (_obstacleTimer >= spawnInterval) {
          _spawnObstacle();
          _obstacleTimer = 0;
        }

        // Power-up spawning
        _powerupTimer += dt;
        if (_powerupTimer >= _powerupSpawnInterval) {
          _spawnPowerup();
          _powerupTimer = 0;
        }
      }

      // Coin spawning
      _coinTimer += dt;
      if (_coinTimer >= 0.9) {
        _spawnCoin();
        _coinTimer = 0;
      }
    }

    // Trackside scenery spawning (el mundo sigue moviéndose durante la pelea)
    _sceneryTimer += dt;
    if (_sceneryTimer >= _scenerySpawnInterval) {
      _spawnScenery();
      _sceneryTimer = 0;
    }

    _updateBossPhase(dt);

    if (magnetActive) {
      _magnetTimer -= dt;
      if (_magnetTimer <= 0) magnetActive = false;
    }
    if (shieldPowerupActive) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) shieldPowerupActive = false;
    }
    if (boostActive) {
      _boostTimer -= dt;
      if (_boostTimer <= 0) boostActive = false;
    }

    _checkDepthCollisions();
    notifyListeners();
  }

  @override
  void render(Canvas canvas) {
    if (_shakeTimer > 0 && _shakeDuration > 0) {
      final decay = (_shakeTimer / _shakeDuration).clamp(0.0, 1.0);
      final amp = _shakeMagnitude * decay;
      final dx = (_rng.nextDouble() * 2 - 1) * amp;
      final dy = (_rng.nextDouble() * 2 - 1) * amp;
      // Sobre-escalado justo para cubrir el desplazamiento y no descubrir los
      // bordes del mundo durante la sacudida.
      final minDim = min(size.x, size.y);
      final overscale = minDim > 0 ? 1 + 2 * amp / minDim : 1.0;
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(overscale);
      canvas.translate(-size.x / 2, -size.y / 2);
      canvas.translate(dx, dy);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  void _recomputeScore() {
    score = meters + (coins * 5) + (obstacleStreak * 2);
    score = (score * multiplier).floor() + bossBonusScore;
  }

  // ── Boss fight ─────────────────────────────────────────────────────────────

  void _updateBossPhase(double dt) {
    switch (phase) {
      case GamePhase.running:
        if (meters >= bossTriggerMeters) _startBossIntro();
      case GamePhase.bossIntro:
        if (_boss?.introDone ?? false) {
          phase = GamePhase.bossFight;
          _attackTimer = 0;
        }
      case GamePhase.bossFight:
        _attackTimer += dt;
        if (_attackTimer >= _attackInterval) {
          _spawnBossAttack();
          _attackTimer = 0;
        }
        _checkBossAttacks();
      case GamePhase.bossDefeated:
        _defeatTimer += dt;
        if (_defeatTimer >= 1.5) _finishVictory();
      case GamePhase.victory:
        break;
    }
  }

  /// Intervalo entre ataques: se acorta cuando el jefe se enfurece.
  double get _attackInterval {
    final enrage = (bossMaxHearts - bossHearts).clamp(0, 2);
    return const [1.15, 0.90, 0.70][enrage];
  }

  void _startBossIntro() {
    phase = GamePhase.bossIntro;
    _boss = BossComponent();
    add(_boss!);
    AudioService.instance.playPowerup();
    add(ScorePopupComponent(
      '${bossConfig.emoji} ${L10n.tp('boss_intro', {
            'name': L10n.t('boss_$worldId'),
          })}',
      spawnPosition: Vector2(size.x / 2, horizonY + 30),
    ));
    notifyListeners();
  }

  void _spawnBossAttack() {
    final kind = bossConfig.attackForRoll(_rng.nextDouble());
    final lane = _rng.nextInt(3);
    final startDepth = _boss?.depth ?? BossComponent.fightDepth;
    _boss?.lunge(); // el jefe se lanza al atacar → pelea con más movimiento
    add(BossAttackComponent(kind: kind, lane: lane, depth: startDepth));

    // Enfurecido lanza a veces un segundo proyectil en otro carril
    if (bossHearts < bossMaxHearts &&
        kind == BossAttackKind.projectile &&
        _rng.nextDouble() < 0.35) {
      final otherLane = (lane + 1 + _rng.nextInt(2)) % 3;
      add(BossAttackComponent(
        kind: BossAttackKind.projectile,
        lane: otherLane,
        depth: startDepth,
      ));
    }
  }

  void _checkBossAttacks() {
    const pastPlayer = 1.16;
    final playerLane = _player.currentLane;

    // Mismo criterio que los obstáculos: el golpe se decide en un único punto
    // (cuando el ataque cruza el plano del jugador, depth ≈ 1.0), no en una
    // ventana ancha. Así saltar/deslizarse justo cuando llega el ataque basta
    // para librarlo. La carga de la embestida sigue disparándose al pasar de
    // largo (pastPlayer).
    for (final atk in children.whereType<BossAttackComponent>().toList()) {
      if (atk.collided) continue;

      if (!atk.resolved && atk.depth >= _collisionDepth) {
        atk.resolved = true;
        final jumping = _player.isJumping &&
            _player.jumpProgress > 0.10 &&
            _player.jumpProgress < 0.90;
        final bool hits = switch (atk.kind) {
          // Proyectil: golpea en su carril salvo que estés en el aire
          BossAttackKind.projectile => atk.lane == playerLane && !jumping,
          // Onda de choque: cubre toda la pista — hay que saltarla
          BossAttackKind.shockwave => !jumping,
          // Barrido alto: cubre toda la pista — hay que deslizarse
          BossAttackKind.sweep => !_player.isSliding,
        };
        if (hits) {
          atk.collided = true;
          hitObstacle();
          return;
        }
      }

      // Ataque evitado que ya pasó de largo: carga la embestida.
      if (!atk.dodged && atk.depth >= pastPlayer) {
        atk.dodged = true;
        onAttackDodged();
      }
    }
  }

  /// Un ataque pasó de largo sin golpear: carga la embestida.
  void onAttackDodged() {
    if (phase != GamePhase.bossFight || !isAlive) return;
    dashCharge = (dashCharge + _chargePerDodge).clamp(0.0, 1.0);
    if (dashCharge >= 1.0) {
      _performDash();
    }
    notifyListeners();
  }

  void _performDash() {
    dashCharge = 0;
    bossHearts = (bossHearts - 1).clamp(0, bossMaxHearts);
    bossBonusScore += _dashScoreBonus;
    _recomputeScore();
    _player.dash();
    _boss?.onDashHit();
    shake(magnitude: 7, duration: 0.28);
    AudioService.instance.playHit();
    add(ScorePopupComponent(
      '${L10n.t('dash_ready')} 💥',
      spawnPosition: Vector2(playerX, playerY - 30),
    ));
    // Limpia los ataques en vuelo para dar una pausa justa tras el golpe
    children
        .whereType<BossAttackComponent>()
        .toList()
        .forEach((a) => a.removeFromParent());

    if (bossHearts <= 0) {
      phase = GamePhase.bossDefeated;
      _defeatTimer = 0;
      final b = _boss;
      b?.startDefeat();
      if (b != null) {
        // Estallido de escombros en el centro del jefe.
        add(BossDefeatEffect(
          center: b.position + b.size / 2,
          primary: bossConfig.primary,
          secondary: bossConfig.secondary,
          baseSize: b.size.x,
        ));
      }
      add(ScorePopupComponent(
        '💥 ${L10n.t('defeated')} 💥',
        spawnPosition: Vector2(size.x / 2, horizonY + 60),
      ));
      shake(magnitude: 14, duration: 0.5); // sacudida fuerte del K.O.
      AudioService.instance.playPowerup();
    }
    notifyListeners();
  }

  void _finishVictory() {
    if (phase == GamePhase.victory) return;
    phase = GamePhase.victory;
    coins += victoryCoinBonus;
    bossBonusScore += _victoryScoreBonus;
    _recomputeScore();
    AudioService.instance.playChestOpen();
    overlays.remove(_overlayHud);
    overlays.add(_overlayVictory);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 400), () {
      pauseEngine();
      onRunComplete?.call(coins);
    });
  }

  // Manual collision detection based on depth proximity and lane matching.
  void _checkDepthCollisions() {
    const hitMin = 0.87;
    const hitMax = 1.11;
    const pastPlayer = 1.16;
    final playerLane = _player.currentLane;

    // Cada obstáculo se resuelve UNA sola vez, en el momento en que cruza el
    // plano del jugador (depth ≈ 1.0, donde el personaje está de verdad). Antes
    // se exigía que el jugador estuviera a salvo en *cada* frame de una ventana
    // ancha [0.87, 1.11]; como el obstáculo tarda más en cruzarla que lo que
    // dura el salto en el aire, era imposible librarlo aunque saltaras a tiempo
    // (y el golpe se veía con el obstáculo aún por delante del corredor).
    for (final obs in children.whereType<ObstacleComponent>().toList()) {
      if (obs.collided || obs.evaded) continue;
      if (obs.depth < _collisionDepth) continue; // aún no llega al corredor

      // Obstáculos del tutorial: nunca son letales (solo enseñan). Se retiran
      // sin muerte ni racha, hayan sido "esquivados" o no.
      if (obs.tutorial) {
        obs.evaded = true;
        continue;
      }

      // Otro carril: pasa de largo, cuenta como esquivado.
      if (obs.lane != playerLane) {
        obs.evaded = true;
        evadedObstacle();
        continue;
      }

      // Mismo carril: ¿lo está librando el jugador en este instante?
      // Las barreras colgantes (overhead) NO se pueden saltar: solo agacharse.
      final jumpingClear = _player.isJumping &&
          _player.jumpProgress > 0.10 &&
          _player.jumpProgress < 0.90 &&
          obs.type != ObstacleType.overhead;
      // Deslizarse pasa por debajo de las barreras (bajas o colgantes).
      final slidingClear = _player.isSliding &&
          (obs.type == ObstacleType.barrier ||
              obs.type == ObstacleType.overhead);
      // El turbo arrasa con cualquier obstáculo sin recibir daño.
      if (jumpingClear || slidingClear || boostActive) {
        obs.evaded = true;
        if (boostActive) obs.collided = true; // efecto de arrasado
        evadedObstacle();
        continue;
      }

      obs.collided = true;
      hitObstacle();
      return;
    }

    for (final coin in children.whereType<CoinComponent>().toList()) {
      // Las monedas atraídas por el imán vuelan solas y se recogen al llegar.
      if (coin.collected || coin.magnetized) continue;
      // Magnet grabs adjacent lanes too
      final inRange = coin.lane == playerLane ||
          (magnetActive && (coin.lane - playerLane).abs() == 1);
      if (inRange && coin.depth >= hitMin && coin.depth <= hitMax) {
        coin.collected = true;
        coin.removeFromParent();
        collectCoin();
      } else if (coin.depth >= pastPlayer) {
        coin.removeFromParent();
      }
    }

    for (final pu in children.whereType<PowerupComponent>().toList()) {
      if (pu.collected) continue;
      if (pu.lane == playerLane && pu.depth >= hitMin && pu.depth <= hitMax) {
        pu.collected = true;
        pu.removeFromParent();
        activatePowerup(pu.type);
      } else if (pu.depth >= pastPlayer) {
        pu.removeFromParent();
      }
    }
  }

  void _spawnObstacle() {
    final lane = _rng.nextInt(3);
    final roll = _rng.nextDouble();
    final type = roll < 0.20
        ? ObstacleType.barrier
        : roll < 0.35
            ? ObstacleType.spike
            : ObstacleType.block;
    add(ObstacleComponent(lane: lane, type: type));

    // Caos zone: 20% chance of a second obstacle in a different lane
    if (currentZone == RunnerZone.caos && _rng.nextDouble() < 0.20) {
      final otherLane = (lane + 1 + _rng.nextInt(2)) % 3;
      final t2 = _rng.nextDouble() < 0.3 ? ObstacleType.barrier : ObstacleType.block;
      add(ObstacleComponent(lane: otherLane, type: t2));
    }
  }

  void _spawnCoin() {
    add(CoinComponent(lane: _rng.nextInt(3)));
  }

  void _spawnPowerup() {
    final type = PowerupType.values[_rng.nextInt(PowerupType.values.length)];
    add(PowerupComponent(lane: _rng.nextInt(3), type: type));
  }

  void _spawnScenery({double startDepth = 0.0}) {
    add(SceneryComponent(
      side: _rng.nextBool() ? -1 : 1,
      variant: _rng.nextInt(3),
      lateral: 2.0 + _rng.nextDouble() * 1.1,
      startDepth: startDepth,
    ));
  }

  // Pre-populate both sides of the track so the world isn't empty on start.
  void _seedScenery() {
    for (double d = 0.12; d <= 1.0; d += 0.16) {
      _spawnScenery(startDepth: d);
      if (_rng.nextDouble() < 0.6) {
        _spawnScenery(startDepth: (d + 0.08).clamp(0.0, 1.0));
      }
    }
  }

  // ── Tutorial guiado ──────────────────────────────────────────────────────

  /// Conduce la secuencia scripted del tutorial: lanza cada paso, espera a que
  /// sus obstáculos salgan de escena y pasa al siguiente hasta terminar.
  void _advanceTutorial(double dt) {
    if (!_tutorialStepSpawned) {
      // Cuenta atrás antes de lanzar el paso actual (más larga la primera vez).
      _tutorialGap += dt;
      final delay = _tutorialStep == 0 ? _tutorialStartDelay : _tutorialStepGap;
      if (_tutorialGap >= delay) {
        _tutorialGap = 0;
        _spawnTutorialStep(_tutorialStep);
        _tutorialStepSpawned = true;
      }
      return;
    }

    // Paso lanzado: avanzar cuando todos sus obstáculos ya cruzaron al corredor.
    if (_tutorialObstacles.every((o) => !o.isMounted)) {
      _tutorialHint?.removeFromParent();
      _tutorialHint = null;
      _tutorialObstacles.clear();
      _tutorialStepSpawned = false;
      _tutorialStep++;
      if (_tutorialStep >= _tutorialStepCount) {
        _tutorialActive = false; // se reanuda la carrera normal
      }
    }
  }

  /// Lanza los obstáculos y la flecha de un paso del tutorial. El corredor
  /// arranca en el carril central (1). Cada paso **fuerza** su acción con un
  /// solo movimiento siguiendo el recorrido esperado (centro → izquierda →
  /// centro):
  /// - 0: muros en los carriles 1 y 2, hueco a la izquierda → mover ← (1→0).
  /// - 1: muros en los carriles 0 y 2, hueco en el centro → mover → (0→1).
  /// - 2: bloques de suelo en los 3 carriles (no se agachan) → saltar ↑.
  /// - 3: barreras colgantes en los 3 carriles (no se saltan) → agacharse ↓.
  void _spawnTutorialStep(int step) {
    // Un "muro" (bloque + colgante en el mismo carril) no se salta ni se agacha:
    // obliga a cambiar de carril.
    void wall(int lane) {
      _addTutorialObstacle(lane, ObstacleType.block);
      _addTutorialObstacle(lane, ObstacleType.overhead);
    }

    final HintDirection dir;
    switch (step) {
      case 0:
        wall(1);
        wall(2);
        dir = HintDirection.left;
      case 1:
        wall(0);
        wall(2);
        dir = HintDirection.right;
      case 2:
        for (var l = 0; l < 3; l++) {
          _addTutorialObstacle(l, ObstacleType.block);
        }
        dir = HintDirection.up;
      default:
        for (var l = 0; l < 3; l++) {
          _addTutorialObstacle(l, ObstacleType.overhead);
        }
        dir = HintDirection.down;
    }

    _tutorialHint = TutorialHintComponent(direction: dir);
    add(_tutorialHint!);
  }

  void _addTutorialObstacle(int lane, ObstacleType type) {
    final obs = ObstacleComponent(lane: lane, type: type, tutorial: true);
    _tutorialObstacles.add(obs);
    add(obs);
  }

  void _resetTutorial() {
    _tutorialActive = showTutorial;
    _tutorialStep = 0;
    _tutorialStepSpawned = false;
    _tutorialGap = 0;
    _tutorialObstacles.clear();
    _tutorialHint?.removeFromParent();
    _tutorialHint = null;
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void onSwipeUp() {
    _player.jump();
    if (isAlive) {
      jumpCount++;
      AudioService.instance.playJump();
    }
  }

  void onSwipeDown() {
    final started = _player.slide();
    if (started && isAlive) {
      AudioService.instance.playSlide();
      // Nube de polvo a los pies del corredor.
      add(SlideDustEffect(center: Vector2(playerX, playerBaseY - 6)));
    }
  }
  void onSwipeLeft() => _player.changeLane(-1, laneXPositions);
  void onSwipeRight() => _player.changeLane(1, laneXPositions);

  void onTap() {
    _player.jump();
    if (isAlive) {
      jumpCount++;
      AudioService.instance.playJump();
    }
  }

  /// Controles de teclado (escritorio/web): flechas para moverse, saltar y
  /// deslizarse. Se aceptan también WASD y espacio por comodidad.
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Solo la pulsación inicial: al mantener la tecla, Flutter emite
    // KeyRepeatEvent y encadenaría cambios de carril o saltos sin querer.
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (paused || !isAlive) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      onSwipeLeft();
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      onSwipeRight();
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.space) {
      onSwipeUp();
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      onSwipeDown();
    } else {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.handled;
  }

  // ── Game events ────────────────────────────────────────────────────────────

  void collectCoin() {
    final base = characterType == CharacterType.villain ? 2 : 1;
    // Multiplicador VIP aplicado con acumulador fraccionario (evita saltos).
    _coinFraction += base * coinMultiplier;
    final value = _coinFraction.floor();
    _coinFraction -= value;
    coins += value;
    AudioService.instance.playCoin();
    add(ScorePopupComponent(
      '+$value',
      spawnPosition: Vector2(playerX, playerY - 20),
    ));
    notifyListeners();
  }

  void activatePowerup(PowerupType type) {
    switch (type) {
      case PowerupType.shield:
        shieldPowerupActive = true;
        _shieldTimer = _shieldPowerupDuration;
        AudioService.instance.playShield();
      case PowerupType.magnet:
        magnetActive = true;
        _magnetTimer = _magnetDuration;
        AudioService.instance.playMagnet();
        // Estallido de succión naranja sobre el jugador + sacudida breve.
        add(MagnetPickupEffect(center: playerCenter));
        shake(magnitude: 5, duration: 0.2);
        add(ScorePopupComponent(
          '🧲 ${L10n.t('powerup_magnet')}',
          spawnPosition: Vector2(playerX, playerY - 30),
          color: const Color(0xFFFF6B35),
        ));
      case PowerupType.boost:
        boostActive = true;
        _boostTimer = _boostDuration;
        AudioService.instance.playPowerup();
        // Ráfaga de velocidad: líneas cinéticas en el jugador + sacudida.
        _player.dash();
        shake(magnitude: 6, duration: 0.25);
        add(ScorePopupComponent(
          '⚡ ${L10n.t('powerup_boost')}',
          spawnPosition: Vector2(playerX, playerY - 30),
          color: const Color(0xFFB266FF),
        ));
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

    if (hasShield) {
      _heroShieldActive = false;
      shieldPowerupActive = false;
      _shieldTimer = 0;
      // El escudo se rompe: fragmentos azules, sacudida y aviso en pantalla.
      add(ShieldBreakEffect(center: playerCenter));
      shake(magnitude: 9, duration: 0.32);
      add(ScorePopupComponent(
        '🛡️ ${L10n.t('shield_block')}',
        spawnPosition: Vector2(playerX, playerY - 30),
        color: const Color(0xFF00AAFF),
      ));
      AudioService.instance.playHit();
      onHit?.call();
      notifyListeners();
      return;
    }

    // Golpe mortal: en vez de ir directo a Game Over, se ofrece retomar la
    // carrera pagando (revive en el mismo punto). El jugador queda "caído" y la
    // partida pausada hasta que decida en el overlay de continuación.
    _enterContinueOffer();
  }

  /// Congela la partida tras un golpe mortal y muestra la oferta de continuar.
  /// No pone `isAlive = false` todavía (la carrera aún puede reanudarse), así
  /// que la lógica que mira `!isAlive` no la trata como terminada.
  void _enterContinueOffer() {
    _player.kill();
    AudioService.instance.playHit();
    onHit?.call();
    awaitingContinue = true;
    overlays.remove(_overlayHud);
    overlays.add(_overlayContinue);
    pauseEngine();
    onOfferContinue?.call();
    notifyListeners();
  }

  /// Retoma la carrera **en el mismo punto** tras pagar (revive). A diferencia
  /// de [restart], NO resetea la partida: se conservan velocidad, distancia,
  /// metros, score, fase y corazones del jefe. Limpia los obstáculos/ataques en
  /// pantalla y concede una invulnerabilidad breve para no morir al instante.
  void continueRun() {
    if (!awaitingContinue) return;
    continuesUsed++;
    awaitingContinue = false;

    _player.revive();

    // Retirar lo que hay en pantalla que podría matar de nuevo de inmediato.
    children.whereType<ObstacleComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<BossAttackComponent>().toList().forEach((c) => c.removeFromParent());

    // Invulnerabilidad breve reutilizando el escudo de power-up.
    shieldPowerupActive = true;
    _shieldTimer = _reviveShieldDuration;

    overlays.remove(_overlayContinue);
    overlays.add(_overlayHud);
    resumeEngine();
    notifyListeners();
  }

  /// El jugador renuncia a continuar: la carrera termina de verdad y salta al
  /// Game Over (contabilizando la partida vía [onRunComplete]).
  void declineContinue() {
    if (!awaitingContinue) return;
    awaitingContinue = false;
    _gameOver();
  }

  /// Flujo de fin de carrera real: marca la muerte, muestra el Game Over y
  /// notifica para que la partida se contabilice (RecordRun, misiones, score…).
  void _gameOver() {
    isAlive = false;
    overlays.remove(_overlayContinue);
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
    _coinFraction = 0;
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
    _sceneryTimer = 0;
    _heroShieldActive = characterType == CharacterType.hero;
    shieldPowerupActive = false;
    magnetActive = false;
    boostActive = false;
    _magnetTimer = 0;
    _shieldTimer = 0;
    _boostTimer = 0;
    isAlive = true;
    continuesUsed = 0;
    awaitingContinue = false;

    phase = GamePhase.running;
    bossHearts = bossMaxHearts;
    dashCharge = 0;
    bossBonusScore = 0;
    _attackTimer = 0;
    _defeatTimer = 0;
    _boss?.removeFromParent();
    _boss = null;

    children.whereType<ObstacleComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<CoinComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<PowerupComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<ScorePopupComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<SceneryComponent>().toList().forEach((c) => c.removeFromParent());
    children.whereType<BossAttackComponent>().toList().forEach((c) => c.removeFromParent());
    _seedScenery();
    _resetTutorial();

    _player.removeFromParent();
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

    overlays.remove(_overlayGameOver);
    overlays.remove(_overlayVictory);
    overlays.remove(_overlayContinue);
    overlays.add(_overlayHud);
    resumeEngine();
    notifyListeners();
  }
}

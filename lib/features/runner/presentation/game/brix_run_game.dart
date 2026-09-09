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
import 'hud_data.dart';

part 'systems/boss_fight_controller.dart';
part 'systems/spawn_system.dart';
part 'systems/tutorial_director.dart';
part 'systems/collision_system.dart';

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

  /// Instantánea discreta del estado del HUD. El HUD la escucha con un
  /// `ValueListenableBuilder`, así que solo se reconstruye cuando algún valor
  /// cambia de verdad (unas pocas veces por segundo), no en cada frame. Se
  /// publica al final de cada `update` con [_publishHud]; como `ValueNotifier`
  /// compara con `==`, publicar un valor igual no dispara reconstrucción.
  final ValueNotifier<HudData> hudData = ValueNotifier(HudData.initial);

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

  /// Controlador de la pelea contra el jefe (systems/boss_fight_controller.dart).
  late final BossFightController _bossFight = BossFightController(this);
  late final SpawnSystem _spawn = SpawnSystem(this);
  late final TutorialDirector _tutorial = TutorialDirector(this);
  late final CollisionSystem _collision = CollisionSystem(this);

  // ── Spawnables activos ───────────────────────────────────────────────────────
  // Listas tipadas de los componentes que la detección de colisión recorre CADA
  // frame. Antes cada frame hacía `children.whereType<X>().toList()` (recorre
  // todo el árbol + materializa una lista nueva) 3-4 veces. Los componentes se
  // registran/desregistran solos en su `onMount`/`onRemove`, así que las listas
  // están siempre al día sin importar cómo se añadieron (spawn normal o un test).
  final List<ObstacleComponent> activeObstacles = [];
  final List<CoinComponent> activeCoins = [];
  final List<PowerupComponent> activePowerups = [];
  final List<BossAttackComponent> activeBossAttacks = [];

  // ── Tutorial guiado ─────────────────────────────────────────────────────────
  // Secuencia scripted al inicio de las pistas gratis: 4 obstáculos "de frente",
  // uno por control (izquierda, derecha, saltar, agacharse), cada uno con su
  // flecha. Fuerza la acción y nunca es letal (ver CollisionSystem).
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
  // El corredor se sitúa bien abajo en la pista para dejar más recorrido
  // visible por delante (más tiempo de reacción ante los obstáculos). Como la
  // colisión se decide en `depth == 1.0` y `perspectivePos(*, 1.0).y` vale
  // exactamente `playerBaseY`, el punto donde los obstáculos golpean baja junto
  // con el jugador de forma automática. Aplica a todas las pistas.
  double get playerBaseY => size.y * 0.88;
  double get vanishX => size.x / 2;
  double get laneSep => size.x * 0.265;

  /// X del centro del carril [lane] (0–2) a la altura del corredor.
  ///
  /// Es la vía rápida: la consultan `perspectivePos` y el corredor en CADA
  /// frame, una vez por objeto vivo en la pista, así que no debe construir
  /// nada. [laneXPositions] sigue existiendo para quien necesite los tres
  /// valores juntos (tests, depuración), pero el bucle de juego usa esto.
  double laneX(int lane) => vanishX + (lane - 1) * laneSep;

  /// X positions of the 3 lanes at player level (bottom of screen).
  List<double> get laneXPositions => [laneX(0), laneX(1), laneX(2)];

  /// Screen position for a lane+depth combination.
  /// depth 0 = horizon, depth 1 = player level.
  Vector2 perspectivePos(int lane, double depth) {
    final lx = laneX(lane);
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
    _spawn.seedScenery();
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
        _tutorial.advance(dt);
      } else {
        // Obstacle spawning
        _obstacleTimer += dt;
        final spawnInterval = (2.2 - effectiveSpeed / 900).clamp(0.65, 2.2);
        if (_obstacleTimer >= spawnInterval) {
          _spawn.obstacle();
          _obstacleTimer = 0;
        }

        // Power-up spawning
        _powerupTimer += dt;
        if (_powerupTimer >= _powerupSpawnInterval) {
          _spawn.powerup();
          _powerupTimer = 0;
        }
      }

      // Coin spawning
      _coinTimer += dt;
      if (_coinTimer >= 0.9) {
        _spawn.coin();
        _coinTimer = 0;
      }
    }

    // Trackside scenery spawning (el mundo sigue moviéndose durante la pelea)
    _sceneryTimer += dt;
    if (_sceneryTimer >= _scenerySpawnInterval) {
      _spawn.scenery();
      _sceneryTimer = 0;
    }

    _bossFight.updatePhase(dt);

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

    _collision.check();
    _publishHud();
  }

  /// Publica la instantánea del HUD. Se llama cada frame, pero `ValueNotifier`
  /// solo notifica cuando el valor cambia (`==` sobre campos discretos), así que
  /// el HUD no se reconstruye salvo que algo cambie de verdad.
  void _publishHud() {
    hudData.value = HudData(
      coins: coins,
      streak: obstacleStreak,
      multiplier: multiplier,
      phase: phase,
      hasShield: hasShield,
      shieldActive: shieldPowerupActive,
      heroShieldReady: _heroShieldActive,
      shieldSeconds: shieldPowerupActive ? _shieldTimer.ceil() : 0,
      magnetActive: magnetActive,
      magnetSeconds: magnetActive ? _magnetTimer.ceil() : 0,
      boostActive: boostActive,
      boostSeconds: boostActive ? _boostTimer.ceil() : 0,
      dashChargePercent: (dashCharge * 100).round(),
      bossHearts: bossHearts,
      trackPermille: (trackProgress * 1000).round(),
    );
  }

  @override
  void dispose() {
    hudData.dispose();
    super.dispose();
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
  // La máquina de fases del jefe vive en BossFightController (systems/).

  /// Un ataque del jefe pasó de largo sin golpear: carga la embestida. La
  /// llama la UI/los tests; delega en el controlador de la pelea.
  void onAttackDodged() => _bossFight.onAttackDodged();




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
  /// Mueve al corredor un carril a la izquierda. Devuelve `true` solo si el
  /// carril cambia de verdad (en el borde de la pista no hay a dónde ir); la
  /// página lo usa para dar retorno háptico únicamente cuando hay movimiento.
  bool onSwipeLeft() => _player.changeLane(-1);

  /// Mueve al corredor un carril a la derecha. Ver [onSwipeLeft].
  bool onSwipeRight() => _player.changeLane(1);

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
    _publishHud();
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
    _publishHud();
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
    _publishHud();
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
      _publishHud();
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
    _publishHud();
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
    _publishHud();
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
    _spawn.seedScenery();
    _tutorial.reset();

    _player.removeFromParent();
    _player = PlayerComponent(appearance: appearance, initialLane: 1);
    add(_player);

    overlays.remove(_overlayGameOver);
    overlays.remove(_overlayVictory);
    overlays.remove(_overlayContinue);
    overlays.add(_overlayHud);
    resumeEngine();
    _publishHud();
  }
}

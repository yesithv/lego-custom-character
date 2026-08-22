part of '../brix_run_game.dart';

/// Máquina de estados de la pelea contra el jefe, extraída de [BrixRunGame].
///
/// Es un colaborador real (no un mixin ni una extensión): [BrixRunGame] delega
/// aquí `update` de la fase de jefe y el evento de "ataque esquivado". Vive en
/// un `part` de la misma librería, así que puede leer y escribir el estado del
/// juego a través de la referencia [g] sin exponerlo todo en público (la API
/// pública del juego —`phase`, `bossHearts`, `dashCharge`…— no cambia).
class BossFightController {
  final BrixRunGame g;
  BossFightController(this.g);

  /// Avanza la máquina de fases: running → intro → pelea → derrota → victoria.
  void updatePhase(double dt) {
    switch (g.phase) {
      case GamePhase.running:
        if (g.meters >= g.bossTriggerMeters) _startBossIntro();
      case GamePhase.bossIntro:
        if (g._boss?.introDone ?? false) {
          g.phase = GamePhase.bossFight;
          g._attackTimer = 0;
        }
      case GamePhase.bossFight:
        g._attackTimer += dt;
        if (g._attackTimer >= _attackInterval) {
          _spawnBossAttack();
          g._attackTimer = 0;
        }
        _checkBossAttacks();
      case GamePhase.bossDefeated:
        g._defeatTimer += dt;
        if (g._defeatTimer >= 1.5) _finishVictory();
      case GamePhase.victory:
        break;
    }
  }

  /// Intervalo entre ataques: se acorta cuando el jefe se enfurece.
  double get _attackInterval {
    final enrage = (g.bossMaxHearts - g.bossHearts).clamp(0, 2);
    return const [1.15, 0.90, 0.70][enrage];
  }

  void _startBossIntro() {
    g.phase = GamePhase.bossIntro;
    g._boss = BossComponent();
    g.add(g._boss!);
    AudioService.instance.playPowerup();
    g.add(ScorePopupComponent(
      '${g.bossConfig.emoji} ${L10n.tp('boss_intro', {
            'name': L10n.t('boss_${g.worldId}'),
          })}',
      spawnPosition: Vector2(g.size.x / 2, g.horizonY + 30),
    ));
    g._publishHud();
  }

  void _spawnBossAttack() {
    final kind = g.bossConfig.attackForRoll(g._rng.nextDouble());
    final lane = g._rng.nextInt(3);
    final startDepth = g._boss?.depth ?? BossComponent.fightDepth;
    g._boss?.lunge(); // el jefe se lanza al atacar → pelea con más movimiento
    g.add(BossAttackComponent(kind: kind, lane: lane, depth: startDepth));

    // Enfurecido lanza a veces un segundo proyectil en otro carril
    if (g.bossHearts < g.bossMaxHearts &&
        kind == BossAttackKind.projectile &&
        g._rng.nextDouble() < 0.35) {
      final otherLane = (lane + 1 + g._rng.nextInt(2)) % 3;
      g.add(BossAttackComponent(
        kind: BossAttackKind.projectile,
        lane: otherLane,
        depth: startDepth,
      ));
    }
  }

  void _checkBossAttacks() {
    const pastPlayer = 1.16;
    final playerLane = g._player.currentLane;

    // Mismo criterio que los obstáculos: el golpe se decide en un único punto
    // (cuando el ataque cruza el plano del jugador, depth ≈ 1.0), no en una
    // ventana ancha. Así saltar/deslizarse justo cuando llega el ataque basta
    // para librarlo. La carga de la embestida sigue disparándose al pasar de
    // largo (pastPlayer).
    for (final atk in g.activeBossAttacks) {
      if (atk.collided) continue;

      if (!atk.resolved && atk.depth >= BrixRunGame._collisionDepth) {
        atk.resolved = true;
        final jumping = g._player.isJumping &&
            g._player.jumpProgress > 0.10 &&
            g._player.jumpProgress < 0.90;
        final bool hits = switch (atk.kind) {
          // Proyectil: golpea en su carril salvo que estés en el aire
          BossAttackKind.projectile => atk.lane == playerLane && !jumping,
          // Onda de choque: cubre toda la pista — hay que saltarla
          BossAttackKind.shockwave => !jumping,
          // Barrido alto: cubre toda la pista — hay que deslizarse
          BossAttackKind.sweep => !g._player.isSliding,
        };
        if (hits) {
          atk.collided = true;
          g.hitObstacle();
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
    if (g.phase != GamePhase.bossFight || !g.isAlive) return;
    g.dashCharge = (g.dashCharge + BrixRunGame._chargePerDodge).clamp(0.0, 1.0);
    if (g.dashCharge >= 1.0) {
      _performDash();
    }
    g._publishHud();
  }

  void _performDash() {
    g.dashCharge = 0;
    g.bossHearts = (g.bossHearts - 1).clamp(0, g.bossMaxHearts);
    g.bossBonusScore += BrixRunGame._dashScoreBonus;
    g._recomputeScore();
    g._player.dash();
    g._boss?.onDashHit();
    g.shake(magnitude: 7, duration: 0.28);
    AudioService.instance.playHit();
    g.add(ScorePopupComponent(
      '${L10n.t('dash_ready')} 💥',
      spawnPosition: Vector2(g.playerX, g.playerY - 30),
    ));
    // Limpia los ataques en vuelo para dar una pausa justa tras el golpe
    g.activeBossAttacks.toList().forEach((a) => a.removeFromParent());

    if (g.bossHearts <= 0) {
      g.phase = GamePhase.bossDefeated;
      g._defeatTimer = 0;
      final b = g._boss;
      b?.startDefeat();
      if (b != null) {
        // Estallido de escombros en el centro del jefe.
        g.add(BossDefeatEffect(
          center: b.position + b.size / 2,
          primary: g.bossConfig.primary,
          secondary: g.bossConfig.secondary,
          baseSize: b.size.x,
        ));
      }
      g.add(ScorePopupComponent(
        '💥 ${L10n.t('defeated')} 💥',
        spawnPosition: Vector2(g.size.x / 2, g.horizonY + 60),
      ));
      g.shake(magnitude: 14, duration: 0.5); // sacudida fuerte del K.O.
      AudioService.instance.playPowerup();
    }
    g._publishHud();
  }

  void _finishVictory() {
    if (g.phase == GamePhase.victory) return;
    g.phase = GamePhase.victory;
    g.coins += BrixRunGame.victoryCoinBonus;
    g.bossBonusScore += BrixRunGame._victoryScoreBonus;
    g._recomputeScore();
    AudioService.instance.playChestOpen();
    g.overlays.remove(BrixRunGame._overlayHud);
    g.overlays.add(BrixRunGame._overlayVictory);
    g._publishHud();
    Future.delayed(const Duration(milliseconds: 400), () {
      g.pauseEngine();
      g.onRunComplete?.call(g.coins);
    });
  }
}

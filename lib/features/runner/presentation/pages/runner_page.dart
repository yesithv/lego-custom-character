import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/orientation/portrait_lock.dart';
import '../../../../core/services/audio_service.dart';
import '../../../analytics/domain/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../character_editor/presentation/widgets/character_preview.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../../economy/presentation/widgets/chest_opening_widget.dart';
import '../../../missions/domain/entities/mission.dart';
import '../../../missions/presentation/bloc/mission_bloc.dart';
import '../../../missions/presentation/bloc/mission_event.dart';
import '../../../missions/presentation/bloc/mission_state.dart';
import '../../../missions/presentation/widgets/mission_card.dart';
import '../../../monetization/domain/entities/vip_perks.dart';
import '../../../monetization/domain/repositories/store_repository.dart';
import '../../../ranking/domain/entities/score.dart';
import '../../../ranking/presentation/bloc/ranking_bloc.dart';
import '../../../ranking/presentation/bloc/ranking_event.dart';
import '../../../ranking/presentation/bloc/ranking_state.dart';
import '../game/brix_run_game.dart';
import 'world_selection_page.dart';

class RunnerPage extends StatefulWidget {
  final Character character;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  /// Pista de fondo elegida para esta partida (relativa a `assets/audio/`).
  /// `null` si el jugador desactivó la música antes de correr.
  final String? musicAsset;

  const RunnerPage({
    super.key,
    required this.character,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    this.musicAsset,
  });

  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage> {
  late final BrixRunGame _game;
  static const double _swipeThreshold = 40.0;
  bool _showChest = false;
  bool _isPaused = false;

  /// Si ya se abrió el cofre de esta partida. Evita reclamarlo dos veces
  /// (el cofre otorga la recompensa al mostrarse) y, en la victoria, cambia
  /// el botón "Reclamar cofre" por las acciones de navegación.
  bool _chestClaimed = false;

  @override
  void initState() {
    super.initState();
    // Los VIP ganan monedas con un multiplicador (beneficio de suscripción).
    final vip = sl<StoreRepository>().entitlementsSync().subscriptionActive;
    _game = BrixRunGame(
      appearance: widget.character.appearance,
      characterType: widget.character.type,
      worldId: widget.worldId,
      onRunComplete: _onRunComplete,
      onHit: _onHit,
      coinMultiplier: vip ? VipPerks.coinMultiplier : 1.0,
    );
    sl<AnalyticsService>()
        .track(AnalyticsEvents.runStart, params: {'world': widget.worldId});
    // Pre-load ranking for this world to show personal best in game over
    context.read<RankingBloc>().add(LoadRanking(widget.worldId));
    // Música de fondo temática del mundo elegida antes de correr (en bucle).
    _startMusic();
    // En la web móvil el navegador puede quedarse en horizontal: mientras el
    // aviso de "gira tu teléfono" tapa la partida, el motor se pausa para que
    // el jugador no muera a ciegas.
    landscapeBlocked.addListener(_onLandscapeBlockedChanged);
  }

  /// Arranca la música de fondo del mundo (en bucle) si el jugador la dejó
  /// activada antes de correr; si la desactivó, garantiza silencio de música.
  /// Se usa al entrar y al reiniciar la partida.
  void _startMusic() {
    final asset = widget.musicAsset;
    if (asset != null) {
      AudioService.instance.playMusic(asset);
    } else {
      AudioService.instance.stopMusic();
    }
  }

  void _onLandscapeBlockedChanged() {
    if (landscapeBlocked.value) {
      _game.pauseEngine();
      AudioService.instance.pauseMusic();
      return;
    }
    // Al volver a vertical solo se reanuda si la partida sigue viva y el
    // jugador no la había pausado a mano.
    final runOver = !_game.isAlive || _game.phase == GamePhase.victory;
    if (!_isPaused && !runOver) {
      _game.resumeEngine();
      AudioService.instance.resumeMusic();
    }
  }

  /// Paga las recompensas de las misiones recién completadas: monedas (que hasta
  /// ahora se mostraban pero NUNCA se acreditaban) y un pequeño faucet de gemas.
  void _rewardCompletedMissions(List<Mission> completed) {
    if (completed.isEmpty) return;
    final coins = completed.fold<int>(0, (sum, m) => sum + m.rewardCoins);
    if (coins > 0) {
      context.read<WalletBloc>().add(EarnCoinsEvent(coins));
    }
    final gems = completed.length * kGemsPerCompletedMission;
    if (gems > 0) {
      // Fire-and-forget: incrementa el saldo de gemas (entitlements) en local.
      sl<StoreRepository>().grantGems(gems);
    }
  }

  void _onRunComplete(int coins) {
    // La carrera terminó (derrota o victoria): corta la música de fondo de
    // inmediato para que no siga sonando bajo la pantalla de fin de partida.
    AudioService.instance.stopMusic();
    context.read<WalletBloc>().add(RecordRunEvent(coins));
    context.read<MissionBloc>().add(AdvanceMissionsEvent(MissionRunData(
      coins: _game.coins,
      meters: _game.meters,
      evadedObstacles: _game.maxObstacleStreak,
      seconds: _game.elapsedSeconds.floor(),
      jumps: _game.jumpCount,
    )));
    context.read<RankingBloc>().add(SubmitScoreEvent(Score(
      id: const Uuid().v4(),
      characterName: widget.character.name,
      worldId: widget.worldId,
      score: _game.score,
      meters: _game.meters,
      coins: _game.coins,
      createdAt: DateTime.now(),
    )));
    // En derrota el cofre se abre automáticamente; en victoria se reclama
    // con el botón "Reclamar cofre" de la pantalla de victoria.
    final isVictory = _game.phase == GamePhase.victory;
    sl<AnalyticsService>().track(
      isVictory ? AnalyticsEvents.runVictory : AnalyticsEvents.runDeath,
      params: {
        'world': widget.worldId,
        'meters': _game.meters,
        'coins': _game.coins,
      },
    );
    setState(() {
      _showChest = !isVictory;
      _isPaused = false;
    });
  }

  void _onHit() {
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    landscapeBlocked.removeListener(_onLandscapeBlockedChanged);
    AudioService.instance.stopMusic();
    _game.dispose();
    super.dispose();
  }

  void _handleSwipe(DragEndDetails d) {
    if (_isPaused) return;
    final v = d.velocity.pixelsPerSecond;
    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx > _swipeThreshold) _game.onSwipeRight();
      else if (v.dx < -_swipeThreshold) _game.onSwipeLeft();
    } else {
      if (v.dy < -_swipeThreshold) _game.onSwipeUp();
      else if (v.dy > _swipeThreshold) _game.onSwipeDown();
    }
  }

  void _handleTap() {
    if (_isPaused) return;
    _game.onTap();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
        // Al pausar también se calla la música de fondo.
        AudioService.instance.pauseMusic();
      } else {
        _game.resumeEngine();
        AudioService.instance.resumeMusic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Paga las misiones recién completadas (monedas + gemas) una sola vez
          // por carrera: se dispara cuando `justCompleted` pasa a no vacío.
          BlocListener<MissionBloc, MissionState>(
            listenWhen: (p, c) =>
                c.justCompleted.isNotEmpty &&
                p.justCompleted != c.justCompleted,
            listener: (context, missionState) =>
                _rewardCompletedMissions(missionState.justCompleted),
            child: const SizedBox.shrink(),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanEnd: _handleSwipe,
            onTap: _handleTap,
            child: GameWidget<BrixRunGame>(
              game: _game,
              overlayBuilderMap: {
                'hud': (context, game) => _HudOverlay(
                      game: game,
                      onTogglePause: _togglePause,
                    ),
                'gameOver': (context, game) =>
                    BlocBuilder<MissionBloc, MissionState>(
                      builder: (context, missionState) => _GameOverOverlay(
                        game: game,
                        character: widget.character,
                        completedMissions: missionState.justCompleted,
                        worldId: widget.worldId,
                        worldName: widget.worldName,
                        worldEmoji: widget.worldEmoji,
                        worldColor: widget.worldColor,
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _chestClaimed = false;
                            _isPaused = false;
                          });
                          game.restart();
                          // La música se cortó al terminar la carrera anterior:
                          // vuelve a arrancarla para la nueva.
                          _startMusic();
                        },
                        onExit: () => context.goNamed('worlds'),
                      ),
                    ),
                'victory': (context, game) =>
                    BlocBuilder<MissionBloc, MissionState>(
                      builder: (context, missionState) => _VictoryOverlay(
                        game: game,
                        completedMissions: missionState.justCompleted,
                        worldId: widget.worldId,
                        worldName: widget.worldName,
                        worldEmoji: widget.worldEmoji,
                        worldColor: widget.worldColor,
                        chestClaimed: _chestClaimed,
                        // Guarda: el cofre entrega la recompensa al mostrarse,
                        // así que nunca debe abrirse dos veces.
                        onClaimChest: () {
                          if (_chestClaimed || _showChest) return;
                          setState(() => _showChest = true);
                        },
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _chestClaimed = false;
                            _isPaused = false;
                          });
                          game.restart();
                          // La música se cortó al terminar la carrera anterior:
                          // vuelve a arrancarla para la nueva.
                          _startMusic();
                        },
                        onExit: () => context.goNamed('worlds'),
                      ),
                    ),
              },
            ),
          ),

          // Pause overlay
          if (_isPaused)
            _PauseOverlay(
              onResume: _togglePause,
              onExit: () => context.goNamed('worlds'),
            ),

          // Chest overlay — shown after game over
          if (_showChest)
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) => ChestOpeningWidget(
                isVip: state.wallet.earnVipChest,
                onDismiss: () => setState(() {
                  _showChest = false;
                  _chestClaimed = true;
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── HUD Overlay ───────────────────────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final BrixRunGame game;
  final VoidCallback onTogglePause;
  const _HudOverlay({required this.game, required this.onTogglePause});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final musicMuted = AudioService.instance.musicMuted;

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Barra vertical de progreso en la pista (lado derecho)
          Positioned(
            right: 22,
            top: 155,
            bottom: 155,
            child: IgnorePointer(
              child: _TrackProgressBar(progress: g.trackProgress),
            ),
          ),

          // Dock de power-ups (lado izquierdo, algo por debajo del centro)
          Align(
            alignment: const Alignment(-1.0, 0.3),
            child: Padding(
              // Misma separación del borde que la barra de progreso de la
              // derecha (right: 22), para que ambos queden simétricos.
              padding: const EdgeInsets.only(left: 22),
              child: IgnorePointer(child: _PowerupDock(game: g)),
            ),
          ),

          // HUD superior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sin contador de metros: el avance por la pista ya lo cuenta la
                // barra vertical de progreso de la derecha. Los metros finales
                // se ven en el resumen de la carrera.

                // Fila 1: pausa | monedas + combo + multiplicador | música
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bajado al mismo nivel que el contador de monedas (que
                    // usa top:16) para que pausa, monedas y música se alineen.
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _SquareChip(
                        icon: Icons.pause_rounded,
                        onTap: widget.onTogglePause,
                      ),
                    ),
                    const Spacer(),
                    // Bajadas respecto a los botones de mando para despejar
                    // la parte alta de la pantalla.
                    IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _CoinCombo(
                              coins: g.coins,
                              streak: g.obstacleStreak,
                            ),
                            const SizedBox(height: 2),
                            _MultiplierRing(
                              streak: g.obstacleStreak,
                              mult: g.multiplier,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Silencia SOLO la música de fondo; los efectos (monedas,
                    // escudo, imán, saltos…) siguen sonando. Por eso usa el
                    // icono de nota musical.
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _SquareChip(
                        icon: musicMuted
                            ? Icons.music_off_rounded
                            : Icons.music_note_rounded,
                        onTap: () => setState(
                            () => AudioService.instance.toggleMusicMute()),
                      ),
                    ),
                  ],
                ),

                if (g.phase != GamePhase.running) ...[
                  const SizedBox(height: 6),
                  IgnorePointer(child: _BossBar(game: g)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Boss bar (nombre + corazones + carga de embestida) ───────────────────────

class _BossBar extends StatelessWidget {
  final BrixRunGame game;
  const _BossBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final cfg = game.bossConfig;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.shade400, width: 1.5),
          ),
          child: Row(
            children: [
              Text(cfg.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  game.phase == GamePhase.bossIntro
                      ? context.l10n.trp('boss_approaching',
                          {'name': context.l10n.bossName(game.worldId)})
                      : context.l10n.bossName(game.worldId),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              // Corazones del jefe
              ...List.generate(game.bossMaxHearts, (i) {
                final alive = i < game.bossHearts;
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    alive ? '❤️' : '🖤',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Barra de carga de la embestida
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: game.dashCharge.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade700,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '⚡ ${context.l10n.tr('dash_hint')}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Botón cuadrado redondeado del HUD (pausa, silenciar música).
class _SquareChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF152238).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}

/// Contador de monedas (píldora dorada) con badge verde de combo debajo.
class _CoinCombo extends StatelessWidget {
  final int coins;
  final int streak;
  const _CoinCombo({required this.coins, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE24D), Color(0xFFFFC400)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniCoin(),
              const SizedBox(width: 7),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Color(0xFF3D2C00),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        if (streak > 0)
          Transform.translate(
            offset: const Offset(0, -5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '+$streak ${context.l10n.tr('combo')}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _miniCoin() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF0A0), Color(0xFFFFB300), Color(0xFFD98E00)],
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF9C6B00).withValues(alpha: 0.7),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Multiplicador con anillo de progreso hacia el siguiente nivel de combo.
class _MultiplierRing extends StatelessWidget {
  final int streak;
  final double mult;
  const _MultiplierRing({required this.streak, required this.mult});

  /// Progreso del anillo hacia el próximo multiplicador:
  /// x2 a 10 esquives, x3 a 25, x5 a 50 (lleno al máximo).
  double get _ringProgress {
    if (streak >= 50) return 1.0;
    if (streak >= 25) return (streak - 25) / 25;
    if (streak >= 10) return (streak - 10) / 15;
    return streak / 10;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(44, 44),
            painter: _RingPainter(progress: _ringProgress),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF152238).withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'x${mult.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white24,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFF9800),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// Barra vertical (borde derecho) con el avance del corredor en la pista.
/// Se llena de abajo hacia arriba; la meta 🏁 es la aparición del jefe.
class _TrackProgressBar extends StatelessWidget {
  final double progress;
  const _TrackProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🏁', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            width: 13,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFFFFC400), Color(0xFFFFE24D)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dock inferior con el estado de los power-ups: escudo, imán y embestida.
class _PowerupDock extends StatelessWidget {
  final BrixRunGame game;
  const _PowerupDock({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final inBossFight = g.phase == GamePhase.bossFight;

    // Etiqueta del escudo: segundos del power-up, "x1" si es el escudo
    // innato del héroe, o inactivo.
    final String shieldLabel;
    if (g.shieldPowerupActive) {
      shieldLabel = '${g.shieldTimeLeft.ceil()}s';
    } else if (g.heroShieldReady) {
      shieldLabel = 'x1';
    } else {
      shieldLabel = '—';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF152238).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PowerSlot(
            emoji: '🛡️',
            color: const Color(0xFF2E9BFF),
            active: g.hasShield,
            label: shieldLabel,
          ),
          const SizedBox(height: 12),
          _PowerSlot(
            emoji: '🧲',
            color: const Color(0xFFFF6B35),
            active: g.magnetActive,
            label: g.magnetActive ? '${g.magnetTimeLeft.ceil()}s' : '—',
          ),
          const SizedBox(height: 12),
          _PowerSlot(
            emoji: '⚡',
            color: const Color(0xFFB266FF),
            active: inBossFight ? g.dashCharge > 0 : g.boostActive,
            label: inBossFight
                ? '${(g.dashCharge * 100).round()}%'
                : (g.boostActive ? '${g.boostTimeLeft.ceil()}s' : '—'),
          ),
        ],
      ),
    );
  }
}

class _PowerSlot extends StatelessWidget {
  final String emoji;
  final Color color;
  final bool active;
  final String label;

  const _PowerSlot({
    required this.emoji,
    required this.color,
    required this.active,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active ? color : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Opacity(
              opacity: active ? 1.0 : 0.35,
              child: Text(emoji, style: const TextStyle(fontSize: 19)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  final RunnerZone zone;
  const _ZoneBadge({required this.zone});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (zone) {
      RunnerZone.inicio =>
        (context.l10n.tr('zone_start'), const Color(0xFF43A047)),
      RunnerZone.nucleo =>
        (context.l10n.tr('zone_core'), const Color(0xFFF57C00)),
      RunnerZone.caos =>
        (context.l10n.tr('zone_chaos'), const Color(0xFFE53935)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Pause Overlay ──────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;
  const _PauseOverlay({required this.onResume, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResume,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⏸ ${context.l10n.tr('pause')}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        context.l10n.tr('resume'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onExit,
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(context.l10n.tr('exit_to_map')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game Over Overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final BrixRunGame game;
  final Character character;
  final List<Mission> completedMissions;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.game,
    required this.character,
    required this.completedMissions,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ocupa toda la pantalla con un degradado del color del mundo apagado
      // hacia negro: hermano de la pantalla de victoria pero en tono sombrío.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(worldColor, Colors.black, 0.35)!,
            Color.lerp(worldColor, Colors.black, 0.64)!,
            const Color(0xFF0A0F1A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.tr('keep_creating'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tr('almost_podium'),
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 18),

                    // Héroe: personaje que corrió la carrera + marcador.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _CharacterPedestal(
                            character: character,
                            worldColor: worldColor,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WideStatBox(
                                  icon: '⭐',
                                  label: context.l10n.tr('stat_points'),
                                  value: _fmtNum(game.score),
                                  valueColor: const Color(0xFFFFD700),
                                ),
                                const SizedBox(height: 10),
                                _WideStatBox(
                                  icon: '🪙',
                                  label: context.l10n.tr('stat_coins'),
                                  value: _fmtNum(game.coins),
                                ),
                                const SizedBox(height: 10),
                                _WideStatBox(
                                  icon: '📏',
                                  label: context.l10n.tr('stat_meters'),
                                  value: _fmtNum(game.meters),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Zona alcanzada + récord personal.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ZoneBadge(zone: game.currentZone),
                        BlocBuilder<RankingBloc, RankingState>(
                          builder: (context, rankingState) {
                            if (rankingState.scores.isEmpty ||
                                rankingState.worldId != worldId) {
                              return const SizedBox.shrink();
                            }
                            final pb = rankingState.scores.first.score;
                            final isNew = game.score >= pb;
                            return Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: isNew
                                  ? Text(
                                      '🎉 ${context.l10n.tr('new_record')}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    )
                                  : Text(
                                      '🥇 ${context.l10n.trp('record_pts', {
                                            'pb': pb
                                          })}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Progreso hacia desbloquear el siguiente mundo.
                    _NextWorldProgress(worldColor: worldColor),

                    if (completedMissions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🎯 ${context.l10n.tr('missions_completed')}',
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...completedMissions
                          .map((m) => MissionCard(mission: m, compact: true)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Acciones fijas abajo: una sola fila estilo Subway Surfers
            // (cuadros compactos de icono + botón grande de "Play again").
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
              child: _RunEndActions(
                worldId: worldId,
                worldName: worldName,
                worldEmoji: worldEmoji,
                worldColor: worldColor,
                onRestart: onRestart,
                onChooseWorld: onExit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Personaje que corrió la carrera sobre un pedestal con foco, con su nombre.
class _CharacterPedestal extends StatelessWidget {
  final Character character;
  final Color worldColor;

  const _CharacterPedestal({required this.character, required this.worldColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 0.9,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: CharacterPreview(
            appearance: character.appearance,
            size: 92,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 128),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Color.lerp(worldColor, Colors.white, 0.16)!,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            character.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Caja de estadística horizontal (icono + etiqueta a la izquierda, valor a la
/// derecha) para el marcador junto al personaje.
class _WideStatBox extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color valueColor;

  const _WideStatBox({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso hacia el siguiente mundo bloqueado (según las monedas
/// totales ganadas). Motiva a seguir jugando sin presionar a comprar.
class _NextWorldProgress extends StatelessWidget {
  final Color worldColor;

  const _NextWorldProgress({required this.worldColor});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final earned = state.wallet.totalCoinsEarned;
        final locked = worlds
            .where((w) =>
                w.status == WorldStatus.locked && earned < w.unlockCost)
            .toList()
          ..sort((a, b) => a.unlockCost.compareTo(b.unlockCost));

        if (locked.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              '🌍 ${context.l10n.tr('all_worlds_unlocked')}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
        }

        final next = locked.first;
        final remaining = (next.unlockCost - earned).clamp(0, next.unlockCost);
        final progress =
            (earned / next.unlockCost).clamp(0.0, 1.0).toDouble();
        final accent = Color.lerp(next.color, Colors.white, 0.35)!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${next.emoji} ${context.l10n.trp('next_world_progress', {
                            'name': context.l10n.worldName(next.id),
                          })}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.trp('coins_to_next_world', {
                      'remaining': _fmtNum(remaining),
                    }),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, next.color],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enlace discreto a la Tienda que aparece al terminar una carrera (victoria o
/// derrota): aprovecha el pico de interés para acercar la compra sin presionar.
class _ShopNudge extends StatelessWidget {
  const _ShopNudge();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.pushNamed('store'),
      child: Text(
        '🛍️  ${context.l10n.tr('run_shop_cta')}',
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Victory Overlay ───────────────────────────────────────────────────────────

class _VictoryOverlay extends StatelessWidget {
  final BrixRunGame game;
  final List<Mission> completedMissions;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;
  final bool chestClaimed;
  final VoidCallback onClaimChest;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _VictoryOverlay({
    required this.game,
    required this.completedMissions,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    required this.chestClaimed,
    required this.onClaimChest,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ocupa toda la pantalla con el color del mundo (no es una tarjeta).
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(worldColor, Colors.white, 0.10)!,
            worldColor,
            Color.lerp(worldColor, Colors.black, 0.55)!,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const Text('🏆', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tr('victory'),
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.trp('world_completed',
                          {'emoji': worldEmoji, 'name': worldName}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Estadísticas de la carrera
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            icon: '🪙',
                            value: _fmtNum(game.coins),
                            label: context.l10n.tr('stat_coins'),
                            valueColor: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            icon: '📏',
                            value: _fmtNum(game.meters),
                            label: context.l10n.tr('stat_meters'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatBox(
                            icon: '⭐',
                            value: _fmtNum(game.score),
                            label: context.l10n.tr('stat_points'),
                          ),
                        ),
                      ],
                    ),

                    if (completedMissions.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '🎯  ${context.l10n.tr('missions_completed')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...completedMissions
                          .map((m) => _CompletedMissionCard(mission: m)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Acciones: primero reclamar el cofre; después, navegación.
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 6, 26, 18),
              child: chestClaimed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GoldActionButton(
                          icon: Icons.replay_rounded,
                          label: context.l10n.tr('play_again'),
                          onTap: onRestart,
                        ),
                        const SizedBox(height: 12),
                        _DarkActionButton(
                          icon: Icons.map_rounded,
                          label: context.l10n.tr('choose_world'),
                          onTap: onExit,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => context.goNamed(
                            'ranking',
                            pathParameters: {'worldId': worldId},
                            extra: {
                              'worldName': worldName,
                              'worldEmoji': worldEmoji,
                              'worldColor': worldColor,
                            },
                          ),
                          child: Text(
                            '🏆  ${context.l10n.tr('view_ranking_short')}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const _ShopNudge(),
                      ],
                    )
                  : _GoldActionButton(
                      icon: Icons.card_giftcard_rounded,
                      label: context.l10n.tr('claim_chest'),
                      onTap: onClaimChest,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gemas gratis por cada misión completada (faucet). Hace que las gemas sean
/// alcanzables jugando, sin regalar tantas que nadie compre. Ver ECONOMIA.md.
const int kGemsPerCompletedMission = 1;

/// Tarjeta verde de misión completada: check, nombre + descripción y premio.
class _CompletedMissionCard extends StatelessWidget {
  final Mission mission;
  const _CompletedMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF43A047), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF43A047),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.missionTitle(mission),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  context.l10n.missionDescription(mission),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${mission.rewardCoins}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$kGemsPerCompletedMission',
                    style: const TextStyle(
                      color: Color(0xFF7FD6FF),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('💎', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Caja de estadística del resumen: icono arriba, valor grande y etiqueta.
class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color valueColor;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Formatea un entero con separador de miles (8540 → "8,540").
String _fmtNum(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Botón dorado principal con efecto 3D de bloque.
class _GoldActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GoldActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE24D), Color(0xFFFFCE1F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC99700),
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            offset: const Offset(0, 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF3D2C00), size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF3D2C00),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario oscuro con borde sutil.
class _DarkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DarkActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de acciones al terminar una carrera, en una sola fila estilo Subway
/// Surfers: cuadros compactos de icono para las acciones secundarias (elegir
/// mundo · ranking · tienda) + un botón grande y protagonista de "Play again".
///
/// Se deja como widget reutilizable para poder aplicarla o intercambiarla en
/// otras pantallas de fin de carrera sin duplicar el layout.
class _RunEndActions extends StatelessWidget {
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;
  final VoidCallback onRestart;
  final VoidCallback onChooseWorld;

  const _RunEndActions({
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
    required this.onRestart,
    required this.onChooseWorld,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareActionButton(
          icon: Icons.map_rounded,
          tooltip: context.l10n.tr('choose_world'),
          onTap: onChooseWorld,
        ),
        const SizedBox(width: 10),
        _SquareActionButton(
          icon: Icons.emoji_events_rounded,
          tooltip: context.l10n.tr('view_ranking_short'),
          onTap: () => context.goNamed(
            'ranking',
            pathParameters: {'worldId': worldId},
            extra: {
              'worldName': worldName,
              'worldEmoji': worldEmoji,
              'worldColor': worldColor,
            },
          ),
        ),
        const SizedBox(width: 10),
        _SquareActionButton(
          icon: Icons.storefront_rounded,
          tooltip: context.l10n.tr('run_shop_cta'),
          onTap: () => context.pushNamed('store'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GoldActionButton(
            icon: Icons.replay_rounded,
            label: context.l10n.tr('play_again'),
            onTap: onRestart,
          ),
        ),
      ],
    );
  }
}

/// Cuadro compacto de acción secundaria: solo un icono centrado, con la misma
/// altura (56) que el botón grande de "Play again" para que la fila quede
/// alineada. El texto se expone vía [Tooltip]/[Semantics] para accesibilidad,
/// sin ocupar espacio visible.
class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: 54,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

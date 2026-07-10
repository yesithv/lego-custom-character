import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/audio_service.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../../economy/presentation/widgets/chest_opening_widget.dart';
import '../../../missions/domain/entities/mission.dart';
import '../../../missions/presentation/bloc/mission_bloc.dart';
import '../../../missions/presentation/bloc/mission_event.dart';
import '../../../missions/presentation/bloc/mission_state.dart';
import '../../../missions/presentation/widgets/mission_card.dart';
import '../../../ranking/domain/entities/score.dart';
import '../../../ranking/presentation/bloc/ranking_bloc.dart';
import '../../../ranking/presentation/bloc/ranking_event.dart';
import '../../../ranking/presentation/bloc/ranking_state.dart';
import '../game/brix_run_game.dart';

class RunnerPage extends StatefulWidget {
  final Character character;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;

  const RunnerPage({
    super.key,
    required this.character,
    required this.worldId,
    required this.worldName,
    required this.worldEmoji,
    required this.worldColor,
  });

  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage> {
  late final BrixRunGame _game;
  static const double _swipeThreshold = 40.0;
  bool _showChest = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _game = BrixRunGame(
      appearance: widget.character.appearance,
      characterType: widget.character.type,
      worldId: widget.worldId,
      onRunComplete: _onRunComplete,
      onHit: _onHit,
    );
    // Pre-load ranking for this world to show personal best in game over
    context.read<RankingBloc>().add(LoadRanking(widget.worldId));
  }

  void _onRunComplete(int coins) {
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
    setState(() {
      _showChest = true;
      _isPaused = false;
    });
  }

  void _onHit() {
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
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
      } else {
        _game.resumeEngine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                        completedMissions: missionState.justCompleted,
                        worldId: widget.worldId,
                        worldName: widget.worldName,
                        worldEmoji: widget.worldEmoji,
                        worldColor: widget.worldColor,
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _isPaused = false;
                          });
                          game.restart();
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
                        onRestart: () {
                          setState(() {
                            _showChest = false;
                            _isPaused = false;
                          });
                          game.restart();
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
                onDismiss: () => setState(() => _showChest = false),
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
    final mult = g.multiplier;
    final muted = AudioService.instance.muted;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _HudPill(
                    icon: '🏃', label: '${g.meters}m', color: Colors.black54),
                const SizedBox(width: 8),
                _HudPill(
                  icon: '✦',
                  label: '${g.coins}',
                  color: const Color(0xFFB8860B).withValues(alpha: 0.85),
                ),
                if (g.hasShield) ...[
                  const SizedBox(width: 8),
                  _PowerupPill(
                      icon: '🛡', color: const Color(0xFF00AAFF)),
                ],
                if (g.magnetActive) ...[
                  const SizedBox(width: 8),
                  _PowerupPill(
                      icon: '🧲', color: const Color(0xFFFF6B35)),
                ],
                const Spacer(),
                if (mult > 1.0) ...[
                  _MultiplierBadge(mult: mult),
                  const SizedBox(width: 8),
                ],
                // Mute button
                GestureDetector(
                  onTap: () => AudioService.instance.toggleMute(),
                  child: _IconChip(
                    icon: muted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                // Pause button
                GestureDetector(
                  onTap: widget.onTogglePause,
                  child: const _IconChip(icon: Icons.pause_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (g.phase == GamePhase.running)
              _ZoneBadge(zone: g.currentZone)
            else
              _BossBar(game: g),
          ],
        ),
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
                      ? '¡${cfg.name} se acerca!'
                      : cfg.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              // Corazones del jefe
              ...List.generate(BrixRunGame.maxBossHearts, (i) {
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
        const Text(
          '⚡ Esquiva ataques para cargar tu EMBESTIDA',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _HudPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerupPill extends StatelessWidget {
  final String icon;
  final Color color;
  const _PowerupPill({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  const _IconChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _MultiplierBadge extends StatelessWidget {
  final double mult;
  const _MultiplierBadge({required this.mult});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.5),
            blurRadius: 8,
          )
        ],
      ),
      child: Text(
        'x${mult.toStringAsFixed(0)} 🔥',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  final RunnerZone zone;
  const _ZoneBadge({required this.zone});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    if (zone == RunnerZone.inicio) {
      label = 'Inicio';
      color = Colors.green.shade700;
    } else if (zone == RunnerZone.nucleo) {
      label = 'Núcleo ⚡';
      color = Colors.orange.shade700;
    } else {
      label = '¡ZONA CAOS! 💥';
      color = Colors.red.shade700;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
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
                  const Text(
                    '⏸ Pausa',
                    style: TextStyle(
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
                      label: const Text(
                        'Continuar',
                        style: TextStyle(
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
                      label: const Text('Salir al mapa'),
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
  final List<Mission> completedMissions;
  final String worldId;
  final String worldName;
  final String worldEmoji;
  final Color worldColor;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.game,
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
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¡Sigue creando!',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '¡Casi llegas al podio!',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBox(label: 'Metros', value: '${game.meters}m'),
                  _StatBox(label: 'Monedas', value: '✦ ${game.coins}'),
                  _StatBox(
                    label: 'Puntos',
                    value: '${game.score}',
                    highlight: true,
                  ),
                ],
              ),

              const SizedBox(height: 10),
              _ZoneBadge(zone: game.currentZone),

              // Personal best from ranking
              BlocBuilder<RankingBloc, RankingState>(
                builder: (context, rankingState) {
                  if (rankingState.scores.isEmpty ||
                      rankingState.worldId != worldId) {
                    return const SizedBox.shrink();
                  }
                  final pb = rankingState.scores.first.score;
                  final isNew = game.score >= pb;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: isNew
                        ? const Text(
                            '🎉 ¡Nuevo récord!',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          )
                        : Text(
                            'Récord: $pb pts',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                  );
                },
              ),

              if (completedMissions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🎯 Misiones completadas',
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

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text(
                    'Jugar de nuevo',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onExit,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Elegir mundo'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.goNamed(
                  'ranking',
                  pathParameters: {'worldId': worldId},
                  extra: {
                    'worldName': worldName,
                    'worldEmoji': worldEmoji,
                    'worldColor': worldColor,
                  },
                ),
                icon: const Icon(Icons.emoji_events_outlined,
                    size: 16, color: Color(0xFFFFD700)),
                label: const Text(
                  'Ver ranking',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _VictoryOverlay({
    required this.game,
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
    final cfg = game.bossConfig;
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 4),
                Text(
                  '¡$worldName superado!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${cfg.emoji} Derrotaste a ${cfg.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8860B).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: Text(
                    '✦ +${BrixRunGame.victoryCoinBonus} monedas de botín',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(label: 'Metros', value: '${game.meters}m'),
                    _StatBox(label: 'Monedas', value: '✦ ${game.coins}'),
                    _StatBox(
                      label: 'Puntos',
                      value: '${game.score}',
                      highlight: true,
                    ),
                  ],
                ),

                // Personal best from ranking
                BlocBuilder<RankingBloc, RankingState>(
                  builder: (context, rankingState) {
                    if (rankingState.scores.isEmpty ||
                        rankingState.worldId != worldId) {
                      return const SizedBox.shrink();
                    }
                    final pb = rankingState.scores.first.score;
                    final isNew = game.score >= pb;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: isNew
                          ? const Text(
                              '🎉 ¡Nuevo récord!',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            )
                          : Text(
                              'Récord: $pb pts',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                    );
                  },
                ),

                if (completedMissions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🎯 Misiones completadas',
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

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'Jugar de nuevo',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onExit,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Elegir mundo'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => context.goNamed(
                    'ranking',
                    pathParameters: {'worldId': worldId},
                    extra: {
                      'worldName': worldName,
                      'worldEmoji': worldEmoji,
                      'worldColor': worldColor,
                    },
                  ),
                  icon: const Icon(Icons.emoji_events_outlined,
                      size: 16, color: Color(0xFFFFD700)),
                  label: const Text(
                    'Ver ranking',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w700,
                    ),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatBox({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFFD700) : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: highlight ? 22 : 17,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

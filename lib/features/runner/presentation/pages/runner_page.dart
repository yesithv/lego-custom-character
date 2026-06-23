import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../game/brix_run_game.dart';

class RunnerPage extends StatefulWidget {
  final Character character;
  final String worldId;

  const RunnerPage({
    super.key,
    required this.character,
    required this.worldId,
  });

  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage> {
  late final BrixRunGame _game;
  Offset? _dragStart;
  static const double _swipeThreshold = 40.0;

  @override
  void initState() {
    super.initState();
    _game = BrixRunGame(
      appearance: widget.character.appearance,
      worldId: widget.worldId,
    );
  }

  @override
  void dispose() {
    _game.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) => _dragStart = d.localPosition;

  void _onPanEnd(DragEndDetails d) {
    if (_dragStart == null) return;
    final v = d.velocity.pixelsPerSecond;

    if (v.dx.abs() > v.dy.abs()) {
      if (v.dx > _swipeThreshold) {
        _game.onSwipeRight();
      } else if (v.dx < -_swipeThreshold) {
        _game.onSwipeLeft();
      }
    } else {
      if (v.dy < -_swipeThreshold) {
        _game.onSwipeUp();
      } else if (v.dy > _swipeThreshold) {
        _game.onSwipeDown();
      }
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanEnd: _onPanEnd,
        onTap: _game.onTap,
        child: GameWidget<BrixRunGame>(
          game: _game,
          overlayBuilderMap: {
            'hud': (context, game) => _HudOverlay(game: game),
            'gameOver': (context, game) => _GameOverOverlay(
                  game: game,
                  character: widget.character,
                  onRestart: game.restart,
                  onExit: () => context.goNamed('worlds'),
                ),
          },
        ),
      ),
    );
  }
}

// ── HUD Overlay ───────────────────────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final BrixRunGame game;
  const _HudOverlay({required this.game});

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
    })
      ..start();
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Score
            _HudPill(
              icon: '🏃',
              label: '${g.meters}m',
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            // Coins
            _HudPill(
              icon: '✦',
              label: '${g.coins}',
              color: const Color(0xFFB8860B).withValues(alpha: 0.8),
            ),
            const Spacer(),
            // Multiplier
            if (mult > 1.0)
              _MultiplierBadge(mult: mult),
          ],
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _HudPill({required this.icon, required this.label, required this.color});

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
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
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
          fontSize: 16,
        ),
      ),
    );
  }
}

// ── Game Over Overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final BrixRunGame game;
  final Character character;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.game,
    required this.character,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
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
                '¡Sigue corriendo!',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '¡Casi llegas al podio!',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Stats row
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

              const SizedBox(height: 28),

              // Restart
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
              const SizedBox(height: 12),

              // Exit
              SizedBox(
                width: double.infinity,
                height: 48,
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
            ],
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
            fontSize: highlight ? 22 : 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

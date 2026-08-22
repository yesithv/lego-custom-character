part of 'runner_page.dart';

// ── HUD Overlay ───────────────────────────────────────────────────────────────

class _HudOverlay extends StatefulWidget {
  final BrixRunGame game;
  final VoidCallback onTogglePause;
  const _HudOverlay({required this.game, required this.onTogglePause});

  @override
  State<_HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<_HudOverlay> {
  @override
  Widget build(BuildContext context) {
    // Antes: un Ticker llamaba setState(() {}) CADA frame y reconstruía todo el
    // HUD 60 veces/s aunque nada cambiara. Ahora el HUD escucha la instantánea
    // discreta del juego (`hudData`) y solo se reconstruye cuando algún valor
    // cambia de verdad (unas pocas veces por segundo). Se envuelve en un
    // RepaintBoundary para que sus repintados no afecten a la capa del juego.
    return ValueListenableBuilder<HudData>(
      valueListenable: widget.game.hudData,
      builder: (context, _, __) => RepaintBoundary(child: _buildHud(context)),
    );
  }

  Widget _buildHud(BuildContext context) {
    final g = widget.game;
    final musicMuted = AudioService.instance.musicMuted;

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Barra vertical de progreso en la pista (lado derecho). Ocupa la
          // franja superior-media para no quedar a la altura del corredor
          // (que ahora corre más abajo) y no "acosar" sus costados.
          Positioned(
            right: 22,
            top: 110,
            // Se mantiene el borde superior y se estira ~15% hacia abajo
            // (bottom 330 -> 275): la barra es delgada y no estorba la vista.
            bottom: 275,
            child: IgnorePointer(
              child: _TrackProgressBar(progress: g.trackProgress),
            ),
          ),

          // Dock de power-ups (lado izquierdo, en la franja superior
          // para despejar los costados del corredor, que corre más abajo).
          Align(
            alignment: const Alignment(-1.0, -0.35),
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


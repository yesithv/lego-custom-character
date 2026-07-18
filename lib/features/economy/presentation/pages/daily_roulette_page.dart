import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

// ── Roulette segment data ─────────────────────────────────────────────────────

class _Segment {
  final String label;
  final Color color;
  final String emoji;
  const _Segment(this.label, this.color, this.emoji);
}

const _segments = [
  _Segment('50', Color(0xFF43A047), '🪙'),
  _Segment('Parte', Color(0xFF9E9E9E), '⚙️'),
  _Segment('100', Color(0xFF1E88E5), '🪙'),
  _Segment('Común', Color(0xFF8D9E63), '⚙️'),
  _Segment('200', Color(0xFFB07A3B), '🪙'),
  _Segment('Raro', Color(0xFF3949AB), '💎'),
  _Segment('500', Color(0xFFE53935), '🪙'),
  _Segment('¡Épico!', Color(0xFF8E24AA), '⚡'),
];

// Map reward type → wheel segment index
int _segmentIndexForReward(Reward reward) {
  if (reward is CoinsReward) {
    if (reward.amount >= 500) return 6;
    if (reward.amount >= 200) return 4;
    if (reward.amount >= 100) return 2;
    return 0;
  }
  if (reward is PartReward) {
    final rarity = reward.rarity;
    if (rarity == AccessoryRarity.epic || rarity == AccessoryRarity.legendary) return 7;
    if (rarity == AccessoryRarity.rare) return 5;
    return 1;
  }
  return 0;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class DailyRoulettePage extends StatefulWidget {
  const DailyRoulettePage({super.key});

  @override
  State<DailyRoulettePage> createState() => _DailyRoulettePageState();
}

class _DailyRoulettePageState extends State<DailyRoulettePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;

  Reward? _pendingReward;
  bool _spinning = false;
  bool _done = false;

  static const double _segmentAngle = (2 * pi) / 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin(Reward reward) {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _pendingReward = reward;
    });

    final targetSegment = _segmentIndexForReward(reward);
    // Pointer is at top (π * 1.5). Segment i starts at i * segmentAngle.
    // We want segment center at top → end angle = -(i + 0.5) * segmentAngle
    final targetAngle =
        -(targetSegment + 0.5) * _segmentAngle + (6 * 2 * pi); // 6 full spins

    _rotation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    HapticFeedback.mediumImpact();
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => _done = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (p, c) =>
          p.status == WalletStatus.claiming &&
          c.status == WalletStatus.ready &&
          c.lastReward != null,
      listener: (context, state) {
        if (state.lastReward != null) {
          _spin(state.lastReward!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A0A3B),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Se navega a la ruleta con `go` (reemplaza la pila), así que
            // Navigator.pop no tiene a dónde volver: usamos go-router al inicio.
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.goNamed('home'),
            ),
            title: const Text(
              '🎡 Ruleta Diaria',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),

              // Coin balance
              _CoinBadge(coins: state.wallet.coins),

              const SizedBox(height: 12),

              if (!state.wallet.canClaimRoulette && !_done) ...[
                const SizedBox(height: 4),
                const Opacity(opacity: 0.35, child: _Pointer()),
                const SizedBox(height: 10),
                const Expanded(child: Center(child: _LockedWheel())),
                _ClaimedPanel(wallet: state.wallet),
              ] else ...[
                const SizedBox(height: 24),

                // Wheel
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pointer triangle
                        const _Pointer(),
                        const SizedBox(height: 4),
                        // Spinning wheel con halo dorado que palpita al girar
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (_, __) {
                            final spinning = _spinning && !_done;
                            final glow = _done
                                ? 26.0
                                : spinning
                                    ? 12 +
                                        sin(_controller.value * pi * 16).abs() *
                                            20
                                    : 0.0;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: glow > 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700)
                                              .withValues(alpha: 0.65),
                                          blurRadius: glow,
                                          spreadRadius: glow * 0.35,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Transform.rotate(
                                angle: _spinning ? _rotation.value : 0,
                                child: _RouletteWheel(segments: _segments),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Result card — aparece con un "pop" elástico al terminar
                if (_done && _pendingReward != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.elasticOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _RewardCard(reward: _pendingReward!),
                  ),

                const SizedBox(height: 12),

                // Indicador de giro disponible
                if (!_spinning && !_done)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      '✨ 1 giro disponible hoy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Spin / close button (efecto 3D de bloque)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                  child: _SpinButton(
                    label: _spinning && !_done
                        ? '¡Girando!'
                        : _done
                            ? '¡Genial!'
                            : '¡GIRAR!',
                    done: _done,
                    onTap: _spinning && !_done
                        ? null
                        : _done
                            ? () => context.goNamed('home')
                            : () => context
                                .read<WalletBloc>()
                                .add(const ClaimRouletteEvent()),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RouletteWheel extends StatelessWidget {
  final List<_Segment> segments;
  const _RouletteWheel({required this.segments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 290,
      child: CustomPaint(
        painter: _WheelPainter(segments: segments),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;
  _WheelPainter({required this.segments});

  static const double _rimWidth = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segRadius = radius - _rimWidth;
    final segAngle = (2 * pi) / segments.length;
    final fullRect = Rect.fromCircle(center: center, radius: radius);

    // ── Aro dorado exterior (metálico) ──
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE680), Color(0xFFE0A800), Color(0xFFB8860B)],
        ).createShader(fullRect),
    );
    // Borde exterior oscuro para dar profundidad
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8A5E00),
    );

    // ── Segmentos ──
    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segAngle - pi / 2;
      final seg = segments[i];
      final segRect = Rect.fromCircle(center: center, radius: segRadius);

      canvas.drawArc(segRect, startAngle, segAngle, true,
          Paint()..color = seg.color);

      // Separador entre segmentos
      canvas.drawArc(
        segRect,
        startAngle,
        segAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Anillo interior que separa segmentos del aro
    canvas.drawCircle(
      center,
      segRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF9C6B00),
    );

    // ── Icono + etiqueta de cada segmento ──
    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segAngle - pi / 2;
      final seg = segments[i];

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segAngle / 2);

      // Icono (moneda / pieza) hacia el borde exterior
      final iconTp = TextPainter(
        text: TextSpan(text: seg.emoji, style: const TextStyle(fontSize: 17)),
        textDirection: TextDirection.ltr,
      )..layout();
      iconTp.paint(
        canvas,
        Offset(segRadius * 0.80 - iconTp.width / 2, -iconTp.height / 2),
      );

      // Etiqueta hacia el centro
      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            shadows: [
              Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 70);
      tp.paint(canvas, Offset(segRadius * 0.46 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // ── Centro (hub) ──
    canvas.drawCircle(center, 26, Paint()..color = const Color(0xFF1A0A3B));
    canvas.drawCircle(
      center,
      26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE680), Color(0xFFC99700)],
        ).createShader(Rect.fromCircle(center: center, radius: 26)),
    );
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFFFFD700));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

/// Botón principal de la ruleta con el efecto 3D de bloque de la app.
class _SpinButton extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback? onTap;

  const _SpinButton({
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final base = done ? const Color(0xFF43A047) : const Color(0xFFFFD700);
    final baseDark = done ? const Color(0xFF2E7D32) : const Color(0xFFC99700);
    final textColor = done ? Colors.white : const Color(0xFF3D2C00);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: baseDark, offset: const Offset(0, 6), blurRadius: 0),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              offset: const Offset(0, 9),
              blurRadius: 12,
            ),
          ],
        ),
        child: Material(
          color: base,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pointer extends StatelessWidget {
  const _Pointer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 20),
      painter: _PointerPainter(),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700));
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RewardCard extends StatelessWidget {
  final Reward reward;
  const _RewardCard({required this.reward});

  Color get _rarityColor {
    if (reward is! PartReward) return Colors.green;
    final r = (reward as PartReward).rarity;
    if (r == AccessoryRarity.legendary) return const Color(0xFFFFD700);
    if (r == AccessoryRarity.epic) return Colors.purple;
    if (r == AccessoryRarity.rare) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rarityColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(reward.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Premio!',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  reward.displayLabel,
                  style: TextStyle(
                    color: _rarityColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
      ),
      child: Text(
        '🪙  $coins monedas',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

/// Rueda desaturada con candado al centro (estado "ya girada").
class _LockedWheel extends StatelessWidget {
  const _LockedWheel();

  // Matriz de saturación reducida (~0.3): los colores quedan apagados
  // pero se siguen intuyendo, como en el diseño.
  static const _desaturate = ColorFilter.matrix(<double>[
    0.449, 0.501, 0.051, 0, 0,
    0.149, 0.801, 0.051, 0, 0,
    0.149, 0.501, 0.351, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Opacity(
          opacity: 0.55,
          child: ColorFiltered(
            colorFilter: _desaturate,
            child: _RouletteWheel(segments: _segments),
          ),
        ),
        // Candado dorado central
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A3B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.lock_rounded,
              color: Color(0xFFFFD700), size: 30),
        ),
      ],
    );
  }
}

/// Panel inferior cuando ya se giró: título, subtítulo, tarjetas de
/// "hoy ganaste" + "próximo giro" y botón "Entendido".
class _ClaimedPanel extends StatelessWidget {
  final Wallet wallet;
  const _ClaimedPanel({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¡Ya reclamaste tu ruleta hoy!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vuelve mañana para girar de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'HOY GANASTE',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        wallet.lastRouletteRewardEmoji ?? '🪙',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        wallet.lastRouletteRewardLabel ?? '—',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _InfoCard(
                  label: 'PRÓXIMO GIRO',
                  child: _Countdown(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SpinButton(
            label: 'Entendido',
            done: false,
            onTap: () => context.goNamed('home'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Cuenta regresiva hasta la medianoche local (cuando se reinicia la ruleta).
class _Countdown extends StatefulWidget {
  const _Countdown();

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _timeToMidnight();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _timeToMidnight());
    });
  }

  Duration _timeToMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final d = nextMidnight.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          _fmt(_remaining),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

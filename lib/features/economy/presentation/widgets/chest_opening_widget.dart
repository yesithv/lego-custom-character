import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/reward.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

// ─────────────────────────────────────────────────────────────────
//  Particle model
// ─────────────────────────────────────────────────────────────────
class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotSpeed;
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotSpeed,
  });
}

// ─────────────────────────────────────────────────────────────────
//  ChestOpeningWidget
// ─────────────────────────────────────────────────────────────────
class ChestOpeningWidget extends StatefulWidget {
  final bool isVip;
  final VoidCallback onDismiss;

  const ChestOpeningWidget({
    super.key,
    required this.isVip,
    required this.onDismiss,
  });

  @override
  State<ChestOpeningWidget> createState() => _ChestOpeningWidgetState();
}

class _ChestOpeningWidgetState extends State<ChestOpeningWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openController;
  late Animation<double> _shakeAnim;
  late Animation<double> _lidAnim;
  late Animation<double> _lidScaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _popAnim;
  late Animation<Offset> _rewardSlide;
  late Animation<double> _chestBounceAnim;

  late AnimationController _flashController;
  late AnimationController _particleController;
  late AnimationController _rayRotController;

  late Animation<double> _flashAnim;
  late Animation<double> _particleAnim;

  bool _opened = false;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  static const _particleColors = [
    Color(0xFFFFD700),
    Color(0xFFFF4081),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFFF6E40),
    Color(0xFFEA80FC),
    Color(0xFFFFFF00),
  ];

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _lidAnim = Tween<double>(begin: 0, end: -1.2).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutCubic),
    );
    _lidScaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.0), weight: 70),
    ]).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeInCubic),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOut),
    );
    _popAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _openController, curve: Curves.elasticOut),
    );
    _rewardSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutBack),
    );
    _chestBounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOut),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flashAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 80),
    ]).animate(_flashController);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _particleAnim = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );
    _generateParticles();

    _rayRotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _shakeController.forward().then((_) {
      if (!mounted) return;
      context.read<WalletBloc>().add(OpenChestEvent(isVip: widget.isVip));
      HapticFeedback.heavyImpact();
      _openController.forward();
      _flashController.forward();
      _particleController.forward();
      _rayRotController.repeat();
      setState(() => _opened = true);
    });
  }

  void _generateParticles() {
    for (var i = 0; i < 28; i++) {
      _particles.add(_Particle(
        angle: _rng.nextDouble() * 2 * pi,
        speed: 80 + _rng.nextDouble() * 140,
        size: 5 + _rng.nextDouble() * 8,
        color: _particleColors[_rng.nextInt(_particleColors.length)],
        rotSpeed: (_rng.nextDouble() - 0.5) * 8,
      ));
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _openController.dispose();
    _flashController.dispose();
    _particleController.dispose();
    _rayRotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final reward = walletState.lastReward;
        return Stack(
          children: [
            Container(color: Colors.black.withValues(alpha: 0.88)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isVip
                        ? '🌟 ${context.l10n.tr('chest_vip')}'
                        : '📦 ${context.l10n.tr('chest_run')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: 260,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_opened)
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_rayRotController, _glowAnim]),
                            builder: (_, __) => Opacity(
                              opacity: _glowAnim.value,
                              child: CustomPaint(
                                size: const Size(260, 220),
                                painter: _RotatingRaysPainter(
                                  rotation: _rayRotController.value * 2 * pi,
                                  color: widget.isVip
                                      ? const Color(0xFFFFE082)
                                      : const Color(0xFFFFB300),
                                  intensity: _glowAnim.value,
                                ),
                              ),
                            ),
                          ),

                        if (_opened)
                          AnimatedBuilder(
                            animation: _particleAnim,
                            builder: (_, __) => CustomPaint(
                              size: const Size(260, 220),
                              painter: _ParticlePainter(
                                progress: _particleAnim.value,
                                particles: _particles,
                              ),
                            ),
                          ),

                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_shakeController, _openController]),
                          builder: (context, _) {
                            return Transform.rotate(
                              angle: _shakeAnim.value,
                              child: _ChestGraphic(
                                lidAngle: _lidAnim.value,
                                lidScale: _lidScaleAnim.value,
                                glowIntensity: _glowAnim.value,
                                chestScale: _chestBounceAnim.value,
                                isVip: widget.isVip,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_opened && reward != null)
                    SlideTransition(
                      position: _rewardSlide,
                      child: FadeTransition(
                        opacity: _glowAnim,
                        child: ScaleTransition(
                          scale: _popAnim,
                          child: _RewardReveal(reward: reward),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 120),

                  const SizedBox(height: 32),

                  if (_opened)
                    FadeTransition(
                      opacity: _glowAnim,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(180, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: widget.onDismiss,
                        child: Text(
                          context.l10n.tr('chest_nice'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: _flashAnim,
              builder: (_, __) => IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: _flashAnim.value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  ChestGraphic
// ─────────────────────────────────────────────────────────────────
class _ChestGraphic extends StatelessWidget {
  final double lidAngle;
  final double lidScale;
  final double glowIntensity;
  final double chestScale;
  final bool isVip;

  const _ChestGraphic({
    required this.lidAngle,
    required this.lidScale,
    required this.glowIntensity,
    required this.chestScale,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    final chestColor =
        isVip ? const Color(0xFFFFD700) : const Color(0xFF8B5E3C);
    final rimColor =
        isVip ? const Color(0xFFB8860B) : const Color(0xFF5C3A1E);
    final glowColor = isVip ? Colors.yellow : Colors.orange;

    return Transform.scale(
      scale: chestScale,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (glowIntensity > 0)
              Opacity(
                opacity: glowIntensity,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.75),
                        blurRadius: 60,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              bottom: 20,
              child: Container(
                width: 110,
                height: 70,
                decoration: BoxDecoration(
                  color: chestColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rimColor, width: 3),
                  boxShadow: glowIntensity > 0
                      ? [
                          BoxShadow(
                            color: glowColor.withValues(
                                alpha: 0.4 * glowIntensity),
                            blurRadius: 16,
                            spreadRadius: 4,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rimColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 2),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 20,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.rotationX(lidAngle)
                  ..scaleByDouble(1.0, lidScale.clamp(0.0, 1.2), 1.0, 1.0),
                child: Container(
                  width: 116,
                  height: 38,
                  decoration: BoxDecoration(
                    color: chestColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border.all(color: rimColor, width: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Rotating rays
// ─────────────────────────────────────────────────────────────────
class _RotatingRaysPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final double intensity;

  _RotatingRaysPainter({
    required this.rotation,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.longestSide * 0.62;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.35 * intensity)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    const count = 10;
    for (var i = 0; i < count; i++) {
      final a = rotation + (2 * pi / count) * i;
      canvas.drawLine(
        center + Offset(cos(a) * maxR * 0.18, sin(a) * maxR * 0.18),
        center + Offset(cos(a) * maxR, sin(a) * maxR),
        paint,
      );
    }
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.20 * intensity)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final a = -rotation * 0.7 + (2 * pi / count) * i + pi / count;
      canvas.drawLine(
        center + Offset(cos(a) * maxR * 0.22, sin(a) * maxR * 0.22),
        center + Offset(cos(a) * maxR * 0.85, sin(a) * maxR * 0.85),
        paint2,
      );
    }
    canvas.drawCircle(
      center,
      maxR * 0.28,
      Paint()
        ..color = color.withValues(alpha: 0.18 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(_RotatingRaysPainter old) =>
      old.rotation != rotation || old.intensity != intensity;
}

// ─────────────────────────────────────────────────────────────────
//  Particle painter
// ─────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ParticlePainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final origin = Offset(size.width / 2, size.height * 0.42);
    final gravity = 180.0 * progress * progress;

    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * progress;
      final dy = sin(p.angle) * p.speed * progress + gravity;
      final fade = (1.0 - progress * 0.85).clamp(0.0, 1.0);
      final pos = origin + Offset(dx, dy);
      final rot = p.rotSpeed * progress;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        Paint()
          ..color = p.color.withValues(alpha: fade)
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────
//  Reward reveal card
// ─────────────────────────────────────────────────────────────────
class _RewardReveal extends StatelessWidget {
  final Reward reward;
  const _RewardReveal({required this.reward});

  Color get _color {
    if (reward is! PartReward) return Colors.green;
    final r = (reward as PartReward).rarity;
    if (r == AccessoryRarity.legendary) return const Color(0xFFFFD700);
    if (r == AccessoryRarity.epic) return Colors.purple;
    if (r == AccessoryRarity.rare) return Colors.blue;
    return Colors.grey;
  }

  String get _rarityLabel {
    if (reward is! PartReward) return L10n.t('chest_coins');
    final r = (reward as PartReward).rarity;
    if (r == AccessoryRarity.legendary) return L10n.t('chest_legendary');
    if (r == AccessoryRarity.epic) return L10n.t('chest_epic');
    if (r == AccessoryRarity.rare) return L10n.t('chest_rare');
    return L10n.t('chest_common');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            _rarityLabel,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reward.displayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

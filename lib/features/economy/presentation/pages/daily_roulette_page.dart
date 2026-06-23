import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reward.dart';
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
  _Segment('50 ✦', Color(0xFF4CAF50), '✦'),
  _Segment('Parte\ncomún', Color(0xFF9E9E9E), '⚙️'),
  _Segment('100 ✦', Color(0xFF2196F3), '✦'),
  _Segment('Parte\ncomún', Color(0xFF607D8B), '⚙️'),
  _Segment('200 ✦', Color(0xFFFF9800), '✦'),
  _Segment('¡Rara!', Color(0xFF3F51B5), '💎'),
  _Segment('500 ✦', Color(0xFFF44336), '✦'),
  _Segment('¡Épico!', Color(0xFF9C27B0), '⚡'),
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
    return switch (reward.rarity) {
      AccessoryRarity.epic || AccessoryRarity.legendary => 7,
      AccessoryRarity.rare => 5,
      _ => 1,
    };
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

    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _done = true);
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
            leading: const BackButton(color: Colors.white),
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
                const Expanded(child: _AlreadyClaimedView()),
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
                        // Spinning wheel
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (_, __) => Transform.rotate(
                            angle: _spinning
                                ? (_rotation.value)
                                : 0,
                            child: _RouletteWheel(segments: _segments),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Result card
                if (_done && _pendingReward != null)
                  _RewardCard(reward: _pendingReward!),

                const SizedBox(height: 16),

                // Spin / close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _done
                            ? Colors.green.shade600
                            : const Color(0xFFFFD700),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _spinning && !_done
                          ? null
                          : _done
                              ? () => Navigator.of(context).pop()
                              : () => context
                                  .read<WalletBloc>()
                                  .add(const ClaimRouletteEvent()),
                      child: Text(
                        _spinning && !_done
                            ? '¡Girando!'
                            : _done
                                ? '¡Genial!'
                                : '¡GIRAR!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
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
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _WheelPainter(segments: segments),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;
  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = (2 * pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segAngle - pi / 2;
      final seg = segments[i];

      // Sector fill
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        Paint()..color = seg.color,
      );

      // Sector border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segAngle / 2);
      final textR = radius * 0.65;

      final tp = TextPainter(
        text: TextSpan(
          text: seg.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 70);
      tp.paint(canvas, Offset(textR - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    canvas.drawCircle(center, 22,
        Paint()..color = const Color(0xFF1A0A3B));
    canvas.drawCircle(
        center,
        22,
        Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
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
    if (reward is PartReward) {
      return switch ((reward as PartReward).rarity) {
        AccessoryRarity.common => Colors.grey,
        AccessoryRarity.rare => Colors.blue,
        AccessoryRarity.epic => Colors.purple,
        AccessoryRarity.legendary => const Color(0xFFFFD700),
      };
    }
    return Colors.green;
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
        '✦  $coins monedas',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _AlreadyClaimedView extends StatelessWidget {
  const _AlreadyClaimedView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🕐', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text(
          '¡Ya reclamaste tu ruleta hoy!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vuelve mañana para girar de nuevo.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black87,
            minimumSize: const Size(160, 48),
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

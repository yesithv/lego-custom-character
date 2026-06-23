import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/reward.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

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
  late Animation<double> _glowAnim;
  late Animation<Offset> _rewardSlide;

  bool _opened = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _lidAnim = Tween<double>(begin: 0, end: -0.6).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutBack),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOut),
    );
    _rewardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutBack),
    );

    // Auto-shake then open
    _shakeController.forward().then((_) {
      context.read<WalletBloc>().add(OpenChestEvent(isVip: widget.isVip));
      _openController.forward();
      setState(() => _opened = true);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _openController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final reward = walletState.lastReward;
        return Container(
          color: Colors.black.withValues(alpha: 0.85),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  widget.isVip ? '🌟 Cofre VIP' : '📦 Cofre de Carrera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 32),

                // Chest animation
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_shakeController, _openController]),
                  builder: (context, _) {
                    return Transform.rotate(
                      angle: _shakeAnim.value,
                      child: _ChestGraphic(
                        lidAngle: _lidAnim.value,
                        glowIntensity: _glowAnim.value,
                        isVip: widget.isVip,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Reward reveal
                if (_opened && reward != null)
                  SlideTransition(
                    position: _rewardSlide,
                    child: FadeTransition(
                      opacity: _glowAnim,
                      child: _RewardReveal(reward: reward),
                    ),
                  )
                else
                  const SizedBox(height: 80),

                const SizedBox(height: 32),

                // Dismiss button
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
                      child: const Text(
                        '¡Genial!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChestGraphic extends StatelessWidget {
  final double lidAngle;
  final double glowIntensity;
  final bool isVip;

  const _ChestGraphic({
    required this.lidAngle,
    required this.glowIntensity,
    required this.isVip,
  });

  @override
  Widget build(BuildContext context) {
    final chestColor =
        isVip ? const Color(0xFFFFD700) : const Color(0xFF8B5E3C);
    final rimColor =
        isVip ? const Color(0xFFB8860B) : const Color(0xFF5C3A1E);
    final glowColor =
        isVip ? Colors.yellow : Colors.orange;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
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
                      color: glowColor.withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

          // Chest body
          Positioned(
            bottom: 20,
            child: Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                color: chestColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rimColor, width: 3),
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

          // Lid (rotates open)
          Positioned(
            top: 20,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.rotationX(lidAngle),
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
    );
  }
}

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
    if (reward is! PartReward) return 'Monedas';
    final r = (reward as PartReward).rarity;
    if (r == AccessoryRarity.legendary) return '¡LEGENDARIO!';
    if (r == AccessoryRarity.epic) return '¡Épico!';
    if (r == AccessoryRarity.rare) return '¡Raro!';
    return 'Común';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color, width: 2),
      ),
      child: Column(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 40)),
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

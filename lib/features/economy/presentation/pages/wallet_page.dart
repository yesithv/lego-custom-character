import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../monetization/domain/entities/entitlements.dart';
import '../../../monetization/domain/repositories/store_repository.dart';
import '../../../runner/presentation/pages/world_selection_page.dart'
    show worlds, WorldStatus;
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';

/// "Mi Billetera": resumen sencillo de la economía del jugador.
///
/// Muestra, de un vistazo, el saldo de monedas y gemas, cuánto ha ganado y
/// gastado de por vida (para gemas usamos `totalGemsEarned`; para monedas,
/// `totalCoinsEarned`), y qué ha conseguido con ello (piezas, mundos, racha,
/// VIP). Pensado para niños: pocas cifras, claras y con color.
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final StoreRepository _store = sl<StoreRepository>();
  Entitlements _ent = const Entitlements();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await _store.getEntitlements();
    if (!mounted) return;
    setState(() => _ent = e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063574),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('👛 ${context.l10n.tr('wallet_title')}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1466C8), Color(0xFF0A4A9E), Color(0xFF063574)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              final wallet = state.wallet;
              final coinsEarned = wallet.totalCoinsEarned < wallet.coins
                  ? wallet.coins
                  : wallet.totalCoinsEarned;
              final coinsSpent = coinsEarned - wallet.coins;

              // Para gemas migradas (registros viejos) el earned ya se ajusta en
              // el adaptador; aquí solo protegemos contra negativos.
              final gemsEarned =
                  _ent.totalGemsEarned < _ent.gems ? _ent.gems : _ent.totalGemsEarned;
              final gemsSpent = gemsEarned - _ent.gems;

              final worldsOpen = worlds
                  .where((w) =>
                      w.status == WorldStatus.available ||
                      wallet.totalCoinsEarned >= w.unlockCost)
                  .length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  // Saldos grandes
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceCard(
                          emoji: '🪙',
                          label: context.l10n.tr('wallet_coins'),
                          value: wallet.coins,
                          accent: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BalanceCard(
                          emoji: '💎',
                          label: context.l10n.tr('wallet_gems'),
                          value: _ent.gems,
                          accent: const Color(0xFF7FD6FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Resumen de economía (monedas + gemas)
                  _EconomyCard(
                    coinsEarned: coinsEarned,
                    coinsSpent: coinsSpent,
                    coinsBalance: wallet.coins,
                    gemsEarned: gemsEarned,
                    gemsSpent: gemsSpent,
                    gemsBalance: _ent.gems,
                  ),
                  const SizedBox(height: 14),

                  // Logros de la economía
                  _AchievementsCard(
                    parts: wallet.unlockedParts.length,
                    worldsOpen: worldsOpen,
                    worldsTotal: worlds.length,
                    streak: wallet.runStreak,
                    isVip: _ent.subscriptionActive,
                    onGetVip: () => context.pushNamed('store'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Balance grande ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color accent;

  const _BalanceCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.05)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _fmt(value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resumen de economía ───────────────────────────────────────────────────────

class _EconomyCard extends StatelessWidget {
  final int coinsEarned;
  final int coinsSpent;
  final int coinsBalance;
  final int gemsEarned;
  final int gemsSpent;
  final int gemsBalance;

  const _EconomyCard({
    required this.coinsEarned,
    required this.coinsSpent,
    required this.coinsBalance,
    required this.gemsEarned,
    required this.gemsSpent,
    required this.gemsBalance,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '📊 ${context.l10n.tr('wallet_economy')}',
      child: Column(
        children: [
          // Cabecera de columnas
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              const Expanded(
                flex: 4,
                child: Text('🪙',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16)),
              ),
              const Expanded(
                flex: 4,
                child: Text('💎',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _EconRow(
            icon: '▲',
            iconColor: const Color(0xFF4CC15E),
            label: context.l10n.tr('wallet_earned'),
            coin: coinsEarned,
            gem: gemsEarned,
            valueColor: const Color(0xFF4CC15E),
          ),
          _EconRow(
            icon: '▼',
            iconColor: const Color(0xFFFF8A2B),
            label: context.l10n.tr('wallet_spent'),
            coin: coinsSpent,
            gem: gemsSpent,
            valueColor: const Color(0xFFFF8A2B),
          ),
          _EconRow(
            icon: '=',
            iconColor: const Color(0xFFFFD700),
            label: context.l10n.tr('wallet_balance'),
            coin: coinsBalance,
            gem: gemsBalance,
            valueColor: const Color(0xFFFFD700),
            emphasize: true,
          ),
          const SizedBox(height: 14),
          // Barra de ahorro de monedas (la economía principal)
          _SavingsBar(earned: coinsEarned, spent: coinsSpent),
        ],
      ),
    );
  }
}

class _EconRow extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label;
  final int coin;
  final int gem;
  final Color valueColor;
  final bool emphasize;

  const _EconRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.coin,
    required this.gem,
    required this.valueColor,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: emphasize
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white24, width: 1),
              ),
            )
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(icon,
                      style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _fmt(coin),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: emphasize ? 17 : 15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _fmt(gem),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: emphasize ? 17 : 15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra proporcional gastado vs. ahorrado (sobre lo ganado de por vida).
class _SavingsBar extends StatelessWidget {
  final int earned;
  final int spent;

  const _SavingsBar({required this.earned, required this.spent});

  @override
  Widget build(BuildContext context) {
    final total = earned <= 0 ? 1 : earned;
    final spentPct = (spent / total).clamp(0.0, 1.0);
    final keptPct = 1 - spentPct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              Expanded(
                flex: (spentPct * 1000).round().clamp(0, 1000),
                child: Container(
                  height: 14,
                  color: const Color(0xFFFF8A2B),
                ),
              ),
              Expanded(
                flex: (keptPct * 1000).round().clamp(0, 1000),
                child: Container(
                  height: 14,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.trp('wallet_spent_pct', {'n': (spentPct * 100).round()}),
              style: const TextStyle(
                  color: Color(0xFFFF8A2B),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5),
            ),
            Text(
              context.l10n.trp('wallet_saved_pct', {'n': (keptPct * 100).round()}),
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Logros ────────────────────────────────────────────────────────────────────

class _AchievementsCard extends StatelessWidget {
  final int parts;
  final int worldsOpen;
  final int worldsTotal;
  final int streak;
  final bool isVip;
  final VoidCallback onGetVip;

  const _AchievementsCard({
    required this.parts,
    required this.worldsOpen,
    required this.worldsTotal,
    required this.streak,
    required this.isVip,
    required this.onGetVip,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '🏆 ${context.l10n.tr('wallet_achievements')}',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: [
          _Tile(
            emoji: '🎽',
            value: '$parts',
            label: context.l10n.tr('wallet_parts'),
          ),
          _Tile(
            emoji: '🌍',
            value: '$worldsOpen/$worldsTotal',
            label: context.l10n.tr('wallet_worlds'),
          ),
          _Tile(
            emoji: '🔥',
            value: '$streak',
            label: context.l10n.tr('wallet_streak'),
          ),
          _Tile(
            emoji: '👑',
            value: isVip
                ? context.l10n.tr('wallet_vip_on')
                : context.l10n.tr('wallet_vip_off'),
            label: context.l10n.tr('wallet_vip'),
            highlight: isVip,
            onTap: isVip ? null : onGetVip,
            smallValue: true,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final bool highlight;
  final bool smallValue;
  final VoidCallback? onTap;

  const _Tile({
    required this.emoji,
    required this.value,
    required this.label,
    this.highlight = false,
    this.smallValue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD700);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: highlight
            ? gold.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: highlight ? gold : Colors.white24,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlight ? gold : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: smallValue ? 14 : 18,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: content,
    );
  }
}

// ── Tarjeta de sección genérica ───────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Formatea con separador de miles (1240 → "1,240").
String _fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

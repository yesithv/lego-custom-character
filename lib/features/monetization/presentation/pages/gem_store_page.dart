import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/game_snackbar.dart';
import '../../../analytics/domain/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../economy/domain/entities/wallet.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../../economy/presentation/bloc/wallet_state.dart';
import '../../domain/entities/entitlements.dart';
import '../../domain/entities/gem_product.dart';
import '../../domain/repositories/store_repository.dart';

/// Canjería de gemas: gasta gemas (moneda dura) en premios de precio fijo
/// (monedas o cosméticos). Sin azar, sin dinero real → no requiere compuerta
/// parental. Los premios se entregan sobre el wallet existente.
class GemStorePage extends StatefulWidget {
  const GemStorePage({super.key});

  @override
  State<GemStorePage> createState() => _GemStorePageState();
}

class _GemStorePageState extends State<GemStorePage> {
  final StoreRepository _store = sl<StoreRepository>();
  final AnalyticsService _analytics = sl<AnalyticsService>();

  Entitlements _ent = const Entitlements();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _analytics.track(AnalyticsEvents.gemStoreOpen);
    _load();
  }

  Future<void> _load() async {
    final e = await _store.getEntitlements();
    if (!mounted) return;
    setState(() {
      _ent = e;
      _loading = false;
    });
  }

  /// Un cosmético ya está en poder del jugador si todas sus piezas están
  /// desbloqueadas en el wallet. Sirve para no cobrar gemas por algo que ya
  /// se tiene (p. ej. la capa que vino en el pack de bienvenida).
  bool _alreadyOwned(GemProduct product, Wallet wallet) =>
      product.kind == GemRewardKind.cosmetic &&
      product.grantPartIds.isNotEmpty &&
      product.grantPartIds.every(wallet.unlockedParts.contains);

  Future<void> _redeem(GemProduct product) async {
    if (_busy) return;

    // Guarda anti doble-canje: los cosméticos son de un solo uso. Sin esto, el
    // jugador podría gastar gemas en una pieza que ya posee (la entrega en el
    // wallet es idempotente, así que perdería las gemas a cambio de nada).
    if (_alreadyOwned(product, context.read<WalletBloc>().state.wallet)) {
      _snack(context.l10n.trp('already_owned', {
        'title': context.l10n.storeProductTitle(product.id, product.title),
      }));
      return;
    }

    if (_ent.gems < product.gemPrice) {
      // Saldo insuficiente: en vez de un simple aviso, se ofrece el camino a
      // la Tienda para conseguir gemas (puente canje → compra).
      _promptBuyGems();
      return;
    }

    final confirmed = await _confirm(product);
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await _store.spendGems(product.gemPrice);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _busy = false);
      _snack(context.l10n.tr('not_enough_gems'));
      return;
    }

    // Entrega del premio sobre el wallet existente.
    switch (product.kind) {
      case GemRewardKind.coins:
        context.read<WalletBloc>().add(EarnCoinsEvent(product.coinAmount));
      case GemRewardKind.cosmetic:
        for (final partId in product.grantPartIds) {
          context.read<WalletBloc>().add(UnlockPartEvent(partId: partId, cost: 0));
        }
    }

    _analytics.track(AnalyticsEvents.gemRedeem, params: {
      'product': product.id,
      'gems': product.gemPrice,
    });

    setState(() {
      _ent = result.entitlements;
      _busy = false;
    });
    _snack(context.l10n.trp('redeemed_done', {
      'title': context.l10n.storeProductTitle(product.id, product.title),
    }));
  }

  Future<bool?> _confirm(GemProduct product) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.trp('redeem_prefix', {
          'title': context.l10n.storeProductTitle(product.id, product.title),
        })),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.l10n.tr('costs_label'),
                style: const TextStyle(fontSize: 15)),
            const Text('💎 ', style: TextStyle(fontSize: 18)),
            Text('${product.gemPrice}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.tr('redeem_action'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    showGameSnackBar(context, msg);
  }

  /// Lleva a la Tienda de dinero real (donde se compran gemas) y, al volver,
  /// refresca el saldo. Es el puente clave: "quiero esto → me faltan gemas →
  /// consigo gemas → compro".
  Future<void> _goToStore() async {
    await context.pushNamed('store');
    if (mounted) _load();
  }

  /// Aviso de saldo insuficiente que ofrece ir a la Tienda a por gemas.
  void _promptBuyGems() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0A4A9E),
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.tr('need_more_gems_go_store'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        action: SnackBarAction(
          label: context.l10n.tr('get_more_gems'),
          textColor: const Color(0xFFFFD700),
          onPressed: _goToStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063574),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text('💎 ${context.l10n.tr('redeem_gems_title')}',
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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white54))
              : BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, walletState) {
                    // Se listan de menor a mayor precio en gemas.
                    final products = [...gemStoreCatalog]
                      ..sort((a, b) => a.gemPrice.compareTo(b.gemPrice));
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _GemBalance(gems: _ent.gems),
                        const SizedBox(height: 12),
                        _GetMoreGemsCard(onTap: _goToStore),
                        const SizedBox(height: 12),
                        ...products.map((p) => _GemProductCard(
                              product: p,
                              affordable: _ent.gems >= p.gemPrice,
                              owned: _alreadyOwned(p, walletState.wallet),
                              busy: _busy,
                              onRedeem: () => _redeem(p),
                            )),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _GemBalance extends StatelessWidget {
  final int gems;
  const _GemBalance({required this.gems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          const Text('💎', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            '$gems',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 6),
          Text(context.l10n.tr('gems_available'),
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }
}

/// CTA destacado que lleva a la Tienda a comprar gemas. Es el puente de
/// conversión: desde donde el jugador *gasta* gemas, un camino claro a *conseguir*
/// más. Dorado llamativo, coherente con los botones de compra.
class _GetMoreGemsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _GetMoreGemsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.22),
                const Color(0xFFFF8A00).withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('get_more_gems'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tr('get_more_gems_sub'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFD700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GemProductCard extends StatelessWidget {
  final GemProduct product;
  final bool affordable;
  final bool owned;
  final bool busy;
  final VoidCallback onRedeem;

  const _GemProductCard({
    required this.product,
    required this.affordable,
    required this.owned,
    required this.busy,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child:
                    Text(product.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.storeProductTitle(product.id, product.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n
                      .storeProductDescription(product.id, product.description),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(context.l10n.tr('owned'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    affordable ? const Color(0xFFFFD700) : Colors.white24,
                foregroundColor:
                    affordable ? const Color(0xFF3D2C00) : Colors.white54,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onPressed: (busy || !affordable) ? null : onRedeem,
              child: Text(
                '💎 ${product.gemPrice}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../analytics/domain/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
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

  Future<void> _redeem(GemProduct product) async {
    if (_busy) return;

    if (_ent.gems < product.gemPrice) {
      _snack('No tienes suficientes gemas. Consíguelas en la Tienda.');
      return;
    }

    final confirmed = await _confirm(product);
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final result = await _store.spendGems(product.gemPrice);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _busy = false);
      _snack('No tienes suficientes gemas.');
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
    _snack('¡Canjeado! "${product.title}".');
  }

  Future<bool?> _confirm(GemProduct product) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Canjear ${product.title}'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Cuesta ', style: TextStyle(fontSize: 15)),
            const Text('💎 ', style: TextStyle(fontSize: 18)),
            Text('${product.gemPrice}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Canjear',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
        title: const Text('💎 Canjear gemas',
            style: TextStyle(fontWeight: FontWeight.w900)),
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _GemBalance(gems: _ent.gems),
                    const SizedBox(height: 12),
                    ...gemStoreCatalog.map((p) => _GemProductCard(
                          product: p,
                          affordable: _ent.gems >= p.gemPrice,
                          busy: _busy,
                          onRedeem: () => _redeem(p),
                        )),
                  ],
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
          const Text('gemas disponibles',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }
}

class _GemProductCard extends StatelessWidget {
  final GemProduct product;
  final bool affordable;
  final bool busy;
  final VoidCallback onRedeem;

  const _GemProductCard({
    required this.product,
    required this.affordable,
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
                  product.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  affordable ? const Color(0xFFFFD700) : Colors.white24,
              foregroundColor:
                  affordable ? const Color(0xFF3D2C00) : Colors.white54,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: (busy || !affordable) ? null : onRedeem,
            child: Text(
              '💎 ${product.gemPrice}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../analytics/domain/analytics_service.dart';
import '../../../analytics/domain/entities/analytics_event.dart';
import '../../../economy/presentation/bloc/wallet_bloc.dart';
import '../../../economy/presentation/bloc/wallet_event.dart';
import '../../domain/entities/entitlements.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/repositories/store_repository.dart';
import '../widgets/parental_gate.dart';

/// Tienda del juego.
///
/// Muestra el catálogo de [storeCatalog] y ejecuta las compras a través del
/// [StoreRepository] (hoy simulado). Toda compra pasa por la
/// [ParentalGate]. Los packs cosméticos desbloquean accesorios en el wallet.
class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreRepository _store = sl<StoreRepository>();
  final AnalyticsService _analytics = sl<AnalyticsService>();

  Entitlements _ent = const Entitlements();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _analytics.track(AnalyticsEvents.storeOpen);
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

  Future<void> _buy(StoreProduct product) async {
    if (_busy) return;

    final oneTime = product.type != ProductType.consumable;
    if (oneTime && _ent.owns(product.id)) {
      _snack('Ya tienes "${product.title}".');
      return;
    }

    // Compuerta parental obligatoria antes de cualquier compra.
    _analytics.track(AnalyticsEvents.parentalGateShown);
    final approved = await ParentalGate.show(context);
    if (!approved || !mounted) return;
    _analytics.track(AnalyticsEvents.parentalGatePassed);
    _analytics
        .track(AnalyticsEvents.purchaseAttempt, params: {'product': product.id});

    setState(() => _busy = true);
    final result = await _store.buy(product);
    if (!mounted) return;

    if (result.success) {
      _analytics.track(AnalyticsEvents.purchaseSuccess, params: {
        'product': product.id,
        'kind': product.kind.name,
      });
      // Los packs cosméticos desbloquean accesorios en el wallet existente.
      if (product.kind == ProductKind.cosmeticBundle) {
        for (final partId in product.grantsPartIds) {
          context.read<WalletBloc>().add(UnlockPartEvent(partId: partId, cost: 0));
        }
      }
      setState(() {
        _ent = result.entitlements;
        _busy = false;
      });
      _snack('¡Listo! "${product.title}" desbloqueado.');
    } else {
      setState(() => _busy = false);
      _snack(result.error ?? 'No se pudo completar la compra.');
    }
  }

  Future<void> _restore() async {
    final e = await _store.restorePurchases();
    if (!mounted) return;
    setState(() => _ent = e);
    _snack('Compras restauradas.');
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
        title: const Text('🛍️ Tienda',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Restaurar',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
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
                    _StatusHeader(ent: _ent),
                    const SizedBox(height: 10),
                    _RedeemGemsButton(
                      onTap: () async {
                        await context.pushNamed('gems');
                        // Al volver, refresca el saldo de gemas.
                        if (mounted) _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    const _StubBanner(),
                    const SizedBox(height: 12),
                    ...storeCatalog.map((p) => _ProductCard(
                          product: p,
                          owned: p.type != ProductType.consumable &&
                              _ent.owns(p.id),
                          busy: _busy,
                          onBuy: () => _buy(p),
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Cabecera con el estado: gemas, sin-anuncios y VIP.
class _StatusHeader extends StatelessWidget {
  final Entitlements ent;
  const _StatusHeader({required this.ent});

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
          const Text('💎', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '${ent.gems}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text('gemas',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const Spacer(),
          if (ent.adsDisabled) const _MiniBadge(emoji: '🚫', label: 'Sin ads'),
          if (ent.subscriptionActive) ...[
            const SizedBox(width: 6),
            const _MiniBadge(emoji: '👑', label: 'VIP'),
          ],
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _MiniBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$emoji $label',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

/// Botón que lleva a la canjería de gemas.
class _RedeemGemsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RedeemGemsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Row(
            children: [
              Text('💎', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Canjear gemas por premios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de que las compras son simuladas (entorno de desarrollo).
class _StubBanner extends StatelessWidget {
  const _StubBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB300), width: 1),
      ),
      child: const Row(
        children: [
          Text('🧪', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Compras simuladas (modo desarrollo). Se conectará el pago real '
              'al publicar en las tiendas.',
              style: TextStyle(color: Colors.white, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final bool owned;
  final bool busy;
  final VoidCallback onBuy;

  const _ProductCard({
    required this.product,
    required this.owned,
    required this.busy,
    required this.onBuy,
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
                child: Text(product.emoji,
                    style: const TextStyle(fontSize: 24))),
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
          owned
              ? const _OwnedChip()
              : _BuyButton(
                  label: product.priceLabel,
                  busy: busy,
                  onTap: onBuy,
                ),
        ],
      ),
    );
  }
}

class _OwnedChip extends StatelessWidget {
  const _OwnedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Adquirido',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _BuyButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF3D2C00),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: busy ? null : onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

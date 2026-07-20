import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/entitlements.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/vip_perks.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_local_datasource.dart';
import '../models/entitlements_model.dart';

/// Implementación **real** de la tienda con `in_app_purchase`
/// (Google Play Billing / Apple StoreKit). Sustituye a `StubStoreRepository`
/// cuando el proyecto tenga plataformas nativas y productos dados de alta en
/// las consolas, con los mismos IDs que [storeCatalog].
///
/// Diseño:
/// - Las **compras** y la **restauración** pasan por la tienda (dinero real).
/// - El **estado** (gemas, VIP, poseídos, regalo diario) se sigue guardando en
///   local ([StoreLocalDatasource]): la tienda confirma la compra y entonces
///   concedemos el beneficio.
/// - Los métodos que **no** implican dinero (`entitlementsSync`, `spendGems`,
///   `claimVipDaily`) son locales (idénticos al stub).
///
/// ⚠️ Requiere `flutter pub get` y **solo funciona en iOS/Android**. No se
/// registra por defecto para no afectar a la web (ver `core/di/injection.dart`).
///
/// Limitaciones conocidas (aptas para v1; endurecer luego):
/// - **Sin validación de recibos en servidor.** El estado se concede en el
///   cliente; para producción robusta, valida el recibo en un backend.
/// - **Suscripción sin control de vencimiento.** Se marca `subscriptionActive`
///   al comprar/restaurar; no se rastrea la fecha de expiración (requiere
///   backend o la App Store Server API / Play Developer API).
/// - **"Pedir permiso" (Ask to Buy):** una compra puede quedar en
///   [PurchaseStatus.pending] a la espera de aprobación parental; la UI debería
///   contemplar ese estado (aquí simplemente no se resuelve hasta que llega el
///   resultado final).
class InAppPurchaseStoreRepository implements StoreRepository {
  final StoreLocalDatasource _ds;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Compras iniciadas por nosotros, esperando confirmación del stream.
  final Map<String, Completer<PurchaseResult>> _pending = {};

  InAppPurchaseStoreRepository(this._ds, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );
  }

  /// Cancela la suscripción al stream de la tienda.
  void dispose() => _sub?.cancel();

  // ── Estado local (sin dinero) ──────────────────────────────────────────────

  @override
  Future<Entitlements> getEntitlements() async => _ds.get().toEntity();

  @override
  Entitlements entitlementsSync() => _ds.get().toEntity();

  @override
  Future<({Entitlements entitlements, bool success})> spendGems(
      int amount) async {
    var e = _ds.get().toEntity();
    if (e.gems < amount) return (entitlements: e, success: false);
    e = e.copyWith(gems: e.gems - amount);
    await _ds.save(EntitlementsModel.fromEntity(e));
    return (entitlements: e, success: true);
  }

  @override
  Future<({Entitlements entitlements, int gemsGranted})> claimVipDaily() async {
    var e = _ds.get().toEntity();
    if (!e.canClaimVipDaily) return (entitlements: e, gemsGranted: 0);
    e = e.copyWith(
      gems: e.gems + VipPerks.dailyGems,
      lastVipClaim: DateTime.now(),
    );
    await _ds.save(EntitlementsModel.fromEntity(e));
    return (entitlements: e, gemsGranted: VipPerks.dailyGems);
  }

  // ── Compras reales ─────────────────────────────────────────────────────────

  @override
  Future<PurchaseResult> buy(StoreProduct product) async {
    final current = _ds.get().toEntity();

    if (product.type != ProductType.consumable && current.owns(product.id)) {
      return PurchaseResult(
        success: false,
        entitlements: current,
        error: 'Ya tienes este producto.',
      );
    }
    if (!await _iap.isAvailable()) {
      return PurchaseResult(
        success: false,
        entitlements: current,
        error: 'La tienda no está disponible.',
      );
    }

    final response = await _iap.queryProductDetails({product.id});
    if (response.productDetails.isEmpty) {
      return PurchaseResult(
        success: false,
        entitlements: current,
        error: 'Producto no encontrado en la tienda (revisa el SKU "${product.id}").',
      );
    }

    final param = PurchaseParam(productDetails: response.productDetails.first);
    final completer = Completer<PurchaseResult>();
    _pending[product.id] = completer;

    // El diálogo nativo de compra (con control parental de la familia) aparece
    // aquí; el resultado llega por [purchaseStream] → [_onPurchases].
    if (product.type == ProductType.consumable) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
    return completer.future;
  }

  @override
  Future<Entitlements> restorePurchases() async {
    await _iap.restorePurchases();
    // Los productos restaurados llegan por el stream y se conceden ahí.
    return _ds.get().toEntity();
  }

  // ── Stream de la tienda ────────────────────────────────────────────────────

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ent = await _grant(p.productID);
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _pending.remove(p.productID)?.complete(
                PurchaseResult(success: true, entitlements: ent),
              );
        case PurchaseStatus.error:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _pending.remove(p.productID)?.complete(
                PurchaseResult(
                  success: false,
                  entitlements: _ds.get().toEntity(),
                  error: p.error?.message ?? 'Error en la compra.',
                ),
              );
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          _pending.remove(p.productID)?.complete(
                PurchaseResult(
                  success: false,
                  entitlements: _ds.get().toEntity(),
                  error: 'Compra cancelada.',
                ),
              );
        case PurchaseStatus.pending:
          // A la espera (p. ej. aprobación parental "Pedir permiso"). No se
          // resuelve el completer hasta que llegue el estado final.
          break;
      }
    }
  }

  /// Concede el beneficio de [productId] y persiste el estado. Los packs
  /// cosméticos solo se registran como poseídos; los accesorios los concede la
  /// UI sobre el wallet (igual que en el stub).
  Future<Entitlements> _grant(String productId) async {
    var e = _ds.get().toEntity();
    final product = _catalogById(productId);
    if (product != null) {
      switch (product.kind) {
        case ProductKind.gems:
          e = e.copyWith(gems: e.gems + product.gemAmount);
        case ProductKind.removeAds:
          e = e.copyWith(adsRemoved: true);
        case ProductKind.subscription:
          e = e.copyWith(subscriptionActive: true);
        case ProductKind.cosmeticBundle:
          break;
      }
    }
    if (!e.owns(productId)) {
      e = e.copyWith(ownedProductIds: [...e.ownedProductIds, productId]);
    }
    await _ds.save(EntitlementsModel.fromEntity(e));
    return e;
  }

  StoreProduct? _catalogById(String id) {
    for (final p in storeCatalog) {
      if (p.id == id) return p;
    }
    return null;
  }
}

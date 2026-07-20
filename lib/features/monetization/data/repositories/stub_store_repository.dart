import '../../domain/entities/entitlements.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/vip_perks.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_local_datasource.dart';
import '../models/entitlements_model.dart';

/// Implementación **simulada** de la tienda para desarrollo.
///
/// No cobra nada: aplica el efecto de la compra en local y lo persiste en
/// Hive, de modo que la Tienda se puede construir y probar sin plugins nativos
/// ni configurar productos en Google Play / App Store. Cuando se conecte el
/// pago real, se sustituye por un adaptador de `in_app_purchase` en
/// `injection.dart` sin tocar la UI.
class StubStoreRepository implements StoreRepository {
  final StoreLocalDatasource _ds;
  StubStoreRepository(this._ds);

  @override
  Future<Entitlements> getEntitlements() async => _ds.get().toEntity();

  @override
  Entitlements entitlementsSync() => _ds.get().toEntity();

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

  @override
  Future<PurchaseResult> buy(StoreProduct product) async {
    // Simula la latencia de la tienda.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    var e = _ds.get().toEntity();

    // No permitir recomprar no consumibles ya poseídos.
    final isOneTime = product.type != ProductType.consumable;
    if (isOneTime && e.owns(product.id)) {
      return PurchaseResult(
        success: false,
        entitlements: e,
        error: 'Ya tienes este producto.',
      );
    }

    switch (product.kind) {
      case ProductKind.gems:
        e = e.copyWith(gems: e.gems + product.gemAmount);
      case ProductKind.removeAds:
        e = e.copyWith(adsRemoved: true);
      case ProductKind.subscription:
        e = e.copyWith(subscriptionActive: true);
      case ProductKind.cosmeticBundle:
        // El desbloqueo de accesorios lo aplica la UI sobre el wallet; aquí
        // solo se registra la posesión del pack.
        break;
    }

    if (!e.owns(product.id)) {
      e = e.copyWith(ownedProductIds: [...e.ownedProductIds, product.id]);
    }

    await _ds.save(EntitlementsModel.fromEntity(e));
    return PurchaseResult(success: true, entitlements: e);
  }

  @override
  Future<Entitlements> restorePurchases() async => _ds.get().toEntity();

  @override
  Future<({Entitlements entitlements, bool success})> spendGems(
      int amount) async {
    var e = _ds.get().toEntity();
    if (e.gems < amount) return (entitlements: e, success: false);
    e = e.copyWith(gems: e.gems - amount);
    await _ds.save(EntitlementsModel.fromEntity(e));
    return (entitlements: e, success: true);
  }
}

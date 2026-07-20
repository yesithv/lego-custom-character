import '../entities/entitlements.dart';
import '../entities/store_product.dart';

/// Resultado de un intento de compra.
class PurchaseResult {
  final bool success;
  final Entitlements entitlements;

  /// Motivo del fallo/cancelación (null si tuvo éxito).
  final String? error;

  const PurchaseResult({
    required this.success,
    required this.entitlements,
    this.error,
  });
}

/// Puerta de entrada a la monetización, **agnóstica del proveedor**.
///
/// La implementación actual ([StubStoreRepository]) simula las compras en
/// local para poder construir y probar la Tienda sin plugins nativos ni
/// configurar productos en las consolas. Para pasar a compras reales basta con
/// sustituir la implementación en `injection.dart` por un adaptador de
/// `in_app_purchase` — igual que el patrón de `ScoreRepository`.
abstract class StoreRepository {
  /// Estado actual de desbloqueos (gemas, sin-anuncios, VIP, poseídos).
  Future<Entitlements> getEntitlements();

  /// Lectura síncrona del estado (para consultas en caliente, p. ej. el
  /// multiplicador de monedas VIP al arrancar una carrera).
  Entitlements entitlementsSync();

  /// Reclama el regalo diario VIP si procede. Devuelve el estado actualizado y
  /// cuántas gemas se otorgaron (0 si no era VIP o ya se reclamó hoy).
  Future<({Entitlements entitlements, int gemsGranted})> claimVipDaily();

  /// Intenta comprar [product]. La **compuerta parental** es responsabilidad
  /// de la capa de presentación: llámala antes de invocar esto.
  Future<PurchaseResult> buy(StoreProduct product);

  /// Restaura compras no consumibles / suscripción (requisito de las tiendas).
  Future<Entitlements> restorePurchases();

  /// Gasta [amount] gemas si hay saldo suficiente. Devuelve el estado
  /// actualizado y si tuvo éxito. La entrega del premio (monedas/cosméticos)
  /// la orquesta la capa de presentación sobre el wallet.
  Future<({Entitlements entitlements, bool success})> spendGems(int amount);
}

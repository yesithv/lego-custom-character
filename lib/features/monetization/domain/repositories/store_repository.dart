import '../entities/entitlements.dart';
import '../entities/store_product.dart';

/// Resultado de un intento de compra.
class PurchaseResult {
  final bool success;
  final Entitlements entitlements;

  /// La compra quedó **pendiente** de una acción externa (típicamente la
  /// aprobación de un adulto vía "Pedir permiso" / Ask to Buy). No es un éxito
  /// ni un fallo: el beneficio se concederá más tarde, cuando la tienda
  /// confirme la compra, y se reflejará al recargar la Tienda.
  final bool pending;

  /// Motivo del fallo/cancelación (null si tuvo éxito o quedó pendiente).
  final String? error;

  const PurchaseResult({
    required this.success,
    required this.entitlements,
    this.pending = false,
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

  /// Precios reales y **localizados** (moneda del usuario, ya formateados por
  /// la tienda) de los productos [ids]. La clave es el id del producto; el
  /// valor, el precio a mostrar. Los ids que la tienda no devuelva se omiten
  /// del mapa: la UI debe caer al `priceLabel` de relleno del catálogo. En web
  /// (stub) el mapa va vacío porque no hay tienda real.
  Future<Map<String, String>> loadPrices(Set<String> ids);

  /// Intenta comprar [product]. La **compuerta parental** es responsabilidad
  /// de la capa de presentación: llámala antes de invocar esto.
  Future<PurchaseResult> buy(StoreProduct product);

  /// Restaura compras no consumibles / suscripción (requisito de las tiendas).
  Future<Entitlements> restorePurchases();

  /// Gasta [amount] gemas si hay saldo suficiente. Devuelve el estado
  /// actualizado y si tuvo éxito. La entrega del premio (monedas/cosméticos)
  /// la orquesta la capa de presentación sobre el wallet.
  Future<({Entitlements entitlements, bool success})> spendGems(int amount);

  /// Regala [amount] gemas al jugador (faucet gratuito: recompensa por
  /// completar misiones, hitos, etc.). No implica dinero real. Devuelve el
  /// estado actualizado. Da a las gemas una vía de obtención jugando, para que
  /// no sean una moneda inalcanzable para quien no paga.
  Future<Entitlements> grantGems(int amount);
}

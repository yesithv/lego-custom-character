/// Catálogo de productos de la tienda (monetización).
///
/// Es **agnóstico del proveedor**: aquí solo se describen los productos. La
/// compra real la resuelve un [StoreRepository] (hoy un stub simulado; mañana
/// un adaptador de `in_app_purchase` / suscripciones de las tiendas).
///
/// ⚠️ Producto **para niños**: todos los productos son cosméticos, de
/// conveniencia o quitar-anuncios. Nada de pago-para-ganar ni cajas de botín
/// con dinero real. La compra siempre pasa por una compuerta parental.
library;

/// Qué entrega el producto al comprarse.
enum ProductKind {
  /// Moneda dura consumible (gemas).
  gems,

  /// Quita los anuncios de forma permanente.
  removeAds,

  /// Suscripción VIP (sin anuncios + gemas diarias + extras).
  subscription,

  /// Pack cosmético: desbloquea accesorios del editor.
  cosmeticBundle,
}

/// Tipo de compra a efectos de la tienda nativa.
enum ProductType { consumable, nonConsumable, subscription }

/// Un producto de la tienda. El `id` es el SKU que se configurará igual en
/// Google Play Console y App Store Connect cuando se conecte el pago real.
class StoreProduct {
  final String id;
  final String title;
  final String description;

  /// Precio a mostrar. Placeholder hasta que la tienda real devuelva el
  /// precio localizado (moneda del usuario). No lo uses para lógica.
  final String priceLabel;

  final ProductKind kind;
  final ProductType type;
  final String emoji;

  /// Gemas que otorga (solo [ProductKind.gems]).
  final int gemAmount;

  /// Accesorios que desbloquea (solo [ProductKind.cosmeticBundle]); ids del
  /// `partCatalog` del editor.
  final List<String> grantsPartIds;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.kind,
    required this.type,
    required this.emoji,
    this.gemAmount = 0,
    this.grantsPartIds = const [],
  });
}

/// Catálogo de la tienda. Precios de ejemplo — ajústalos y replícalos como
/// SKUs en las consolas de las tiendas antes de conectar el pago real.
const storeCatalog = <StoreProduct>[
  // Nota: el juego NO tiene anuncios (decisión de producto), por eso no hay
  // producto "quitar anuncios". El VIP se centra en valor tangible.
  StoreProduct(
    id: 'vip_monthly',
    title: 'Club VIP',
    description: 'Gemas diarias + monedas x1.5 en cada carrera.',
    priceLabel: 'USD 4.99 / mes',
    kind: ProductKind.subscription,
    type: ProductType.subscription,
    emoji: '👑',
  ),
  StoreProduct(
    id: 'gems_small',
    title: 'Puñado de gemas',
    description: '100 gemas para la tienda.',
    priceLabel: 'USD 1.99',
    kind: ProductKind.gems,
    type: ProductType.consumable,
    emoji: '💎',
    gemAmount: 100,
  ),
  StoreProduct(
    id: 'gems_medium',
    title: 'Cofre de gemas',
    description: '550 gemas (¡+10% extra!).',
    priceLabel: 'USD 8.99',
    kind: ProductKind.gems,
    type: ProductType.consumable,
    emoji: '💎',
    gemAmount: 550,
  ),
  StoreProduct(
    id: 'bundle_starter',
    title: 'Pack de bienvenida',
    description: 'Jetpack, alas, varita y antifaz para tu corredor.',
    priceLabel: 'USD 3.99',
    kind: ProductKind.cosmeticBundle,
    type: ProductType.nonConsumable,
    emoji: '🎁',
    grantsPartIds: ['jetpack', 'alas', 'varita', 'antifaz'],
  ),
];

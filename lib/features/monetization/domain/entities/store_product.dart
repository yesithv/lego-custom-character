/// Catálogo de productos de la tienda (monetización).
///
/// Es **agnóstico del proveedor**: aquí solo se describen los productos. La
/// compra la resuelve un [StoreRepository]: en móvil,
/// `InAppPurchaseStoreRepository` (Google Play Billing / StoreKit); en la demo
/// web, `StubStoreRepository` (simulada, sin cobrar).
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

/// Un producto de la tienda. El `id` **es** el SKU: tiene que existir con
/// exactamente el mismo identificador en Google Play Console (y en App Store
/// Connect cuando se publique en iOS), o la compra fallará con "producto no
/// encontrado".
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

  /// Gemas que otorga. Para [ProductKind.gems] es el paquete; para un
  /// [ProductKind.cosmeticBundle] (p. ej. el pack de bienvenida) son las gemas
  /// extra que trae el pack.
  final int gemAmount;

  /// Monedas que otorga (packs de valor como el de bienvenida). La entrega la
  /// hace la capa de presentación sobre el wallet.
  final int coinAmount;

  /// Accesorios que desbloquea (solo [ProductKind.cosmeticBundle]); ids del
  /// `partCatalog` del editor.
  final List<String> grantsPartIds;

  /// Etiqueta corta de marketing para la tarjeta (p. ej. "MÁS POPULAR",
  /// "MEJOR VALOR", "AHORRA 50%"). Null = sin etiqueta.
  final String? badge;

  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.kind,
    required this.type,
    required this.emoji,
    this.gemAmount = 0,
    this.coinAmount = 0,
    this.grantsPartIds = const [],
    this.badge,
  });
}

/// Catálogo de la tienda. Precios de ejemplo — ajústalos y replícalos como
/// SKUs en las consolas de las tiendas antes de conectar el pago real.
///
/// Orden pensado para la conversión: primero el pack de bienvenida (gancho de
/// primera compra), luego VIP (recurrente, el de mayor LTV), luego la escalera
/// de gemas con bonus creciente. Ver `docs/ECONOMIA.md`.
///
/// Nota: el juego NO tiene anuncios (decisión de producto), por eso no hay
/// producto "quitar anuncios". El VIP se centra en valor tangible.
const storeCatalog = <StoreProduct>[
  // ── Pack de bienvenida: gancho de primera compra (una sola vez) ─────────────
  // Valor percibido ~3-4x el precio: gemas + monedas + un cosmético EXCLUSIVO
  // que no se consigue de otra forma barata.
  StoreProduct(
    id: 'bundle_starter',
    title: 'Pack de bienvenida',
    description: 'Capa vampiro EXCLUSIVA + 150 💎 + 1000 🪙. Solo una vez.',
    priceLabel: 'USD 2.99',
    kind: ProductKind.cosmeticBundle,
    type: ProductType.nonConsumable,
    emoji: '🎁',
    gemAmount: 150,
    coinAmount: 1000,
    grantsPartIds: ['capa vampiro'],
    badge: 'OFERTA ÚNICA',
  ),
  // ── Club VIP: recurrente, el de mayor valor a largo plazo ───────────────────
  StoreProduct(
    id: 'vip_monthly',
    title: 'Club VIP',
    description: '25 💎 cada día + monedas x1.5 en cada carrera + regalo VIP.',
    priceLabel: 'USD 4.99 / mes',
    kind: ProductKind.subscription,
    type: ProductType.subscription,
    emoji: '👑',
    badge: 'MÁS POPULAR',
  ),
  StoreProduct(
    id: 'vip_yearly',
    title: 'Club VIP anual',
    description: 'Todo el VIP, todo el año. Ahorras ~50% frente al mensual.',
    priceLabel: 'USD 29.99 / año',
    kind: ProductKind.subscription,
    type: ProductType.subscription,
    emoji: '👑',
    badge: 'AHORRA 50%',
  ),
  // ── Escalera de gemas (bonus creciente) ─────────────────────────────────────
  StoreProduct(
    id: 'gems_small',
    title: 'Puñado de gemas',
    description: '200 gemas para la Tienda.',
    priceLabel: 'USD 1.99',
    kind: ProductKind.gems,
    type: ProductType.consumable,
    emoji: '💎',
    gemAmount: 200,
  ),
  StoreProduct(
    id: 'gems_medium',
    title: 'Cofre de gemas',
    description: '550 gemas (¡+10% extra!).',
    priceLabel: 'USD 4.99',
    kind: ProductKind.gems,
    type: ProductType.consumable,
    emoji: '💎',
    gemAmount: 550,
  ),
  StoreProduct(
    id: 'gems_large',
    title: 'Baúl de gemas',
    description: '1200 gemas (¡+20% extra!).',
    priceLabel: 'USD 9.99',
    kind: ProductKind.gems,
    type: ProductType.consumable,
    emoji: '💎',
    gemAmount: 1200,
    badge: 'MEJOR VALOR',
  ),
];

/// Productos que se compran con **gemas** (moneda dura) a precio fijo.
///
/// ⚠️ Kid-safe: precios **transparentes y deterministas**, sin azar ni cajas
/// de botín. Las gemas canjean monedas o cosméticos concretos que el jugador
/// ve antes de canjear. La entrega se hace sobre el wallet existente
/// (`EarnCoinsEvent` para monedas, `UnlockPartEvent` para accesorios).
library;

enum GemRewardKind { coins, cosmetic }

class GemProduct {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int gemPrice;
  final GemRewardKind kind;

  /// Monedas que otorga (solo [GemRewardKind.coins]).
  final int coinAmount;

  /// Accesorios que desbloquea (solo [GemRewardKind.cosmetic]); ids del
  /// `partCatalog`.
  final List<String> grantPartIds;

  const GemProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.gemPrice,
    required this.kind,
    this.coinAmount = 0,
    this.grantPartIds = const [],
  });
}

/// Catálogo de la canjería de gemas.
///
/// Diseño coherente (ver `docs/ECONOMIA.md`):
/// - **Monedas por gemas** = conveniencia: te saltas el farmeo. Ancla ~12–17
///   monedas por gema, con mejor tasa en el paquete grande.
/// - **Cosméticos** = SOLO piezas `premium` (exclusivas): no se pueden comprar
///   con monedas, así que la gema es la única vía y nunca queda "dominada" por
///   una compra en monedas más barata.
const gemStoreCatalog = <GemProduct>[
  // ── Cosméticos EXCLUSIVOS (solo con gemas) ──────────────────────────────────
  GemProduct(
    id: 'gem_capa_vampiro',
    title: 'Capa vampiro ✨',
    description: 'Cosmético EXCLUSIVO. No se consigue con monedas.',
    emoji: '🧛',
    gemPrice: 120,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['capa vampiro'],
  ),
  GemProduct(
    id: 'gem_botas',
    title: 'Botas de propulsión ✨',
    description: 'Cosmético EXCLUSIVO. No se consigue con monedas.',
    emoji: '🚀',
    gemPrice: 140,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['botas propulsión'],
  ),
  // ── Monedas por gemas (conveniencia) ────────────────────────────────────────
  GemProduct(
    id: 'coins_500',
    title: '500 monedas',
    description: 'Un empujón para la tienda de piezas.',
    emoji: '🪙',
    gemPrice: 40,
    kind: GemRewardKind.coins,
    coinAmount: 500,
  ),
  GemProduct(
    id: 'coins_1500',
    title: '1500 monedas',
    description: 'Bolsa grande de monedas.',
    emoji: '💰',
    gemPrice: 100,
    kind: GemRewardKind.coins,
    coinAmount: 1500,
  ),
  GemProduct(
    id: 'coins_4000',
    title: '4000 monedas',
    description: '¡Mejor valor! Cofre enorme de monedas.',
    emoji: '💰',
    gemPrice: 240,
    kind: GemRewardKind.coins,
    coinAmount: 4000,
  ),
];

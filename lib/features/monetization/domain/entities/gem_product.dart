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

/// Catálogo de la canjería de gemas. Ajusta precios/premios a tu gusto.
const gemStoreCatalog = <GemProduct>[
  // ── Monedas ────────────────────────────────────────────────────────────────
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
  // ── Cosméticos (deterministas) ──────────────────────────────────────────────
  GemProduct(
    id: 'gem_jetpack',
    title: 'Jetpack',
    description: 'Accesorio de espalda.',
    emoji: '🎒',
    gemPrice: 50,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['jetpack'],
  ),
  GemProduct(
    id: 'gem_medallon',
    title: 'Medallón dorado',
    description: 'Accesorio de cuello.',
    emoji: '🥇',
    gemPrice: 50,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['medallón'],
  ),
  GemProduct(
    id: 'gem_capa_vampiro',
    title: 'Capa vampiro',
    description: 'Accesorio épico de espalda.',
    emoji: '🧛',
    gemPrice: 120,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['capa vampiro'],
  ),
  GemProduct(
    id: 'gem_botas',
    title: 'Botas de propulsión',
    description: 'Accesorio épico de pies.',
    emoji: '🚀',
    gemPrice: 120,
    kind: GemRewardKind.cosmetic,
    grantPartIds: ['botas propulsión'],
  ),
];

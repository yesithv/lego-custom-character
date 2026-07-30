import '../../../character_editor/domain/entities/character.dart';
import 'part_catalog.dart';
import 'reward.dart';

/// Entrada ponderada de una tabla de premios: un premio y su peso relativo.
typedef WeightedReward = ({int weight, Reward prize});

// ─────────────────────────────────────────────────────────────────────────────
//  Sistema de premios ESCALABLE
//
//  Los accesorios que reparten la ruleta y los cofres NO se listan a mano. Se
//  derivan del catálogo único de piezas (`partCatalog`). Ventajas:
//
//   1. Todo premio de accesorio usa un `partId` real del catálogo → siempre es
//      equipable en el editor (antes se usaban ids inventados como `hat_1`,
//      `wings`, `crown`… que no existían y no servían para nada).
//   2. El nombre y la rareza salen del catálogo → nunca se desincronizan.
//   3. Al agregar un accesorio nuevo NO premium al catálogo, entra solo al
//      reparto de la ruleta y los cofres, sin tocar este archivo.
// ─────────────────────────────────────────────────────────────────────────────

/// Construye un [PartReward] a partir de un id del catálogo, tomando nombre y
/// rareza de la única fuente de verdad. Lanza si el id no existe (lo cubre un
/// test), para que un premio roto no llegue nunca a producción.
PartReward partRewardFromCatalog(String id) {
  final entry = partCatalog[id];
  if (entry == null) {
    throw ArgumentError('Premio inválido: "$id" no existe en partCatalog');
  }
  return PartReward(
    partId: entry.id,
    partName: entry.name,
    rarity: entry.rarity,
  );
}

/// Accesorios que pueden caer como premio (ruleta / cofres).
///
/// Regla: **no premium** (los premium son exclusivos de la Tienda: se pagan con
/// gemas o dinero real, nunca deben caer gratis) y **no gratis** (los comunes
/// gratis ya están disponibles en el editor; regalarlos como premio no aporta
/// nada). En la práctica: los que cuestan monedas (rares y epics), más cualquier
/// legendario que se agregue en el futuro.
Iterable<CatalogEntry> get droppableAccessories =>
    partCatalog.values.where((e) => !e.premium && !e.isFree);

/// Peso relativo base de un accesorio según su rareza: cuanto más raro, menos
/// probable individualmente.
double _accessoryRarityWeight(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => 12,
      AccessoryRarity.rare => 6,
      AccessoryRarity.epic => 2,
      AccessoryRarity.legendary => 1,
    };

/// Valor en monedas de "consuelo" cuando el accesorio premiado ya se posee, para
/// que ningún cofre/ruleta se sienta vacío. Escala con la rareza.
int coinValueForRarity(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => 50,
      AccessoryRarity.rare => 150,
      AccessoryRarity.epic => 350,
      AccessoryRarity.legendary => 750,
    };

/// Construye una tabla de premios ponderada combinando recompensas de monedas
/// fijas con el pool de accesorios derivado del catálogo.
///
/// [accessoryFraction] es la probabilidad objetivo de que salga *cualquier*
/// accesorio (0..1). El bucket de accesorios se normaliza a ese objetivo, así la
/// proporción monedas/accesorios se mantiene estable **aunque el catálogo
/// crezca**: agregar 20 accesorios nuevos da más variedad, no dispara la
/// probabilidad global de accesorio.
List<WeightedReward> buildRewardTable({
  required List<WeightedReward> coinRewards,
  required Set<AccessoryRarity> accessoryRarities,
  required double accessoryFraction,
}) {
  final table = <WeightedReward>[...coinRewards];

  final pool = droppableAccessories
      .where((e) => accessoryRarities.contains(e.rarity))
      .toList();
  final coinTotal = coinRewards.fold<int>(0, (s, e) => s + e.weight);
  if (pool.isEmpty || accessoryFraction <= 0 || coinTotal <= 0) return table;

  // A / (A + C) = f  →  A = C * f / (1 - f)
  final f = accessoryFraction.clamp(0.0, 0.95);
  final accBudget = coinTotal * f / (1 - f);

  final rawTotal =
      pool.fold<double>(0, (s, e) => s + _accessoryRarityWeight(e.rarity));
  for (final e in pool) {
    final share = _accessoryRarityWeight(e.rarity) / rawTotal;
    final w = (accBudget * share).round().clamp(1, 1 << 30);
    table.add((weight: w, prize: partRewardFromCatalog(e.id)));
  }
  return table;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tablas concretas (se calculan una sola vez al primer uso)
// ─────────────────────────────────────────────────────────────────────────────

/// Ruleta diaria: sobre todo monedas, con un toque de accesorios rare/epic.
final List<WeightedReward> roulettePrizeTable = buildRewardTable(
  coinRewards: const [
    (weight: 30, prize: CoinsReward(50)),
    (weight: 25, prize: CoinsReward(100)),
    (weight: 15, prize: CoinsReward(200)),
    (weight: 10, prize: CoinsReward(500)),
  ],
  accessoryRarities: const {AccessoryRarity.rare, AccessoryRarity.epic},
  accessoryFraction: 0.20,
);

/// Cofre común (fin de carrera): monedas modestas + accesorios rare/epic.
final List<WeightedReward> commonChestPrizeTable = buildRewardTable(
  coinRewards: const [
    (weight: 50, prize: CoinsReward(30)),
    (weight: 25, prize: CoinsReward(75)),
  ],
  accessoryRarities: const {AccessoryRarity.rare, AccessoryRarity.epic},
  accessoryFraction: 0.30,
);

/// Cofre VIP: monedas generosas y, sobre todo, accesorios (incluye legendarios
/// en cuanto existan en el catálogo).
final List<WeightedReward> vipChestPrizeTable = buildRewardTable(
  coinRewards: const [
    (weight: 30, prize: CoinsReward(150)),
  ],
  accessoryRarities: const {
    AccessoryRarity.rare,
    AccessoryRarity.epic,
    AccessoryRarity.legendary,
  },
  accessoryFraction: 0.65,
);

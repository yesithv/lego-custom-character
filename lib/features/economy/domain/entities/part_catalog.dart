import '../../../character_editor/domain/entities/character.dart';

class CatalogEntry {
  final String id;
  final String name;
  final String slot;
  final AccessoryRarity rarity;
  final int coinCost;

  const CatalogEntry({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    this.coinCost = 0,
  });

  bool get isFree => coinCost == 0;
}

// Coin costs by rarity
int coinCostForRarity(AccessoryRarity r) {
  if (r == AccessoryRarity.common) return 0;
  if (r == AccessoryRarity.rare) return 200;
  if (r == AccessoryRarity.epic) return 500;
  return 1000;
}

const partCatalog = <String, CatalogEntry>{
  // ── Right hand ─────────────────────────────────────────────────────────────
  'pistola': CatalogEntry(id: 'pistola', name: 'Pistola', slot: 'rightHand', rarity: AccessoryRarity.common),
  'espada': CatalogEntry(id: 'espada', name: 'Espada', slot: 'rightHand', rarity: AccessoryRarity.common),
  'varita': CatalogEntry(id: 'varita', name: 'Varita mágica', slot: 'rightHand', rarity: AccessoryRarity.rare, coinCost: 200),
  'antorcha': CatalogEntry(id: 'antorcha', name: 'Antorcha', slot: 'rightHand', rarity: AccessoryRarity.common),
  'micrófono': CatalogEntry(id: 'micrófono', name: 'Micrófono', slot: 'rightHand', rarity: AccessoryRarity.common),
  'helado': CatalogEntry(id: 'helado', name: 'Helado', slot: 'rightHand', rarity: AccessoryRarity.common),
  'cetro real': CatalogEntry(id: 'cetro real', name: 'Cetro de princesa', slot: 'rightHand', rarity: AccessoryRarity.common),
  'globo corazón': CatalogEntry(id: 'globo corazón', name: 'Globo de corazón', slot: 'rightHand', rarity: AccessoryRarity.common),

  // ── Left hand ──────────────────────────────────────────────────────────────
  'bolso': CatalogEntry(id: 'bolso', name: 'Bolso', slot: 'leftHand', rarity: AccessoryRarity.common),
  'linterna': CatalogEntry(id: 'linterna', name: 'Linterna', slot: 'leftHand', rarity: AccessoryRarity.common),
  'escudo': CatalogEntry(id: 'escudo', name: 'Escudo', slot: 'leftHand', rarity: AccessoryRarity.common),
  'libro': CatalogEntry(id: 'libro', name: 'Libro', slot: 'leftHand', rarity: AccessoryRarity.common),
  'bomba': CatalogEntry(id: 'bomba', name: 'Bomba', slot: 'leftHand', rarity: AccessoryRarity.epic, coinCost: 500),
  'escoba': CatalogEntry(id: 'escoba', name: 'Escoba de bruja', slot: 'leftHand', rarity: AccessoryRarity.rare, coinCost: 200),
  'peluche': CatalogEntry(id: 'peluche', name: 'Osito de peluche', slot: 'leftHand', rarity: AccessoryRarity.common),
  'espejo': CatalogEntry(id: 'espejo', name: 'Espejo de mano', slot: 'leftHand', rarity: AccessoryRarity.common),

  // ── Back ───────────────────────────────────────────────────────────────────
  'capa corta': CatalogEntry(id: 'capa corta', name: 'Capa corta', slot: 'back', rarity: AccessoryRarity.common),
  'mochila': CatalogEntry(id: 'mochila', name: 'Mochila', slot: 'back', rarity: AccessoryRarity.common),
  'jetpack': CatalogEntry(id: 'jetpack', name: 'Jetpack', slot: 'back', rarity: AccessoryRarity.rare, coinCost: 200),
  'alas': CatalogEntry(id: 'alas', name: 'Alas', slot: 'back', rarity: AccessoryRarity.rare, coinCost: 200),
  'capa vampiro': CatalogEntry(id: 'capa vampiro', name: 'Capa vampiro', slot: 'back', rarity: AccessoryRarity.epic, coinCost: 500),
  'alas mariposa': CatalogEntry(id: 'alas mariposa', name: 'Alas de mariposa', slot: 'back', rarity: AccessoryRarity.common),

  // ── Shoulders ──────────────────────────────────────────────────────────────
  'hombreras': CatalogEntry(id: 'hombreras', name: 'Hombreras', slot: 'shoulders', rarity: AccessoryRarity.common),
  'loro pirata': CatalogEntry(id: 'loro pirata', name: 'Loro pirata', slot: 'shoulders', rarity: AccessoryRarity.rare, coinCost: 200),
  'insignia': CatalogEntry(id: 'insignia', name: 'Insignia de rango', slot: 'shoulders', rarity: AccessoryRarity.epic, coinCost: 500),
  'gatito': CatalogEntry(id: 'gatito', name: 'Gatito', slot: 'shoulders', rarity: AccessoryRarity.common),

  // ── Waist ──────────────────────────────────────────────────────────────────
  'cinturón herramientas': CatalogEntry(id: 'cinturón herramientas', name: 'Cinturón herramientas', slot: 'waist', rarity: AccessoryRarity.common),
  'faja ninja': CatalogEntry(id: 'faja ninja', name: 'Faja ninja', slot: 'waist', rarity: AccessoryRarity.rare, coinCost: 200),
  'correa cowboy': CatalogEntry(id: 'correa cowboy', name: 'Correa cowboy', slot: 'waist', rarity: AccessoryRarity.common),
  'tutú': CatalogEntry(id: 'tutú', name: 'Tutú de bailarina', slot: 'waist', rarity: AccessoryRarity.common),

  // ── Neck ───────────────────────────────────────────────────────────────────
  'collar': CatalogEntry(id: 'collar', name: 'Collar', slot: 'neck', rarity: AccessoryRarity.common),
  'corbata': CatalogEntry(id: 'corbata', name: 'Corbata', slot: 'neck', rarity: AccessoryRarity.common),
  'medallón': CatalogEntry(id: 'medallón', name: 'Medallón dorado', slot: 'neck', rarity: AccessoryRarity.rare, coinCost: 200),
  'bufanda': CatalogEntry(id: 'bufanda', name: 'Bufanda', slot: 'neck', rarity: AccessoryRarity.common),
  'perlas': CatalogEntry(id: 'perlas', name: 'Collar de perlas', slot: 'neck', rarity: AccessoryRarity.common),
  'bandana': CatalogEntry(id: 'bandana', name: 'Bandana amarilla', slot: 'neck', rarity: AccessoryRarity.common),

  // ── Face ───────────────────────────────────────────────────────────────────
  'gafas de sol': CatalogEntry(id: 'gafas de sol', name: 'Gafas de sol', slot: 'face', rarity: AccessoryRarity.common),
  'antifaz': CatalogEntry(id: 'antifaz', name: 'Antifaz', slot: 'face', rarity: AccessoryRarity.rare, coinCost: 200),
  'parche pirata': CatalogEntry(id: 'parche pirata', name: 'Parche pirata', slot: 'face', rarity: AccessoryRarity.common),
  'máscara': CatalogEntry(id: 'máscara', name: 'Máscara de gas', slot: 'face', rarity: AccessoryRarity.epic, coinCost: 500),
  'moño rosa': CatalogEntry(id: 'moño rosa', name: 'Moño rosa', slot: 'face', rarity: AccessoryRarity.common),
  'pendientes': CatalogEntry(id: 'pendientes', name: 'Pendientes', slot: 'face', rarity: AccessoryRarity.common),
  'ojo biónico': CatalogEntry(id: 'ojo biónico', name: 'Ojo biónico', slot: 'face', rarity: AccessoryRarity.common),
  'gafas tácticas': CatalogEntry(id: 'gafas tácticas', name: 'Gafas tácticas', slot: 'face', rarity: AccessoryRarity.common),

  // ── Feet ───────────────────────────────────────────────────────────────────
  'espuelas': CatalogEntry(id: 'espuelas', name: 'Espuelas cowboy', slot: 'feet', rarity: AccessoryRarity.common),
  'tobilleras': CatalogEntry(id: 'tobilleras', name: 'Tobilleras', slot: 'feet', rarity: AccessoryRarity.common),
  'botas propulsión': CatalogEntry(id: 'botas propulsión', name: 'Botas de propulsión', slot: 'feet', rarity: AccessoryRarity.epic, coinCost: 500),
  'moños zapatos': CatalogEntry(id: 'moños zapatos', name: 'Moños en los zapatos', slot: 'feet', rarity: AccessoryRarity.common),
};

List<CatalogEntry> catalogForSlot(String slot) =>
    partCatalog.values.where((e) => e.slot == slot).toList();

CatalogEntry? catalogEntry(String id) => partCatalog[id];

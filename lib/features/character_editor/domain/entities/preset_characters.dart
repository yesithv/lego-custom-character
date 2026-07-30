import 'character.dart';

/// A preset (preconfigured) character: a ready-made name + appearance that the
/// user can load into the editor and then freely modify.
class PresetCharacter {
  final String id;
  final String name;
  final String collection; // e.g. 'Ninjas dorados', 'Superhéroes'
  final CharacterType type;
  final CharacterAppearance appearance;

  const PresetCharacter({
    required this.id,
    required this.name,
    required this.collection,
    required this.type,
    required this.appearance,
  });
}

/// All bundled preconfigured characters, grouped by collection.
/// Selecting one loads its full configuration into the editor as a brand-new
/// (editable) character, so the user can tweak the mouth, hair, etc.
const List<PresetCharacter> presetCharacters = [
  // ── Colección: Ninjas dorados ──────────────────────────────────────────────
  PresetCharacter(
    id: 'preset_ninja_dorado',
    name: 'Ninja Dorado',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.silent,
      eyebrows: EyebrowStyle.angry,
      facialExtra: FacialExtra.warPaint,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ninjaHood,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.legArmor,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana dorada',
        leftHand: 'escudo dragón',
        back: 'katanas dobles',
        shoulders: 'hombreras doradas',
        waist: 'faja ninja',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_maestro_wu',
    name: 'Maestro Wu',
    collection: 'Ninjas dorados',
    type: CharacterType.mysterious,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.hat,
      hatStyle: HatStyle.conical,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.sandals,
      accessories: CharacterAccessories(
        rightHand: 'bastón bo',
        face: 'barba larga',
        waist: 'faja ninja',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_kai',
    name: 'Kai',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.teeth,
      eyebrows: EyebrowStyle.angry,
      facialExtra: FacialExtra.scar,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ninjaHood,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.legArmor,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana',
        back: 'katanas dobles',
        shoulders: 'hombreras doradas',
        waist: 'faja ninja',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_kora',
    name: 'Kora',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.wink,
      mouth: MouthStyle.smile,
      eyebrows: EyebrowStyle.arched,
      facialExtra: FacialExtra.blush,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.braids,
      gloves: GloveType.boxing,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      // Falda de placas doradas sobre la armadura: misma protección,
      // silueta distinta
      legType: LegType.skirt,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'bastón bo',
        neck: 'bandana',
        waist: 'faja ninja',
        face: 'moño rosa',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_nya',
    name: 'Nya',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.smile,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.ponytail,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        leftHand: 'escudo dragón',
        waist: 'faja ninja',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_zaina',
    name: 'Zaina',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      // Los ojos "estrellados" se pierden sobre la piel dorada: la mirada
      // esmeralda con sombra sí destaca y remata el gesto femenino.
      eyes: EyeStyle.emerald,
      mouth: MouthStyle.smile,
      eyebrows: EyebrowStyle.arched,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.longBlonde,
      gloves: GloveType.energy,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana dorada',
        // La melena tapa las orejas, así que la tiara es el detalle que sí
        // se ve por encima del pelo
        face: 'diadema estrella',
        neck: 'medallón',
        waist: 'faja ninja',
      ),
    ),
  ),

  // ── Colección: Superhéroes ─────────────────────────────────────────────────
  PresetCharacter(
    id: 'preset_capitan_america',
    name: 'Capitán Estrella',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.straight,
      torso: TorsoDesign.superhero,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        leftHand: 'escudo capitán',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_iron_man',
    name: 'Titán Metálico',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.laser,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ironMan,
      torso: TorsoDesign.superhero,
      legDesign: LegDesign.armor,
      shoes: ShoeType.military,
    ),
  ),
  PresetCharacter(
    id: 'preset_superman',
    name: 'Guardián Celeste',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.straight,
      torso: TorsoDesign.superhero,
      hasCape: true,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
    ),
  ),
  PresetCharacter(
    id: 'preset_black_panther',
    name: 'Sombra Felina',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.dark,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.blackPanther,
      torso: TorsoDesign.ninja,
      gloves: GloveType.claws,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
    ),
  ),
  PresetCharacter(
    id: 'preset_hulk',
    name: 'Coloso Verde',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.green,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.teeth,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.shaved,
      torso: TorsoDesign.monster,
      legDesign: LegDesign.stripes,
      shoes: ShoeType.barefoot,
    ),
  ),
  PresetCharacter(
    id: 'preset_vision',
    name: 'Espectro Púrpura',
    collection: 'Superhéroes',
    type: CharacterType.mysterious,
    appearance: CharacterAppearance(
      skinTone: SkinTone.purple,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.shaved,
      torso: TorsoDesign.futuristic,
      hasCape: true,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        neck: 'medallón',
      ),
    ),
  ),

  // ── Colección: Heroínas ────────────────────────────────────────────────────
  PresetCharacter(
    id: 'preset_ghost_spider',
    name: 'Aracna Espectral',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.surprised,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ghostSpider,
      torso: TorsoDesign.spiderGwen,
      gloves: GloveType.spiderWeb,
      legDesign: LegDesign.urbanCamo,
      legType: LegType.pants,
      shoes: ShoeType.balletTeal,
    ),
  ),
  PresetCharacter(
    id: 'preset_captain_marvel',
    name: 'Capitana Cósmica',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.determined,
      mouth: MouthStyle.smile,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.longBlonde,
      torso: TorsoDesign.captainMarvel,
      gloves: GloveType.energy,
      legDesign: LegDesign.plain,
      legType: LegType.pants,
      shoes: ShoeType.military,
    ),
  ),
  PresetCharacter(
    id: 'preset_black_widow',
    name: 'Agente Escarlata',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.determined,
      mouth: MouthStyle.smile,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.wavyBob,
      torso: TorsoDesign.blackWidow,
      gloves: GloveType.medieval,
      legDesign: LegDesign.urbanCamo,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'pistola',
        leftHand: 'pistola bláster',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_wonder_woman',
    name: 'Amazona Dorada',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.determined,
      mouth: MouthStyle.smile,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.longBlack,
      torso: TorsoDesign.wonderWoman,
      gloves: GloveType.medieval,
      legDesign: LegDesign.stars,
      legType: LegType.skirt,
      shoes: ShoeType.heroBoots,
      accessories: CharacterAccessories(
        rightHand: 'lazo dorado',
        face: 'diadema estrella',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_star_princess',
    name: 'Princesa Estelar',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.medium,
      eyes: EyeStyle.emerald,
      mouth: MouthStyle.smile,
      eyebrows: EyebrowStyle.arched,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.longCoral,
      torso: TorsoDesign.starPrincess,
      legDesign: LegDesign.cosmicStripes,
      legType: LegType.pants,
      shoes: ShoeType.cosmicBoots,
      accessories: CharacterAccessories(
        rightHand: 'esfera estelar',
        leftHand: 'orbe estelar',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_leila_princess',
    name: 'Princesa Rebelde',
    collection: 'Heroínas',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.determined,
      mouth: MouthStyle.smile,
      eyebrows: EyebrowStyle.arched,
      // Peinado icónico: raya al medio y dos grandes rodetes a los lados
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.sideBuns,
      // Túnica ceremonial blanca con cuello en capucha
      torso: TorsoDesign.princessLeia,
      // Vestido largo blanco (falda) que cae hasta los pies
      legDesign: LegDesign.whiteGown,
      legType: LegType.skirt,
      shoes: ShoeType.sandals,
      accessories: CharacterAccessories(
        // Cinturón de cadena plateada, el detalle metálico de la túnica
        waist: 'cinturón plateado',
        // Bláster defensivo en la mano
        leftHand: 'pistola bláster',
      ),
    ),
  ),
];

List<String> get presetCollections {
  final seen = <String>[];
  for (final p in presetCharacters) {
    if (!seen.contains(p.collection)) seen.add(p.collection);
  }
  return seen;
}

List<PresetCharacter> presetsForCollection(String collection) =>
    presetCharacters.where((p) => p.collection == collection).toList();

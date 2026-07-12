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
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ninjaHood,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana',
        waist: 'faja ninja',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_cole',
    name: 'Cole',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ninjaHood,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'bastón bo',
        waist: 'faja ninja',
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
    id: 'preset_zane',
    name: 'Zane',
    collection: 'Ninjas dorados',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.gold,
      eyes: EyeStyle.robot,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.ninjaHood,
      torso: TorsoDesign.golden,
      legDesign: LegDesign.golden,
      legType: LegType.pants,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana dorada',
        waist: 'faja ninja',
      ),
    ),
  ),

  // ── Colección: Superhéroes ─────────────────────────────────────────────────
  PresetCharacter(
    id: 'preset_capitan_america',
    name: 'Capitán América',
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
    name: 'Iron Man',
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
    name: 'Superman',
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
    id: 'preset_spiderman',
    name: 'Spider-Man',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.surprised,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.spiderMan,
      torso: TorsoDesign.superhero,
      legDesign: LegDesign.plain,
      shoes: ShoeType.sneakers,
    ),
  ),
  PresetCharacter(
    id: 'preset_black_panther',
    name: 'Black Panther',
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
    id: 'preset_deadpool',
    name: 'Deadpool',
    collection: 'Superhéroes',
    type: CharacterType.neutral,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.silent,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.deadpool,
      torso: TorsoDesign.plain,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'katana',
        back: 'katanas dobles',
        leftHand: 'pistola bláster',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_wolverine',
    name: 'Wolverine',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.angry,
      mouth: MouthStyle.teeth,
      headwearType: HeadwearType.helmet,
      helmetStyle: HelmetStyle.wolverine,
      torso: TorsoDesign.superhero,
      gloves: GloveType.claws,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
    ),
  ),
  PresetCharacter(
    id: 'preset_hulk',
    name: 'Hulk',
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
    id: 'preset_star_lord',
    name: 'Star-Lord',
    collection: 'Superhéroes',
    type: CharacterType.hero,
    appearance: CharacterAppearance(
      skinTone: SkinTone.light,
      eyes: EyeStyle.happy,
      mouth: MouthStyle.smile,
      headwearType: HeadwearType.hair,
      hairStyle: HairStyle.straight,
      torso: TorsoDesign.futuristic,
      legDesign: LegDesign.plain,
      shoes: ShoeType.military,
      accessories: CharacterAccessories(
        rightHand: 'pistola',
        leftHand: 'pistola bláster',
        face: 'gafas piloto',
      ),
    ),
  ),
  PresetCharacter(
    id: 'preset_vision',
    name: 'Vision',
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

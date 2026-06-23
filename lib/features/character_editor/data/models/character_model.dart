import 'package:hive/hive.dart';

import '../../domain/entities/character.dart';

part 'character_model.g.dart';

@HiveType(typeId: 1)
class CharacterAppearanceModel extends HiveObject {
  @HiveField(0)
  int skinTone;
  @HiveField(1)
  int eyes;
  @HiveField(2)
  int mouth;
  @HiveField(3)
  int eyebrows;
  @HiveField(4)
  int facialExtra;
  @HiveField(5)
  int headwearType;
  @HiveField(6)
  int? hairStyle;
  @HiveField(7)
  int? helmetStyle;
  @HiveField(8)
  int? hatStyle;
  @HiveField(9)
  int torso;
  @HiveField(10)
  bool hasCape;
  @HiveField(11)
  int gloves;
  @HiveField(12)
  int legDesign;
  @HiveField(13)
  int legType;
  @HiveField(14)
  int shoes;
  // Accessories as nullable strings
  @HiveField(15)
  String? rightHand;
  @HiveField(16)
  String? leftHand;
  @HiveField(17)
  String? back;
  @HiveField(18)
  String? shoulders;
  @HiveField(19)
  String? waist;
  @HiveField(20)
  String? neck;
  @HiveField(21)
  String? face;
  @HiveField(22)
  String? feet;

  CharacterAppearanceModel({
    required this.skinTone,
    required this.eyes,
    required this.mouth,
    required this.eyebrows,
    required this.facialExtra,
    required this.headwearType,
    this.hairStyle,
    this.helmetStyle,
    this.hatStyle,
    required this.torso,
    required this.hasCape,
    required this.gloves,
    required this.legDesign,
    required this.legType,
    required this.shoes,
    this.rightHand,
    this.leftHand,
    this.back,
    this.shoulders,
    this.waist,
    this.neck,
    this.face,
    this.feet,
  });

  factory CharacterAppearanceModel.fromEntity(CharacterAppearance e) =>
      CharacterAppearanceModel(
        skinTone: e.skinTone.index,
        eyes: e.eyes.index,
        mouth: e.mouth.index,
        eyebrows: e.eyebrows.index,
        facialExtra: e.facialExtra.index,
        headwearType: e.headwearType.index,
        hairStyle: e.hairStyle?.index,
        helmetStyle: e.helmetStyle?.index,
        hatStyle: e.hatStyle?.index,
        torso: e.torso.index,
        hasCape: e.hasCape,
        gloves: e.gloves.index,
        legDesign: e.legDesign.index,
        legType: e.legType.index,
        shoes: e.shoes.index,
        rightHand: e.accessories.rightHand,
        leftHand: e.accessories.leftHand,
        back: e.accessories.back,
        shoulders: e.accessories.shoulders,
        waist: e.accessories.waist,
        neck: e.accessories.neck,
        face: e.accessories.face,
        feet: e.accessories.feet,
      );

  CharacterAppearance toEntity() => CharacterAppearance(
        skinTone: SkinTone.values[skinTone],
        eyes: EyeStyle.values[eyes],
        mouth: MouthStyle.values[mouth],
        eyebrows: EyebrowStyle.values[eyebrows],
        facialExtra: FacialExtra.values[facialExtra],
        headwearType: HeadwearType.values[headwearType],
        hairStyle: hairStyle != null ? HairStyle.values[hairStyle!] : null,
        helmetStyle:
            helmetStyle != null ? HelmetStyle.values[helmetStyle!] : null,
        hatStyle: hatStyle != null ? HatStyle.values[hatStyle!] : null,
        torso: TorsoDesign.values[torso],
        hasCape: hasCape,
        gloves: GloveType.values[gloves],
        legDesign: LegDesign.values[legDesign],
        legType: LegType.values[legType],
        shoes: ShoeType.values[shoes],
        accessories: CharacterAccessories(
          rightHand: rightHand,
          leftHand: leftHand,
          back: back,
          shoulders: shoulders,
          waist: waist,
          neck: neck,
          face: face,
          feet: feet,
        ),
      );
}

@HiveType(typeId: 0)
class CharacterModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  int type;
  @HiveField(3)
  String? specialPower;
  @HiveField(4)
  CharacterAppearanceModel appearance;
  @HiveField(5)
  DateTime createdAt;
  @HiveField(6)
  DateTime updatedAt;
  @HiveField(7)
  int totalCoinsEarned;
  @HiveField(8)
  int bestRunScore;

  CharacterModel({
    required this.id,
    required this.name,
    required this.type,
    this.specialPower,
    required this.appearance,
    required this.createdAt,
    required this.updatedAt,
    this.totalCoinsEarned = 0,
    this.bestRunScore = 0,
  });

  factory CharacterModel.fromEntity(Character c) => CharacterModel(
        id: c.id,
        name: c.name,
        type: c.type.index,
        specialPower: c.specialPower,
        appearance: CharacterAppearanceModel.fromEntity(c.appearance),
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        totalCoinsEarned: c.totalCoinsEarned,
        bestRunScore: c.bestRunScore,
      );

  Character toEntity() => Character(
        id: id,
        name: name,
        type: CharacterType.values[type],
        specialPower: specialPower,
        appearance: appearance.toEntity(),
        createdAt: createdAt,
        updatedAt: updatedAt,
        totalCoinsEarned: totalCoinsEarned,
        bestRunScore: bestRunScore,
      );
}

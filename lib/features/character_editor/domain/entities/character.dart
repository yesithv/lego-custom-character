import 'package:equatable/equatable.dart';

enum CharacterType { hero, villain, neutral, mysterious }

enum SkinTone {
  light, medium, dark,       // realistic
  blue, green, purple, orange, silver, gold  // fantastic
}

enum EyeStyle { happy, angry, surprised, sleepy, wink, laser, robot, crying, starry }
enum MouthStyle { smile, frown, teeth, fangs, mustache, tongueOut, silent }
enum EyebrowStyle { normal, arched, angry, friendly, absent }
enum FacialExtra { none, freckles, blush, scar, tribalTattoo, warPaint, monocle }

enum HairStyle { straight, curly, afro, mohawk, ponytail, braids, shaved, bald }
enum HeadwearType { none, hair, helmet, hat }
enum HelmetStyle { medieval, space, roman, viking, firefighter, biker, astronaut }
enum HatStyle { wizard, cowboy, cap, crown, tiara, topHat, pirate }

enum TorsoDesign {
  plain, police, firefighter, astronaut, doctor, chef, military,
  ninja, pirate, superhero, casual, medieval, futuristic, samurai,
  dinosaur, robot, monster, alien
}

enum GloveType { none, boxing, medieval, superhero, claws }
enum LegDesign { plain, camouflage, stripes, checkered, flames, stars, armor }
enum LegType { pants, shorts, skirt, legArmor, spacesuit }
enum ShoeType { sneakers, military, cowboy, sandals, skates, flippers, witchBoots, barefoot }

// Accessory slots
enum AccessoryRarity { common, rare, epic, legendary }

class CharacterAccessories extends Equatable {
  final String? rightHand;
  final String? leftHand;
  final String? back;
  final String? shoulders;
  final String? waist;
  final String? neck;
  final String? face;
  final String? feet;

  const CharacterAccessories({
    this.rightHand,
    this.leftHand,
    this.back,
    this.shoulders,
    this.waist,
    this.neck,
    this.face,
    this.feet,
  });

  CharacterAccessories copyWith({
    String? rightHand,
    String? leftHand,
    String? back,
    String? shoulders,
    String? waist,
    String? neck,
    String? face,
    String? feet,
  }) =>
      CharacterAccessories(
        rightHand: rightHand ?? this.rightHand,
        leftHand: leftHand ?? this.leftHand,
        back: back ?? this.back,
        shoulders: shoulders ?? this.shoulders,
        waist: waist ?? this.waist,
        neck: neck ?? this.neck,
        face: face ?? this.face,
        feet: feet ?? this.feet,
      );

  @override
  List<Object?> get props =>
      [rightHand, leftHand, back, shoulders, waist, neck, face, feet];
}

class CharacterAppearance extends Equatable {
  final SkinTone skinTone;
  final EyeStyle eyes;
  final MouthStyle mouth;
  final EyebrowStyle eyebrows;
  final FacialExtra facialExtra;
  final HeadwearType headwearType;
  final HairStyle? hairStyle;
  final HelmetStyle? helmetStyle;
  final HatStyle? hatStyle;
  final TorsoDesign torso;
  final bool hasCape;
  final GloveType gloves;
  final LegDesign legDesign;
  final LegType legType;
  final ShoeType shoes;
  final CharacterAccessories accessories;

  const CharacterAppearance({
    this.skinTone = SkinTone.medium,
    this.eyes = EyeStyle.happy,
    this.mouth = MouthStyle.smile,
    this.eyebrows = EyebrowStyle.normal,
    this.facialExtra = FacialExtra.none,
    this.headwearType = HeadwearType.hair,
    this.hairStyle = HairStyle.straight,
    this.helmetStyle,
    this.hatStyle,
    this.torso = TorsoDesign.plain,
    this.hasCape = false,
    this.gloves = GloveType.none,
    this.legDesign = LegDesign.plain,
    this.legType = LegType.pants,
    this.shoes = ShoeType.sneakers,
    this.accessories = const CharacterAccessories(),
  });

  CharacterAppearance copyWith({
    SkinTone? skinTone,
    EyeStyle? eyes,
    MouthStyle? mouth,
    EyebrowStyle? eyebrows,
    FacialExtra? facialExtra,
    HeadwearType? headwearType,
    HairStyle? hairStyle,
    HelmetStyle? helmetStyle,
    HatStyle? hatStyle,
    TorsoDesign? torso,
    bool? hasCape,
    GloveType? gloves,
    LegDesign? legDesign,
    LegType? legType,
    ShoeType? shoes,
    CharacterAccessories? accessories,
  }) =>
      CharacterAppearance(
        skinTone: skinTone ?? this.skinTone,
        eyes: eyes ?? this.eyes,
        mouth: mouth ?? this.mouth,
        eyebrows: eyebrows ?? this.eyebrows,
        facialExtra: facialExtra ?? this.facialExtra,
        headwearType: headwearType ?? this.headwearType,
        hairStyle: hairStyle ?? this.hairStyle,
        helmetStyle: helmetStyle ?? this.helmetStyle,
        hatStyle: hatStyle ?? this.hatStyle,
        torso: torso ?? this.torso,
        hasCape: hasCape ?? this.hasCape,
        gloves: gloves ?? this.gloves,
        legDesign: legDesign ?? this.legDesign,
        legType: legType ?? this.legType,
        shoes: shoes ?? this.shoes,
        accessories: accessories ?? this.accessories,
      );

  @override
  List<Object?> get props => [
        skinTone, eyes, mouth, eyebrows, facialExtra,
        headwearType, hairStyle, helmetStyle, hatStyle,
        torso, hasCape, gloves, legDesign, legType, shoes, accessories,
      ];
}

class Character extends Equatable {
  final String id;
  final String name;
  final CharacterType type;
  final String? specialPower;
  final CharacterAppearance appearance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalCoinsEarned;
  final int bestRunScore;

  const Character({
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

  Character copyWith({
    String? name,
    CharacterType? type,
    String? specialPower,
    CharacterAppearance? appearance,
    DateTime? updatedAt,
    int? totalCoinsEarned,
    int? bestRunScore,
  }) =>
      Character(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        specialPower: specialPower ?? this.specialPower,
        appearance: appearance ?? this.appearance,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
        bestRunScore: bestRunScore ?? this.bestRunScore,
      );

  @override
  List<Object?> get props =>
      [id, name, type, specialPower, appearance, createdAt, updatedAt];
}

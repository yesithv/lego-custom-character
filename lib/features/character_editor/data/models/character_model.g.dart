// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterModelAdapter extends TypeAdapter<CharacterModel> {
  @override
  final int typeId = 0;

  @override
  CharacterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as int,
      specialPower: fields[3] as String?,
      appearance: fields[4] as CharacterAppearanceModel,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      totalCoinsEarned: fields[7] as int,
      bestRunScore: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.specialPower)
      ..writeByte(4)
      ..write(obj.appearance)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.totalCoinsEarned)
      ..writeByte(8)
      ..write(obj.bestRunScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CharacterAppearanceModelAdapter
    extends TypeAdapter<CharacterAppearanceModel> {
  @override
  final int typeId = 1;

  @override
  CharacterAppearanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterAppearanceModel(
      skinTone: fields[0] as int,
      eyes: fields[1] as int,
      mouth: fields[2] as int,
      eyebrows: fields[3] as int,
      facialExtra: fields[4] as int,
      headwearType: fields[5] as int,
      hairStyle: fields[6] as int?,
      helmetStyle: fields[7] as int?,
      hatStyle: fields[8] as int?,
      torso: fields[9] as int,
      hasCape: fields[10] as bool,
      gloves: fields[11] as int,
      legDesign: fields[12] as int,
      legType: fields[13] as int,
      shoes: fields[14] as int,
      rightHand: fields[15] as String?,
      leftHand: fields[16] as String?,
      back: fields[17] as String?,
      shoulders: fields[18] as String?,
      waist: fields[19] as String?,
      neck: fields[20] as String?,
      face: fields[21] as String?,
      feet: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterAppearanceModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.skinTone)
      ..writeByte(1)
      ..write(obj.eyes)
      ..writeByte(2)
      ..write(obj.mouth)
      ..writeByte(3)
      ..write(obj.eyebrows)
      ..writeByte(4)
      ..write(obj.facialExtra)
      ..writeByte(5)
      ..write(obj.headwearType)
      ..writeByte(6)
      ..write(obj.hairStyle)
      ..writeByte(7)
      ..write(obj.helmetStyle)
      ..writeByte(8)
      ..write(obj.hatStyle)
      ..writeByte(9)
      ..write(obj.torso)
      ..writeByte(10)
      ..write(obj.hasCape)
      ..writeByte(11)
      ..write(obj.gloves)
      ..writeByte(12)
      ..write(obj.legDesign)
      ..writeByte(13)
      ..write(obj.legType)
      ..writeByte(14)
      ..write(obj.shoes)
      ..writeByte(15)
      ..write(obj.rightHand)
      ..writeByte(16)
      ..write(obj.leftHand)
      ..writeByte(17)
      ..write(obj.back)
      ..writeByte(18)
      ..write(obj.shoulders)
      ..writeByte(19)
      ..write(obj.waist)
      ..writeByte(20)
      ..write(obj.neck)
      ..writeByte(21)
      ..write(obj.face)
      ..writeByte(22)
      ..write(obj.feet);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterAppearanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// Hand-written Hive TypeAdapter — typeId 3
part of 'score_model.dart';

class ScoreModelAdapter extends TypeAdapter<ScoreModel> {
  @override
  final int typeId = 3;

  @override
  ScoreModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreModel()
      ..id = fields[0] as String
      ..characterName = fields[1] as String
      ..worldId = fields[2] as String
      ..score = fields[3] as int
      ..meters = fields[4] as int
      ..coins = fields[5] as int
      ..createdAtMs = fields[6] as int;
  }

  @override
  void write(BinaryWriter writer, ScoreModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.characterName)
      ..writeByte(2)
      ..write(obj.worldId)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.meters)
      ..writeByte(5)
      ..write(obj.coins)
      ..writeByte(6)
      ..write(obj.createdAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

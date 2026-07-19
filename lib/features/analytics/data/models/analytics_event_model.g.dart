// Hand-written Hive TypeAdapter — typeId 5

part of 'analytics_event_model.dart';

class AnalyticsEventModelAdapter extends TypeAdapter<AnalyticsEventModel> {
  @override
  final int typeId = 5;

  @override
  AnalyticsEventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsEventModel(
      name: fields[0] as String,
      tsMs: fields[1] as int,
      paramsJson: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsEventModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.tsMs)
      ..writeByte(2)
      ..write(obj.paramsJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsEventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

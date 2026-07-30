// Hand-written Hive TypeAdapter — typeId 4

part of 'entitlements_model.dart';

class EntitlementsModelAdapter extends TypeAdapter<EntitlementsModel> {
  @override
  final int typeId = 4;

  @override
  EntitlementsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EntitlementsModel(
      gems: fields[0] as int,
      adsRemoved: fields[1] as bool,
      subscriptionActive: fields[2] as bool,
      ownedProductIds: (fields[3] as List).cast<String>(),
      // Campos añadidos después: los datos antiguos no los tienen → default.
      lastVipClaimMs: fields[4] as int?,
      // Si un registro antiguo no trae el total, se asume que se ha ganado al
      // menos el saldo actual (gemas que ya tiene) → gastado 0, no negativo.
      totalGemsEarned: fields[5] as int? ?? (fields[0] as int? ?? 0),
    );
  }

  @override
  void write(BinaryWriter writer, EntitlementsModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.gems)
      ..writeByte(1)
      ..write(obj.adsRemoved)
      ..writeByte(2)
      ..write(obj.subscriptionActive)
      ..writeByte(3)
      ..write(obj.ownedProductIds)
      ..writeByte(4)
      ..write(obj.lastVipClaimMs)
      ..writeByte(5)
      ..write(obj.totalGemsEarned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntitlementsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

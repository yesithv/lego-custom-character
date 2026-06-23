// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 2;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletModel(
      coins: fields[0] as int,
      lastRouletteDate: fields[1] as DateTime?,
      unlockedParts: (fields[2] as List).cast<String>(),
      runStreak: fields[3] as int,
      lastPlayDate: fields[4] as DateTime?,
      totalCoinsEarned: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.coins)
      ..writeByte(1)
      ..write(obj.lastRouletteDate)
      ..writeByte(2)
      ..write(obj.unlockedParts)
      ..writeByte(3)
      ..write(obj.runStreak)
      ..writeByte(4)
      ..write(obj.lastPlayDate)
      ..writeByte(5)
      ..write(obj.totalCoinsEarned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

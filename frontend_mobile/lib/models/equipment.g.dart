// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentAdapter extends TypeAdapter<Equipment> {
  @override
  final int typeId = 0;

  @override
  Equipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Equipment(
      id: fields[0] as String?,
      codeParent: fields[1] as String?,
      feeder: fields[2] as String?,
      feederDescription: fields[3] as String?,
      code: fields[4] as String,
      famille: fields[5] as String,
      zone: fields[6] as String,
      entity: fields[7] as String,
      unite: fields[8] as String,
      centreCharge: fields[9] as String,
      description: fields[10] as String,
      longitude: fields[11] as String,
      latitude: fields[12] as String,
      cachedAt: fields[14] as DateTime?,
      attributes: (fields[15] as List?)?.cast<EquipmentAttribute>(),
    );
  }

  @override
  void write(BinaryWriter writer, Equipment obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.codeParent)
      ..writeByte(2)
      ..write(obj.feeder)
      ..writeByte(3)
      ..write(obj.feederDescription)
      ..writeByte(4)
      ..write(obj.code)
      ..writeByte(5)
      ..write(obj.famille)
      ..writeByte(6)
      ..write(obj.zone)
      ..writeByte(7)
      ..write(obj.entity)
      ..writeByte(8)
      ..write(obj.unite)
      ..writeByte(9)
      ..write(obj.centreCharge)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.longitude)
      ..writeByte(12)
      ..write(obj.latitude)
      ..writeByte(14)
      ..write(obj.cachedAt)
      ..writeByte(15)
      ..write(obj.attributes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

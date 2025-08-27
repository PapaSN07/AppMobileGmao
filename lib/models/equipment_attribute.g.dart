// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_attribute.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentAttributeAdapter extends TypeAdapter<EquipmentAttribute> {
  @override
  final int typeId = 9;

  @override
  EquipmentAttribute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquipmentAttribute(
      id: fields[0] as String?,
      specification: fields[1] as String?,
      index: fields[2] as String?,
      name: fields[3] as String?,
      value: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentAttribute obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.specification)
      ..writeByte(2)
      ..write(obj.index)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAttributeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

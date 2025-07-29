// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EquipmentHiveAdapter extends TypeAdapter<EquipmentHive> {
  @override
  final int typeId = 0;

  @override
  EquipmentHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EquipmentHive(
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
      attributs: (fields[13] as List).cast<AttributeValueHive>(),
      cachedAt: fields[14] as DateTime?,
      isSync: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EquipmentHive obj) {
    writer
      ..writeByte(16)
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
      ..writeByte(13)
      ..write(obj.attributs)
      ..writeByte(14)
      ..write(obj.cachedAt)
      ..writeByte(15)
      ..write(obj.isSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttributeValueHiveAdapter extends TypeAdapter<AttributeValueHive> {
  @override
  final int typeId = 1;

  @override
  AttributeValueHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttributeValueHive(
      name: fields[0] as String?,
      value: fields[1] as String?,
      type: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttributeValueHive obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributeValueHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReferenceDataHiveAdapter extends TypeAdapter<ReferenceDataHive> {
  @override
  final int typeId = 2;

  @override
  ReferenceDataHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReferenceDataHive(
      zones: (fields[0] as List).cast<String>(),
      familles: (fields[1] as List).cast<String>(),
      entities: (fields[2] as List).cast<String>(),
      lastSync: fields[3] as DateTime?,
      cacheVersion: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReferenceDataHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.zones)
      ..writeByte(1)
      ..write(obj.familles)
      ..writeByte(2)
      ..write(obj.entities)
      ..writeByte(3)
      ..write(obj.lastSync)
      ..writeByte(4)
      ..write(obj.cacheVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceDataHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntityAdapter extends TypeAdapter<Entity> {
  @override
  final int typeId = 4;

  @override
  Entity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Entity(
      id: fields[0] as String,
      code: fields[1] as String,
      description: fields[2] as String,
      parentCategory: fields[3] as String,
      systemCategory: fields[4] as String,
      level: fields[5] as int,
      entity: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Entity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.parentCategory)
      ..writeByte(4)
      ..write(obj.systemCategory)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.entity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

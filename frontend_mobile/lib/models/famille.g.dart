// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'famille.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilleAdapter extends TypeAdapter<Famille> {
  @override
  final int typeId = 3;

  @override
  Famille read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Famille(
      id: fields[0] as String,
      code: fields[1] as String,
      description: fields[2] as String,
      parentCategory: fields[3] as String,
      systemCategory: fields[4] as String,
      level: fields[5] as String,
      entity: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Famille obj) {
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
      other is FamilleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

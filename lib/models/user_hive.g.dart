// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHiveAdapter extends TypeAdapter<UserHive> {
  @override
  final int typeId = 3;

  @override
  UserHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHive(
      id: fields[0] as String,
      code: fields[1] as String?,
      username: fields[2] as String,
      password: fields[3] as String?,
      email: fields[4] as String,
      entity: fields[5] as String,
      group: fields[6] as String?,
      urlImage: fields[7] as String?,
      isAbsent: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserHive obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.entity)
      ..writeByte(6)
      ..write(obj.group)
      ..writeByte(7)
      ..write(obj.urlImage)
      ..writeByte(8)
      ..write(obj.isAbsent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

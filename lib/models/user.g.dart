// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 2;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      code: fields[1] as String?,
      username: fields[2] as String,
      password: fields[3] as String?,
      email: fields[4] as String,
      entity: fields[5] as String,
      group: fields[6] as String?,
      urlImage: fields[7] as String?,
      isAbsent: fields[8] as String?,
      role: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.isAbsent)
      ..writeByte(9)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

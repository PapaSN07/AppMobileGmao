// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historique_equipment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoriqueEquipmentAdapter extends TypeAdapter<HistoriqueEquipment> {
  @override
  final int typeId = 16;

  @override
  HistoriqueEquipment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoriqueEquipment(
      id: fields[0] as String?,
      code: fields[1] as String?,
      famille: fields[2] as String?,
      zone: fields[3] as String?,
      entity: fields[4] as String?,
      unite: fields[5] as String?,
      centreCharge: fields[6] as String?,
      description: fields[7] as String?,
      feeder: fields[8] as String?,
      feederDescription: fields[9] as String?,
      localisation: fields[10] as String?,
      codeParent: fields[11] as String?,
      createdAt: fields[12] as String?,
      updatedAt: fields[13] as String?,
      createdBy: fields[14] as String?,
      judgedBy: fields[15] as String?,
      isUpdate: fields[16] as bool?,
      isNew: fields[17] as bool?,
      isApproved: fields[18] as bool?,
      isRejected: fields[19] as bool?,
      isDeleted: fields[20] as bool?,
      commentaire: fields[21] as String?,
      status: fields[22] as String?,
      attributes: (fields[23] as List?)?.cast<EquipmentAttribute>(),
      equipmentId: fields[24] as String?,
      dateHistoryCreatedAt: fields[25] as String?,
      cachedAt: fields[26] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoriqueEquipment obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.famille)
      ..writeByte(3)
      ..write(obj.zone)
      ..writeByte(4)
      ..write(obj.entity)
      ..writeByte(5)
      ..write(obj.unite)
      ..writeByte(6)
      ..write(obj.centreCharge)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.feeder)
      ..writeByte(9)
      ..write(obj.feederDescription)
      ..writeByte(10)
      ..write(obj.localisation)
      ..writeByte(11)
      ..write(obj.codeParent)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.createdBy)
      ..writeByte(15)
      ..write(obj.judgedBy)
      ..writeByte(16)
      ..write(obj.isUpdate)
      ..writeByte(17)
      ..write(obj.isNew)
      ..writeByte(18)
      ..write(obj.isApproved)
      ..writeByte(19)
      ..write(obj.isRejected)
      ..writeByte(20)
      ..write(obj.isDeleted)
      ..writeByte(21)
      ..write(obj.commentaire)
      ..writeByte(22)
      ..write(obj.status)
      ..writeByte(23)
      ..write(obj.attributes)
      ..writeByte(24)
      ..write(obj.equipmentId)
      ..writeByte(25)
      ..write(obj.dateHistoryCreatedAt)
      ..writeByte(26)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoriqueEquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

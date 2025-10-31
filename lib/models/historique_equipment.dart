import 'package:hive/hive.dart';
import 'package:appmobilegmao/models/equipment_attribute.dart';

part 'historique_equipment.g.dart';

@HiveType(typeId: 16) // ✅ Nouveau typeId
class HistoriqueEquipment extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? code;

  @HiveField(2)
  String? famille;

  @HiveField(3)
  String? zone;

  @HiveField(4)
  String? entity;

  @HiveField(5)
  String? unite;

  @HiveField(6)
  String? centreCharge;

  @HiveField(7)
  String? description;

  @HiveField(8)
  String? feeder;

  @HiveField(9)
  String? feederDescription;

  @HiveField(10)
  String? localisation;

  @HiveField(11)
  String? codeParent;

  @HiveField(12)
  String? createdAt;

  @HiveField(13)
  String? updatedAt;

  @HiveField(14)
  String? createdBy;

  @HiveField(15)
  String? judgedBy;

  @HiveField(16)
  bool? isUpdate;

  @HiveField(17)
  bool? isNew;

  @HiveField(18)
  bool? isApproved;

  @HiveField(19)
  bool? isRejected;

  @HiveField(20)
  bool? isDeleted;

  @HiveField(21)
  String? commentaire;

  @HiveField(22)
  String? status;

  @HiveField(23)
  List<EquipmentAttribute>? attributes;

  @HiveField(24)
  String? equipmentId;

  @HiveField(25)
  String? dateHistoryCreatedAt;

  @HiveField(26)
  DateTime? cachedAt;

  HistoriqueEquipment({
    this.id,
    this.code,
    this.famille,
    this.zone,
    this.entity,
    this.unite,
    this.centreCharge,
    this.description,
    this.feeder,
    this.feederDescription,
    this.localisation,
    this.codeParent,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.judgedBy,
    this.isUpdate,
    this.isNew,
    this.isApproved,
    this.isRejected,
    this.isDeleted,
    this.commentaire,
    this.status,
    this.attributes,
    this.equipmentId,
    this.dateHistoryCreatedAt,
    this.cachedAt,
  });

  factory HistoriqueEquipment.fromJson(Map<String, dynamic> json) {
    return HistoriqueEquipment(
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      famille: json['famille']?.toString(),
      zone: json['zone']?.toString(),
      entity: json['entity']?.toString(),
      unite: json['unite']?.toString(),
      centreCharge: json['centre_charge']?.toString(),
      description: json['description']?.toString(),
      feeder: json['feeder']?.toString(),
      feederDescription: json['feeder_description']?.toString(),
      localisation: json['localisation']?.toString(),
      codeParent: json['code_parent']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      createdBy: json['created_by']?.toString(),
      judgedBy: json['judged_by']?.toString(),
      isUpdate: json['is_update'] as bool?,
      isNew: json['is_new'] as bool?,
      isApproved: json['is_approved'] as bool?,
      isRejected: json['is_rejected'] as bool?,
      isDeleted: json['is_deleted'] as bool?,
      commentaire: json['commentaire']?.toString(),
      status: json['status']?.toString(),
      // ✅ Parser les attributs avec la structure de l'historique
      attributes:
          json['attributes'] != null
              ? (json['attributes'] as List).map((attr) {
                return EquipmentAttribute(
                  id: attr['id']?.toString(),
                  specification: attr['specification']?.toString(),
                  index: attr['index']?.toString(),
                  name: attr['name']?.toString(),
                  value: attr['value']?.toString(),
                  type: 'string',
                );
              }).toList()
              : null,
      equipmentId: json['equipment_id']?.toString(),
      dateHistoryCreatedAt: json['date_history_created_at']?.toString(),
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'famille': famille,
      'zone': zone,
      'entity': entity,
      'unite': unite,
      'centre_charge': centreCharge,
      'description': description,
      'feeder': feeder,
      'feeder_description': feederDescription,
      'localisation': localisation,
      'code_parent': codeParent,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'judged_by': judgedBy,
      'is_update': isUpdate,
      'is_new': isNew,
      'is_approved': isApproved,
      'is_rejected': isRejected,
      'is_deleted': isDeleted,
      'commentaire': commentaire,
      'status': status,
      'attributes': attributes?.map((a) => a.toJson()).toList(),
      'equipment_id': equipmentId,
      'date_history_created_at': dateHistoryCreatedAt,
    };
  }
}

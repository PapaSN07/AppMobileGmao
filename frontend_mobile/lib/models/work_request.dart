class WorkRequest {
  final int pkWorkRequest;
  final int? dinqPk;
  final String dinqCode;
  final String dinqUserStatus;
  final String dinqEquipment;
  final String dinqEquipmentDescription;
  final String? dinqJob;
  final String? dinqJobType;
  final String? dinqJobClass;
  final String? dinqPriority;
  final String? dinqActionEntity;
  final String? dinqRequestEntity;
  final String? dinqAskDate;
  final String? dinqTargetDate;
  final String? dinqSupervisor;
  final String? dinqCostcentre;
  final String? dinqCostcentreDescription;
  final String? dinqZone;
  final String? dinqFunction;
  final String dinqDescription;
  final String? mailsToNotify;
  final String? dateDebut;
  final String? dateFin;

  WorkRequest({
    required this.pkWorkRequest,
    this.dinqPk,
    required this.dinqCode,
    required this.dinqUserStatus,
    required this.dinqEquipment,
    required this.dinqEquipmentDescription,
    this.dinqJob,
    this.dinqJobType,
    this.dinqJobClass,
    this.dinqPriority,
    this.dinqActionEntity,
    this.dinqRequestEntity,
    this.dinqAskDate,
    this.dinqTargetDate,
    this.dinqSupervisor,
    this.dinqCostcentre,
    this.dinqCostcentreDescription,
    this.dinqZone,
    this.dinqFunction,
    required this.dinqDescription,
    this.mailsToNotify,
    this.dateDebut,
    this.dateFin,
  });

  factory WorkRequest.fromJson(Map<String, dynamic> json) {
    return WorkRequest(
      pkWorkRequest: json['pkWorkRequest'] ?? 0,
      dinqPk: json['dinqPk'],
      dinqCode: json['dinqCode'] ?? '',
      dinqUserStatus: json['dinqUserStatus'] ?? '0. Créée',
      dinqEquipment: json['dinqEquipment'] ?? '',
      dinqEquipmentDescription: json['dinqEquipmentDescription'] ?? '',
      dinqJob: json['dinqJob'],
      dinqJobType: json['dinqJobType'],
      dinqJobClass: json['dinqJobClass'],
      dinqPriority: json['dinqPriority'],
      dinqActionEntity: json['dinqActionEntity'],
      dinqRequestEntity: json['dinqRequestEntity'],
      dinqAskDate: json['dinqAskDate'],
      dinqTargetDate: json['dinqTargetDate'],
      dinqSupervisor: json['dinqSupervisor'],
      dinqCostcentre: json['dinqCostcentre'],
      dinqCostcentreDescription: json['dinqCostcentreDescription'],
      dinqZone: json['dinqZone'],
      dinqFunction: json['dinqFunction'],
      dinqDescription: json['dinqDescription'] ?? '',
      mailsToNotify: json['mailsToNotify'],
      dateDebut: json['dateDebut'],
      dateFin: json['dateFin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pkWorkRequest': pkWorkRequest,
      'dinqPk': dinqPk,
      'dinqCode': dinqCode,
      'dinqUserStatus': dinqUserStatus,
      'dinqEquipment': dinqEquipment,
      'dinqEquipmentDescription': dinqEquipmentDescription,
      'dinqJob': dinqJob,
      'dinqJobType': dinqJobType,
      'dinqJobClass': dinqJobClass,
      'dinqPriority': dinqPriority,
      'dinqActionEntity': dinqActionEntity,
      'dinqRequestEntity': dinqRequestEntity,
      'dinqAskDate': dinqAskDate,
      'dinqTargetDate': dinqTargetDate,
      'dinqSupervisor': dinqSupervisor,
      'dinqCostcentre': dinqCostcentre,
      'dinqCostcentreDescription': dinqCostcentreDescription,
      'dinqZone': dinqZone,
      'dinqFunction': dinqFunction,
      'dinqDescription': dinqDescription,
      'mailsToNotify': mailsToNotify,
      'dateDebut': dateDebut,
      'dateFin': dateFin,
    };
  }
}

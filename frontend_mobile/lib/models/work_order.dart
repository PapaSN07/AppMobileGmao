class WorkOrder {
  // Propriétés principales
  final int pkWorkOrder;
  final int wowoCode;
  final String wowoUserStatus;
  final String wowoEquipment;
  final String wowoJob;
  final String wowoJobType;
  final String wowoJobClass;
  final String? wowoPriority;
  final String wowoActionEntity;
  final String wowoRequestEntity;
  final String? wowoScheduleDate;
  final String? wowoSupervisor;
  final String wowoCostcentre;
  final String? wowoTargetDate;
  final String? wowoStartDate;
  final String? wowoEndDate;
  final String? wowoJobRequest;
  final String? wowoZone;
  final String? wowoFunction;
  final String? wowoFeedbackNote;

  // Descriptions
  final String wowoEquipmentDescription;
  final String? wowoActionEntityDescription;
  final String? wowoCostcentreDescription;
  final String? wowoJobClassDescription;
  final String? wowoJobTypeDescription;
  final String? wowoSupervisorDescription;
  final String? mdjbDescription;

  // Champs personnalisés
  final String? wowoString1; // Charge des travaux
  final String? wowoString2; // Nature des travaux
  final String? wowoString4; // Société
  final String? mdusDescription; // État complet

  WorkOrder({
    required this.pkWorkOrder,
    required this.wowoCode,
    required this.wowoUserStatus,
    required this.wowoEquipment,
    required this.wowoJob,
    required this.wowoJobType,
    required this.wowoJobClass,
    this.wowoPriority,
    required this.wowoActionEntity,
    required this.wowoRequestEntity,
    this.wowoScheduleDate,
    this.wowoSupervisor,
    required this.wowoCostcentre,
    this.wowoTargetDate,
    this.wowoStartDate,
    this.wowoEndDate,
    this.wowoJobRequest,
    this.wowoZone,
    this.wowoFunction,
    this.wowoFeedbackNote,
    required this.wowoEquipmentDescription,
    this.wowoActionEntityDescription,
    this.wowoCostcentreDescription,
    this.wowoJobClassDescription,
    this.wowoJobTypeDescription,
    this.wowoSupervisorDescription,
    this.mdjbDescription,
    this.wowoString1,
    this.wowoString2,
    this.wowoString4,
    this.mdusDescription,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      pkWorkOrder: json['pkWorkOrder'] ?? 0,
      wowoCode: json['wowoCode'] ?? 0,
      wowoUserStatus: json['wowoUserStatus'] ?? '',
      wowoEquipment: json['wowoEquipment'] ?? '',
      wowoJob: json['wowoJob'] ?? '',
      wowoJobType: json['wowoJobType'] ?? '',
      wowoJobClass: json['wowoJobClass'] ?? '',
      wowoPriority: json['wowoPriority'],
      wowoActionEntity: json['wowoActionEntity'] ?? '',
      wowoRequestEntity: json['wowoRequestEntity'] ?? '',
      wowoScheduleDate: json['wowoScheduleDate'],
      wowoSupervisor: json['wowoSupervisor'],
      wowoCostcentre: json['wowoCostcentre'] ?? '',
      wowoTargetDate: json['wowoTargetDate'],
      wowoStartDate: json['wowoStartDate'],
      wowoEndDate: json['wowoEndDate'],
      wowoJobRequest: json['wowoJobRequest'],
      wowoZone: json['wowoZone'],
      wowoFunction: json['wowoFunction'],
      wowoFeedbackNote: json['wowoFeedbackNote'],
      wowoEquipmentDescription: json['wowoEquipmentDescription'] ?? '',
      wowoActionEntityDescription: json['wowoActionEntityDescription'],
      wowoCostcentreDescription: json['wowoCostcentreDescription'],
      wowoJobClassDescription: json['wowoJobClassDescription'],
      wowoJobTypeDescription: json['wowoJobTypeDescription'],
      wowoSupervisorDescription: json['wowoSupervisorDescription'],
      mdjbDescription: json['mdjbDescription'],
      wowoString1: json['wowoString1'],
      wowoString2: json['wowoString2'],
      wowoString4: json['wowoString4'],
      mdusDescription: json['mdusDescription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pkWorkOrder': pkWorkOrder,
      'wowoCode': wowoCode,
      'wowoUserStatus': wowoUserStatus,
      'wowoEquipment': wowoEquipment,
      'wowoJob': wowoJob,
      'wowoJobType': wowoJobType,
      'wowoJobClass': wowoJobClass,
      'wowoPriority': wowoPriority,
      'wowoActionEntity': wowoActionEntity,
      'wowoRequestEntity': wowoRequestEntity,
      'wowoScheduleDate': wowoScheduleDate,
      'wowoSupervisor': wowoSupervisor,
      'wowoCostcentre': wowoCostcentre,
      'wowoTargetDate': wowoTargetDate,
      'wowoStartDate': wowoStartDate,
      'wowoEndDate': wowoEndDate,
      'wowoJobRequest': wowoJobRequest,
      'wowoZone': wowoZone,
      'wowoFunction': wowoFunction,
      'wowoFeedbackNote': wowoFeedbackNote,
      'wowoEquipmentDescription': wowoEquipmentDescription,
      'wowoActionEntityDescription': wowoActionEntityDescription,
      'wowoCostcentreDescription': wowoCostcentreDescription,
      'wowoJobClassDescription': wowoJobClassDescription,
      'wowoJobTypeDescription': wowoJobTypeDescription,
      'wowoSupervisorDescription': wowoSupervisorDescription,
      'mdjbDescription': mdjbDescription,
      'wowoString1': wowoString1,
      'wowoString2': wowoString2,
      'wowoString4': wowoString4,
      'mdusDescription': mdusDescription,
    };
  }

  String get workOrderNumber => wowoCode.toString();
}

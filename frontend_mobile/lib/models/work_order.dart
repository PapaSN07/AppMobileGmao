import 'package:appmobilegmao/models/ot_status.dart';

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

  // Taux de réalisation
  final double? wowoCompletionRate; // AJOUTÉ

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
    this.wowoCompletionRate, //  AJOUTÉ
  });

  /// Taux saisi dans Coswin (`wowoLongString2`) : nombre en tête, suivi de « % »
  /// et parfois d'un texte (« 100% suite vandalisme » → 100). Null si absent.
  static double? parseCompletionRate(dynamic raw) {
    final m = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*%').firstMatch(raw?.toString() ?? '');
    if (m == null) return null;
    final value = double.tryParse(m.group(1)!.replaceAll(',', '.'));
    return value?.clamp(0, 100).toDouble();
  }

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    final extra = json['workOrderExtraViewworkorderfind'] as Map<String, dynamic>?;

    // Taux de réalisation : valeur saisie dans Coswin (wowoLongString2, ex. « 75% »),
    // sinon valeur fournie, sinon déduite du statut en dernier recours.
    final double? completionRate = parseCompletionRate(json['wowoLongString2']) ??
        double.tryParse(json['wowoCompletionRate']?.toString() ?? '') ??
        OTStatus.completionRate(json['wowoUserStatus']?.toString());

    // Extraction robuste des descriptions (Coswin natif vs format aplati)
    final equipDesc = json['wowoEquipmentDescription'] ??
        extra?['ereqDescription'] ??
        json['wowoSystemEquipmentDescription'] ??
        '';

    final jobDesc = json['mdjbDescription'] ??
        extra?['mdjbDescription'] ??
        json['wowoJob'] ??
        '';

    return WorkOrder(
      wowoCompletionRate: completionRate,
      pkWorkOrder: json['pkWorkOrder'] is int
          ? json['pkWorkOrder']
          : int.tryParse(json['pkWorkOrder']?.toString() ?? '') ?? 0,
      wowoCode: json['wowoCode'] is int
          ? json['wowoCode']
          : int.tryParse(json['wowoCode']?.toString() ?? '') ?? 0,
      wowoUserStatus: (json['wowoUserStatus'] ?? '').toString(),
      wowoEquipment: (json['wowoEquipment'] ?? '').toString(),
      wowoJob: (json['wowoJob'] ?? '').toString(),
      wowoJobType: (json['wowoJobType'] ?? '').toString(),
      wowoJobClass: (json['wowoJobClass'] ?? '').toString(),
      wowoPriority: json['wowoPriority']?.toString(),
      wowoActionEntity: (json['wowoActionEntity'] ?? '').toString(),
      wowoRequestEntity: (json['wowoRequestEntity'] ?? '').toString(),
      wowoScheduleDate: json['wowoScheduleDate']?.toString(),
      wowoSupervisor: json['wowoSupervisor']?.toString(),
      wowoCostcentre: (json['wowoCostcentre'] ?? '').toString(),
      wowoTargetDate: json['wowoTargetDate']?.toString(),
      wowoStartDate: json['wowoStartDate']?.toString(),
      wowoEndDate: json['wowoEndDate']?.toString(),
      wowoJobRequest: json['wowoJobRequest']?.toString(),
      wowoZone: json['wowoZone']?.toString(),
      wowoFunction: json['wowoFunction']?.toString(),
      wowoFeedbackNote: json['wowoFeedbackNote']?.toString(),
      wowoEquipmentDescription: equipDesc.toString(),
      wowoActionEntityDescription: json['wowoActionEntityDescription']?.toString(),
      wowoCostcentreDescription: json['wowoCostcentreDescription']?.toString(),
      wowoJobClassDescription: json['wowoJobClassDescription']?.toString(),
      wowoJobTypeDescription: json['wowoJobTypeDescription']?.toString(),
      wowoSupervisorDescription: json['wowoSupervisorDescription']?.toString(),
      mdjbDescription: jobDesc.toString(),
      wowoString1: json['wowoString1']?.toString(),
      wowoString2: json['wowoString2']?.toString(),
      wowoString4: json['wowoString4']?.toString(),
      mdusDescription: json['mdusDescription']?.toString(),
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
      'wowoCompletionRate': wowoCompletionRate, //  AJOUTÉ
    };
  }

  String get workOrderNumber => wowoCode.toString();
}

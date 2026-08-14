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

  static List<WorkRequest> getMockData() {
    return [
      WorkRequest(
        pkWorkRequest: 1,
        dinqCode: 'DI00062853',
        dinqUserStatus: '0. Créée',
        dinqEquipment: 'LM0308FAFROTRF1',
        dinqEquipmentDescription: 'POSTE FANN FROBENIUS - TRANSFORMATEUR',
        dinqDescription: 'DECHARGE PARTIELLE SUR CELLULE HTA ET ECHAUFFEMENT CONSTATE LORS DE LA VISITE THERMIQUE.',
        dinqPriority: 'URGENT',
        dinqAskDate: '2026-07-24T13:41:00Z',
        dinqTargetDate: '2026-07-24T18:00:00Z',
        dinqSupervisor: 'ERIC DASYLVA CARDOZO',
        dinqCostcentre: 'DD303',
        dinqCostcentreDescription: 'CC / Mails',
        dinqZone: 'DAKAR',
        dinqActionEntity: 'SDDV',
        dinqRequestEntity: 'SDDV',
        mailsToNotify: 'Cheikhousoumar.dia@senelec.sn;papamadou.niang@senelec.sn',
        dateDebut: '2026-07-24T13:37:00Z',
        dateFin: '2026-07-24T13:37:00Z',
      ),
      WorkRequest(
        pkWorkRequest: 2,
        dinqCode: 'BRC-001235',
        dinqUserStatus: '3. OT créé',
        dinqEquipment: 'LM0902ALALBTR1',
        dinqEquipmentDescription: 'CABLE LIAISON BT HTA',
        dinqDescription: 'Défaut câble entre Saly vélingara extension et Amisack city.',
        dinqPriority: 'URGENT',
        dinqAskDate: '2026-07-26T22:03:00Z',
        dinqTargetDate: '2026-07-27T08:00:00Z',
        dinqSupervisor: 'Mouhamadou Mansour KEBE',
        dinqCostcentre: 'DD304',
        dinqCostcentreDescription: 'CC / Mails',
        dinqZone: 'THIES',
        dinqActionEntity: 'SEM',
        dinqRequestEntity: 'SEM',
        mailsToNotify: 'kebe.m@senelec.sn',
        dateDebut: '2026-07-26T22:00:00Z',
      ),
      WorkRequest(
        pkWorkRequest: 3,
        dinqCode: 'BRC-001250',
        dinqUserStatus: '0. Créée',
        dinqEquipment: 'LM1201PACL12TR2',
        dinqEquipmentDescription: 'POSTE ALASSANE DJIGO CELLULE PROTEC',
        dinqDescription: 'Câble incriminé entre Zam Zam - Cabine Beyri Baïla Dia.',
        dinqPriority: 'NORMAL',
        dinqAskDate: '2026-07-25T14:50:00Z',
        dinqSupervisor: 'ERIC DASYLVA CARDOZO',
        dinqZone: 'DAKAR',
        dinqActionEntity: 'SEM',
        dinqRequestEntity: 'SEM',
        mailsToNotify: 'eric.cardozo@senelec.sn',
      ),
      WorkRequest(
        pkWorkRequest: 4,
        dinqCode: 'DI00062657',
        dinqUserStatus: '3. OT créé',
        dinqEquipment: 'LM0905PACONSU1',
        dinqEquipmentDescription: 'POSTE CONSULAT ITALIE',
        dinqDescription: 'Demande de déplacement de câble électrique et installation pour la sécurité du compte.',
        dinqPriority: 'DEPL_SUPPORT',
        dinqAskDate: '2026-07-24T15:47:00Z',
        dinqSupervisor: 'Nafissatou DIAGNE',
        dinqZone: 'DAKAR',
        dinqActionEntity: 'UED/N-DV',
        dinqRequestEntity: 'UED/N-DV',
        mailsToNotify: 'nafissatou.diagne@senelec.sn',
      ),
      WorkRequest(
        pkWorkRequest: 5,
        dinqCode: 'DI00062656',
        dinqUserStatus: '3. OT créé',
        dinqEquipment: 'LM0312PAFANN1',
        dinqEquipmentDescription: 'POSTE FANN RESIDENCE',
        dinqDescription: 'Visite et prise en charge suite échauffement constaté sur le disjoncteur général.',
        dinqPriority: 'URGENT',
        dinqAskDate: '2026-07-24T15:43:00Z',
        dinqSupervisor: 'Mouhamadou Mansour KEBE',
        dinqZone: 'DAKAR',
        dinqActionEntity: 'AY',
        dinqRequestEntity: 'UED/N-DV',
      ),
    ];
  }
}

export interface WorkRequest {
    pkWorkRequest: number;
    dinqCode: string;
    dinqUserStatus: string;
    dinqEquipment: string;
    dinqEquipmentDescription: string;
    dinqPriority?: string;
    dinqSupervisor?: string;
    dinqCostcentre?: string;
    dinqCostcentreDescription?: string;
    dinqZone?: string;
    dinqActionEntity?: string;
    dinqRequestEntity?: string;
    dinqDescription: string;
    mailsToNotify?: string;
    dinqAskDate?: string;
    dateDebut?: string;
    dateFin?: string;
}

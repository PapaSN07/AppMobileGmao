export interface EquipmentHistory {
    id: string;
    commentaire?: string;
    dateHistoryCreatedAt?: Date;
    equipmentId: string;
    famille?: string;
    unite?: string;
    centreCharge?: string;
    zone?: string;
    entity?: string;
    feeder?: string;
    feederDescription?: string;
    location?: string;
    code: string;
    codeParent?: string;
    description: string;
    createdAt?: Date;
    updatedAt?: Date;
    createdBy?: string;
    validatedBy?: string;
    isUpdate?: boolean;
    isNew?: boolean;
    isApproved?: boolean;
    isRejected?: boolean;
}
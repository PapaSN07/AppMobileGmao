/**
 * ✅ Attribut d'un équipement historisé
 */
export interface EquipmentHistoryAttribute {
    id?: string;
    specification?: string;
    famille?: string;
    index?: number;
    name?: string;
    value?: string;
    code?: string;
    description?: string;
    createdAt?: string;
    updatedAt?: string;
    isCopyOt?: boolean;
}

/**
 * ✅ Équipement dans l'historique (archivé ou en cours)
 */
export interface EquipmentHistoryItem {
    id: string;
    code: string;
    famille?: string;
    zone?: string;
    entity?: string;
    unite?: string;
    centreCharge?: string;
    description?: string;
    feeder?: string;
    feederDescription?: string;
    localisation?: string;
    codeParent?: string;
    createdAt?: string;
    updatedAt?: string;
    createdBy?: string;
    judgedBy?: string;
    isUpdate?: boolean;
    isNew?: boolean;
    isApproved?: boolean;
    isRejected?: boolean;
    isDeleted?: boolean;
    commentaire?: string;
    status: 'archived' | 'in_progress';
    attributes?: EquipmentHistoryAttribute[];
    
    // Champs spécifiques aux historiques archivés
    equipmentId?: string;
    dateHistoryCreatedAt?: string;
}

/**
 * ✅ Réponse API pour l'historique d'un prestataire
 */
export interface PrestataireHistoryResponse {
    success: boolean;
    message: string;
    data: EquipmentHistoryItem[];
    count: number;
    prestataire: string;
}
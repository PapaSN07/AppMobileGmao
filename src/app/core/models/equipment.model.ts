import { Attribute } from './attribute.model';

export interface Equipment {
    id: string;
    famille: string;
    unite: string;
    centreCharge: string;
    zone: string;
    entity: string;
    feeder?: string;
    feederDescription?: string;
    localisation?: string;
    code: string;
    codeParent?: string;
    description: string;
    createdAt?: Date;
    updatedAt?: Date;
    createdBy?: string;
    judgedBy?: string;
    isUpdate?: boolean;
    isNew?: boolean;
    isApproved?: boolean;
    isRejected?: boolean;
    isDeleted?: boolean;
    attributes?: Attribute[];
    commentaire?: string;
}

export interface EquipmentResponse {
    success?: boolean;
    data?: Equipment[];
    count?: number;
    message?: string;
}

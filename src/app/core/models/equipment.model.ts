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
    validatedBy?: string;
    isUpdate?: boolean;
    isNew?: boolean;
    isApproved?: boolean;
    attributes?: Attribute[];
}

export interface EquipmentResponse {
    success?: boolean;
    data?: Equipment[];
    count?: number;
    message?: string;
}

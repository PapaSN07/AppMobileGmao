export interface AttributeHistory {
    id: string;
    historyId: string;
    specification: string;
    famille: string;
    indx: string;
    attributeName: string;
    value: string;
    code: string;
    description?: string;
    isCopyOt?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
}
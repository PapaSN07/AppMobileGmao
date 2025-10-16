export interface Attribute {
    id: string;
    specification: string;
    famille: string;
    indx: string;
    attributeName: string;
    value: string;
    code: string;
    description?: string;
    isCopyOT?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
}
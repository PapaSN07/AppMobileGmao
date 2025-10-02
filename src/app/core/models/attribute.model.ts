export interface Attribute {
    id: string;
    specification: string;
    famille: string;
    index: string;
    attributeName: string;
    attributeValue: string;
    code: string;
    description?: string;
    isCopyOT?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
}
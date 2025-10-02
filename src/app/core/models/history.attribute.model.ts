export interface AttributeHistory {
    id: string;
    historyId: string;
    attributeId: string;
    attributeName: string;
    attributeValue: string;
    code: string;
    description?: string;
    createdAt?: Date;
    updatedAt?: Date;
}
export class Tools {
    // Méthode pour transformer les clés snake_case en camelCase
    static transformKeys(obj: any): any {
        if (obj === null || typeof obj !== 'object') return obj;
        if (Array.isArray(obj)) return obj.map(item => this.transformKeys(item));
        const transformed: any = {};
        for (const key in obj) {
            if (obj.hasOwnProperty(key)) {
                const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
                transformed[camelKey] = this.transformKeys(obj[key]);
            }
        }
        return transformed;
    }
}
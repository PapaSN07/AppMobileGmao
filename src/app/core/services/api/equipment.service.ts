import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { Equipment, EquipmentResponse } from '../../models';

@Injectable({ providedIn: 'root' })
export class EquipmentService {
    private apiUrl = `${environment.apiUrl}/equipments`;

    constructor(private http: HttpClient) {}

    getAll(): Observable<Equipment[]> {
        return this.http.get<EquipmentResponse>(this.apiUrl).pipe(
            map(response => (response.data || []).map(equipment => this.transformKeys(equipment)))
        );
    }

    getAllNoApproved(): Observable<Equipment[]> {
        return this.getAll().pipe(
            map(equipments => equipments.filter(equipment => !equipment.isApproved && equipment.isNew))
        );
    }

    getAllNoModified(): Observable<Equipment[]> {
        return this.getAll().pipe(
            map(equipments => equipments.filter(equipment => !equipment.isApproved && equipment.isUpdate))
        );
    }

    getById(id: string): Observable<Equipment> {
        return this.http.get<Equipment>(`${this.apiUrl}/${id}`);
    }

    create(equipment: Equipment): Observable<Equipment> {
        return this.http.post<Equipment>(this.apiUrl, equipment);
    }

    update(id: string, equipment: Equipment): Observable<Equipment> {
        return this.http.patch<Equipment>(`${this.apiUrl}/${id}`, equipment);
    }

    delete(id: string): Observable<void> {
        return this.http.delete<void>(`${this.apiUrl}/${id}`);
    }

    // Méthode pour transformer les clés snake_case en camelCase
    private transformKeys(obj: any): any {
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

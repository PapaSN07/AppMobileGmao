import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { Equipment, EquipmentResponse } from '../../models';
import { Tools } from '../utils';

@Injectable({ providedIn: 'root' })
export class EquipmentService {
    private API_URL = `${environment.API_URL}/equipments`;

    constructor(private http: HttpClient) {
        this.getAll();
    }

    private dataSource: Observable<Equipment[]> = new Observable<Equipment[]>();

    getAll(): Observable<Equipment[]> {
        this.dataSource = this.http.get<EquipmentResponse>(this.API_URL).pipe(
            map(response => (response.data || []).map(equipment => Tools.transformKeys(equipment)))
        );
        return this.dataSource;
    }

    getAllNoApproved(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map(equipments => equipments.filter(equipment => equipment.isNew && !equipment.isApproved && !equipment.isRejected))
        );
    }

    getAllNoModified(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map(equipments => equipments.filter(equipment => equipment.isUpdate && !equipment.isApproved && !equipment.isRejected))
        );
    }

    getAllApproved(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map(equipments => equipments.filter(equipment => equipment.isApproved))
        );
    }

    getAllHistory(): Observable<Equipment[]> {
        return this.http.get<EquipmentResponse>(`${this.API_URL}/history`).pipe(
            map(response => (response.data || []).map(equipment => Tools.transformKeys(equipment)))
        );
    }

    getById(id: string): Observable<Equipment> {
        return this.http.get<Equipment>(`${this.API_URL}/${id}`);
    }

    update(id: string, equipment: Equipment): Observable<Equipment> {
        return this.http.post<Equipment>(`${this.API_URL}/${id}`, equipment);
    }

    delete(id: string): Observable<void> {
        return this.http.delete<void>(`${this.API_URL}/${id}`);
    }

    archive(equipmentIds: string[]): Observable<any> {
        return this.http.post(`${this.API_URL}/archive`, { equipment_ids: equipmentIds });
    }
}

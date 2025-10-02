import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../../../environments/environment';
import { Equipment } from '../../models';

@Injectable({ providedIn: 'root' })
export class EquipmentService {
    private apiUrl = `${environment.apiUrl}/equipment`;

    constructor(private http: HttpClient) {}

    getAll(): Observable<Equipment[]> {
        return this.http.get<Equipment[]>(this.apiUrl);
    }

    getById(id: string): Observable<Equipment> {
        return this.http.get<Equipment>(`${this.apiUrl}/${id}`);
    }

    create(equipment: Equipment): Observable<Equipment> {
        return this.http.post<Equipment>(this.apiUrl, equipment);
    }

    update(id: string, equipment: Equipment): Observable<Equipment> {
        return this.http.put<Equipment>(`${this.apiUrl}/${id}`, equipment);
    }

    delete(id: string): Observable<void> {
        return this.http.delete<void>(`${this.apiUrl}/${id}`);
    }
}

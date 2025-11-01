import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { 
    Equipment, 
    EquipmentResponse, 
    PrestataireHistoryResponse 
} from '../../models';
import { Tools } from '../utils';

@Injectable({ providedIn: 'root' })
export class EquipmentService {
    private API_URL = `${environment.API_URL}/equipments`;

    constructor(private http: HttpClient) {
        this.getAll();
    }

    private dataSource: Observable<Equipment[]> = new Observable<Equipment[]>();

    /**
     * Trie les équipements du plus récent au plus ancien
     * @param equipments - Liste d'équipements à trier
     * @returns Liste triée par date décroissante
     */
    private sortByDateDesc(equipments: Equipment[]): Equipment[] {
        return equipments.sort((a, b) => {
            // Priorité 1: updatedAt (si existe)
            const dateA = a.updatedAt ? new Date(a.updatedAt).getTime() : a.createdAt ? new Date(a.createdAt).getTime() : 0;
            const dateB = b.updatedAt ? new Date(b.updatedAt).getTime() : b.createdAt ? new Date(b.createdAt).getTime() : 0;

            return dateB - dateA; // Ordre décroissant (plus récent en premier)
        });
    }

    getAll(): Observable<Equipment[]> {
        this.dataSource = this.http.get<EquipmentResponse>(this.API_URL).pipe(
            map((response) => {
                const equipments = (response.data || []).map((equipment) => Tools.transformKeys(equipment));
                return this.sortByDateDesc(equipments);
            })
        );
        return this.dataSource;
    }

    getAllNoApproved(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map((equipments) => {
                const filtered = equipments.filter((equipment) => equipment.isNew && !equipment.isApproved && !equipment.isRejected);
                return this.sortByDateDesc(filtered);
            })
        );
    }

    getAllNoModified(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map((equipments) => {
                const filtered = equipments.filter((equipment) => equipment.isUpdate && !equipment.isApproved && !equipment.isRejected);
                return this.sortByDateDesc(filtered);
            })
        );
    }

    getAllApproved(): Observable<Equipment[]> {
        return this.dataSource.pipe(
            map((equipments) => {
                const filtered = equipments.filter((equipment) => equipment.isApproved);
                return this.sortByDateDesc(filtered);
            })
        );
    }

    getAllHistory(): Observable<Equipment[]> {
        return this.http.get<EquipmentResponse>(`${this.API_URL}/history`).pipe(
            map((response) => {
                const equipments = (response.data || []).map((equipment) => Tools.transformKeys(equipment));
                return this.sortByDateDesc(equipments);
            })
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

    /**
     * ✅ NOUVEAU: Récupère l'historique complet d'un prestataire
     * Principe DRY: Méthode réutilisable pour tous les prestataires
     * @param username - Nom d'utilisateur du prestataire
     * @returns Observable avec l'historique complet
     */
    getPrestataireHistory(username: string): Observable<PrestataireHistoryResponse> {
        return this.http.get<PrestataireHistoryResponse>(
            `${this.API_URL}/history/prestataire/${username}`
        ).pipe(
            map(response => ({
                ...response,
                data: response.data.map(item => Tools.transformKeys(item))
            }))
        );
    }
}

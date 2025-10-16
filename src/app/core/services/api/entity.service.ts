import { Injectable } from '@angular/core';
import { environment } from '../../../../../environments/environment';
import { HttpClient } from '@angular/common/http';
import { EntityModel } from '../../models';
import { Tools } from '../utils';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class EntityService {
    private apiUrl = `${environment.apiUrl}/entity`;

    constructor(private http: HttpClient) {}

    getAllEntities(): Observable<EntityModel[]> {
        return this.http
            .get<{ data: EntityModel[] }>(this.apiUrl)
            .pipe(map((response) => (response.data || []).map((entity: EntityModel) => Tools.transformKeys(entity))));
    }
}

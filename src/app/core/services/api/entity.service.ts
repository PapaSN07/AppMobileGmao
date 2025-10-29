import { Injectable } from '@angular/core';
import { environment } from '../../../../../environments/environment';
import { HttpClient } from '@angular/common/http';
import { EntityModel } from '../../models';
import { Tools } from '../utils';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable({ providedIn: 'root' })
export class EntityService {
    private API_URL = `${environment.API_URL}/entity`;

    constructor(private http: HttpClient) {}

    getAllEntities(): Observable<EntityModel[]> {
        return this.http
            .get<{ data: EntityModel[] }>(this.API_URL)
            .pipe(map((response) => (response.data || []).map((entity: EntityModel) => Tools.transformKeys(entity))));
    }
}

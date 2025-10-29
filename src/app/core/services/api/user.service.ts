import { Injectable } from "@angular/core";
import { environment } from "../../../../../environments/environment";
import { User } from "../../models";
import { HttpClient } from "@angular/common/http";
import { map, Observable } from "rxjs";

@Injectable({ providedIn: 'root' })
export class UserService {
    private API_URL = `${environment.API_URL}/users`;

    constructor(private http: HttpClient) {}

    addUser(user: User): Observable<User> {
        return this.http.post<User>(this.API_URL, user);
    }

    getAllUsers(supervisorId: string): Observable<User[]> {
        return this.http.get<User[]>(`${this.API_URL}/${supervisorId}`);
    }

    updateUser(id: string, user: Partial<User>): Observable<User> {
        return this.http.patch<User>(`${this.API_URL}/${id}`, user);
    }

    deleteUser(id: string): Observable<void> {
        return this.http.delete<void>(`${this.API_URL}/${id}`);
    }
}
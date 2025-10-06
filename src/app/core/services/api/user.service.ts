import { Injectable } from "@angular/core";
import { environment } from "../../../../../environments/environment";
import { User } from "../../models";
import { HttpClient } from "@angular/common/http";
import { Observable } from "rxjs";

@Injectable({ providedIn: 'root' })
export class UserService {
    private apiUrl = `${environment.apiUrl}/users`;

    constructor(private http: HttpClient) {}

    addUser(user: User): Observable<User> {
        return this.http.post<User>(this.apiUrl, user);
    }

    getAllUsers(supervisorId: string): Observable<User[]> {
        return this.http.get<User[]>(`${this.apiUrl}/${supervisorId}`);
    }

    updateUser(id: string, user: Partial<User>): Observable<User> {
        return this.http.put<User>(`${this.apiUrl}/${id}`, user);
    }

    deleteUser(id: string): Observable<void> {
        return this.http.delete<void>(`${this.apiUrl}/${id}`);
    }
}
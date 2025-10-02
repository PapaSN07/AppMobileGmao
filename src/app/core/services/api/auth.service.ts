import { HttpClient } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Router } from "@angular/router"; // Ajout de l'import pour Router
import { environment } from "../../../../../environments/environment";
import { Observable, tap } from "rxjs";
import { AuthResponse, DecodedToken, User } from "../../models/user.model";
import { jwtDecode } from "jwt-decode";

@Injectable({ providedIn: 'root' })
export class AuthService {
    private apiUrl = environment.apiUrlAuth;

    constructor(private http: HttpClient, private router: Router) {}
    
    login(username: string, password: string): Observable<AuthResponse> {
        const credentials = { username, password };
        return this.http.post<AuthResponse>(`${this.apiUrl}/login`, credentials).pipe(
            tap(response => {
                if (response.success) {
                    this.storeTokens(response);
                }
            })
        );
    }

    private storeTokens(response: AuthResponse): void {
        sessionStorage.setItem('access_token', response.access_token);
        sessionStorage.setItem('refresh_token', response.refresh_token);
        sessionStorage.setItem('user', JSON.stringify(response.data));
        
        // Décoder le token pour obtenir la vraie date d'expiration
        const decoded = this.decodeToken(response.access_token);
        if (decoded?.exp) {
            // exp est en secondes, on le convertit en millisecondes
            sessionStorage.setItem('token_expiry', (decoded.exp * 1000).toString());
        }
    }

    private decodeToken(token: string): DecodedToken | null {
        try {
            return jwtDecode<DecodedToken>(token);
        } catch (error) {
            console.error('Erreur lors du décodage du token', error);
            return null;
        }
    }

    isAuthenticated(): boolean {
        const token = this.getAccessToken();
        if (!token) return false;

        const decoded = this.decodeToken(token);
        if (!decoded) return false;

        // Vérifier si le token n'est pas expiré
        const currentTime = Date.now();
        const expiryTime = decoded.exp * 1000; // Conversion en millisecondes
        
        return currentTime < expiryTime;
    }

    isTokenExpired(): boolean {
        const token = this.getAccessToken();
        if (!token) return true;

        const decoded = this.decodeToken(token);
        if (!decoded) return true;

        const currentTime = Math.floor(Date.now() / 1000);
        return decoded.exp < currentTime;
    }

    getAccessToken(): string | null {
        return sessionStorage.getItem('access_token');
    }

    getRefreshToken(): string | null {
        return sessionStorage.getItem('refresh_token');
    }

    getUser(): User | null {
        const userStr = sessionStorage.getItem('user');
        return userStr ? JSON.parse(userStr) : null;
    }

    getUserFromToken(): DecodedToken | null {
        const token = this.getAccessToken();
        if (!token) return null;
        return this.decodeToken(token);
    }

    refreshToken(): Observable<AuthResponse> {
        const refreshToken = this.getRefreshToken();
        return this.http.post<AuthResponse>(`${this.apiUrl}/refresh`, { refresh_token: refreshToken }).pipe(
            tap(response => {
                if (response.success) {
                    sessionStorage.setItem('access_token', response.access_token);
                    
                    // Mettre à jour l'expiration avec la vraie valeur du token
                    const decoded = this.decodeToken(response.access_token);
                    if (decoded?.exp) {
                        sessionStorage.setItem('token_expiry', (decoded.exp * 1000).toString());
                    }
                }
            })
        );
    }

    logout(): void {
        let user = this.getUser();
        
        // Appel au backend pour invalider le token avant la navigation
        this.http.post(`${this.apiUrl}/logout`, { username: user?.username }).subscribe({
            next: () => {
                // Suppression des données de session après l'appel réussi
                sessionStorage.removeItem('access_token');
                sessionStorage.removeItem('refresh_token');
                sessionStorage.removeItem('user');
                sessionStorage.removeItem('token_expiry');
                
                // Navigation Angular recommandée au lieu de window.location.href
                this.router.navigate(['/auth/login']);
            },
            error: (err) => {
                console.error('Erreur lors du logout', err);
                // Même en cas d'erreur, nettoyer la session et naviguer
                sessionStorage.removeItem('access_token');
                sessionStorage.removeItem('refresh_token');
                sessionStorage.removeItem('user');
                sessionStorage.removeItem('token_expiry');
                this.router.navigate(['/auth/login']);
            }
        });
    }
}
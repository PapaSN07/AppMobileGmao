import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { environment } from '../../../../../environments/environment';
import { Observable, tap, interval, Subscription } from 'rxjs';
import { AuthResponse, DecodedToken, User } from '../../models/user.model';
import { jwtDecode } from 'jwt-decode';
import { WebSocketService } from '.';

@Injectable({ providedIn: 'root' })
export class AuthService {
    private apiUrl = environment.apiUrlAuth;
    private tokenRefreshSubscription?: Subscription;

    constructor(private websocketService: WebSocketService, private http: HttpClient, private router: Router) {
        // Démarrer le rafraîchissement automatique au démarrage de l'app
        this.startTokenRefreshTimer();
    }

    login(username: string, password: string): Observable<AuthResponse> {
        const credentials = { username, password };
        return this.http.post<AuthResponse>(`${this.apiUrl}/login`, credentials).pipe(
            tap((response) => {
                if (response.success) {
                    this.storeTokens(response);
                    this.startTokenRefreshTimer(); // Démarrer le timer après login

                    // ✅ NOUVEAU : Connecter le WebSocket après login
                    this.websocketService.connect().catch(err => {
                        console.error('❌ Erreur connexion WebSocket après login:', err);
                    });
                }
            })
        );
    }

    private storeTokens(response: AuthResponse): void {
        sessionStorage.setItem('access_token', response.access_token);
        sessionStorage.setItem('refresh_token', response.refresh_token);
        sessionStorage.setItem('user', JSON.stringify(response.data));

        const decoded = this.decodeToken(response.access_token);
        if (decoded?.exp) {
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
        if (!decoded) {
            this.logout();
            return false;
        }

        const currentTime = Date.now();
        const expiryTime = decoded.exp * 1000;

        if (currentTime >= expiryTime) {
            this.logout();
            return false;
        }

        return true;
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
            tap((response) => {
                if (response.success) {
                    sessionStorage.setItem('access_token', response.access_token);

                    const decoded = this.decodeToken(response.access_token);
                    if (decoded?.exp) {
                        sessionStorage.setItem('token_expiry', (decoded.exp * 1000).toString());
                    }
                }
            })
        );
    }
    
    hasRole(roles: string[]): boolean {
        const user = this.getUser();
        return user ? roles.includes(user.role) : false;
    }

    isAdmin(): boolean {
        return this.hasRole(['ADMIN']);
    }

    isPrestataire(): boolean {
        return this.hasRole(['PRESTATAIRE']);
    }

    /**
     * Démarre un timer qui vérifie toutes les minutes si le token expire bientôt (dans les 5 prochaines minutes).
     * Si oui, il rafraîchit automatiquement le token.
     */
    private startTokenRefreshTimer(): void {
        // Arrêter le timer précédent s'il existe
        this.stopTokenRefreshTimer();

        // Vérifier toutes les minutes (60000 ms)
        this.tokenRefreshSubscription = interval(60000).subscribe(() => {
            const token = this.getAccessToken();
            if (!token) return;

            const decoded = this.decodeToken(token);
            if (!decoded) return;

            const currentTime = Math.floor(Date.now() / 1000);
            const timeUntilExpiry = decoded.exp - currentTime;

            // Si le token expire dans moins de 5 minutes (300 secondes), le rafraîchir
            if (timeUntilExpiry > 0 && timeUntilExpiry < 300) {
                console.log('Token expire bientôt, rafraîchissement automatique...');
                this.refreshToken().subscribe({
                    next: () => console.log('Token rafraîchi automatiquement'),
                    error: (err) => {
                        console.error('Erreur lors du rafraîchissement automatique', err);
                        this.logout();
                    }
                });
            }
        });
    }

    /**
     * Arrête le timer de rafraîchissement du token.
     */
    private stopTokenRefreshTimer(): void {
        if (this.tokenRefreshSubscription) {
            this.tokenRefreshSubscription.unsubscribe();
        }
    }

    logout(): void {
        let user = this.getUser();

        // ✅ NOUVEAU : Déconnecter le WebSocket avant logout
        this.websocketService.disconnect();

        // Arrêter le timer de rafraîchissement
        this.stopTokenRefreshTimer();

        this.http.post(`${this.apiUrl}/logout`, { username: user?.username }).subscribe({
            next: () => {
                this.clearSession();
                this.router.navigate(['/auth/login']);
            },
            error: (err) => {
                console.error('Erreur lors du logout', err);
                this.clearSession();
                this.router.navigate(['/auth/login']);
            }
        });
    }

    private clearSession(): void {
        sessionStorage.removeItem('access_token');
        sessionStorage.removeItem('refresh_token');
        sessionStorage.removeItem('user');
        sessionStorage.removeItem('token_expiry');
    }
}

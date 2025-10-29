import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, BehaviorSubject, throwError, timer } from 'rxjs';
import { catchError, retry, shareReplay, switchMap, tap } from 'rxjs/operators';
import { environment } from '../../../../../environments/environment';
import { DashboardStatistics } from '../../models/statistics.model';

@Injectable({ providedIn: 'root' })
export class StatisticsService {
    private apiUrl = `${environment.API_URL}/statistics`;
    private cache$ = new BehaviorSubject<DashboardStatistics | null>(null);
    private cacheTimestamp = 0;
    private readonly CACHE_TTL = 5 * 60 * 1000; // 5 minutes

    constructor(private http: HttpClient) {}

    /**
     * Récupère les statistiques complètes avec détails
     * @param includeDetails - Inclure les graphiques détaillés
     * @param forceRefresh - Forcer le rafraîchissement du cache
     */
    getStatistics(includeDetails = false, forceRefresh = false): Observable<DashboardStatistics> {
        const now = Date.now();
        const isCacheValid = !forceRefresh && this.cache$.value && now - this.cacheTimestamp < this.CACHE_TTL;

        if (isCacheValid && this.cache$.value) {
            return this.cache$.asObservable() as Observable<DashboardStatistics>;
        }

        return this.http.get<DashboardStatistics>(`${this.apiUrl}?include_details=${includeDetails}`).pipe(
            retry({ count: 3, delay: 1000 }),
            tap((data) => {
                this.cache$.next(data);
                this.cacheTimestamp = Date.now();
            }),
            shareReplay(1),
            catchError(this.handleError)
        );
    }

    /**
     * Récupère le résumé des statistiques (version légère)
     */
    getStatisticsSummary(): Observable<DashboardStatistics> {
        return this.http.get<DashboardStatistics>(`${this.apiUrl}/summary`).pipe(retry({ count: 3, delay: 1000 }), catchError(this.handleError));
    }

    /**
     * Configure l'auto-refresh des statistiques
     * @param intervalMs - Intervalle en millisecondes (par défaut 5 minutes)
     */
    startAutoRefresh(intervalMs = 5 * 60 * 1000): Observable<DashboardStatistics> {
        return timer(0, intervalMs).pipe(switchMap(() => this.getStatistics(true, true)));
    }

    /**
     * Vide le cache
     */
    clearCache(): void {
        this.cache$.next(null);
        this.cacheTimestamp = 0;
    }

    /**
     * Gestion centralisée des erreurs HTTP
     */
    private handleError(error: HttpErrorResponse): Observable<never> {
        let errorMessage = 'Une erreur est survenue lors du chargement des statistiques';

        if (error.error instanceof ErrorEvent) {
            // Erreur côté client
            errorMessage = `Erreur : ${error.error.message}`;
        } else {
            // Erreur côté serveur
            switch (error.status) {
                case 0:
                    errorMessage = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
                    break;
                case 401:
                    errorMessage = 'Session expirée. Veuillez vous reconnecter.';
                    break;
                case 403:
                    errorMessage = 'Accès non autorisé aux statistiques.';
                    break;
                case 500:
                    errorMessage = 'Erreur serveur. Réessayez plus tard.';
                    break;
                default:
                    errorMessage = `Erreur ${error.status} : ${error.error?.detail || error.message}`;
            }
        }

        console.error('❌ StatisticsService Error:', errorMessage, error);
        return throwError(() => new Error(errorMessage));
    }
}

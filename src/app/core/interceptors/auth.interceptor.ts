import { HttpErrorResponse, HttpInterceptorFn, HttpRequest, HttpHandlerFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError, BehaviorSubject, filter, take, Observable } from 'rxjs';
import { AuthService } from '../services/api/auth.service';

let isRefreshing = false;
const refreshTokenSubject = new BehaviorSubject<string | null>(null);

export const authInterceptor: HttpInterceptorFn = (req, next) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    // Ne pas ajouter le token pour les requêtes d'authentification
    if (req.url.includes('/login') || req.url.includes('/refresh')) {
        return next(req);
    }

    const token = authService.getAccessToken();

    // Ajouter le token si disponible
    if (token) {
        req = req.clone({
            setHeaders: {
                Authorization: `Bearer ${token}`
            }
        });
    }

    return next(req).pipe(
        catchError((error: HttpErrorResponse) => {
            // Si erreur 401 et token expiré, tenter le refresh
            if (error.status === 401 && authService.isTokenExpired()) {
                return handleTokenRefresh(req, next, authService, router);
            }
            return throwError(() => error);
        })
    );
};

function handleTokenRefresh(
    req: HttpRequest<any>,
    next: HttpHandlerFn,
    authService: AuthService,
    router: Router
): Observable<any> {
    if (!isRefreshing) {
        isRefreshing = true;
        refreshTokenSubject.next(null);

        const refreshToken = authService.getRefreshToken();

        if (!refreshToken) {
            isRefreshing = false;
            authService.logout();
            router.navigate(['/auth/login']);
            return throwError(() => new Error('No refresh token available'));
        }

        return authService.refreshToken().pipe(
            switchMap((response) => {
                isRefreshing = false;
                const newToken = response.access_token;
                refreshTokenSubject.next(newToken);

                // Rejouer la requête avec le nouveau token
                return next(req.clone({
                    setHeaders: {
                        Authorization: `Bearer ${newToken}`
                    }
                }));
            }),
            catchError((error) => {
                isRefreshing = false;
                authService.logout();
                router.navigate(['/auth/login']);
                return throwError(() => error);
            })
        );
    } else {
        // Attendre que le refresh soit terminé
        return refreshTokenSubject.pipe(
            filter(token => token !== null),
            take(1),
            switchMap(token => {
                return next(req.clone({
                    setHeaders: {
                        Authorization: `Bearer ${token}`
                    }
                }));
            })
        );
    }
}

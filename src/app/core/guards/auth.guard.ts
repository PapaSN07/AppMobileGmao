import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/api/auth.service';
import { catchError, map, of } from 'rxjs';

export const authGuard: CanActivateFn = (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    // Si l'utilisateur est authentifié (token valide)
    if (authService.isAuthenticated()) {
        return true;
    }

    // Si le token est expiré mais qu'un refresh token existe, tenter le refresh
    if (authService.isTokenExpired() && authService.getRefreshToken()) {
        return authService.refreshToken().pipe(
            map((response) => {
                if (response.success) {
                    console.log('Token rafraîchi avec succès dans le garde');
                    return true;
                }
                // Si le refresh échoue, rediriger vers login
                router.navigate(['/auth/login'], { queryParams: { returnUrl: state.url } });
                return false;
            }),
            catchError(() => {
                // En cas d'erreur, déconnecter et rediriger
                authService.logout();
                router.navigate(['/auth/login'], { queryParams: { returnUrl: state.url } });
                return of(false);
            })
        );
    }

    // Pas de token ou refresh token invalide, rediriger vers login
    router.navigate(['/auth/login'], { queryParams: { returnUrl: state.url } });
    return false;
};

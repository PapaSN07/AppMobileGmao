import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from '../services/api/auth.service';

/**
 * ✅ Guard qui vérifie si l'utilisateur PRESTATAIRE doit changer son mot de passe
 * Principe SOLID: Single Responsibility - une seule responsabilité (vérification first login)
 */
export const firstLoginGuard: CanActivateFn = (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    const user = authService.getUser();

    // ✅ Si pas d'utilisateur connecté, rediriger vers login
    if (!user) {
        return router.createUrlTree(['/auth/login']);
    }

    // ✅ Si PRESTATAIRE et première connexion, forcer le changement de mot de passe
    if (user.role === 'PRESTATAIRE' && user.is_first_time === true) {
        // Autoriser uniquement la route de changement de mot de passe
        if (state.url !== '/auth/change-password') {
            return router.createUrlTree(['/auth/change-password']);
        }
    }

    return true;
};
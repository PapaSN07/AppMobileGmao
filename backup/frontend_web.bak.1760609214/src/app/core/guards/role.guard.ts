import { inject } from '@angular/core';
import { Router, CanActivateFn } from '@angular/router';
import { AuthService } from '../services/api/auth.service';

export const roleGuard: CanActivateFn = (route, state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    const user = authService.getUser();

    if (!user) {
        router.navigate(['/auth/login']);
        return false;
    }

    const requiredRoles = route.data['roles'] as string[];

    if (requiredRoles && !requiredRoles.includes(user.role)) {
        router.navigate(['/auth/access']); // Page d'accès refusé
        return false;
    }

    return true;
};

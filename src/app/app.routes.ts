import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { firstLoginGuard } from './core/guards';

export const routes: Routes = [
    {
        path: '',
        loadComponent: () => import('./layout/app.layout').then((m) => m.AppLayout),
        canActivate: [authGuard],
        children: [
            {
                path: '',
                redirectTo: 'dashboard',
                pathMatch: 'full'
            },
            {
                path: 'dashboard',
                loadComponent: () => import('./features/dashboard/dashboard').then((m) => m.Dashboard),
                canActivate: [authGuard, firstLoginGuard], 
            },
            {
                path: 'equipment',
                loadChildren: () => import('./features/equipment/equipment.routes').then((m) => m.EQUIPMENT_ROUTES)
            },
            {
                path: 'prestataire-history',
                loadComponent: () => import('./features/prestataire/prestataire-history/prestataire-history').then((m) => m.PrestataireHistory),
                canActivate: [authGuard, firstLoginGuard],
            },
            {
                path: 'parameter',
                loadChildren: () => import('./features/parameter/parameter.routes').then((m) => m.PARAMETER_ROUTES)
            }
        ]
    },
    {
        path: 'auth',
        loadChildren: () => import('./features/auth/auth.routes').then((m) => m.AUTH_ROUTES)
    },
    {
        path: 'not-found',
        loadComponent: () => import('./features/notfound/notfound').then((m) => m.Notfound)
    },
    {
        path: '**',
        redirectTo: 'not-found'
    }
];

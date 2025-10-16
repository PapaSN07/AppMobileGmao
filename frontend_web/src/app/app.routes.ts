import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';

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
                loadComponent: () => import('./features/dashboard/dashboard').then((m) => m.Dashboard)
            },
            {
                path: 'equipment',
                loadChildren: () => import('./features/equipment/equipment.routes').then((m) => m.EQUIPMENT_ROUTES)
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

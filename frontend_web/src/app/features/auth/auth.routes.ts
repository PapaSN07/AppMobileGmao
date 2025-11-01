import { Routes } from '@angular/router';
import { authGuard } from '../../core/guards';

export const AUTH_ROUTES: Routes = [
    { 
        path: '', 
        redirectTo: 'login', 
        pathMatch: 'full' 
    },
    { 
        path: 'login', 
        loadComponent: () => import('./components/login/login').then((m) => m.Login) 
    },
    { 
        path: 'access', 
        loadComponent: () => import('./components/access/access').then((m) => m.Access) 
    },
    { 
        path: 'error', 
        loadComponent: () => import('./components/error/error').then((m) => m.Error) 
    },
    { 
        path: 'change-password', 
        loadComponent: () => import('./components/change-password/change-password').then((m) => m.ChangePassword) ,
        canActivate: [authGuard]
    },
];

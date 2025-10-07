import { Routes } from '@angular/router';
import { roleGuard } from '../../core/guards';

export const PARAMETER_ROUTES: Routes = [
  {
    path: 'configuration',
    loadComponent: () => import('./components/configuration/parameter.configuration').then(m => m.ParameterConfiguration),
    canActivate: [roleGuard],
    data: { roles: ['ADMIN'] } // Seulement les ADMIN peuvent créer des comptes
  },
  {
    path: 'users',
    loadComponent: () => import('./components/users/parameter.users').then(m => m.ParameterUsers),
    canActivate: [roleGuard],
    data: { roles: ['ADMIN'] } // Seulement les ADMIN peuvent accéder à cette route
  }
];
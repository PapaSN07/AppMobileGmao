import { Routes } from '@angular/router';

export const PARAMETER_ROUTES: Routes = [
  {
    path: 'configuration',
    loadComponent: () => import('./components/configuration/parameter.configuration').then(m => m.ParameterConfiguration)
  },
  {
    path: 'users',
    loadComponent: () => import('./components/users/parameter.users').then(m => m.ParameterUsers)
  }
];
import { Routes } from '@angular/router';
import { roleGuard } from '../../core/guards';

export const EQUIPMENT_ROUTES: Routes = [
    {
        path: 'list',
        loadComponent: () => import('./components/equipment-list/equipment.list').then((m) => m.EquipmentList),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
    },
    {
        path: 'history',
        loadComponent: () => import('./components/equipment-history/equipment.history').then((m) => m.EquipmentHistory),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
    }
];

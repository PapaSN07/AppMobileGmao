import { Routes } from '@angular/router';

export const EQUIPMENT_ROUTES: Routes = [
  {
    path: 'list',
    loadComponent: () => import('./components/equipment-list/equipment.list').then(m => m.EquipmentList)
  },
  {
    path: 'history',
    loadComponent: () => import('./components/equipment-history/equipment.history').then(m => m.EquipmentHistory)
  }
];
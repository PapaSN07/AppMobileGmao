import { Routes } from '@angular/router';
import { AppLayout } from './core/layout/component/app.layout';
import { Notfound } from './pages/notfound/notfound';
import { Dashboard } from './pages/dashboard/dashboard';
import { Equipment } from './pages/equipment/equipment';
import { EquipmentHistory } from './pages/equipment.history/equipment.history';

export const routes: Routes = [
    {
        path: '',
        component: AppLayout,
        children: [
            { path: '', component: Dashboard },
            { path: 'list-equipment', component: Equipment },
            { path: 'history-equipment', component: EquipmentHistory }
        ]
    },
    { path: 'notfound', component: Notfound }, // route explicite
    { path: '**', redirectTo: 'notfound' }
];

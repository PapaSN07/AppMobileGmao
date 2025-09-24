import { Routes } from '@angular/router';
import { AppLayout } from './core/layout/component/app.layout';
import { Notfound } from './pages/notfound/notfound';
import { Dashboard } from './pages/dashboard/dashboard';
import { Equipment } from './pages/equipment/equipment';

export const routes: Routes = [
    {
        path: '',
        component: AppLayout,
        children: [
            { path: '', component: Dashboard },
            { path: 'list-equipment', component: Equipment }
        ]
    },
    { path: 'notfound', component: Notfound }, // route explicite
    { path: '**', redirectTo: 'notfound' }
];

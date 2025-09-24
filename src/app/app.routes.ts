import { Routes } from '@angular/router';
import { AppLayout } from './core/layout/component/app.layout';
import { Notfound } from './pages/notfound/notfound';
import { Dashboard } from './pages/dashboard/dashboard';

export const routes: Routes = [
    {
        path: '',
        component: AppLayout,
        children: [{ path: '', component: Dashboard }],
    },
    { path: 'notfound', component: Notfound }, // route explicite
    { path: '**', redirectTo: 'notfound' }
];

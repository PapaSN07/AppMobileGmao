import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
    { path: '', redirectTo: 'login', pathMatch: 'full' },
    // Remplace m.Login / m.Access / m.Error par les noms exportés réels dans tes fichiers login.ts, access.ts, error.ts
    { path: 'login', loadComponent: () => import('./login/login').then((m) => m.Login) },
    { path: 'access', loadComponent: () => import('./access/access').then((m) => m.Access) },
    { path: 'error', loadComponent: () => import('./error/error').then((m) => m.Error) }
];

@NgModule({
    imports: [RouterModule.forChild(routes)],
    exports: [RouterModule]
})
export class AuthRoutingModule {}

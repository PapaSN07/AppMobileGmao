import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from '../../app.menuitem';
import { AuthService } from '../../../core/services/api';

@Component({
    selector: 'app-menu',
    imports: [CommonModule, AppMenuitem, RouterModule],
    standalone: true,
    templateUrl: './menu.html'
})
export class Menu implements OnInit {
    private authService = inject(AuthService);

    model: MenuItem[] = [];

    ngOnInit() {
        const user = this.authService.getUser();

        // Initialiser le sous-menu AVANT de créer model
        let subHome: MenuItem = {};

        // Si ADMIN, ajouter le sous-menu Équipements
        if (user && user.role === 'ADMIN') {
            subHome = {
                label: 'Équipements',
                icon: 'pi pi-fw pi-circle',
                items: [
                    { label: 'Liste Équipement', icon: 'pi pi-fw pi-list', routerLink: ['/equipment/list'] },
                    { label: 'Historique Équipement', icon: 'pi pi-fw pi-history', routerLink: ['/equipment/history'] }
                ]
            };
        }

        // Créer le menu principal
        const homeItems: MenuItem[] = [{ label: 'Dashboard', icon: 'pi pi-fw pi-home', routerLink: ['/dashboard'] }];

        // Ajouter subHome seulement s'il n'est pas vide
        if (subHome.label) {
            homeItems.push(subHome);
        }

        this.model = [
            {
                label: 'Accueil',
                items: homeItems
            }
        ];

        // Ajouter le menu Configuration pour les ADMIN
        if (user && user.role === 'ADMIN') {
            this.model.push({
                label: 'Configuration',
                icon: 'pi pi-fw pi-cog',
                items: [
                    {
                        label: 'Paramétrage Compte',
                        icon: 'pi pi-fw pi-sliders-h',
                        routerLink: ['/parameter/configuration']
                    },
                    {
                        label: 'Liste Utilisateurs',
                        icon: 'pi pi-fw pi-users',
                        routerLink: ['/parameter/users']
                    }
                ]
            });
        }
    }
}

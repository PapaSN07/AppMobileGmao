import { CommonModule } from '@angular/common';
import { Component, inject, Inject } from '@angular/core';
import { RouterModule } from '@angular/router';
import { StyleClassModule } from 'primeng/styleclass';
import { Configurator } from '../configurator/configurator';
import { MenuItem } from 'primeng/api';
import { LayoutService } from '../../../core/services/state/layout.service';
import { Menu } from "primeng/menu";
import { AuthService } from '../../../core/services/api';

@Component({
    selector: 'app-topbar',
    standalone: true,
    imports: [RouterModule, CommonModule, StyleClassModule, Configurator, Menu],
    templateUrl: './topbar.html'
})
export class Topbar {
    authService = inject(AuthService);

    emailUserConnect: string = '';

    constructor(public layoutService: LayoutService) {}

    ngOnInit() {
        this.emailUserConnect = this.getEmailUser();
    }

    items!: MenuItem[];
    itemsProfile: MenuItem[] | undefined = [
        {
            label: 'Options',
            items: [
                {
                    label: 'Mon profile',
                    icon: 'pi pi-users'
                },
                {
                    label: 'Paramètres',
                    icon: 'pi pi-cog'
                },
                {
                    label: 'Se déconnecter',
                    icon: 'pi pi-sign-out',
                    command: () => {
                        this.authService.logout();
                    }
                }
            ]
        }
    ];

    toggleDarkMode() {
        this.layoutService.layoutConfig.update((state) => ({ ...state, darkTheme: !state.darkTheme }));
    }

    getEmailUser() {
        const user = this.authService.getUser();
        return user ? user.email : '';
    }
}

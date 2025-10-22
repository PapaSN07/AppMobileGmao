import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { MenuModule } from 'primeng/menu';
import { StyleClassModule } from 'primeng/styleclass';
import { Configurator } from '../configurator/configurator';
import { MenuItem } from 'primeng/api';
import { LayoutService } from '../../../core/services/state/layout.service';
import { AvatarModule } from 'primeng/avatar';
import { BadgeModule } from 'primeng/badge';
import { AuthService } from '../../../core/services/api';
import { NotificationListComponent } from '../../../shared/notification-list/notification.list.component';
import { User } from '../../../core/models';

@Component({
    selector: 'app-topbar',
    standalone: true,
    imports: [
        RouterModule,
        CommonModule,
        ButtonModule,
        MenuModule,
        StyleClassModule,
        AvatarModule,
        BadgeModule,
        NotificationListComponent,
        Configurator
    ],
    templateUrl: './topbar.html'
})
export class Topbar implements OnInit {
    authService = inject(AuthService);

    emailUserConnect: string = '';

    user: User | null = null;
    items: MenuItem[] = [];

    private router = inject(Router);
    public layoutService = inject(LayoutService);

    ngOnInit() {
        const userString = sessionStorage.getItem('user');
        if (userString) {
            this.user = JSON.parse(userString);
        }

        this.emailUserConnect = this.getEmailUser();

        this.items = [
            {
                label: 'Mon profil',
                icon: 'pi pi-user',
                command: () => this.router.navigate(['/profile'])
            },
            {
                label: 'Paramètres',
                icon: 'pi pi-cog',
                command: () => this.router.navigate(['/parameter'])
            },
            {
                separator: true
            },
            {
                label: 'Se déconnecter',
                icon: 'pi pi-sign-out',
                command: () => this.logout()
            }
        ];
    }

    toggleDarkMode() {
        this.layoutService.layoutConfig.update((state) => ({ ...state, darkTheme: !state.darkTheme }));
    }

    getEmailUser() {
        const user = this.authService.getUser();
        return user ? user.email : '';
    }

    logout() {
        this.authService.logout();
    }
}

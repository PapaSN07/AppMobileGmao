import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { MenuItem } from 'primeng/api';
import { AppMenuitem } from '../app.menuitem';

@Component({
    selector: 'app-menu',
    imports: [CommonModule, AppMenuitem, RouterModule],
    templateUrl: './menu.html'
})
export class Menu {
    model: MenuItem[] = [];

    ngOnInit() {
        this.model = [
            {
                label: 'Accueil',
                items: [
                    { label: 'Dashboard', icon: 'pi pi-fw pi-home', routerLink: ['/'] },
                    { label: 'Liste Équipement', icon: 'pi pi-fw pi-list', routerLink: ['/list-equipment'] }
                ]
            }
        ];
    }
}

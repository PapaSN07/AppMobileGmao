import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { StyleClassModule } from 'primeng/styleclass';
import { Configurator } from '../configurator/configurator';
import { MenuItem } from 'primeng/api';
import { LayoutService } from '../../service/layout.service';

@Component({
    selector: 'app-topbar',
    standalone: true,
    imports: [RouterModule, CommonModule, StyleClassModule, Configurator],
    templateUrl: './topbar.html'
})
export class Topbar {
    items!: MenuItem[];

    constructor(public layoutService: LayoutService) {}

    toggleDarkMode() {
        this.layoutService.layoutConfig.update((state) => ({ ...state, darkTheme: !state.darkTheme }));
    }
}

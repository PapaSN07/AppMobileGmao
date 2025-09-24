import { Component, ElementRef } from '@angular/core';
import { Menu } from './menu/menu';

@Component({
    selector: 'app-sidebar',
    standalone: true,
    imports: [Menu],
    template: ` <div class="layout-sidebar">
        <app-menu></app-menu>
    </div>`
})
export class AppSidebar {
    constructor(public el: ElementRef) {}
}

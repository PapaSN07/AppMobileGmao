import { Component } from '@angular/core';

@Component({
    standalone: true,
    selector: 'app-footer',
    template: `<div class="layout-footer">
        GMAO - Senelec by
        <a href="https://www.senelec.sn" target="_blank" rel="noopener noreferrer" class="text-primary font-bold hover:underline">SENELEC</a>
    </div>`
})
export class AppFooter {}

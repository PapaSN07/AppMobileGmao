import { Component, HostBinding, Input, OnDestroy, OnInit } from '@angular/core';
import { NavigationEnd, Router, RouterModule, UrlTree } from '@angular/router';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { Subscription } from 'rxjs';
import { filter } from 'rxjs/operators';
import { CommonModule } from '@angular/common';
import { RippleModule } from 'primeng/ripple';
import { MenuItem } from 'primeng/api';
import { LayoutService } from '../core/services/state/layout.service';

@Component({
    selector: '[app-menuitem]',
    imports: [CommonModule, RouterModule, RippleModule],
    template: `
        <ng-container>
            <div *ngIf="root && item.visible !== false" class="layout-menuitem-root-text">{{ item.label }}</div>
            <a *ngIf="(!item.routerLink || item.items) && item.visible !== false" [attr.href]="item.url" (click)="itemClick($event)" [ngClass]="item.styleClass" [attr.target]="item.target" tabindex="0" pRipple>
                <i [ngClass]="dynamicIcon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item.label }}</span>
                <i class="pi pi-fw pi-angle-down layout-submenu-toggler" *ngIf="item.items"></i>
            </a>
            <a
                *ngIf="item.routerLink && !item.items && item.visible !== false"
                (click)="itemClick($event)"
                [ngClass]="item.styleClass"
                [routerLink]="item.routerLink"
                routerLinkActive="active-route"
                [routerLinkActiveOptions]="item.routerLinkActiveOptions || { paths: 'exact', queryParams: 'ignored', matrixParams: 'ignored', fragment: 'ignored' }"
                [fragment]="item.fragment"
                [queryParamsHandling]="item.queryParamsHandling"
                [preserveFragment]="item.preserveFragment"
                [skipLocationChange]="item.skipLocationChange"
                [replaceUrl]="item.replaceUrl"
                [state]="item.state"
                [queryParams]="item.queryParams"
                [attr.target]="item.target"
                tabindex="0"
                pRipple
            >
                <i [ngClass]="dynamicIcon" class="layout-menuitem-icon"></i>
                <span class="layout-menuitem-text">{{ item.label }}</span>
                <i class="pi pi-fw pi-angle-down layout-submenu-toggler" *ngIf="item.items"></i>
            </a>

            <ul *ngIf="item.items && item.visible !== false" [@children]="submenuAnimation">
                <ng-template ngFor let-child let-i="index" [ngForOf]="item.items">
                    <li app-menuitem [item]="child" [index]="i" [parentKey]="key" [class]="child['badgeClass']"></li>
                </ng-template>
            </ul>
        </ng-container>
    `,
    animations: [
        trigger('children', [
            state(
                'collapsed',
                style({
                    height: '0'
                })
            ),
            state(
                'expanded',
                style({
                    height: '*'
                })
            ),
            transition('collapsed <=> expanded', animate('400ms cubic-bezier(0.86, 0, 0.07, 1)'))
        ])
    ],
    providers: [LayoutService]
})
export class AppMenuitem implements OnInit, OnDestroy {
    @Input() item!: MenuItem;

    @Input() index!: number;

    @Input() @HostBinding('class.layout-root-menuitem') root!: boolean;

    @Input() parentKey!: string;

    active = false;

    menuSourceSubscription: Subscription;

    menuResetSubscription: Subscription;

    key: string = '';

    constructor(
        public router: Router,
        private layoutService: LayoutService
    ) {
        // écoute des changements venant du layout (clics sur d'autres items)
        this.menuSourceSubscription = this.layoutService.menuSource$.subscribe((value) => {
            Promise.resolve(null).then(() => {
                if (value.routeEvent) {
                    // routeEvent signifie qu'on a navigué — on garde ouvert si la clé correspond
                    this.active = value.key === this.key || value.key.startsWith(this.key + '-') ? true : false;
                } else {
                    // événement utilisateur : fermer si on n'est pas dans la branche
                    if (value.key !== this.key && !value.key.startsWith(this.key + '-')) {
                        this.active = false;
                    }
                }
            });
        });

        this.menuResetSubscription = this.layoutService.resetSource$.subscribe(() => {
            this.active = false;
        });

        // Sur chaque navigation, recalculer l'état actif (ne pas se limiter aux items qui ont routerLink)
        this.router.events.pipe(filter((event) => event instanceof NavigationEnd)).subscribe(() => {
            this.updateActiveStateFromRoute();
        });
    }

    ngOnInit() {
        this.key = this.parentKey ? this.parentKey + '-' + this.index : String(this.index);

        // Toujours mettre à jour l'état initial depuis la route courante (pour persistance après refresh)
        this.updateActiveStateFromRoute();
    }

    // Getter pour l'icône dynamique
    get dynamicIcon(): string {
        if (this.item.label === 'Équipements') {
            return this.active ? 'pi pi-fw pi-circle-fill' : 'pi pi-fw pi-circle';
        }
        return this.item.icon || '';
    }

    /**
     * Vérifie récursivement si l'item ou un de ses enfants correspond à la route courante.
     * Utilise router.createUrlTree + router.isActive pour une détection robuste (supporte array/string routerLink).
     */
    private isActive(item: MenuItem): boolean {
        // si item a routerLink, créer un UrlTree et vérifier isActive (non strict pour permettre les sous-routes)
        if (item.routerLink) {
            try {
                const link = item.routerLink as any;
                const tree: UrlTree = this.router.createUrlTree(Array.isArray(link) ? link : [link]);
                if (this.router.isActive(tree, false)) {
                    return true;
                }
            } catch (e) {
                // fallback : essayer une comparaison simple
                try {
                    const path = Array.isArray(item.routerLink) ? item.routerLink.join('/') : String(item.routerLink);
                    if (this.router.url.startsWith(path)) return true;
                } catch {}
            }
        }

        // sinon, si enfants, vérifier récursivement
        if (item.items && item.items.length) {
            return item.items.some((child) => this.isActive(child));
        }

        return false;
    }

    updateActiveStateFromRoute() {
        const activeRoute = this.isActive(this.item);

        // si la route correspond à cet item ou un descendant, on l'ouvre et on notifie en tant que routeEvent
        if (activeRoute) {
            this.active = true;
            this.layoutService.onMenuStateChange({ key: this.key, routeEvent: true });
        } else {
            // Ne pas forcer la fermeture si l'utilisateur a explicitement ouvert ce menu.
            // On ferme seulement si la route ne concerne pas la branche ET aucun événement utilisateur récent.
            // Ici on met active = false pour refléter l'état de route au chargé initial,
            // mais menuSource subscription (clic utilisateur) gardera la priorité ultérieurement.
            this.active = false;
        }
    }

    itemClick(event: Event) {
        // avoid processing disabled items
        if (this.item.disabled) {
            event.preventDefault();
            return;
        }

        // execute command
        if (this.item.command) {
            this.item.command({ originalEvent: event, item: this.item });
        }

        // toggle active state for submenus
        if (this.item.items) {
            this.active = !this.active;
        }

        // notifier le layout (clic utilisateur)
        this.layoutService.onMenuStateChange({ key: this.key });
    }

    get submenuAnimation() {
        return this.root ? 'expanded' : this.active ? 'expanded' : 'collapsed';
    }

    @HostBinding('class.active-menuitem')
    get activeClass() {
        return this.active && !this.root;
    }

    ngOnDestroy() {
        if (this.menuSourceSubscription) {
            this.menuSourceSubscription.unsubscribe();
        }

        if (this.menuResetSubscription) {
            this.menuResetSubscription.unsubscribe();
        }
    }
}

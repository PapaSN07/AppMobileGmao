import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { BadgeModule } from 'primeng/badge';
import { ButtonModule } from 'primeng/button';
import { MenuModule } from 'primeng/menu';
import { MenuItem } from 'primeng/api';
import { WebSocketService } from '../../core/services/api';
import { Notification } from '../../core/models';
import { TooltipModule } from 'primeng/tooltip';

@Component({
    selector: 'app-notification-list',
    standalone: true,
    imports: [
        CommonModule,
        BadgeModule,
        ButtonModule,
        MenuModule,
        TooltipModule
    ],
    templateUrl: './notification.list.component.html',
    styleUrls: ['./notification.list.component.scss']
})
export class NotificationListComponent implements OnInit, OnDestroy {
    notifications: Notification[] = [];
    unreadCount = 0;
    connectionState: 'disconnected' | 'connecting' | 'connected' | 'error' = 'disconnected';
    
    notificationMenuItems: MenuItem[] = [];
    
    private destroy$ = new Subject<void>();

    constructor(private websocketService: WebSocketService) {}

    ngOnInit(): void {
        // S'abonner aux notifications
        this.websocketService.notifications$
            .pipe(takeUntil(this.destroy$))
            .subscribe(notifications => {
                this.notifications = notifications;
                this.unreadCount = notifications.filter(n => !n.is_read).length;
                this.updateMenuItems();
            });

        // S'abonner à l'état de connexion
        this.websocketService.connectionState$
            .pipe(takeUntil(this.destroy$))
            .subscribe(state => {
                this.connectionState = state;
            });

        // Charger les notifications non lues depuis l'API
        this.websocketService.loadUnreadNotifications();

        // Écouter les nouvelles notifications en temps réel
        this.websocketService.newNotification$
            .pipe(takeUntil(this.destroy$))
            .subscribe(notification => {
                console.log('🔔 Nouvelle notification temps réel:', notification);
            });
    }

    private updateMenuItems(): void {
        if (this.notifications.length === 0) {
            this.notificationMenuItems = [
                {
                    label: 'Aucune notification',
                    disabled: true,
                    icon: 'pi pi-inbox'
                }
            ];
        } else {
            this.notificationMenuItems = this.notifications.slice(0, 5).map(notif => ({
                label: notif.title,
                icon: this.getNotificationIcon(notif.type),
                styleClass: this.getNotificationClass(notif.type),
                command: () => this.markAsRead(notif),
                title: notif.message
            }));

            // Ajouter "Voir tout" si plus de 5 notifications
            if (this.notifications.length > 5) {
                this.notificationMenuItems.push({
                    separator: true
                });
                this.notificationMenuItems.push({
                    label: `Voir toutes (${this.notifications.length})`,
                    icon: 'pi pi-list',
                    command: () => console.log('Redirection vers liste complète')
                });
            }
        }
    }

    /**
     * Marque une notification comme lue
     */
    markAsRead(notification: Notification): void {
        if (!notification.is_read) {
            this.websocketService.markAsRead(notification.id);
        }
    }

    /**
     * Retourne l'icône Material Design selon le type de notification
     */
    getNotificationIcon(type: string): string {
        switch (type) {
            case 'success': return 'pi pi-check-circle';
            case 'error': return 'pi pi-times-circle';
            case 'warning': return 'pi pi-exclamation-triangle';
            case 'info':
            default: return 'pi pi-info-circle';
        }
    }

    /**
     * Retourne la classe CSS selon le type de notification
     */
    getNotificationClass(type: string): string {
        return `notification-${type}`;
    }

    /**
     * Formate la date de la notification
     */
    formatTimestamp(timestamp: string): string {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now.getTime() - date.getTime();
        const diffMins = Math.floor(diffMs / 60000);
        
        if (diffMins < 1) return 'À l\'instant';
        if (diffMins < 60) return `Il y a ${diffMins} min`;
        
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `Il y a ${diffHours}h`;
        
        const diffDays = Math.floor(diffHours / 24);
        return `Il y a ${diffDays}j`;
    }

    ngOnDestroy(): void {
        this.destroy$.next();
        this.destroy$.complete();
    }
}

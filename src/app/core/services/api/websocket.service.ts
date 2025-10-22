import { inject, Injectable, OnDestroy } from '@angular/core';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ToastrService } from 'ngx-toastr';
import { jwtDecode } from 'jwt-decode';
import { environment } from '../../../../../environments/environment';
import { isControlMessage, isNotification, Notification, WebSocketAction } from "../../models";

@Injectable({
    providedIn: 'root'
})
export class WebSocketService implements OnDestroy {
    private socket: WebSocket | null = null;
    private reconnectAttempts = 0;
    private maxReconnectAttempts = 5;
    private reconnectDelay = 1000; // Délai initial en ms
    private pingInterval: any = null;
    private reconnectTimeout: any = null;
    private destroy$ = new Subject<void>();
    private isManualDisconnect = false;
    private tokenCheckInterval: any = null;

    // BehaviorSubject pour stocker l'historique des notifications
    private notificationsSubject = new BehaviorSubject<Notification[]>([]);
    public notifications$ = this.notificationsSubject.asObservable();

    // Subject pour les nouvelles notifications en temps réel
    private newNotificationSubject = new Subject<Notification>();
    public newNotification$ = this.newNotificationSubject.asObservable();

    // État de la connexion
    private connectionStateSubject = new BehaviorSubject<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected');
    public connectionState$ = this.connectionStateSubject.asObservable();

    constructor(
        private toastr: ToastrService
    ) {}

    /**
     * Vérifie si le token JWT est expiré ou va expirer bientôt
     * @param bufferTime Temps en secondes avant expiration (par défaut 5 minutes)
     */
    private isTokenExpired(token: string, bufferTime: number = 300): boolean {
        try {
            const decoded: any = jwtDecode(token);
            if (!decoded.exp) return true;
            
            const currentTime = Math.floor(Date.now() / 1000);
            
            return decoded.exp - bufferTime < currentTime;
        } catch (error) {
            console.error('❌ Erreur décodage JWT:', error);
            return true;
        }
    }

    /**
     * ✅ NOUVEAU : Obtient le temps restant avant expiration du token en secondes
     */
    private getTokenTimeToExpiry(token: string): number {
        try {
            const decoded: any = jwtDecode(token);
            if (!decoded.exp) return 0;
            
            const currentTime = Math.floor(Date.now() / 1000);
            return decoded.exp - currentTime;
        } catch (error) {
            console.error('❌ Erreur décodage JWT:', error);
            return 0;
        }
    }

    /**
     * Obtient un token valide (rafraîchit si expiré)
     */
    private async getValidToken(): Promise<string | null> {
        let token = sessionStorage.getItem('access_token');
        
        if (!token) {
            console.warn('⚠️ Aucun token disponible');
            return null;
        }

        // Vérifier expiration avec un buffer de 1 minute
        if (this.isTokenExpired(token, 60)) {
            console.log('🔄 Token expiré ou proche de l\'expiration, rafraîchissement en cours...');
            
            try {
                const response = await fetch(`${environment.apiUrlAuth}/refresh`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ refresh_token: sessionStorage.getItem('refresh_token') })
                });

                if (response.ok) {
                    const data = await response.json();
                    if (data.success && data.access_token) {
                        sessionStorage.setItem('access_token', data.access_token);
                        token = data.access_token;
                        console.log('✅ Token rafraîchi avec succès');
                    } else {
                        throw new Error('Échec du rafraîchissement');
                    }
                } else {
                    throw new Error('Erreur HTTP lors du rafraîchissement');
                }
            } catch (error) {
                console.error('❌ Erreur lors du rafraîchissement:', error);
                this.toastr.error('Session expirée, veuillez vous reconnecter', 'Erreur');
                sessionStorage.clear();
                window.location.href = '/auth/login';
                return null;
            }
        }

        return token;
    }

    /**
     * ✅ NOUVEAU : Démarre la surveillance du token pour reconnexion proactive
     */
    private startTokenMonitoring(): void {
        this.stopTokenMonitoring();

        // Vérifier le token toutes les 2 minutes
        this.tokenCheckInterval = setInterval(async () => {
            const token = sessionStorage.getItem('access_token');
            if (!token) {
                console.warn('⚠️ Token absent, déconnexion WebSocket');
                this.disconnect();
                return;
            }

            const timeToExpiry = this.getTokenTimeToExpiry(token);
            
            // Si le token expire dans moins de 5 minutes (300 secondes)
            if (timeToExpiry > 0 && timeToExpiry < 300) {
                console.log(`⏰ Token expire dans ${timeToExpiry}s, reconnexion WebSocket avec nouveau token...`);
                
                // Déconnecter proprement
                if (this.socket && this.socket.readyState === WebSocket.OPEN) {
                    this.socket.close(1000, 'Token refresh');
                }
                
                // Reconnecter avec nouveau token
                await this.connect();
            } else if (timeToExpiry <= 0) {
                console.warn('⚠️ Token expiré, déconnexion WebSocket');
                this.disconnect();
            } else {
                console.log(`✅ Token valide encore ${Math.floor(timeToExpiry / 60)} minutes`);
            }
        }, 120000); // Vérifier toutes les 2 minutes
    }

    /**
     * ✅ NOUVEAU : Arrête la surveillance du token
     */
    private stopTokenMonitoring(): void {
        if (this.tokenCheckInterval) {
            clearInterval(this.tokenCheckInterval);
            this.tokenCheckInterval = null;
        }
    }

    /**
     * Établit la connexion WebSocket
     */
    async connect(): Promise<void> {
        if (this.socket?.readyState === WebSocket.OPEN || this.socket?.readyState === WebSocket.CONNECTING) {
            console.log('⚠️ WebSocket déjà connecté ou en cours de connexion');
            return;
        }

        this.isManualDisconnect = false;
        this.connectionStateSubject.next('connecting');

        try {
            const token = await this.getValidToken();
            if (!token) {
                this.connectionStateSubject.next('error');
                return;
            }

            const wsUrl = `${environment.WEBSOCKET_URL}?token=${encodeURIComponent(token)}`;
            console.log('🔌 Connexion WebSocket en cours...');

            this.socket = new WebSocket(wsUrl);

            this.socket.onopen = () => {
                console.log('✅ WebSocket connecté avec succès');
                this.connectionStateSubject.next('connected');
                this.reconnectAttempts = 0;
                this.reconnectDelay = 1000;
                this.startPingInterval();
                // ✅ NOUVEAU : Démarrer la surveillance du token
                this.startTokenMonitoring();
            };

            this.socket.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this.handleIncomingMessage(data);
                } catch (error) {
                    console.error('❌ Erreur parsing message WebSocket:', error);
                }
            };

            this.socket.onerror = (error) => {
                console.error('❌ Erreur WebSocket:', error);
                this.connectionStateSubject.next('error');
                this.toastr.error('Erreur de connexion aux notifications', 'Erreur');
            };

            this.socket.onclose = (event) => {
                console.log(`🔌 WebSocket fermé (code: ${event.code}, raison: ${event.reason})`);
                this.stopPingInterval();
                // ✅ NOUVEAU : Arrêter la surveillance du token
                this.stopTokenMonitoring();
                this.connectionStateSubject.next('disconnected');

                if (!this.isManualDisconnect && this.reconnectAttempts < this.maxReconnectAttempts) {
                    this.scheduleReconnect();
                } else if (this.reconnectAttempts >= this.maxReconnectAttempts) {
                    this.toastr.error('Impossible de se reconnecter aux notifications', 'Erreur');
                }
            };

        } catch (error) {
            console.error('❌ Erreur lors de la connexion WebSocket:', error);
            this.connectionStateSubject.next('error');
            this.toastr.error('Erreur lors de la connexion aux notifications', 'Erreur');
        }
    }

    /**
     * Gère les messages entrants du WebSocket
     */
    private handleIncomingMessage(data: any): void {
        // Vérifier si c'est un message de contrôle
        if (isControlMessage(data)) {
            console.log(`🔔 Message de contrôle: ${data.type}`, data.message || '');
            
            if (data.type === 'ping') {
                // Répondre au ping
                this.send({ action: 'ping' });
            }
            return;
        }

        // Vérifier si c'est une notification
        if (isNotification(data)) {
            console.log('📬 Nouvelle notification reçue:', data);
            
            // Ajouter à l'historique
            const currentNotifications = this.notificationsSubject.value;
            this.notificationsSubject.next([data, ...currentNotifications]);

            // Émettre la nouvelle notification
            this.newNotificationSubject.next(data);

            // Afficher un toast
            this.showToast(data);
        } else {
            console.warn('⚠️ Message WebSocket non reconnu:', data);
        }
    }

    /**
     * Affiche un toast pour une notification
     */
    private showToast(notification: Notification): void {
        const config = {
            timeOut: 5000,
            closeButton: true,
            progressBar: true
        };

        switch (notification.type) {
            case 'success':
                this.toastr.success(notification.message, notification.title, config);
                break;
            case 'error':
                this.toastr.error(notification.message, notification.title, config);
                break;
            case 'warning':
                this.toastr.warning(notification.message, notification.title, config);
                break;
            case 'info':
            default:
                this.toastr.info(notification.message, notification.title, config);
                break;
        }
    }

    /**
     * Démarre l'intervalle de ping (toutes les 30 secondes)
     */
    private startPingInterval(): void {
        this.stopPingInterval();
        
        this.pingInterval = setInterval(() => {
            if (this.socket?.readyState === WebSocket.OPEN) {
                console.log('🏓 Envoi ping au serveur');
                this.send({ action: 'ping' });
            }
        }, 30000); // 30 secondes
    }

    /**
     * Arrête l'intervalle de ping
     */
    private stopPingInterval(): void {
        if (this.pingInterval) {
            clearInterval(this.pingInterval);
            this.pingInterval = null;
        }
    }

    /**
     * Programme une tentative de reconnexion avec backoff exponentiel
     */
    private scheduleReconnect(): void {
        this.reconnectAttempts++;
        const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
        
        console.log(`🔄 Tentative de reconnexion ${this.reconnectAttempts}/${this.maxReconnectAttempts} dans ${delay}ms`);

        this.reconnectTimeout = setTimeout(() => {
            this.connect();
        }, delay);
    }

    /**
     * Envoie un message au serveur WebSocket
     */
    private send(message: WebSocketAction): void {
        if (this.socket?.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(message));
        } else {
            console.warn('⚠️ WebSocket non connecté, impossible d\'envoyer le message');
        }
    }

    /**
     * Marque une notification comme lue
     */
    markAsRead(notificationId: number): void {
        console.log(`✅ Marquer notification ${notificationId} comme lue`);
        
        // Envoyer au serveur
        this.send({ action: 'mark_read', notification_id: notificationId });

        // Mettre à jour localement
        const currentNotifications = this.notificationsSubject.value;
        const updatedNotifications = currentNotifications.map(notif => 
            notif.id === notificationId ? { ...notif, is_read: true } : notif
        );
        this.notificationsSubject.next(updatedNotifications);
    }

    /**
     * Récupère le nombre de notifications non lues
     */
    getUnreadCount(): Observable<number> {
        return new Observable<number>(observer => {
            this.notifications$.pipe(takeUntil(this.destroy$)).subscribe(notifications => {
                const unreadCount = notifications.filter(n => !n.is_read).length;
                observer.next(unreadCount);
            });
        });
    }

    /**
     * Charge les notifications non lues depuis l'API HTTP
     */
    loadUnreadNotifications(): void {
        // Cette méthode sera appelée au démarrage pour charger l'historique
        // Implémentation à ajouter selon votre endpoint HTTP
        console.log('📥 Chargement des notifications non lues depuis l\'API...');
        // Exemple : this.http.get<Notification[]>('/notifications/unread').subscribe(...)
    }

    /**
     * Déconnecte proprement le WebSocket
     */
    disconnect(): void {
        console.log('🔌 Déconnexion WebSocket manuelle');
        this.isManualDisconnect = true;
        this.stopPingInterval();
        
        if (this.reconnectTimeout) {
            clearTimeout(this.reconnectTimeout);
            this.reconnectTimeout = null;
        }

        if (this.socket) {
            this.socket.close(1000, 'Déconnexion manuelle');
            this.socket = null;
        }

        this.connectionStateSubject.next('disconnected');
    }

    /**
     * Nettoyage lors de la destruction du service
     */
    ngOnDestroy(): void {
        this.disconnect();
        this.destroy$.next();
        this.destroy$.complete();
    }
}
import { inject, Injectable, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
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
    private reconnectDelay = 1000;
    private pingInterval: any = null;
    private reconnectTimeout: any = null;
    private tokenCheckInterval: any = null;
    private destroy$ = new Subject<void>();
    private isManualDisconnect = false;

    private http = inject(HttpClient);

    private notificationsSubject = new BehaviorSubject<Notification[]>([]);
    public notifications$ = this.notificationsSubject.asObservable();

    private newNotificationSubject = new Subject<Notification>();
    public newNotification$ = this.newNotificationSubject.asObservable();

    private connectionStateSubject = new BehaviorSubject<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected');
    public connectionState$ = this.connectionStateSubject.asObservable();

    constructor(private toastr: ToastrService) {}

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
     * ✅ NOUVEAU : Récupère l'ID de l'utilisateur connecté depuis sessionStorage
     */
    private getCurrentUserId(): string {
        const userString = sessionStorage.getItem('user');
        if (userString) {
            try {
                const user = JSON.parse(userString);
                return user.id?.toString() || user.code?.toString() || '';
            } catch (error) {
                console.error('❌ Erreur parsing user depuis sessionStorage:', error);
            }
        }
        return '';
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
                const response = await fetch(`${environment.API_URL_AUTH}/refresh`, {
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
                this.startTokenMonitoring();
                
                // ✅ NOUVEAU : Charger les notifications non lues après connexion
                this.loadUnreadNotifications();
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
     * ✅ CORRECTION : Gestion des messages broadcast et spécifiques avec validation d'ID
     */
    private handleIncomingMessage(data: any): void {
        console.log('📨 Message WebSocket reçu:', data);

        // 1. Messages de contrôle (connected, pong, mark_read_ack)
        if (isControlMessage(data)) {
            console.log(`🔔 Message de contrôle: ${data.type}`, data.message || '');
            
            if (data.type === 'ping') {
                this.send({ action: 'ping' });
            }
            return;
        }

        // 2. Notifications (broadcast ou spécifiques)
        if (isNotification(data)) {
            const currentUserId = this.getCurrentUserId();
            
            // ✅ VALIDATION : Générer un ID si manquant
            if (!data.id || data.id === null) {
                console.warn('⚠️ Notification sans ID reçue, génération locale');
                data.id = this.generateNotificationId();
            }
            
            const notification: Notification = {
                ...data,
                id: data.id,
                broadcast: data.broadcast || false
            };

            // Filtrage selon le type de notification
            if (notification.broadcast) {
                console.log('📢 Notification BROADCAST reçue:', notification.title);
                this.addNotification(notification);
                this.showToast(notification);
            } else if (notification.user_id === currentUserId) {
                console.log('📨 Notification SPÉCIFIQUE reçue:', notification.title);
                this.addNotification(notification);
                this.showToast(notification);
            } else {
                console.log(`⏭️ Notification ignorée (destinée à user_id=${notification.user_id}, vous êtes user_id=${currentUserId})`);
            }
            
            return;
        }

        console.warn('⚠️ Message WebSocket non reconnu:', data);
    }

    /**
     * ✅ NOUVEAU : Génère un ID unique pour les notifications
     */
    private generateNotificationId(): number {
        return Date.now() + Math.floor(Math.random() * 1000);
    }

    /**
     * ✅ NOUVEAU : Ajoute une notification sans doublon
     */
    private addNotification(notification: Notification): void {
        const currentNotifications = this.notificationsSubject.value;
        
        // Vérifier si la notification existe déjà
        const exists = currentNotifications.some(n => n.id === notification.id);
        if (!exists) {
            this.notificationsSubject.next([notification, ...currentNotifications]);
            this.newNotificationSubject.next(notification);
        } else {
            console.log('⚠️ Notification déjà présente, ignorée');
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

        // ✅ AJOUT : Afficher badge [BROADCAST] pour les notifications globales
        const title = notification.broadcast 
            ? `[BROADCAST] ${notification.title}` 
            : notification.title;

        switch (notification.type) {
            case 'success':
                this.toastr.success(notification.message, title, config);
                break;
            case 'error':
                this.toastr.error(notification.message, title, config);
                break;
            case 'warning':
                this.toastr.warning(notification.message, title, config);
                break;
            case 'info':
            default:
                this.toastr.info(notification.message, title, config);
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
     * ✅ CORRECTION : Marque une notification comme lue avec validation
     */
    markAsRead(notificationId: number): void {
        // ✅ VALIDATION : Vérifier que l'ID existe et est valide
        if (!notificationId || notificationId === null || isNaN(notificationId)) {
            console.error('❌ Impossible de marquer comme lue : ID manquant ou invalide', notificationId);
            this.toastr.error('Impossible de marquer cette notification comme lue', 'Erreur');
            return;
        }

        console.log(`✅ Marquer notification ${notificationId} comme lue`);
        
        // Envoyer au serveur via WebSocket
        this.send({ action: 'mark_read', notification_id: notificationId });

        // Mettre à jour localement AVANT l'appel HTTP pour feedback immédiat
        const currentNotifications = this.notificationsSubject.value;
        const updatedNotifications = currentNotifications.map(notif => 
            notif.id === notificationId ? { ...notif, is_read: true } : notif
        );
        this.notificationsSubject.next(updatedNotifications);

        // Appeler l'API HTTP pour synchroniser avec le serveur
        this.http.post(`${environment.API_URL_BASE}/notifications/mark-read`, { 
            notification_id: notificationId 
        })
        .pipe(takeUntil(this.destroy$))
        .subscribe({
            next: () => {
                console.log(`✅ Notification ${notificationId} marquée comme lue sur le serveur`);
                
                // ✅ AMÉLIORATION : Retirer complètement la notification de la liste après succès
                const remainingNotifications = this.notificationsSubject.value.filter(
                    notif => notif.id !== notificationId
                );
                this.notificationsSubject.next(remainingNotifications);
            },
            error: (err) => {
                console.error(`❌ Erreur marquage notification ${notificationId}:`, err);
                
                // ✅ ROLLBACK : Remettre is_read à false en cas d'erreur
                const rolledBackNotifications = this.notificationsSubject.value.map(notif => 
                    notif.id === notificationId ? { ...notif, is_read: false } : notif
                );
                this.notificationsSubject.next(rolledBackNotifications);
                
                this.toastr.error('Impossible de marquer la notification comme lue', 'Erreur');
            }
        });
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
     * ✅ CORRECTION : Charge les notifications avec validation des IDs
     */
    loadUnreadNotifications(): void {
        console.log('📥 Chargement des notifications non lues depuis l\'API...');
        
        this.http.get<{ notifications: Notification[] }>(`${environment.API_URL_BASE}/notifications/unread`)
            .pipe(takeUntil(this.destroy$))
            .subscribe({
                next: (response) => {
                    if (response.notifications && Array.isArray(response.notifications)) {
                        console.log(`✅ ${response.notifications.length} notifications chargées depuis l'API`);
                        
                        // ✅ VALIDATION : Générer des IDs pour les notifications sans ID
                        const validatedNotifications = response.notifications.map(notif => {
                            if (!notif.id || notif.id === null) {
                                console.warn('⚠️ Notification sans ID détectée, génération locale:', notif);
                                notif.id = this.generateNotificationId();
                            }
                            return notif;
                        });
                        
                        // Filtrer les doublons
                        const currentNotifications = this.notificationsSubject.value;
                        const newNotifications = validatedNotifications.filter(
                            apiNotif => !currentNotifications.some(n => n.id === apiNotif.id)
                        );
                        
                        if (newNotifications.length > 0) {
                            this.notificationsSubject.next([...newNotifications, ...currentNotifications]);
                            console.log(`📬 ${newNotifications.length} nouvelles notifications ajoutées`);
                        }
                    } else {
                        console.warn('⚠️ Réponse API invalide:', response);
                    }
                },
                error: (error) => {
                    console.error('❌ Erreur lors du chargement des notifications:', error);
                    this.toastr.error('Impossible de charger les notifications', 'Erreur');
                }
            });
    }

    /**
     * Déconnecte proprement le WebSocket
     */
    disconnect(): void {
        console.log('🔌 Déconnexion WebSocket manuelle');
        this.isManualDisconnect = true;
        this.stopPingInterval();
        this.stopTokenMonitoring();
        
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
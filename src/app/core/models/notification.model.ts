/**
 * Types de notifications supportés par l'application
 */
export type NotificationType = 'info' | 'success' | 'warning' | 'error';

/**
 * Interface représentant une notification reçue du backend
 */
export interface Notification {
    id: number;
    user_id: string;
    title: string;
    message: string;
    type: NotificationType;
    timestamp: string;
    is_read: boolean;
}

/**
 * Message de contrôle WebSocket (ping/pong, connected, etc.)
 */
export interface WebSocketControlMessage {
    type: 'ping' | 'pong' | 'connected';
    message?: string;
    timestamp?: string;
}

/**
 * Action envoyée au serveur via WebSocket
 */
export interface WebSocketAction {
    action: 'mark_read' | 'ping';
    notification_id?: number;
}

/**
 * Type guard pour vérifier si un message est une notification
 */
export function isNotification(message: any): message is Notification {
    return message && typeof message.id === 'number' && typeof message.user_id === 'string';
}

/**
 * Type guard pour vérifier si un message est un message de contrôle
 */
export function isControlMessage(message: any): message is WebSocketControlMessage {
    return message && ['ping', 'pong', 'connected'].includes(message.type);
}
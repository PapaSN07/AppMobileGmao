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
    broadcast: boolean; // ✅ AJOUT : Différencier broadcast vs spécifique
}

/**
 * Message de contrôle WebSocket (ping/pong, connected, etc.)
 */
export interface WebSocketControlMessage {
    type: 'connected' | 'pong' | 'ping' | 'mark_read_ack';
    message?: string;
    timestamp?: string;
    notification_id?: number;
    success?: boolean;
}

/**
 * Action envoyée au serveur via WebSocket
 */
export interface WebSocketAction {
    action: 'ping' | 'mark_read';
    notification_id?: number;
}

// ✅ Type guards
export function isNotification(data: any): data is Notification {
    return (
        data &&
        typeof data === 'object' &&
        'title' in data &&
        'message' in data &&
        'type' in data &&
        ['info', 'success', 'warning', 'error'].includes(data.type)
    );
}

export function isControlMessage(data: any): data is WebSocketControlMessage {
    return (
        data &&
        typeof data === 'object' &&
        'type' in data &&
        ['connected', 'pong', 'ping', 'mark_read_ack'].includes(data.type)
    );
}
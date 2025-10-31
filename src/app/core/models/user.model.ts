export interface User {
    id?: string;
    username: string;
    email: string;
    role: string;
    password?: string;
    supervisor?: string;
    entity?: string;
    url_image?: string;
    is_connected?: boolean;
    is_enabled?: boolean;
    is_first_time?: boolean; // ✅ NOUVEAU
    created_at?: Date;
    updated_at?: Date;
    address?: string;
    company?: string;
}

export interface AuthResponse {
    success: boolean;
    data: User;
    count: number;
    message: string;
    access_token: string;
    refresh_token: string;
}

export interface DecodedToken {
    sub: string;
    username: string;
    exp: number;
    iat: number;
}

// ✅ NOUVEAU: Interface pour le changement de mot de passe
export interface ChangePasswordRequest {
    current_password?: string;
    new_password: string;
    confirm_password: string;
}

export interface ChangePasswordResponse {
    success: boolean;
    message: string;
}
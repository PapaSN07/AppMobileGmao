export interface User {
    id?: string;
    username: string;
    email: string;
    role: string;
    supervisor?: string;
    url_image?: string;
    is_connected?: boolean;
    is_enabled?: boolean;
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
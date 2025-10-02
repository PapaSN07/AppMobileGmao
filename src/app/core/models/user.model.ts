export interface User {
    id: string;
    username: string;
    email: string;
    roles: string;
    supervisor?: string;
    urlName?: string;
    isConnected?: boolean;
    isEnabled?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
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
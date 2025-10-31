import { Injectable, inject } from '@angular/core';
import { Observable, map, switchMap } from 'rxjs';
import { ChangePasswordRequest, ChangePasswordResponse, User } from '../../models/user.model';
import { UserService } from '../api/user.service';
import { AuthService } from '../api/auth.service';

/**
 * ✅ Service dédié à la gestion des mots de passe
 * Principe SOLID: Single Responsibility - gestion uniquement des mots de passe
 * Principe DRY: Centralisation de la logique + réutilisation de updateUser
 */
@Injectable({
    providedIn: 'root'
})
export class PasswordService {
    private userService = inject(UserService);
    private authService = inject(AuthService);

    /**
     * ✅ Change le mot de passe de l'utilisateur connecté en utilisant updateUser
     * Principe DRY: Réutilise la méthode existante updateUser
     * @param data - Données de changement de mot de passe
     */
    changePassword(data: ChangePasswordRequest): Observable<ChangePasswordResponse> {
        const currentUser = this.authService.getUser();
        
        if (!currentUser?.id) {
            throw new Error('Utilisateur non connecté');
        }

        // ✅ Préparer les données de mise à jour
        const updateData: Partial<User> = {
            password: data.new_password,
            is_first_time: false // ✅ Marquer comme n'étant plus première connexion
        };

        // ✅ Utiliser updateUser existant
        return this.userService.updateUser(currentUser.id, updateData).pipe(
            map((updatedUser: User) => {
                // ✅ Mettre à jour le sessionStorage avec les nouvelles données
                const storedUser = this.authService.getUser();
                if (storedUser) {
                    storedUser.is_first_time = false;
                    storedUser.updated_at = updatedUser.updated_at;
                    sessionStorage.setItem('user', JSON.stringify(storedUser));
                }

                return {
                    success: true,
                    message: 'Mot de passe changé avec succès'
                } as ChangePasswordResponse;
            })
        );
    }

    /**
     * ✅ Validation côté client des mots de passe
     * Principe DRY: Réutilisable dans tous les composants
     */
    validatePasswordStrength(password: string): { 
        valid: boolean; 
        errors: string[] 
    } {
        const errors: string[] = [];

        if (password.length < 8) {
            errors.push('Le mot de passe doit contenir au moins 8 caractères');
        }
        if (!/[A-Z]/.test(password)) {
            errors.push('Le mot de passe doit contenir au moins une majuscule');
        }
        if (!/[a-z]/.test(password)) {
            errors.push('Le mot de passe doit contenir au moins une minuscule');
        }
        if (!/[0-9]/.test(password)) {
            errors.push('Le mot de passe doit contenir au moins un chiffre');
        }
        if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
            errors.push('Le mot de passe doit contenir au moins un caractère spécial');
        }

        return {
            valid: errors.length === 0,
            errors
        };
    }

    /**
     * ✅ Vérifie si les mots de passe correspondent
     */
    passwordsMatch(password: string, confirmPassword: string): boolean {
        return password === confirmPassword;
    }
}
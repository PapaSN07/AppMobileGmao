import { Component, inject, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { MessageService } from 'primeng/api';
import { Toast } from 'primeng/toast';
import { ProgressSpinnerModule } from 'primeng/progressspinner';
import { CardModule } from 'primeng/card';
import { AuthService } from '../../../../core/services/api';
import { PasswordService } from '../../../../core/services/utils';
import { ChangePasswordRequest } from '../../../../core/models';


/**
 * ✅ Composant de changement de mot de passe obligatoire
 * Principe SOLID: Single Responsibility - gestion du changement de mot de passe
 */
@Component({
    selector: 'app-change-password',
    standalone: true,
    imports: [
        CommonModule,
        FormsModule,
        ButtonModule,
        InputTextModule,
        PasswordModule,
        Toast,
        ProgressSpinnerModule,
        CardModule
    ],
    templateUrl: './change-password.html',
    styleUrls: ['./change-password.scss'],
    providers: [MessageService]
})
export class ChangePassword implements OnInit {
    private authService = inject(AuthService);
    private passwordService = inject(PasswordService);
    private messageService = inject(MessageService);
    private router = inject(Router);

    newPassword: string = '';
    confirmPassword: string = '';
    loading: boolean = false;
    isFirstTime: boolean = false;
    username: string = '';

    // ✅ Validation errors
    passwordErrors: string[] = [];
    showPasswordErrors: boolean = false;
    passwordMismatch: boolean = false; // ✅ NOUVEAU: Flag pour la non-correspondance

    ngOnInit(): void {
        const user = this.authService.getUser();
        if (user) {
            this.isFirstTime = user.is_first_time || false;
            this.username = user.username;
        }

        // ✅ Si pas prestataire ou pas première connexion, rediriger
        if (!user || user.role !== 'PRESTATAIRE' || !this.isFirstTime) {
            this.router.navigate(['/dashboard']);
        }
    }

    /**
     * ✅ Valide le nouveau mot de passe en temps réel
     */
    validateNewPassword(): void {
        if (this.newPassword.trim()) {
            const validation = this.passwordService.validatePasswordStrength(this.newPassword);
            this.passwordErrors = validation.errors;
            this.showPasswordErrors = !validation.valid;
        } else {
            this.passwordErrors = [];
            this.showPasswordErrors = false;
        }

        // ✅ Vérifier la correspondance si confirmPassword a déjà été saisi
        if (this.confirmPassword.trim()) {
            this.checkPasswordMatch();
        }
    }

    /**
     * ✅ NOUVEAU: Vérifie la correspondance des mots de passe en temps réel
     */
    checkPasswordMatch(): void {
        if (this.confirmPassword.trim() && this.newPassword.trim()) {
            this.passwordMismatch = !this.passwordService.passwordsMatch(
                this.newPassword,
                this.confirmPassword
            );
        } else {
            this.passwordMismatch = false;
        }
    }

    /**
     * ✅ Soumet le changement de mot de passe
     * Principe DRY: Utilise le service pour la validation
     */
    onSubmit(): void {
        // Validation côté client - Champs vides
        if (!this.newPassword.trim() || !this.confirmPassword.trim()) {
            this.messageService.add({
                severity: 'warn',
                summary: 'Champs requis',
                detail: 'Veuillez remplir tous les champs obligatoires',
                life: 4000
            });
            return;
        }

        // Vérifier la force du mot de passe
        const validation = this.passwordService.validatePasswordStrength(this.newPassword);
        if (!validation.valid) {
            this.messageService.add({
                severity: 'error',
                summary: 'Mot de passe faible',
                detail: validation.errors.join(', '),
                life: 5000
            });
            return;
        }

        // ✅ Vérifier la correspondance des mots de passe avec toast
        if (!this.passwordService.passwordsMatch(this.newPassword, this.confirmPassword)) {
            this.passwordMismatch = true; // ✅ Activer l'indicateur visuel
            this.messageService.add({
                severity: 'error',
                summary: 'Mots de passe différents',
                detail: 'Les mots de passe ne correspondent pas. Veuillez vérifier.',
                life: 4000
            });
            return;
        }

        this.loading = true;

        const data: ChangePasswordRequest = {
            new_password: this.newPassword,
            confirm_password: this.confirmPassword
        };

        this.passwordService.changePassword(data).subscribe({
            next: (response) => {
                if (response.success) {
                    this.messageService.add({
                        severity: 'success',
                        summary: 'Succès',
                        detail: 'Mot de passe changé avec succès. Redirection...',
                        life: 3000
                    });

                    // ✅ Mettre à jour is_first_time dans le sessionStorage
                    const user = this.authService.getUser();
                    if (user) {
                        user.is_first_time = false;
                        sessionStorage.setItem('user', JSON.stringify(user));
                    }

                    // Rediriger après 2 secondes
                    setTimeout(() => {
                        this.loading = false;
                        this.router.navigate(['/dashboard']);
                    }, 2000);
                }
            },
            error: (error) => {
                this.loading = false;
                this.messageService.add({
                    severity: 'error',
                    summary: 'Erreur',
                    detail: error.error?.message || 'Erreur lors du changement de mot de passe',
                    life: 4000
                });
            }
        });
    }

    /**
     * ✅ Annuler et se déconnecter
     */
    onCancel(): void {
        this.authService.logout();
        this.router.navigate(['/auth/login']);
    }
}

import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ButtonModule } from 'primeng/button';
import { CheckboxModule } from 'primeng/checkbox';
import { InputTextModule } from 'primeng/inputtext';
import { PasswordModule } from 'primeng/password';
import { RippleModule } from 'primeng/ripple';
import { ImageModule } from 'primeng/image';
import { AuthService } from '../../../../core/services/api/auth.service';
import { MessageService } from 'primeng/api';
import { Toast } from "primeng/toast";

@Component({
    selector: 'app-login',
    imports: [ButtonModule, CheckboxModule, InputTextModule, PasswordModule, FormsModule, RouterModule, RippleModule, ImageModule, Toast],
    standalone: true,
    templateUrl: './login.html',
    providers: [MessageService]
})
export class Login {
    authService = inject(AuthService);
    router = inject(Router);
    messageService = inject(MessageService);

    email: string = '';
    password: string = '';
    checked: boolean = false;

    onLogin() {
        
        // validation simple
        if (!this.email?.trim() || !this.password?.trim()) {
            this.messageService.add({
                severity: 'warn',
                summary: 'Champs requis',
                detail: "Veuillez renseigner l'email et le mot de passe.",
                life: 4000
            });
            return;
        }

        const identifier = this.email.trim();

        this.authService.login(identifier, this.password).subscribe({
            next: (response) => {
                if (response.success) {
                    this.router.navigate(['/dashboard']);
                }
            },
            error: (error) => {
                if (error?.status === 401) {
                    const errorData = error;
                    if (errorData?.error_code === 'USER_NOT_FOUND') {
                        this.messageService.add({ severity: 'warn', summary: 'Erreur', detail: 'Utilisateur introuvable. Vérifiez votre email/username.', life: 4000 });
                    } else if (errorData?.error_code === 'INVALID_PASSWORD') {
                        this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Mot de passe incorrect.', life: 4000 });
                    } else {
                        this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Identifiants invalides.', life: 4000 });
                    }
                } else if (error?.status === 500) {
                    this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur serveur. Réessayez plus tard.', life: 4000 });
                } else {
                    this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Une erreur est survenue.', life: 4000 });
                }
            }
        });
    }
}

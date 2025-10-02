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

@Component({
    selector: 'app-login',
    imports: [ButtonModule, CheckboxModule, InputTextModule, PasswordModule, FormsModule, RouterModule, RippleModule, ImageModule],
    standalone: true,
    templateUrl: './login.html'
})
export class Login {
    authService = inject(AuthService);
    router = inject(Router);

    email: string = '';
    password: string = '';
    checked: boolean = false;

    onLogin() {
        this.authService.login(this.email, this.password).subscribe({
            next: (response) => {
                if (response.success) {
                    this.router.navigate(['/dashboard']); // Navigation après succès
                }
            },
            error: (err) => console.error('Erreur login', err)
        });
    }
}

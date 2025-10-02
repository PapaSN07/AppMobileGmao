import { Component, inject } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../core/services/api';

@Component({
  selector: 'app-notfound',
  standalone: true,
  imports: [RouterModule, ButtonModule],
  templateUrl: './notfound.html',
})
export class Notfound {
  private authService = inject(AuthService);

  isAuthenticated(): boolean {
    return this.authService.isAuthenticated();
  }
}

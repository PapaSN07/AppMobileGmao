import { Component } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { AppFloatingConfigurator } from '../../core/layout/component/app.floatingconfigurator';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-notfound',
  standalone: true,
  imports: [RouterModule, ButtonModule, AppFloatingConfigurator],
  templateUrl: './notfound.html',
  styleUrl: './notfound.css'
})
export class Notfound {
}

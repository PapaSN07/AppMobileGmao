import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { trigger, transition, style, animate } from '@angular/animations';

@Component({
    selector: 'app-stats-card',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './stats-card.component.html',
    styleUrls: ['./stats-card.component.scss'],
    animations: [trigger('fadeIn', [transition(':enter', [style({ opacity: 0, transform: 'translateY(20px)' }), animate('300ms ease-out', style({ opacity: 1, transform: 'translateY(0)' }))])])]
})
export class StatsCardComponent {
    @Input() title!: string;
    @Input() value!: number;
    @Input() icon!: string;
    @Input() color!: string;
    @Input() bgColor!: string;
    @Input() trend?: number;
    @Input() loading = false;
}

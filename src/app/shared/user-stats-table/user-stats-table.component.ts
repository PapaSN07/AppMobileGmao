import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TableModule } from 'primeng/table';
import { UserStats } from '../../core/models';

@Component({
  selector: 'app-user-stats-table',
  standalone: true,
  imports: [CommonModule, TableModule],
  templateUrl: './user-stats-table.component.html'
})
export class UserStatsTableComponent {
  @Input() data: UserStats[] = [];
}

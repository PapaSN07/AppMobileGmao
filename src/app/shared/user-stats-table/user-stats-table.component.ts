import { Component, Input, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { UserStats } from '../../core/models/statistics.model';

@Component({
  selector: 'app-user-stats-table',
  standalone: true,
  imports: [CommonModule, TableModule, TagModule],
  template: `
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-xl font-semibold">
          {{ isAdmin ? 'Statistiques par utilisateur' : 'Mon activité' }}
        </h3>
        <p-tag 
          [value]="totalLabel()" 
          severity="info"
          icon="pi pi-users"
        />
      </div>
      
      <p-table 
        [value]="data" 
        [paginator]="isAdmin && data.length > 5"
        [rows]="5"
        [rowsPerPageOptions]="[5, 10, 20]"
        [tableStyle]="{'min-width': '50rem'}"
        styleClass="p-datatable-sm"
      >
        <ng-template pTemplate="header">
          <tr>
            <th pSortableColumn="username">
              Utilisateur <p-sortIcon field="username" />
            </th>
            <th pSortableColumn="new_count" class="text-center">
              Créations <p-sortIcon field="new_count" />
            </th>
            <th pSortableColumn="update_count" class="text-center">
              Modifications <p-sortIcon field="update_count" />
            </th>
            <th class="text-center">Total</th>
          </tr>
        </ng-template>
        <ng-template pTemplate="body" let-user>
          <tr [class.bg-blue-50]="user.username === currentUser && !isAdmin">
            <td>
              <div class="flex items-center gap-2">
                <i class="pi pi-user text-primary"></i>
                <span class="font-semibold">{{ user.username }}</span>
                @if (user.username === currentUser && !isAdmin) {
                  <p-tag value="Vous" severity="success" [rounded]="true" />
                }
              </div>
            </td>
            <td class="text-center">
              <p-tag 
                [value]="user.new_count.toString()" 
                severity="success"
                icon="pi pi-plus"
                [rounded]="true"
              />
            </td>
            <td class="text-center">
              <p-tag 
                [value]="user.update_count.toString()" 
                severity="info"
                icon="pi pi-pencil"
                [rounded]="true"
              />
            </td>
            <td class="text-center">
              <p-tag 
                [value]="(user.new_count + user.update_count).toString()" 
                severity="warn"
                [rounded]="true"
              />
            </td>
          </tr>
        </ng-template>
        <ng-template pTemplate="emptymessage">
          <tr>
            <td colspan="4" class="text-center py-8">
              <i class="pi pi-inbox text-4xl text-muted-color mb-3"></i>
              <p class="text-muted-color">Aucune statistique disponible</p>
            </td>
          </tr>
        </ng-template>
      </p-table>
    </div>
  `
})
export class UserStatsTableComponent {
  @Input() data: UserStats[] = [];
  @Input() currentUser: string = '';
  @Input() isAdmin: boolean = false;

  totalLabel = computed(() => {
    const count = this.data.length;
    return this.isAdmin 
      ? `${count} utilisateur${count > 1 ? 's' : ''}`
      : 'Mon compte';
  });
}

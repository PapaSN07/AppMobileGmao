import { Component, OnInit, OnDestroy, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ButtonModule } from 'primeng/button';
import { Toast } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { Subscription } from 'rxjs';

import { StatisticsService } from '../../core/services/api/statistics.service';
import { DashboardStatistics, StatCard } from '../../core/models/statistics.model';
import { EntityChartComponent } from '../../shared/entity-chart/entity-chart.component';
import { FamilyChartComponent } from '../../shared/family-chart/family-chart.component';
import { StatsCardComponent } from '../../shared/stats-card/stats-card.component';
import { UserStatsTableComponent } from '../../shared/user-stats-table/user-stats-table.component';
import { ProgressSpinnerModule } from 'primeng/progressspinner';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    ButtonModule,
    Toast,
    StatsCardComponent,
    EntityChartComponent,
    FamilyChartComponent,
    UserStatsTableComponent,
    ProgressSpinnerModule
],
  providers: [MessageService, StatisticsService],
  templateUrl: './dashboard.html'
})
export class Dashboard implements OnInit, OnDestroy {
  private statisticsService = inject(StatisticsService);
  private messageService = inject(MessageService);

  loading = signal(true);
  statistics = signal<DashboardStatistics | null>(null);
  statsCards = signal<StatCard[]>([]);
  lastUpdated = signal<string>('');
  
  private autoRefreshSubscription?: Subscription;
  private readonly AUTO_REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes

  ngOnInit() {
    this.loadStatistics();
    this.startAutoRefresh();
  }

  ngOnDestroy() {
    this.stopAutoRefresh();
  }

  /**
   * Charge les statistiques depuis l'API
   */
  loadStatistics(showToast = false) {
    this.loading.set(true);
    
    this.statisticsService.getStatistics(true, true).subscribe({
      next: (data) => {
        this.statistics.set(data);
        this.buildStatsCards(data);
        this.updateLastUpdatedTime(data.last_updated);
        this.loading.set(false);
        
        if (showToast) {
          this.messageService.add({
            severity: 'success',
            summary: 'Actualisation réussie',
            detail: 'Les statistiques ont été mises à jour',
            life: 3000
          });
        }
      },
      error: (error) => {
        this.loading.set(false);
        this.messageService.add({
          severity: 'error',
          summary: 'Erreur',
          detail: error.message || 'Impossible de charger les statistiques',
          life: 5000
        });
      }
    });
  }

  /**
   * Rafraîchissement manuel
   */
  onRefresh() {
    this.loadStatistics(true);
  }

  /**
   * Démarre l'auto-refresh
   */
  private startAutoRefresh() {
    this.autoRefreshSubscription = this.statisticsService
      .startAutoRefresh(this.AUTO_REFRESH_INTERVAL)
      .subscribe({
        next: (data) => {
          this.statistics.set(data);
          this.buildStatsCards(data);
          this.updateLastUpdatedTime(data.last_updated);
          console.log('✅ Auto-refresh des statistiques effectué');
        },
        error: (error) => {
          console.error('❌ Erreur auto-refresh:', error);
        }
      });
  }

  /**
   * Arrête l'auto-refresh
   */
  private stopAutoRefresh() {
    this.autoRefreshSubscription?.unsubscribe();
  }

  /**
   * Construit les cartes de statistiques
   */
  private buildStatsCards(data: DashboardStatistics) {
    const stats = data.equipment_stats;
    
    this.statsCards.set([
      {
        title: 'Total GMAO',
        value: stats.total_gmao,
        icon: 'pi-database',
        color: '#1976d2',
        bgColor: 'rgba(25, 118, 210, 0.1)'
      },
      {
        title: 'En attente',
        value: stats.total_temp,
        icon: 'pi-clock',
        color: '#ff9800',
        bgColor: 'rgba(255, 152, 0, 0.1)'
      },
      {
        title: 'Nouveaux',
        value: stats.new_equipments,
        icon: 'pi-plus-circle',
        color: '#4caf50',
        bgColor: 'rgba(76, 175, 80, 0.1)'
      },
      {
        title: 'Modifiés',
        value: stats.updated_equipments,
        icon: 'pi-pencil',
        color: '#00bcd4',
        bgColor: 'rgba(0, 188, 212, 0.1)'
      },
      {
        title: 'Approuvés',
        value: stats.approved_equipments,
        icon: 'pi-check-circle',
        color: '#388e3c',
        bgColor: 'rgba(56, 142, 60, 0.1)'
      },
      {
        title: 'Rejetés',
        value: stats.rejected_equipments,
        icon: 'pi-times-circle',
        color: '#f44336',
        bgColor: 'rgba(244, 67, 54, 0.1)'
      },
      {
        title: 'Validation en attente',
        value: stats.pending_validation,
        icon: 'pi-hourglass',
        color: '#ffc107',
        bgColor: 'rgba(255, 193, 7, 0.1)'
      },
      {
        title: 'Archivés',
        value: stats.archived_equipments,
        icon: 'pi-box',
        color: '#9e9e9e',
        bgColor: 'rgba(158, 158, 158, 0.1)'
      }
    ]);
  }

  /**
   * Met à jour l'heure de dernière mise à jour
   */
  private updateLastUpdatedTime(timestamp: string) {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) {
      this.lastUpdated.set('À l\'instant');
    } else if (diffMins < 60) {
      this.lastUpdated.set(`Il y a ${diffMins} min`);
    } else {
      this.lastUpdated.set(date.toLocaleString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }));
    }
  }
}

import { Component, Input, OnInit, OnDestroy, inject } from '@angular/core';
import { ChartModule } from 'primeng/chart';
import { Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import { LayoutService } from '../../layout/state/layout.service';
import { EntityStats } from '../../core/models';

@Component({
  selector: 'app-entity-chart',
  standalone: true,
  imports: [ChartModule],
  templateUrl: './entity-chart.component.html',
  styleUrls: ['./entity-chart.component.scss'],
  providers: [LayoutService]
})
export class EntityChartComponent implements OnInit, OnDestroy {
  @Input() data: EntityStats[] = [];
  
  chartData: any;
  chartOptions: any;
  private subscription?: Subscription;
  private layoutService = inject(LayoutService);

  constructor() {}

  ngOnInit() {
    this.initChart();
    
    // Réagir aux changements de thème
    this.subscription = this.layoutService.configUpdate$
      .pipe(debounceTime(25))
      .subscribe(() => this.initChart());
  }

  ngOnDestroy() {
    this.subscription?.unsubscribe();
  }

  private initChart() {
    const documentStyle = getComputedStyle(document.documentElement);
    const primaryColor = documentStyle.getPropertyValue('--p-primary-500');
    const textColor = documentStyle.getPropertyValue('--text-color');
    const borderColor = documentStyle.getPropertyValue('--surface-border');
    const textMutedColor = documentStyle.getPropertyValue('--text-color-secondary');

    // Trier par count décroissant et prendre les 10 premiers
    const sortedData = [...this.data]
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    this.chartData = {
      labels: sortedData.map(item => item.entity),
      datasets: [
        {
          label: 'Nombre d\'équipements',
          data: sortedData.map(item => item.count),
          backgroundColor: primaryColor,
          borderColor: primaryColor,
          borderWidth: 1
        }
      ]
    };

    this.chartOptions = {
      indexAxis: 'y', // Barres horizontales
      maintainAspectRatio: false,
      responsive: true,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          callbacks: {
            label: (context: any) => {
              return ` ${context.parsed.x} équipements`;
            }
          }
        }
      },
      scales: {
        x: {
          ticks: { color: textMutedColor },
          grid: { color: borderColor }
        },
        y: {
          ticks: { color: textMutedColor },
          grid: { display: false }
        }
      }
    };
  }
}

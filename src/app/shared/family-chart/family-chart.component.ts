import { Component, Input, OnInit, OnDestroy, inject } from '@angular/core';
import { ChartModule } from 'primeng/chart';
import { Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';
import { FamilyStats } from '../../core/models';
import { LayoutService } from '../../layout/state/layout.service';

@Component({
  selector: 'app-family-chart',
  standalone: true,
  imports: [ChartModule],
  templateUrl: './family-chart.component.html',
})
export class FamilyChartComponent implements OnInit, OnDestroy {
  private layoutService = inject(LayoutService);

  @Input() data: FamilyStats[] = [];
  
  chartData: any;
  chartOptions: any;
  private subscription?: Subscription;

  private readonly CHART_COLORS = [
    '#1976d2', '#ff9800', '#4caf50', '#f44336', 
    '#9c27b0', '#00bcd4', '#ffeb3b', '#795548', 
    '#607d8b', '#e91e63'
  ];


  ngOnInit() {
    this.initChart();
    
    this.subscription = this.layoutService.configUpdate$
      .pipe(debounceTime(25))
      .subscribe(() => this.initChart());
  }

  ngOnDestroy() {
    this.subscription?.unsubscribe();
  }

  private initChart() {
    const documentStyle = getComputedStyle(document.documentElement);
    const textColor = documentStyle.getPropertyValue('--text-color');

    // Top 10 familles
    const sortedData = [...this.data]
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    this.chartData = {
      labels: sortedData.map(item => item.family),
      datasets: [
        {
          data: sortedData.map(item => item.count),
          backgroundColor: this.CHART_COLORS,
          hoverBackgroundColor: this.CHART_COLORS.map(color => color + 'CC') // Ajouter transparence
        }
      ]
    };

    this.chartOptions = {
      maintainAspectRatio: false,
      responsive: true,
      plugins: {
        legend: {
          position: 'right',
          labels: {
            color: textColor,
            usePointStyle: true,
            padding: 15,
            font: {
              size: 12
            }
          }
        },
        tooltip: {
          callbacks: {
            label: (context: any) => {
              const label = context.label || '';
              const value = context.parsed || 0;
              const total = context.dataset.data.reduce((a: number, b: number) => a + b, 0);
              const percentage = ((value / total) * 100).toFixed(1);
              return `${label}: ${value} (${percentage}%)`;
            }
          }
        }
      }
    };
  }
}

import { Component } from '@angular/core';
import { StatsWidget } from './components/statswidget';
import { BestSellingWidget } from './components/bestsellingwidget';
import { RevenueStreamWidget } from './components/revenuestreamwidget';
import { NotificationsWidget } from './components/notificationswidget';

@Component({
  selector: 'app-dashboard',
  imports: [StatsWidget, BestSellingWidget, RevenueStreamWidget, NotificationsWidget],
  templateUrl: './dashboard.html',
})
export class Dashboard {}

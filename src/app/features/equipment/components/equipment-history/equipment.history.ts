import { Component, OnInit, signal, ViewChild } from '@angular/core';
import { MessageService } from 'primeng/api';
import { Table, TableModule } from 'primeng/table';
import { DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { TabsModule } from 'primeng/tabs';
import { Tag } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { ToastModule } from 'primeng/toast';
import { Equipment } from '../../../../core/models';
import { EquipmentService } from '../../../../core/services/api';

interface expandedRows {
    [key: string]: boolean;
}

@Component({
    selector: 'app-equipment.history',
    standalone: true,
    imports: [TableModule, ButtonModule, ToastModule, InputTextModule, DialogModule, InputIconModule, IconFieldModule, TabsModule, Tag, DatePipe, TextareaModule, FormsModule],
    templateUrl: './equipment.history.html',
    styleUrl: './equipment.history.scss',
    providers: [MessageService]
})
export class EquipmentHistory implements OnInit {
    equipmentsHistory = signal<Equipment[]>([]);

    @ViewChild('dt1') dt1!: Table;

    expandedRows: expandedRows = {};

    loading: boolean = true;

    balanceFrozen: boolean = true;

    detailsDialog: boolean = false;

    selectedEquipment: Equipment | null = null;

    constructor(private messageService: MessageService, private equipmentService: EquipmentService) {}

    ngOnInit() {
        this.loadData();
    }

    // Ouvrir modal détails
    viewDetails(equipment: Equipment) {
        this.selectedEquipment = { ...equipment };
        this.detailsDialog = true;
    }

    // Fermer modal détails
    hideDetails() {
        this.selectedEquipment = null;
        this.detailsDialog = false;
    }

    loadData() {
        this.loading = true;
        this.equipmentService.getAllHistory().subscribe({
            next: (data) => {
                console.log(data);
                this.equipmentsHistory.set(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur lors du chargement des données', life: 3000 });
                this.loading = false;
            }
        });
    }
}

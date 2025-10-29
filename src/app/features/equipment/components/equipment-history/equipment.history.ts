import { Component, OnInit } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { Tag } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { TooltipModule } from 'primeng/tooltip';
import { FormsModule } from '@angular/forms';
import { TextareaModule } from 'primeng/textarea';

import { Equipment } from '../../../../core/models';
import { EquipmentService } from '../../../../core/services/api';

interface expandedRows {
    [key: string]: boolean;
}

@Component({
    selector: 'app-equipment.history',
    standalone: true,
    imports: [
        CommonModule,
        TableModule,
        ButtonModule,
        InputTextModule,
        IconFieldModule,
        InputIconModule,
        Tag,
        DialogModule,
        TooltipModule,
        FormsModule,
        TextareaModule,
        DatePipe
    ],
    templateUrl: './equipment.history.html',
    styleUrls: ['./equipment.history.scss']
})
export class EquipmentHistory implements OnInit {
    equipments: Equipment[] = [];
    selectedEquipment: Equipment | null = null;
    loading = false;
    detailsDialog = false;
    expandedRows: expandedRows = {};
    balanceFrozen = true;

    constructor(private equipmentService: EquipmentService) {}

    ngOnInit(): void {
        this.loadHistory();
    }

    /**
     * ✅ Charge l'historique des équipements
     */
    loadHistory(): void {
        this.loading = true;
        this.equipmentService.getAllHistory().subscribe({
            next: (data) => {
                this.equipments = data;
                this.loading = false;
            },
            error: (err) => {
                console.error('Erreur chargement historique:', err);
                this.loading = false;
            }
        });
    }

    /**
     * ✅ Affiche les détails d'un équipement
     */
    viewDetails(equipment: Equipment): void {
        this.selectedEquipment = { ...equipment };
        this.detailsDialog = true;
    }

    /**
     * ✅ Ferme le dialog de détails
     */
    hideDetails(): void {
        this.detailsDialog = false;
        this.selectedEquipment = null;
    }

    /**
     * ✅ NOUVEAU : Retourne le tag de statut selon l'état de l'équipement
     */
    getStatusTag(equipment: Equipment): { severity: string; value: string; icon: string } {
        if (equipment.isDeleted) {
            return { 
                severity: 'danger', 
                value: 'Supprimé', 
                icon: 'pi pi-trash' 
            };
        }
        if (equipment.isRejected) {
            return { 
                severity: 'danger', 
                value: 'Rejeté', 
                icon: 'pi pi-times-circle' 
            };
        }
        if (equipment.isApproved) {
            return { 
                severity: 'success', 
                value: 'Approuvé', 
                icon: 'pi pi-check-circle' 
            };
        }
        if (equipment.isUpdate) {
            return { 
                severity: 'info', 
                value: 'Modifié', 
                icon: 'pi pi-pencil' 
            };
        }
        if (equipment.isNew) {
            return { 
                severity: 'warn', 
                value: 'Nouveau', 
                icon: 'pi pi-plus-circle' 
            };
        }
        return { 
            severity: 'secondary', 
            value: 'Inconnu', 
            icon: 'pi pi-question-circle' 
        };
    }

    /**
     * ✅ NOUVEAU : Retourne la classe CSS selon le statut
     */
    getRowClass(equipment: Equipment): string {
        if (equipment.isDeleted) {
            return 'deleted-row';
        }
        if (equipment.isRejected) {
            return 'rejected-row';
        }
        if (equipment.isApproved) {
            return 'approved-row';
        }
        return '';
    }
}

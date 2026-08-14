import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { Tag } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { FormsModule } from '@angular/forms';
import { WorkRequest } from '../../core/models/work-request.model';

@Component({
    selector: 'app-di-list',
    standalone: true,
    imports: [
        CommonModule,
        TableModule,
        ButtonModule,
        DialogModule,
        Tag,
        TooltipModule,
        FormsModule
    ],
    templateUrl: './di-list.component.html',
    styleUrls: ['./di-list.component.scss']
})
export class DIListComponent implements OnInit {
    workRequests: WorkRequest[] = [];
    selectedDI: WorkRequest | null = null;
    detailsDialog = false;
    loading = false;
    activeTab = 'probleme'; // tab-switching state: 'probleme' | 'plus' | 'diagnostic' | 'remarque' | 'historique' | 'repartitions'

    ngOnInit(): void {
        this.loadRequests();
    }

    loadRequests(): void {
        // Mock data matching the Senelec Coswin 8 screenshots
        this.workRequests = [
            {
                pkWorkRequest: 1,
                dinqCode: 'DI00062853',
                dinqUserStatus: '0. Créée',
                dinqEquipment: 'LM0308FAFROTRF1',
                dinqEquipmentDescription: 'POSTE FANN FROBENIUS - TRANSFORMATEUR',
                dinqDescription: 'DECHARGE PARTIELLE SUR CELLULE HTA ET ECHAUFFEMENT CONSTATE LORS DE LA VISITE THERMIQUE.',
                dinqPriority: 'URGENT',
                dinqAskDate: '24/07/2026 13:41',
                dinqSupervisor: 'ERIC DASYLVA CARDOZO',
                dinqCostcentre: 'DD303',
                dinqCostcentreDescription: 'CC / Mails',
                dinqZone: 'DAKAR',
                dinqActionEntity: 'SDDV',
                dinqRequestEntity: 'SDDV',
                mailsToNotify: 'Cheikhousoumar.dia@senelec.sn;papamadou.niang@senelec.sn',
                dateDebut: '24/07/2026 13:37',
                dateFin: '24/07/2026 13:37'
            },
            {
                pkWorkRequest: 2,
                dinqCode: 'BRC-001235',
                dinqUserStatus: '3. OT créé',
                dinqEquipment: 'LM0902ALALBTR1',
                dinqEquipmentDescription: 'CABLE LIAISON BT HTA',
                dinqDescription: 'Défaut câble entre Saly vélingara extension et Amisack city.',
                dinqPriority: 'URGENT',
                dinqAskDate: '26/07/2026 22:03',
                dinqSupervisor: 'Mouhamadou Mansour KEBE',
                dinqCostcentre: 'DD304',
                dinqCostcentreDescription: 'CC / Mails',
                dinqZone: 'THIES',
                dinqActionEntity: 'SEM',
                dinqRequestEntity: 'SEM',
                mailsToNotify: 'kebe.m@senelec.sn',
                dateDebut: '26/07/2026 22:00'
            },
            {
                pkWorkRequest: 3,
                dinqCode: 'BRC-001250',
                dinqUserStatus: '0. Créée',
                dinqEquipment: 'LM1201PACL12TR2',
                dinqEquipmentDescription: 'POSTE ALASSANE DJIGO CELLULE PROTEC',
                dinqDescription: 'Câble incriminé entre Zam Zam - Cabine Beyri Baïla Dia.',
                dinqPriority: 'URGENT',
                dinqAskDate: '25/07/2026 14:50',
                dinqSupervisor: 'ERIC DASYLVA CARDOZO',
                dinqZone: 'DAKAR',
                dinqActionEntity: 'SEM',
                dinqRequestEntity: 'SEM',
                mailsToNotify: 'eric.cardozo@senelec.sn'
            },
            {
                pkWorkRequest: 4,
                dinqCode: 'DI00062657',
                dinqUserStatus: '3. OT créé',
                dinqEquipment: 'LM0905PACONSU1',
                dinqEquipmentDescription: 'POSTE CONSULAT ITALIE',
                dinqDescription: 'Demande de déplacement de câble électrique et installation pour la sécurité du compte.',
                dinqPriority: 'DEPL_SUPPORT',
                dinqAskDate: '24/07/2026 15:47',
                dinqSupervisor: 'Nafissatou DIAGNE',
                dinqZone: 'DAKAR',
                dinqActionEntity: 'UED/N-DV',
                dinqRequestEntity: 'UED/N-DV',
                mailsToNotify: 'nafissatou.diagne@senelec.sn'
            },
            {
                pkWorkRequest: 5,
                dinqCode: 'DI00062656',
                dinqUserStatus: '3. OT créé',
                dinqEquipment: 'LM0312PAFANN1',
                dinqEquipmentDescription: 'POSTE FANN RESIDENCE',
                dinqDescription: 'Visite et prise en charge suite échauffement constaté sur le disjoncteur général.',
                dinqPriority: 'CREAT_DEPART',
                dinqAskDate: '24/07/2026 15:43',
                dinqSupervisor: 'Mouhamadou Mansour KEBE',
                dinqZone: 'DAKAR',
                dinqActionEntity: 'UED/N-DV',
                dinqRequestEntity: 'UED/N-DV'
            }
        ];
    }

    viewDetails(di: WorkRequest): void {
        this.selectedDI = { ...di };
        this.activeTab = 'probleme';
        this.detailsDialog = true;
    }

    hideDetails(): void {
        this.detailsDialog = false;
        this.selectedDI = null;
    }

    getPrioritySeverity(priority?: string): 'danger' | 'warn' | 'info' | 'secondary' {
        if (!priority) return 'secondary';
        switch (priority.toUpperCase()) {
            case 'URGENT':
                return 'danger';
            case 'NORMAL':
                return 'warn';
            case 'DEPL_SUPPORT':
            case 'CREAT_DEPART':
                return 'info';
            default:
                return 'secondary';
        }
    }

    getStatusSeverity(status?: string): 'success' | 'warn' | 'secondary' {
        if (!status) return 'secondary';
        if (status.includes('OT créé')) {
            return 'success';
        }
        if (status.includes('Créée')) {
            return 'warn';
        }
        return 'secondary';
    }
}

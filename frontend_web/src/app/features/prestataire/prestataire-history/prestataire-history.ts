import { Component, computed, inject, OnInit, signal, ViewChild } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';

// PrimeNG imports
import { TableModule, Table } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { Toast } from 'primeng/toast';
import { InputTextModule } from 'primeng/inputtext';
import { DialogModule } from 'primeng/dialog';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { Tag } from 'primeng/tag';
import { TextareaModule } from 'primeng/textarea';
import { MessageService } from 'primeng/api';
import { Card } from 'primeng/card';
import { Skeleton } from 'primeng/skeleton';
import { TabsModule } from 'primeng/tabs';
import { Divider } from 'primeng/divider';
import { Chip } from 'primeng/chip';
import { AuthService, EquipmentService } from '../../../core/services/api';
import { EquipmentHistoryItem } from '../../../core/models';


interface ExpandedRows {
    [key: string]: boolean;
}

/**
 * ✅ Composant Historique Prestataire
 * Principe SOLID: Single Responsibility - Affichage de l'historique
 * Principe DRY: Réutilisation des composants PrimeNG
 */
@Component({
    selector: 'app-prestataire-history',
    standalone: true,
    imports: [
        CommonModule,
        FormsModule,
        DatePipe,
        TableModule,
        ButtonModule,
        Toast,
        InputTextModule,
        DialogModule,
        InputIconModule,
        IconFieldModule,
        Tag,
        TextareaModule,
        Card,
        Skeleton,
        TabsModule,
        Divider,
        Chip
    ],
    templateUrl: './prestataire-history.html',
    styleUrls: ['./prestataire-history.scss'],
    providers: [MessageService]
})
export class PrestataireHistory implements OnInit {
    private authService = inject(AuthService);
    private equipmentService = inject(EquipmentService);
    private messageService = inject(MessageService);

    @ViewChild('dt1') dt1!: Table;

    // ✅ Signals pour la réactivité
    allEquipments = signal<EquipmentHistoryItem[]>([]);
    loading = signal<boolean>(true);
    detailsDialog = signal<boolean>(false);
    selectedEquipment = signal<EquipmentHistoryItem | null>(null);
    expandedRows: ExpandedRows = {};

    // ✅ Computed signals
    currentUsername = computed(() => this.authService.getUser()?.username || '');
    
    archivedEquipments = computed(() => 
        this.allEquipments().filter(eq => eq.status === 'archived')
    );
    
    inProgressEquipments = computed(() => 
        this.allEquipments().filter(eq => eq.status === 'in_progress')
    );

    pendingEquipments = computed(() => 
        this.inProgressEquipments().filter(eq => 
            !eq.isApproved && !eq.isRejected
        )
    );

    approvedEquipments = computed(() => 
        this.inProgressEquipments().filter(eq => eq.isApproved)
    );

    rejectedEquipments = computed(() => 
        this.inProgressEquipments().filter(eq => eq.isRejected)
    );

    // ✅ Statistiques
    stats = computed(() => ({
        total: this.allEquipments().length,
        archived: this.archivedEquipments().length,
        pending: this.pendingEquipments().length,
        approved: this.approvedEquipments().length,
        rejected: this.rejectedEquipments().length
    }));

    ngOnInit(): void {
        this.loadHistory();
    }

    /**
     * ✅ Charge l'historique du prestataire connecté
     * Principe DRY: Méthode réutilisable
     */
    loadHistory(): void {
        const username = this.currentUsername();
        if (!username) {
            this.messageService.add({
                severity: 'error',
                summary: 'Erreur',
                detail: 'Utilisateur non connecté',
                life: 4000
            });
            return;
        }

        this.loading.set(true);

        this.equipmentService.getPrestataireHistory(username).subscribe({
            next: (response) => {
                this.allEquipments.set(response.data);
                this.loading.set(false);
                
                this.messageService.add({
                    severity: 'success',
                    summary: 'Chargé',
                    detail: response.message,
                    life: 3000
                });
            },
            error: (error) => {
                console.error('❌ Erreur chargement historique:', error);
                this.messageService.add({
                    severity: 'error',
                    summary: 'Erreur',
                    detail: 'Impossible de charger l\'historique',
                    life: 4000
                });
                this.loading.set(false);
            }
        });
    }

    /**
     * ✅ Ouvre la modal de détails
     * Principe SOLID: Méthode dédiée pour une action spécifique
     */
    viewDetails(equipment: EquipmentHistoryItem): void {
        this.selectedEquipment.set({ ...equipment });
        this.detailsDialog.set(true);
    }

    /**
     * ✅ Ferme la modal de détails
     */
    hideDetails(): void {
        this.selectedEquipment.set(null);
        this.detailsDialog.set(false);
    }

    /**
     * ✅ Actualise les données
     */
    onRefresh(): void {
        this.loadHistory();
    }

    /**
     * ✅ Filtre global
     */
    onGlobalFilter(event: Event): void {
        const input = event.target as HTMLInputElement;
        this.dt1.filterGlobal(input.value, 'contains');
    }

    /**
     * ✅ Obtient la sévérité du tag selon le statut
     * Principe DRY: Méthode réutilisable pour les styles
     */
    getStatusSeverity(equipment: EquipmentHistoryItem): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
        if (equipment.status === 'archived') return 'secondary';
        if (equipment.isApproved) return 'success';
        if (equipment.isRejected) return 'danger';
        return 'warn';
    }

    /**
     * ✅ Obtient le label du statut
     */
    getStatusLabel(equipment: EquipmentHistoryItem): string {
        if (equipment.status === 'archived') return 'Archivé';
        if (equipment.isApproved) return 'Approuvé';
        if (equipment.isRejected) return 'Rejeté';
        return 'En attente';
    }

    /**
     * ✅ Obtient l'icône du statut
     */
    getStatusIcon(equipment: EquipmentHistoryItem): string {
        if (equipment.status === 'archived') return 'pi-archive';
        if (equipment.isApproved) return 'pi-check-circle';
        if (equipment.isRejected) return 'pi-times-circle';
        return 'pi-hourglass';
    }
}

import { Component, OnInit, signal, ViewChild, inject } from '@angular/core';
import { ButtonModule } from 'primeng/button';
import { Table, TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { Toast, ToastModule } from 'primeng/toast';
import { DialogModule } from 'primeng/dialog';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';

import { ConfirmationService, MessageService } from 'primeng/api';
import { EquipmentService, AuthService } from '../../../../core/services/api';
import { Equipment, User } from '../../../../core/models';

import * as XLSX from 'xlsx';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import { InputTextModule } from 'primeng/inputtext';
import { firstValueFrom } from 'rxjs';
import { Tag } from 'primeng/tag';
import { DatePipe } from '@angular/common';
import { TextareaModule } from 'primeng/textarea';
import { ConfirmDialog } from 'primeng/confirmdialog';

interface ExportColumn {
    title: string;
    dataKey: string;
}

interface expandedRows {
    [key: string]: boolean;
}

@Component({
    selector: 'app-equipment',
    standalone: true,
    imports: [TableModule, ButtonModule, ToastModule, InputTextModule, DialogModule, InputIconModule, IconFieldModule, TabsModule, Tag, DatePipe, TextareaModule, Toast, ConfirmDialog],
    templateUrl: './equipment.list.html',
    styleUrls: ['equipment.list.scss'],
    providers: [MessageService, ConfirmationService]
})
export class EquipmentList implements OnInit {
    private authService = inject(AuthService);

    loading: boolean = true;

    // Équipements
    equipmentsNoApproved = signal<Equipment[]>([]);
    equipmentsNoModified = signal<Equipment[]>([]);
    equipmentsApproved = signal<Equipment[]>([]);

    selectedEquipmentsNoApproved!: Equipment[] | null;
    selectedEquipmentsNoModified!: Equipment[] | null;
    selectedEquipmentsExport!: Equipment[] | null;

    @ViewChild('dt1') dt1!: Table;
    @ViewChild('dt2') dt2!: Table;
    @ViewChild('dt3') dt3!: Table;

    expandedRows: expandedRows = {};
    exportColumns!: ExportColumn[];

    balanceFrozen: boolean = true;

    selectedEquipment: Equipment | null = null;
    detailsDialog: boolean = false;

    userConnected: User | null = this.authService.getUser();
    // Fin équipements

    constructor(private equipmentService: EquipmentService, private messageService: MessageService, private confirmationService: ConfirmationService) {}

    ngOnInit() {
        this.loadDataNoApproved();
        this.loadDataNoModified();
        this.loadDataApproved();
    }

    // Export vers deux fichiers Excel : équipements ET attributs
    private async exportEquipmentsAndAttributes(tableIndex: number): Promise<void> {
        const equipments = tableIndex === 1 ? this.equipmentsNoApproved() : this.equipmentsNoModified();

        // Préparer les lignes pour le fichier équipements (sans attributs)
        const equipmentRows = equipments.map((e) => ({
            id: e.id ?? '',
            centreCharge: e.centreCharge ?? '',
            code: e.code ?? '',
            codeParent: e.codeParent ?? '',
            description: e.description ?? '',
            entity: e.entity ?? '',
            famille: e.famille ?? '',
            feeder: e.feeder ?? '',
            localisation: e.localisation ?? '',
            unite: e.unite ?? '',
            zone: e.zone ?? '',
            isApproved: e.isApproved ?? false,
            isNew: e.isNew ?? false,
            isUpdate: e.isUpdate ?? false,
            createdAt: e.createdAt ? new Date(e.createdAt).toISOString() : '',
            createdBy: e.createdBy ?? ''
        }));

        // Préparer les lignes pour le fichier attributs (chaque attribut sur une ligne, avec référence équipement)
        const attributeRows: any[] = [];
        equipments.forEach((e) => {
            if (e.attributes && Array.isArray(e.attributes)) {
                e.attributes.forEach((attr) => {
                    attributeRows.push({
                        equipmentId: e.id ?? '',
                        equipmentCode: e.code ?? '',
                        attributeId: attr.id ?? '',
                        specification: attr.specification ?? '',
                        attributeName: attr.attributeName ?? '',
                        attributeValue: attr.attributeValue ?? '',
                        index: attr.index ?? '',
                        isCopyOT: attr.isCopyOT ?? false,
                        attributeCreatedAt: attr.createdAt ? new Date(attr.createdAt).toISOString() : '',
                        attributeUpdatedAt: attr.updatedAt ? new Date(attr.updatedAt).toISOString() : ''
                    });
                });
            }
        });

        // Générer et télécharger le fichier équipements
        const filenameSuffix = this.getFormatDate();
        // créer workbooks en ArrayBuffer
        const wsEquip = XLSX.utils.json_to_sheet(equipmentRows);
        const wbEquip = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wbEquip, wsEquip, 'Équipements');
        const wbEquipArray = XLSX.write(wbEquip, { bookType: 'xlsx', type: 'array' });

        const wsAttr = XLSX.utils.json_to_sheet(attributeRows);
        const wbAttr = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wbAttr, wsAttr, 'Attributs');
        const wbAttrArray = XLSX.write(wbAttr, { bookType: 'xlsx', type: 'array' });

        // zipper
        const zip = new JSZip();
        zip.file(`equipments_${filenameSuffix}.xlsx`, new Uint8Array(wbEquipArray), { binary: true });
        zip.file(`attributes_${filenameSuffix}.xlsx`, new Uint8Array(wbAttrArray), { binary: true });

        const content = await zip.generateAsync({ type: 'blob' });
        saveAs(content, `export_equipments_${filenameSuffix}.zip`);
    }

    private getFormatDate(): string {
        const now = new Date();
        const pad = (n: number) => n.toString().padStart(2, '0');
        const dd = pad(now.getDate());
        const mm = pad(now.getMonth() + 1);
        const yy = pad(now.getFullYear() % 100);
        const hh = pad(now.getHours());
        const min = pad(now.getMinutes());
        const ss = pad(now.getSeconds());
        return `${dd}${mm}${yy}${hh}${min}${ss}`;
    }

    // Méthode publique déjà utilisée par le template — la redirige vers la nouvelle implémentation
    exportExcelTable(): void {
        this.exportEquipmentsAndAttributes(2);
    }

    loadDataNoApproved() {
        this.loading = true;
        this.equipmentService.getAllNoApproved().subscribe({
            next: (data) => {
                this.equipmentsNoApproved.set(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur lors du chargement des données', life: 3000 });
                this.loading = false;
            }
        });
    }

    loadDataNoModified() {
        this.loading = true;
        this.equipmentService.getAllNoModified().subscribe({
            next: (data) => {
                this.equipmentsNoModified.set(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur lors du chargement des données', life: 3000 });
                this.loading = false;
            }
        });
    }

    loadDataApproved() {
        this.loading = true;
        this.equipmentService.getAllApproved().subscribe({
            next: (data) => {
                this.equipmentsApproved.set(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur lors du chargement des données', life: 3000 });
                this.loading = false;
            }
        });
    }

    onGlobalFilter(table: Table, event: Event) {
        table.filterGlobal((event.target as HTMLInputElement).value, 'contains');
    }

    approveEquipmentNoApproved(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isApproved: true, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} approuvé`, life: 3000 });
                this.loadDataNoApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec de l'approbation de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoApproved(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} rejeté`, life: 3000 });
                this.loadDataNoApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec du rejet de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    approveEquipmentNoModified(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isApproved: true, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} approuvé`, life: 3000 });
                this.loadDataNoModified();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec de l'approbation de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoModified(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isUpdated: true, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} rejeté`, life: 3000 });
                this.loadDataNoModified();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec du rejet de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    confirm1(event: Event, equipment: Equipment) {
        this.confirmationService.confirm({
            header: 'Confirmation',
            target: event.currentTarget as EventTarget,
            message: 'Êtes-vous sûr de vouloir continuer 🤔?',
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Enregistrer'
            },
            accept: () => {
                this.messageService.add({ severity: 'info', summary: 'Confirmé', detail: 'Vous avez accepté la validation de cet équipement 🥳🎉', life: 3000 });
                this.approveEquipmentNoApproved(equipment);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Annulé', detail: 'Vous avez annulé la validation de cet équipement 🥲🥲🥲', life: 3000 });
            }
        });
    }

    confirm2(event: Event, equipment: Equipment) {
        this.confirmationService.confirm({
            header: 'Confirmation',
            target: event.currentTarget as EventTarget,
            message: 'Voulez-vous rejeter cet équipement 🤔?',
            icon: 'pi pi-info-circle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Rejeter',
                severity: 'danger'
            },
            accept: () => {
                this.messageService.add({ severity: 'info', summary: 'Confirmé', detail: 'Équipement rejeté', life: 3000 });
                this.deniedEquipmentNoApproved(equipment);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Annulé', detail: 'Vous avez annulé la validation de cet équipement', life: 3000 });
            }
        });
    }

    // Ajoutez ces nouvelles méthodes pour les confirmations de modifications
    confirm3(event: Event, equipment: Equipment) {
        this.confirmationService.confirm({
            header: 'Confirmation',
            target: event.currentTarget as EventTarget,
            message: 'Êtes-vous sûr de vouloir approuver cette modification 🤔?',
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Approuver'
            },
            accept: () => {
                this.messageService.add({ severity: 'info', summary: 'Confirmé', detail: 'Modification approuvée 🥳🎉', life: 3000 });
                this.approveEquipmentNoModified(equipment);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Rejeté', detail: 'Vous avez rejeté la modification de cet équipement 🥲🥲🥲', life: 3000 });
            }
        });
    }

    confirm4(event: Event, equipment: Equipment) {
        this.confirmationService.confirm({
            header: 'Confirmation',
            target: event.currentTarget as EventTarget,
            message: 'Voulez-vous refuser cette modification 🤔?',
            icon: 'pi pi-info-circle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Refuser',
                severity: 'danger'
            },
            accept: () => {
                this.messageService.add({ severity: 'info', summary: 'Confirmé', detail: 'Modification refusée 🥳🎉', life: 3000 });
                this.deniedEquipmentNoModified(equipment);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Rejeté', detail: 'Vous avez rejeté la modification de cet équipement 🥲🥲🥲', life: 3000 });
            }
        });
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

    saveAllEquipmentAdd() {
        if (!this.selectedEquipmentsNoApproved || this.selectedEquipmentsNoApproved.length === 0) {
            this.messageService.add({ severity: 'warn', summary: 'Aucune sélection', detail: 'Veuillez sélectionner au moins un équipement à approuver.', life: 3000 });
            return;
        }

        this.confirmationService.confirm({
            message: `Êtes-vous sûr de vouloir approuver ${this.selectedEquipmentsNoApproved.length} équipement(s) ajouté(s) ?`,
            header: "Confirmation d'approbation en masse",
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Enregistrer',
                severity: 'info'
            },
            accept: () => {
                this.approveMultipleEquipments(this.selectedEquipmentsNoApproved!, 'add');
            },
            reject: () => {
                this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Approbation annulée.', life: 3000 });
            }
        });
    }

    saveAllEquipmentUpdate() {
        if (!this.selectedEquipmentsNoModified || this.selectedEquipmentsNoModified.length === 0) {
            this.messageService.add({ severity: 'warn', summary: 'Aucune sélection', detail: 'Veuillez sélectionner au moins un équipement à approuver.', life: 3000 });
            return;
        }

        this.confirmationService.confirm({
            message: `Êtes-vous sûr de vouloir approuver ${this.selectedEquipmentsNoModified.length} modification(s) d'équipement(s) ?`,
            header: "Confirmation d'approbation en masse",
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Enregistrer',
                severity: 'info'
            },
            accept: () => {
                this.approveMultipleEquipments(this.selectedEquipmentsNoModified!, 'update');
            },
            reject: () => {
                this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Approbation annulée.', life: 3000 });
            }
        });
    }

    // Rejet en masse pour ajouts
    rejectAllEquipmentAdd() {
        if (!this.selectedEquipmentsNoApproved || this.selectedEquipmentsNoApproved.length === 0) {
            this.messageService.add({ severity: 'warn', summary: 'Aucune sélection', detail: 'Veuillez sélectionner au moins un équipement à rejeter.', life: 3000 });
            return;
        }

        this.confirmationService.confirm({
            message: `Êtes-vous sûr de vouloir rejeter ${this.selectedEquipmentsNoApproved.length} équipement(s) ajouté(s) ?`,
            header: 'Confirmation de rejet en masse',
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Enregistrer',
                severity: 'danger'
            },
            accept: () => {
                this.rejectMultipleEquipments(this.selectedEquipmentsNoApproved!, 'add');
            },
            reject: () => {
                this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Rejet annulé.', life: 3000 });
            }
        });
    }

    // Rejet en masse pour modifications
    rejectAllEquipmentUpdate() {
        if (!this.selectedEquipmentsNoModified || this.selectedEquipmentsNoModified.length === 0) {
            this.messageService.add({ severity: 'warn', summary: 'Aucune sélection', detail: 'Veuillez sélectionner au moins un équipement à rejeter.', life: 3000 });
            return;
        }

        this.confirmationService.confirm({
            message: `Êtes-vous sûr de vouloir rejeter ${this.selectedEquipmentsNoModified.length} modification(s) d'équipement(s) ?`,
            header: 'Confirmation de rejet en masse',
            icon: 'pi pi-exclamation-triangle',
            rejectButtonProps: {
                label: 'Annuler',
                severity: 'secondary',
                outlined: true
            },
            acceptButtonProps: {
                label: 'Enregistrer',
                severity: 'danger'
            },
            accept: () => {
                this.rejectMultipleEquipments(this.selectedEquipmentsNoModified!, 'update');
            },
            reject: () => {
                this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Rejet annulé.', life: 3000 });
            }
        });
    }

    // Implementation du rejet en masse (réutilise firstValueFrom)
    private rejectMultipleEquipments(equipments: Equipment[], type: 'add' | 'update') {
        const updatePromises = equipments.map((equipment) => {
            let updatedEquipment: any = { ...equipment, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
            if (type === 'update') {
                // respecter la logique utilisée dans deniedEquipmentNoModified
                updatedEquipment = { ...updatedEquipment, isUpdated: true };
            }
            return firstValueFrom(this.equipmentService.update(equipment.id!, updatedEquipment));
        });

        Promise.all(updatePromises)
            .then(() => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `${equipments.length} équipement(s) rejeté(s) avec succès.`, life: 3000 });
                // remettre à zéro les sélections
                this.selectedEquipmentsNoApproved = [];
                this.selectedEquipmentsNoModified = [];
                this.selectedEquipmentsExport = [];
                this.loadDataNoApproved();
                this.loadDataNoModified();
            })
            .catch((err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Une erreur est survenue lors du rejet en masse.', life: 3000 });
                console.error(err);
            });
    }

    private approveMultipleEquipments(equipments: Equipment[], type: 'add' | 'update') {
        const updatePromises = equipments.map((equipment) => {
            const updatedEquipment = { ...equipment, isApproved: true, isNew: false, judgedBy: this.userConnected?.username || 'unknown' };
            if (type === 'update') {
                updatedEquipment.isUpdate = false;
            }
            return firstValueFrom(this.equipmentService.update(equipment.id!, updatedEquipment));
        });

        Promise.all(updatePromises)
            .then(() => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `${equipments.length} équipement(s) approuvé(s) avec succès.`, life: 3000 });
                // remettre à zéro les sélections
                this.selectedEquipmentsNoApproved = [];
                this.selectedEquipmentsNoModified = [];
                this.selectedEquipmentsExport = [];
                this.loadDataNoApproved();
                this.loadDataNoModified();
            })
            .catch((err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Une erreur est survenue lors de l'approbation en masse.", life: 3000 });
                console.error(err);
            });
    }
}

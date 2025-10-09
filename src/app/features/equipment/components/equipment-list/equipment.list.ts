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

    // Export vers deux fichiers Excel : équipements ET attributs (refactorisé)
    private async exportEquipmentsAndAttributes(tableIndex: number): Promise<void> {
        const equipments = tableIndex === 1 ? this.equipmentsNoApproved() : this.equipmentsNoModified();

        const equipmentRows = this.buildEquipmentRows(equipments);
        const attributeRows = this.buildAttributeRows(equipments);

        const filenameSuffix = this.getFormatDate();

        const wbEquipArray = this.createWorkbookArray(equipmentRows, 'Équipements');
        const wbAttrArray = this.createWorkbookArray(attributeRows, 'Attributs');

        await this.zipAndDownload(
            [
                { name: `equipments_${filenameSuffix}.xlsx`, data: wbEquipArray },
                { name: `attributes_${filenameSuffix}.xlsx`, data: wbAttrArray }
            ],
            `export_equipments_${filenameSuffix}.zip`
        );
    }

    // construit les lignes pour le fichier équipements
    private buildEquipmentRows(equipments: Equipment[]) {
        return equipments.map((e) => ({
            Famille: e.famille,
            Unité: e.unite,
            CC: e.centreCharge,
            Zone: e.zone,
            Entité: e.entity,
            'Code Feeder': e.feeder,
            'Description Feeder': e.feederDescription,
            Localisation: e.localisation,
            'Code Parent': e.codeParent,
            'Code Équipement': e.code,
            'Description Équipement': e.description,
            'Alimenté par': e.feeder
        }));
    }

    // construit et trie les lignes des attributs ; retourne un tableau d'objets (colonnes lisibles)
    private buildAttributeRows(equipments: Equipment[]) {
        const attributeRows: any[] = [];

        equipments.forEach((e) => {
            if (!e.attributes || !Array.isArray(e.attributes) || e.attributes.length === 0) return;

            // trier les attributs de cet équipement par indx (ordre croissant)
            const sortedAttrs = [...e.attributes].sort((a: any, b: any) => (Number(a.indx) || 0) - (Number(b.indx) || 0));

            sortedAttrs.forEach((attr) => {
                attributeRows.push({
                    'Classe Attribut': attr.specification ?? '',
                    'Description Attribut': e.famille ?? '',
                    Index: attr.indx ?? '',
                    Attribut: attr.attributeName ?? '',
                    Valeur: attr.value ?? '',
                    'Code Équipement': e.code ?? '',
                    'Description Équipement': e.description ?? '',
                    "Copie sur l'OT": attr.isCopyOT ? 1 : 0
                });
            });

            // optionnel : ajouter une ligne vide comme séparateur (si tu veux visual separator dans le XLSX)
            attributeRows.push({
                'Classe Attribut': '',
                'Description Attribut': '',
                Index: '',
                Attribut: '',
                Valeur: '',
                'Code Équipement': '',
                'Description Équipement': '',
                "Copie sur l'OT": ''
            });
        });

        // tri global par 'Index' pour garantir ordre si nécessaire
        // attributeRows.sort((a, b) => (Number(a['Index']) || 0) - (Number(b['Index']) || 0));

        return attributeRows;
    }

    // crée un workbook et renvoie un ArrayBuffer (type 'array')
    private createWorkbookArray(rows: any[], sheetName: string): ArrayBuffer {
        const ws = XLSX.utils.json_to_sheet(rows);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, sheetName);
        return XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
    }

    // zipper et télécharger (utilise JSZip + file-saver)
    private async zipAndDownload(files: { name: string; data: ArrayBuffer }[], zipName: string) {
        try {
            const zip = new JSZip();
            files.forEach((f) => {
                zip.file(f.name, new Uint8Array(f.data), { binary: true });
            });
            const content = await zip.generateAsync({ type: 'blob' });
            saveAs(content, zipName);
        } catch (err) {
            console.error('Erreur export ZIP:', err);
            this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Impossible de générer l'export.", life: 4000 });
        }
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

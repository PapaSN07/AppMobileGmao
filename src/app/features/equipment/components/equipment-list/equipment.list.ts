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

import * as XLSX from 'xlsx-js-style';
import JSZip from 'jszip';
import { saveAs } from 'file-saver';
import { InputTextModule } from 'primeng/inputtext';
import { firstValueFrom } from 'rxjs';
import { Tag } from 'primeng/tag';
import { DatePipe } from '@angular/common';
import { TextareaModule } from 'primeng/textarea';
import { ConfirmDialog } from 'primeng/confirmdialog';
import { FormsModule } from '@angular/forms';

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
    imports: [TableModule, ButtonModule, ToastModule, InputTextModule, DialogModule, InputIconModule, IconFieldModule, TabsModule, Tag, DatePipe, TextareaModule, Toast, ConfirmDialog, FormsModule],
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

    // Propriétés pour le dialogue de rejet en masse
    bulkRejectDialog: boolean = false;
    bulkRejectEquipments: { equipment: Equipment; comment: string }[] = [];
    bulkRejectType: 'add' | 'update' = 'add';
    // Propriétés pour le dialogue de rejet individuel
    singleRejectDialog: boolean = false;
    singleRejectEquipment: Equipment | null = null;
    singleRejectComment: string = '';
    singleRejectType: 'add' | 'update' = 'add';
    // Fin équipements

    constructor(private equipmentService: EquipmentService, private messageService: MessageService, private confirmationService: ConfirmationService) {}

    ngOnInit() {
        this.loadDataNoApproved();
        this.loadDataNoModified();
        this.loadDataApproved();
    }

    // Export vers deux fichiers Excel : équipements ET attributs (refactorisé)
    private async exportEquipmentsAndAttributes(equipments: Equipment[]): Promise<void> {
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
        console.log(equipments);
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

            sortedAttrs.forEach((attr, index) => {
                const row: any = {
                    'Classe Attribut': attr.specification ?? '',
                    'Description Attribut': e.famille ?? '',
                    Index: attr.indx ?? '',
                    Attribut: attr.attributeName ?? '',
                    Valeur: attr.value ?? '',
                    'Code Équipement': e.code ?? '',
                    'Description Équipement': e.description ?? '',
                    "Copie sur l'OT": attr.isCopyOT ? 1 : 0
                };

                // Marquer la dernière ligne d'attributs de cet équipement
                if (index === sortedAttrs.length - 1) {
                    row['isLast'] = true;
                }

                attributeRows.push(row);
            });
        });

        return attributeRows;
    }

    // crée un workbook et renvoie un ArrayBuffer (type 'array')
    private createWorkbookArray(rows: any[], sheetName: string): ArrayBuffer {
        // Filtrer 'isLast' des lignes pour éviter qu'il apparaisse comme colonne
        const filteredRows = rows.map((row) => {
            const { isLast, ...rest } = row;
            return rest;
        });

        // si pas de ligne, créer feuille vide avec header minimal
        const headers = filteredRows && filteredRows.length > 0 ? Object.keys(filteredRows[0]) : [];

        // construire la feuille en conservant l'ordre des colonnes (sans 'isLast')
        const ws = XLSX.utils.json_to_sheet(filteredRows, { header: headers, skipHeader: false });

        // --- STYLE HEADER (avec xlsx-js-style) ---
        headers.forEach((h, c) => {
            const cellAddress = XLSX.utils.encode_cell({ r: 0, c });
            if (!ws[cellAddress]) ws[cellAddress] = { t: 's', v: h };

            // Style compatible xlsx-js-style
            ws[cellAddress].s = {
                font: {
                    bold: true,
                    color: { rgb: 'FFFFFF' },
                    sz: 12
                },
                fill: {
                    fgColor: { rgb: '2F6FED' },
                    patternType: 'solid'
                },
                alignment: {
                    horizontal: 'center',
                    vertical: 'center'
                },
                border: {
                    top: { style: 'thin', color: { rgb: '000000' } },
                    bottom: { style: 'thin', color: { rgb: '000000' } },
                    left: { style: 'thin', color: { rgb: '000000' } },
                    right: { style: 'thin', color: { rgb: '000000' } }
                }
            };
        });

        // --- AUTO WIDTH (wch) : calculer longueur max par colonne ---
        const colMax: number[] = headers.map((h) => Math.max(String(h).length, 10));

        // parcourir toutes les lignes pour mesurer
        const allRows = [headers].concat(
            rows.map((r) =>
                headers.map((h) => {
                    const v = r[h];
                    return v === null || v === undefined ? '' : String(v);
                })
            )
        );

        for (let r = 1; r < allRows.length; r++) {
            for (let c = 0; c < headers.length; c++) {
                const cellStr = allRows[r][c] ?? '';
                const len = Math.max(
                    ...String(cellStr)
                        .split('\n')
                        .map((l) => l.length)
                );
                if (len > (colMax[c] || 0)) colMax[c] = len;
            }
        }

        // Définir ws['!cols'] avec padding
        ws['!cols'] = colMax.map((m) => ({ wch: Math.min(Math.max(m + 3, 10), 60) }));

        // --- STYLE SÉPARATEUR (bordure épaisse sur la dernière ligne d'un bloc) ---
        const range = XLSX.utils.decode_range(ws['!ref']!);
        // Activer les filtres sur toute la plage (les dropdowns apparaîtront sur la ligne 0)
        ws['!autofilter'] = { ref: XLSX.utils.encode_range(range) };

        for (let r = 1; r <= range.e.r; r++) {
            const rowIndex = r; // 1-based for data rows
            const rowData = rows[r - 1]; // utiliser les rows originales pour accéder à 'isLast'

            if (rowData && rowData['isLast']) {
                // Appliquer bordure inférieure épaisse sur toute la ligne (marqueur de fin de bloc)
                for (let c = 0; c <= range.e.c; c++) {
                    const addr = XLSX.utils.encode_cell({ r, c });
                    if (!ws[addr]) ws[addr] = { t: 's', v: '' };
                    if (!ws[addr].s) ws[addr].s = {};
                    ws[addr].s.border = {
                        ...ws[addr].s.border,
                        bottom: { style: 'thick', color: { rgb: '000000' } }
                    };
                }
            } else {
                // Appliquer bordures légères aux cellules de données (si pas déjà stylées)
                for (let c = 0; c <= range.e.c; c++) {
                    const addr = XLSX.utils.encode_cell({ r, c });
                    if (ws[addr] && !ws[addr].s) {
                        ws[addr].s = {
                            border: {
                                top: { style: 'thin', color: { rgb: 'D3D3D3' } },
                                bottom: { style: 'thin', color: { rgb: 'D3D3D3' } },
                                left: { style: 'thin', color: { rgb: 'D3D3D3' } },
                                right: { style: 'thin', color: { rgb: 'D3D3D3' } }
                            }
                        };
                    }
                }
            }
        }

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
        const allApproved = this.equipmentsApproved();
        const selected = this.selectedEquipmentsExport && this.selectedEquipmentsExport.length > 0 ? this.selectedEquipmentsExport : allApproved;
        this.exportEquipmentsAndAttributes(selected);
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
        const now = new Date();
        const updatedEquipment = { ...equipment, isApproved: true, judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} approuvé`, life: 3000 });
                this.loadDataNoApproved();
                this.loadDataApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec de l'approbation de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoApproved(equipment: Equipment, comment: string = '') {
        const now = new Date();
        const updatedEquipment = { ...equipment, isRejected: true, commentaire: comment, judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} rejeté`, life: 3000 });
                this.loadDataNoApproved();
                this.loadDataApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec du rejet de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    approveEquipmentNoModified(equipment: Equipment) {
        const now = new Date();
        const updatedEquipment = { ...equipment, isApproved: true, judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} approuvé`, life: 3000 });
                this.loadDataNoModified();
                this.loadDataApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: `Échec de l'approbation de l'équipement ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoModified(equipment: Equipment, comment: string = '') {
        const now = new Date();
        const updatedEquipment = { ...equipment, isRejected: true, commentaire: comment, judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: `Équipement ${equipment.code} rejeté`, life: 3000 });
                this.loadDataNoModified();
                this.loadDataApproved();
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
        this.openSingleRejectDialog(equipment, 'add');
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
        this.openSingleRejectDialog(equipment, 'update');
    }

    // Ouvrir le dialogue de rejet individuel
    private openSingleRejectDialog(equipment: Equipment, type: 'add' | 'update') {
        this.singleRejectEquipment = equipment;
        this.singleRejectType = type;
        this.singleRejectComment = '';
        this.singleRejectDialog = true;
    }

    // Soumettre le rejet individuel
    submitSingleReject() {
        if (!this.singleRejectEquipment) return;
        const comment = this.singleRejectComment || '';
        if (this.singleRejectType === 'add') {
            this.messageService.add({ severity: 'info', summary: 'Rejet en cours', detail: `Rejet de l'équipement ${this.singleRejectEquipment.code} en cours...`, life: 3000 });
            this.deniedEquipmentNoApproved(this.singleRejectEquipment, comment);
        } else {
            this.messageService.add({ severity: 'info', summary: 'Rejet en cours', detail: `Rejet de l'équipement ${this.singleRejectEquipment.code} en cours...`, life: 3000 });
            this.deniedEquipmentNoModified(this.singleRejectEquipment, comment);
        }
        this.singleRejectDialog = false;
        this.singleRejectEquipment = null;
        this.singleRejectComment = '';
    }

    // Annuler le rejet individuel
    cancelSingleReject() {
        this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Rejet annulé.', life: 3000 });
        this.singleRejectDialog = false;
        this.singleRejectEquipment = null;
        this.singleRejectComment = '';
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

        // Ouvrir le dialogue de rejet en masse
        this.bulkRejectEquipments = this.selectedEquipmentsNoApproved.map((e) => ({ equipment: e, comment: '' }));
        this.bulkRejectType = 'add';
        this.bulkRejectDialog = true;
    }

    // Rejet en masse pour modifications
    rejectAllEquipmentUpdate() {
        if (!this.selectedEquipmentsNoModified || this.selectedEquipmentsNoModified.length === 0) {
            this.messageService.add({ severity: 'warn', summary: 'Aucune sélection', detail: 'Veuillez sélectionner au moins un équipement à rejeter.', life: 3000 });
            return;
        }

        // Ouvrir le dialogue de rejet en masse
        this.bulkRejectEquipments = this.selectedEquipmentsNoModified.map((e) => ({ equipment: e, comment: '' }));
        this.bulkRejectType = 'update';
        this.bulkRejectDialog = true;
    }

    // Soumettre le rejet en masse
    submitBulkReject() {
        this.rejectMultipleEquipments(
            this.bulkRejectEquipments.map((item) => item.equipment),
            this.bulkRejectType,
            this.bulkRejectEquipments.map((item) => item.comment)
        );
        this.bulkRejectDialog = false;
        this.bulkRejectEquipments = [];
    }

    // Annuler le rejet en masse
    cancelBulkReject() {
        this.messageService.add({ severity: 'info', summary: 'Annulé', detail: 'Rejet en masse annulé.', life: 3000 });
        this.bulkRejectDialog = false;
        this.bulkRejectEquipments = [];
    }

    // Implementation du rejet en masse (réutilise firstValueFrom)
    private rejectMultipleEquipments(equipments: Equipment[], type: 'add' | 'update', comments: string[] = []) {
        const now = new Date();
        const updatePromises = equipments.map((equipment, index) => {
            let updatedEquipment: any = { ...equipment, isRejected: true, commentaire: comments[index] || '', judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
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
                this.loadDataApproved();
            })
            .catch((err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Une erreur est survenue lors du rejet en masse.', life: 3000 });
                console.error(err);
            });
    }

    private approveMultipleEquipments(equipments: Equipment[], type: 'add' | 'update') {
        const now = new Date();
        const updatePromises = equipments.map((equipment) => {
            const updatedEquipment = { ...equipment, isApproved: true, judgedBy: this.userConnected?.username || 'unknown', updatedAt: now };
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
                this.loadDataApproved();
            })
            .catch((err) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Une erreur est survenue lors de l'approbation en masse.", life: 3000 });
                console.error(err);
            });
    }
}

import { CommonModule } from '@angular/common';
import { Component, OnInit, signal, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { InputNumberModule } from 'primeng/inputnumber';
import { InputTextModule } from 'primeng/inputtext';
import { RadioButtonModule } from 'primeng/radiobutton';
import { RippleModule } from 'primeng/ripple';
import { SelectModule } from 'primeng/select';
import { Table, TableModule } from 'primeng/table';
import { TabsModule } from 'primeng/tabs';
import { ToastModule } from 'primeng/toast';
import { ToolbarModule } from 'primeng/toolbar';
import { RatingModule } from 'primeng/rating';
import { TextareaModule } from 'primeng/textarea';
import { DialogModule } from 'primeng/dialog';
import { TagModule } from 'primeng/tag';
import { InputIconModule } from 'primeng/inputicon';
import { IconFieldModule } from 'primeng/iconfield';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmPopupModule } from 'primeng/confirmpopup';
import { MultiSelectModule } from 'primeng/multiselect';
import { SliderModule } from 'primeng/slider';
import { ProgressBarModule } from 'primeng/progressbar';
import { ToggleButtonModule } from 'primeng/togglebutton';

import { ConfirmationService, MessageService } from 'primeng/api';
import { EquipmentService } from '../../../../core/services/api';
import { Equipment } from '../../../../core/models';

import * as XLSX from 'xlsx';

interface Column {
    field: string;
    header: string;
    customExportHeader?: string;
}

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
    imports: [
        CommonModule,
        TableModule,
        FormsModule,
        ButtonModule,
        RippleModule,
        ToastModule,
        ToolbarModule,
        RatingModule,
        InputTextModule,
        TextareaModule,
        SelectModule,
        RadioButtonModule,
        InputNumberModule,
        DialogModule,
        TagModule,
        InputIconModule,
        IconFieldModule,
        ConfirmDialogModule,
        MultiSelectModule,
        SliderModule,
        ProgressBarModule,
        ToggleButtonModule,
        TabsModule,
        ConfirmPopupModule
    ],
    templateUrl: './equipment.list.html',
    styleUrls: ['equipment.list.scss'],
    providers: [MessageService, ConfirmationService]
})
export class EquipmentList implements OnInit {
    loading: boolean = true;

    // Équipements
    equipmentsNoApproved = signal<Equipment[]>([]);
    equipmentsNoModified = signal<Equipment[]>([]);

    selectedEquipmentsNoApproved!: Equipment[] | null;
    selectedEquipmentsNoModified!: Equipment[] | null;

    @ViewChild('dt1') dt1!: Table;
    @ViewChild('dt2') dt2!: Table;

    expandedRows: expandedRows = {};
    exportColumns!: ExportColumn[];

    balanceFrozen: boolean = true;
    // Fin équipements

    constructor(private equipmentService: EquipmentService, private messageService: MessageService, private confirmationService: ConfirmationService) {}

    ngOnInit() {
        this.loadDataNoApproved();
        this.loadDataNoModified();
    }

    // Méthode pour aplatir les données (équipement + attributs)
    private flattenData(equipments: Equipment[]): any[] {
        const flattened: any[] = [];
        equipments.forEach((equipment) => {
            if (equipment.attributes && equipment.attributes.length > 0) {
                equipment.attributes.forEach((attribute) => {
                    flattened.push({
                        // Champs de l'équipement
                        id: equipment.id,
                        centreCharge: equipment.centreCharge,
                        code: equipment.code,
                        codeParent: equipment.codeParent,
                        createdAt: equipment.createdAt,
                        createdBy: equipment.createdBy,
                        description: equipment.description,
                        localisation: equipment.localisation,
                        entity: equipment.entity,
                        famille: equipment.famille,
                        feeder: equipment.feeder,
                        feederDescription: equipment.feederDescription,
                        unite: equipment.unite,
                        zone: equipment.zone,
                        isApproved: equipment.isApproved,
                        isNew: equipment.isNew,
                        isUpdate: equipment.isUpdate,
                        // Champs de l'attribut
                        attributeId: attribute.id,
                        specification: attribute.specification,
                        attributeName: attribute.attributeName,
                        value: attribute.attributeValue,
                        indx: attribute.index,
                        isCopyOT: attribute.isCopyOT,
                        attributeCreatedAt: attribute.createdAt,
                        attributeUpdatedAt: attribute.updatedAt
                    });
                });
            } else {
                // Si pas d'attributs, ajouter une ligne vide pour l'équipement
                flattened.push({
                    id: equipment.id,
                    centreCharge: equipment.centreCharge,
                    code: equipment.code,
                    codeParent: equipment.codeParent,
                    createdAt: equipment.createdAt,
                    createdBy: equipment.createdBy,
                    description: equipment.description,
                    entity: equipment.entity,
                    famille: equipment.famille,
                    feeder: equipment.feeder,
                    feederDescription: equipment.feederDescription,
                    localisation: equipment.localisation,
                    unite: equipment.unite,
                    zone: equipment.zone,
                    isApproved: equipment.isApproved,
                    isNew: equipment.isNew,
                    isUpdate: equipment.isUpdate,
                    attributeId: '',
                    specification: '',
                    attributeName: '',
                    value: '',
                    indx: '',
                    isCopyOT: '',
                    attributeCreatedAt: '',
                    attributeUpdatedAt: ''
                });
            }
        });
        return flattened;
    }

    // Export vers Excel
    exportToExcel(tableIndex: number): void {
        const equipments = tableIndex === 1 ? this.equipmentsNoApproved() : this.equipmentsNoModified();
        const flattenedData = this.flattenData(equipments);
        const worksheet = XLSX.utils.json_to_sheet(flattenedData);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Equipments');
        XLSX.writeFile(workbook, `equipments_${tableIndex === 1 ? 'no_approved' : 'no_modified'}.xlsx`);
    }

    // Ajoutez des méthodes pour Excel si souhaité
    exportExcelTable1(): void {
        this.exportToExcel(1);
    }

    exportExcelTable2(): void {
        this.exportToExcel(2);
    }

    loadDataNoApproved() {
        this.loading = true;
        this.equipmentService.getAllNoApproved().subscribe({
            next: (data) => {
                this.equipmentsNoApproved.set(data);
                console.log(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: 'Failed to load data', life: 3000 });
                this.loading = false;
            }
        });
    }

    loadDataNoModified() {
        this.loading = true;
        this.equipmentService.getAllNoModified().subscribe({
            next: (data) => {
                this.equipmentsNoModified.set(data);
                console.log(data);
                this.loading = false;
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: 'Failed to load data', life: 3000 });
                this.loading = false;
            }
        });
    }

    onGlobalFilter(table: Table, event: Event) {
        table.filterGlobal((event.target as HTMLInputElement).value, 'contains');
    }

    approveEquipmentNoApproved(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isApproved: true, isNew: false };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Success', detail: `Equipment ${equipment.code} approved`, life: 3000 });
                this.loadDataNoApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: `Failed to approve equipment ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoApproved(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isNew: false };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Success', detail: `Equipment ${equipment.code} denied`, life: 3000 });
                this.loadDataNoApproved();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: `Failed to deny equipment ${equipment.code}`, life: 3000 });
            }
        });
    }

    approveEquipmentNoModified(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isApproved: true, isNew: false };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Success', detail: `Equipment ${equipment.code} approved`, life: 3000 });
                this.loadDataNoModified();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: `Failed to approve equipment ${equipment.code}`, life: 3000 });
            }
        });
    }

    deniedEquipmentNoModified(equipment: Equipment) {
        const updatedEquipment = { ...equipment, isUpdated: true, isNew: false };
        this.equipmentService.update(equipment.id!, updatedEquipment).subscribe({
            next: (data) => {
                this.messageService.add({ severity: 'success', summary: 'Success', detail: `Equipment ${equipment.code} denied`, life: 3000 });
                this.loadDataNoModified();
            },
            error: (err) => {
                this.messageService.add({ severity: 'error', summary: 'Error', detail: `Failed to deny equipment ${equipment.code}`, life: 3000 });
            }
        });
    }

    confirm1(event: Event, equipment: Equipment) {
        this.confirmationService.confirm({
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
}

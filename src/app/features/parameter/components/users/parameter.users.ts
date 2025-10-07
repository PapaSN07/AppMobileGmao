import { Component, inject, ViewChild } from '@angular/core';
import { User } from '../../../../core/models';
import { ConfirmationService, MessageService } from 'primeng/api';
import { UserService, AuthService } from '../../../../core/services/api';
import { Table, TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { ConfirmPopupModule } from 'primeng/confirmpopup';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { DatePipe } from '@angular/common';
import { TagModule } from 'primeng/tag';

interface expandedRows {
    [key: string]: boolean;
}

@Component({
    selector: 'app-parameter.users',
    imports: [
        TableModule,
        ButtonModule,
        InputIconModule,
        IconFieldModule,
        InputTextModule,
        ConfirmPopupModule,
        DatePipe,
        TagModule
    ],
    standalone: true,
    templateUrl: './parameter.users.html',
    providers: [MessageService, ConfirmationService]
})
export class ParameterUsers {
    userService = inject(UserService);
    authService = inject(AuthService);
    messageService = inject(MessageService);
    confirmationService = inject(ConfirmationService);

    @ViewChild('dt') dt1!: Table;
    users: User[] = [];
    loading: boolean = true;
    selection: User[] = [];
    expandedRows: expandedRows = {};
    balanceFrozen: boolean = true;
    searchValue: string = '';

    ngOnInit() {
        const currentUser = this.authService.getUser();
        if (currentUser && currentUser.id) {
            this.loadUsers(currentUser.id);
        }
    }

    loadUsers(supervisorId: string) {
        this.loading = true;
        this.userService.getAllUsers(supervisorId).subscribe({
            next: (response: { data: User[] } | User[]) => {
                this.users = Array.isArray(response) ? response : response.data;
                // Convertir createdAt en Date pour le filtre date
                this.users.forEach(user => {
                    if (user.createdAt) {
                        user.createdAt = new Date(user.createdAt);
                    }
                });
                this.loading = false;
            },
            error: (error) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Erreur lors du chargement des utilisateurs.', life: 4000 });
                this.loading = false;
            }
        });
    }

    deleteUser(userId: string) {
        this.userService.deleteUser(userId).subscribe({
            next: () => {
                this.users = this.users.filter((user) => user.id !== userId);
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: 'Utilisateur supprimé avec succès.', life: 4000 });
            },
            error: (error) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Erreur lors de la suppression de l'utilisateur.", life: 4000 });
            }
        });
    }

    updateUser(user: User) {
        if (!user.id) return;

        this.userService.updateUser(user.id, user).subscribe({
            next: (updatedUser) => {
                const index = this.users.findIndex((u) => u.id === updatedUser.id);
                if (index !== -1) {
                    this.users[index] = updatedUser;
                }
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: 'Utilisateur mis à jour avec succès.', life: 4000 });
            },
            error: (error) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Erreur lors de la mise à jour de l'utilisateur.", life: 4000 });
            }
        });
    }

    onGlobalFilter(table: Table, event: Event) {
        table.filterGlobal((event.target as HTMLInputElement).value, 'contains');
    }

    confirm1(event: Event, user: User) {
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
                // this.approveEquipmentNoApproved(user);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Annulé', detail: 'Vous avez annulé la validation de cet équipement 🥲🥲🥲', life: 3000 });
            }
        });
    }

    confirm2(event: Event, user: User) {
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
                // this.deniedEquipmentNoApproved(equipment);
            },
            reject: () => {
                this.messageService.add({ severity: 'error', summary: 'Annulé', detail: 'Vous avez annulé la validation de cet équipement', life: 3000 });
            }
        });
    }

    clear(table: Table) {
        table.clear();
        this.searchValue = '';
    }
}

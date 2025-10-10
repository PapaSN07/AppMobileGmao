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
import { Dialog } from 'primeng/dialog';
import { ConfirmDialog } from 'primeng/confirmdialog';
import { FormsModule } from '@angular/forms';
import { SelectModule } from 'primeng/select';
import { Toast } from "primeng/toast";
import { TextareaModule } from 'primeng/textarea';

interface expandedRows {
    [key: string]: boolean;
}

@Component({
    selector: 'app-parameter.users',
    imports: [TableModule, ButtonModule, InputIconModule, IconFieldModule, InputTextModule, ConfirmPopupModule, DatePipe, TagModule, Dialog, ConfirmDialog, FormsModule, SelectModule, Toast, TextareaModule],
    standalone: true,
    templateUrl: './parameter.users.html',
    providers: [MessageService, ConfirmationService]
})
export class ParameterUsers {
    userService = inject(UserService);
    authService = inject(AuthService);
    messageService = inject(MessageService);
    confirmationService = inject(ConfirmationService);

    @ViewChild('dt') dt!: Table;
    users: User[] = [];
    loading: boolean = true;
    selection: User[] = [];
    expandedRows: expandedRows = {};
    balanceFrozen: boolean = true;
    searchValue: string = '';
    userDialog: boolean = false;
    user: User = {
        username: '',
        email: '',
        role: ''
    };
    submitted: boolean = false;
    enabledOptions = [
        { label: 'Activé', value: true },
        { label: 'Désactivé', value: false }
    ];

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
                this.users.forEach((user) => {
                    if (user.created_at) {
                        user.created_at = new Date(user.created_at);
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

    deleteUser(user: User) {
        const userId: string = user.id || '';

        if (!userId) return;

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
            next: (response: any) => {
                const updatedUser = response.data;
                const index = this.users.findIndex((u) => u.id === user.id);

                if (index !== -1) {
                    this.users[index] = updatedUser;
                }
                
                this.messageService.add({ severity: 'success', summary: 'Succès', detail: response.message || 'Utilisateur mis à jour avec succès.', life: 4000 });
            },
            error: (error) => {
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: "Erreur lors de la mise à jour de l'utilisateur.", life: 4000 });
            }
        });
    }

    onGlobalFilter(table: Table, event: Event) {
        table.filterGlobal((event.target as HTMLInputElement).value, 'contains');
    }

    clear(table: Table) {
        table.clear();
        this.searchValue = '';
    }

    editUser(user: User) {
        this.user = { ...user };
        this.submitted = false; // Réinitialiser l'état de soumission
        this.userDialog = true;
        console.log('Editing user:', this.user); // Debug: vérifier que l'utilisateur est bien chargé
        console.log('Dialog state:', this.userDialog); // Debug: vérifier l'état du dialogue
    }

    saveUser() {
        this.submitted = true;
        // Validation: username et email requis
        if (!this.user.username?.trim() || !this.user.email?.trim()) {
            this.messageService.add({ 
                severity: 'error', 
                summary: 'Erreurs', 
                detail: 'Username et Email sont obligatoires.', 
                life: 4000 
            });
            return;
        }

        this.updateUser(this.user);
        this.hideDialog();
    }

    hideDialog() {
        this.userDialog = false;
        this.submitted = false;
        // Réinitialiser l'utilisateur
        this.user = {
            username: '',
            email: '',
            role: ''
        };
    }
}

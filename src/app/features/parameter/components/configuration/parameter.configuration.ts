import { Component, inject, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { FluidModule } from 'primeng/fluid';
import { InputTextModule } from 'primeng/inputtext';
import { SelectModule } from 'primeng/select';
import { TextareaModule } from 'primeng/textarea';
import { ToggleSwitch } from 'primeng/toggleswitch';
import { AuthService, EntityService, UserService } from '../../../../core/services/api';
import { MessageService } from 'primeng/api';
import { Toast } from "primeng/toast";
import { EntityModel, User } from '../../../../core/models';
import { AutoCompleteModule } from 'primeng/autocomplete';

interface AutoCompleteCompleteEvent {
    originalEvent: Event;
    query: string;
}

interface Entity {
    code: string;
}

@Component({
    selector: 'app-configuration',
    imports: [
        InputTextModule, 
        FluidModule, 
        ButtonModule, 
        SelectModule, 
        FormsModule, 
        TextareaModule, 
        ToggleSwitch, 
        Toast,
        AutoCompleteModule
    ],
    standalone: true,
    templateUrl: './parameter.configuration.html',
    providers: [MessageService]
})
export class ParameterConfiguration implements OnInit {
    authService = inject(AuthService);
    entityService = inject(EntityService);
    userService = inject(UserService);
    messageService = inject(MessageService);

    username: string = '';
    email: string = '';
    superviseur: string = '';
    company: string = '';
    role: string = 'PRESTATAIRE';
    checked: boolean = true;
    address: string = '';

    usernameError: boolean = false;
    emailError: boolean = false;
    companyError: boolean = false;

    selectedEntity!: Entity | null;
    selectedEntityError: boolean = false;
    filteredItems: Entity[] = [];
    entities: Entity[] = [];


    ngOnInit() {
        this.loadSupervisor();
        this.loadEntities();
    }

    loadSupervisor() {
        const currentUser = this.authService.getUser();
        if (currentUser) {
            this.superviseur = currentUser.username.split('.').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
        }
    }

    filterItems(event: AutoCompleteCompleteEvent) {
        const query = (event.query || '').toLowerCase();
        if (!this.entities || this.entities.length === 0) {
            this.filteredItems = [];
            return;
        }

        // utiliser includes pour plus de flexibilité (ou startsWith si besoin)
        this.filteredItems = (this.entities as Entity[]).filter(item =>
            item.code.toLowerCase().includes(query)
        );
    }

    loadEntities() {
        this.entityService.getAllEntities().subscribe({
            next: (data) => {
                const seen = new Set<string>();
                const unique: Entity[] = [];

                (data || []).forEach((entity: EntityModel) => {
                    const item: Entity = {
                        code: entity.code
                    };
                    const key = `${item.code}`;
                    if (!seen.has(key)) {
                        seen.add(key);
                        unique.push(item);
                    }
                });

                this.entities = unique.sort((a, b) => a.code.localeCompare(b.code));
                // initialisation safe
                this.filteredItems = [];
            },
            error: (error) => {
                console.error('Erreur lors du chargement des entités:', error);
                this.messageService.add({ severity: 'error', summary: 'Erreur', detail: 'Impossible de charger les entités.', life: 4000 });
            }
        });
    }

    validateField(field: string) {
        switch (field) {
            case 'username':
                this.usernameError = !this.username?.trim();
                break;
            case 'email':
                this.emailError = !this.email?.trim() || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email);
                break;
            case 'company':
                this.companyError = !this.company?.trim();
                break;
            case 'entity':
                this.selectedEntityError = !this.selectedEntity || !this.selectedEntity.code?.trim();
                break;
        }
    }

    onSave() {
        this.validateField('username');
        this.validateField('email');
        this.validateField('company');
        this.validateField('entity');

        if (this.usernameError || this.emailError || this.companyError || this.selectedEntityError) {
            this.messageService.add({ severity: 'error', summary: 'Erreurs', detail: 'Remplissez les champs obligatoires.', life: 4000 });
            return;
        }

        // Préparer les données pour le backend
        const userData: User = {
            username: this.username.trim(),
            email: this.email.trim(),
            company: this.company.trim(),
            address: this.address?.trim() || '',
            supervisor: this.authService.getUser()?.id || '',
            role: this.role,
            is_enabled: this.checked,
        };

        // Envoyer au backend
        this.userService.addUser(userData).subscribe({
            next: (response) => {
                console.log(response);
                this.messageService.add({
                    severity: 'success',
                    summary: 'Succès',
                    detail: 'Compte prestataire créé avec succès.',
                    life: 4000
                });
                this.resetForm();
            },
            error: (error) => {
                const errorDetail = error?.message || error?.error?.message || 'Erreur lors de la création du compte.';
                this.messageService.add({
                    severity: 'error',
                    summary: 'Erreur',
                    detail: errorDetail,
                    life: 4000
                });
            }
        });
    }

    private resetForm() {
        this.username = '';
        this.email = '';
        this.company = '';
        this.address = '';
        this.checked = true;
        this.usernameError = false;
        this.emailError = false;
        this.companyError = false;
    }
}


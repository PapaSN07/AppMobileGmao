import { Injectable, inject } from '@angular/core';
import { AuthService } from '../api/auth.service';
import { DashboardStatistics, StatCard, UserStats } from '../../models/statistics.model';

/**
 * ✅ Service de filtrage des statistiques selon le rôle
 * Principe SOLID: Single Responsibility - Gestion uniquement du filtrage
 * Principe DRY: Logique centralisée réutilisable
 */
@Injectable({
    providedIn: 'root'
})
export class StatisticsFilterService {
    private authService = inject(AuthService);

    /**
     * ✅ Filtre les statistiques selon le rôle de l'utilisateur
     * @param data - Statistiques complètes
     * @returns Statistiques filtrées
     */
    filterStatistics(data: DashboardStatistics): DashboardStatistics {
        const user = this.authService.getUser();
        
        if (!user) {
            return this.getEmptyStatistics();
        }

        // ✅ Si ADMIN, retourner toutes les statistiques
        if (user.role === 'ADMIN') {
            return data;
        }

        // ✅ Si PRESTATAIRE, filtrer pour n'afficher que ses propres données
        if (user.role === 'PRESTATAIRE') {
            return this.filterForPrestataire(data, user.username);
        }

        return this.getEmptyStatistics();
    }

    /**
     * ✅ Filtre les statistiques pour un prestataire
     * Principe DRY: Méthode réutilisable
     */
    private filterForPrestataire(data: DashboardStatistics, username: string): DashboardStatistics {
        // Filtrer les stats utilisateur pour n'afficher que celles du prestataire connecté
        const userStats = data.stats_by_user?.filter(stat => 
            stat.username === username
        ) || [];

        // Calculer les équipements du prestataire uniquement
        const prestataireStats = userStats.reduce((acc, stat) => ({
            new_count: acc.new_count + stat.new_count,
            update_count: acc.update_count + stat.update_count
        }), { new_count: 0, update_count: 0 });

        return {
            success: data.success,
            message: data.message,
            equipment_stats: {
                total_gmao: data.equipment_stats.total_gmao, // Lecture seule
                total_temp: prestataireStats.new_count + prestataireStats.update_count,
                new_equipments: prestataireStats.new_count,
                updated_equipments: prestataireStats.update_count,
                approved_equipments: 0, // Masqué pour prestataire
                rejected_equipments: 0, // Masqué pour prestataire
                pending_validation: prestataireStats.new_count + prestataireStats.update_count,
                archived_equipments: 0 // Masqué pour prestataire
            },
            stats_by_entity: undefined, // Masqué pour prestataire
            stats_by_family: undefined, // Masqué pour prestataire
            stats_by_user: userStats, // Uniquement ses propres stats
            last_updated: data.last_updated
        };
    }

    /**
     * ✅ Filtre les cartes de statistiques selon le rôle
     */
    filterStatsCards(cards: StatCard[]): StatCard[] {
        const user = this.authService.getUser();
        
        if (!user) {
            return [];
        }

        // ✅ Si ADMIN, toutes les cartes
        if (user.role === 'ADMIN') {
            return cards;
        }

        // ✅ Si PRESTATAIRE, cartes limitées
        if (user.role === 'PRESTATAIRE') {
            const allowedTitles = [
                'Total GMAO',
                'En attente', 
                'Nouveaux',
                'Modifiés',
                'Validation en attente'
            ];
            return cards.filter(card => allowedTitles.includes(card.title));
        }

        return [];
    }

    /**
     * ✅ Vérifie si l'utilisateur peut voir les graphiques détaillés
     */
    canViewDetailedCharts(): boolean {
        return this.authService.isAdmin();
    }

    /**
     * ✅ Statistiques vides en cas d'erreur
     */
    private getEmptyStatistics(): DashboardStatistics {
        return {
            success: false,
            message: 'Accès non autorisé',
            equipment_stats: {
                total_gmao: 0,
                total_temp: 0,
                new_equipments: 0,
                updated_equipments: 0,
                approved_equipments: 0,
                rejected_equipments: 0,
                pending_validation: 0,
                archived_equipments: 0
            },
            stats_by_entity: [],
            stats_by_family: [],
            stats_by_user: [],
            last_updated: new Date().toISOString()
        };
    }
}
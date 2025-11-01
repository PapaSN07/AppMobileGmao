export interface DashboardStatistics {
    success: boolean;
    message: string;
    equipment_stats: EquipmentStats;
    stats_by_entity?: EntityStats[];
    stats_by_family?: FamilyStats[];
    stats_by_user?: UserStats[];
    last_updated: string;
}

export interface EquipmentStats {
    total_gmao: number;
    total_temp: number;
    new_equipments: number;
    updated_equipments: number;
    approved_equipments: number;
    rejected_equipments: number;
    pending_validation: number;
    archived_equipments: number;
}

export interface EntityStats {
    entity: string;
    count: number;
}

export interface FamilyStats {
    family: string;
    count: number;
}

export interface UserStats {
    username: string;
    new_count: number;
    update_count: number;
}

export interface StatCard {
    title: string;
    value: number;
    icon: string;
    color: string;
    bgColor: string;
    trend?: number;
}

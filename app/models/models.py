from pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any, List
from datetime import datetime

class EquipmentModel(BaseModel):
    """
    Modèle de données pour les équipements Coswin.
    """
    id: str = Field(..., description="Identifiant unique de l'équipement")
    codeParent: Optional[str] = Field(None, description="Code de l'équipement parent")
    code: str = Field(..., description="Code de l'équipement")
    famille: str = Field(..., description="Famille d'équipement")
    zone: str = Field(..., description="Zone géographique")
    entity: str = Field(..., description="Entité responsable")
    unite: str = Field(..., description="Unité organisationnelle")
    centreCharge: str = Field(..., description="Centre de charge")
    description: str = Field(..., description="Description de l'équipement")
    longitude: Optional[str] = Field(None, description="Coordonnée longitude")
    latitude: Optional[str] = Field(None, description="Coordonnée latitude")
    feeder: Optional[str] = Field(None, description="Identifiant du feeder")
    feederDescription: Optional[str] = Field(None, description="Description du feeder")

    class Config:
        """Configuration Pydantic"""
        str_strip_whitespace = True  # Supprime les espaces en début/fin
        validate_assignment = True   # Valide lors des assignations
        use_enum_values = True      # Utilise les valeurs des enums
        
    @validator('id', 'code', 'famille', 'zone', 'entity', 'unite', 'centreCharge')
    def validate_required_fields(cls, v):
        """Valide que les champs obligatoires ne sont pas vides"""
        if not v or v.strip() == "":
            raise ValueError("Ce champ ne peut pas être vide")
        return v.strip()

    @validator('longitude', 'latitude')
    def validate_coordinates(cls, v):
        """Valide les coordonnées géographiques"""
        if v is not None and v.strip():
            try:
                float_val = float(v)
                return str(float_val)  # Normalise le format
            except ValueError:
                raise ValueError("Les coordonnées doivent être des nombres valides")
        return None

    @classmethod
    def from_db_row(cls, row: tuple) -> 'EquipmentModel':
        """
        Crée une instance EquipmentModel à partir d'une ligne de base de données.
        
        Args:
            row: Tuple contenant les données de la base de données Oracle
            
        Returns:
            Instance EquipmentModel
            
        Raises:
            ValueError: Si les données sont invalides
        """
        try:
            return cls(
                id=str(row[0]) if row[0] is not None else "",
                codeParent=str(row[1]) if row[1] is not None else None,
                code=str(row[2]) if row[2] is not None else "",
                famille=str(row[3]) if row[3] is not None else "",
                zone=str(row[4]) if row[4] is not None else "",
                entity=str(row[5]) if row[5] is not None else "",
                unite=str(row[6]) if row[6] is not None else "",
                centreCharge=str(row[7]) if row[7] is not None else "",
                description=str(row[8]) if row[8] is not None else "",
                longitude=str(row[9]) if row[9] is not None and str(row[9]).strip() else None,
                latitude=str(row[10]) if row[10] is not None and str(row[10]).strip() else None,
                feeder=str(row[11]) if len(row) > 11 and row[11] is not None else None,
                feederDescription=str(row[12]) if len(row) > 12 and row[12] is not None else None
            )
        except IndexError as e:
            raise ValueError(f"Ligne de base de données incomplète: {e}")
        except Exception as e:
            raise ValueError(f"Erreur lors de la création du modèle: {e}")

    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le modèle en dictionnaire.
        
        Returns:
            Dictionnaire représentant l'équipement
        """
        return self.dict(exclude_none=False)

    def to_api_response(self) -> Dict[str, Any]:
        """
        Convertit le modèle en format de réponse API.
        
        Returns:
            Dictionnaire formaté pour l'API
        """
        data = self.to_dict()
        # Ajouter des métadonnées utiles
        data['has_coordinates'] = bool(self.longitude and self.latitude)
        data['has_feeder'] = bool(self.feeder)
        return data

    def __str__(self) -> str:
        """Représentation string de l'équipement"""
        return f"Equipment({self.code} - {self.description})"

    def __repr__(self) -> str:
        """Représentation détaillée de l'équipement"""
        return f"EquipmentModel(id={self.id}, code={self.code}, zone={self.zone})"

    def to_mobile_detail(self) -> Dict[str, Any]:
        """Format détaillé pour mobile"""
        return {
            'id': self.id,
            'code': self.code,
            'famille': self.famille,
            'zone': self.zone,
            'entity': self.entity,
            'unite': self.unite,
            'centre_charge': self.centreCharge,
            'description': self.description,
            'coordinates': {
                'latitude': float(self.latitude) if self.latitude else None,
                'longitude': float(self.longitude) if self.longitude else None,
                'has_location': bool(self.longitude and self.latitude)
            },
            'feeder': {
                'id': self.feeder,
                'description': self.feederDescription
            } if self.feeder else None
        }


class UserModel(BaseModel):
    """
    Modèle de données pour les utilisateurs.
    """
    id: str = Field(..., description="Identifiant unique de l'utilisateur")
    code: str = Field(..., description="Code de l'utilisateur")
    username: str = Field(..., description="Nom d'utilisateur")
    password: Optional[str] = Field(None, description="Mot de passe de l'utilisateur")
    email: Optional[str] = Field(None, description="Adresse e-mail de l'utilisateur")
    entity: Optional[str] = Field(None, description="Nom de l'entité de l'utilisateur")
    group: Optional[str] = Field(None, description="Groupe de l'utilisateur")
    url_image: Optional[str] = Field(None, description="URL de l'image de profil")
    is_absent: bool = Field(True, description="Indique si l'utilisateur est absent")

    class Config:
        """Configuration Pydantic"""
        str_strip_whitespace = True  # Supprime les espaces en début/fin
        validate_assignment = True   # Valide lors des assignations
        use_enum_values = True      # Utilise les valeurs des enums
    
    @validator('username', 'password')
    def validate_required_fields(cls, v):
        """Valide que les champs obligatoires ne sont pas vides"""
        if not v or v.strip() == "":
            raise ValueError("Ce champ ne peut pas être vide")
        return v.strip()
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'UserModel':
        """
        Crée une instance UserModel à partir d'une ligne de base de données.
        
        Args:
            row: Tuple contenant les données de la base de données Oracle
            
        Returns:
            Instance UserModel
            
        Raises:
            ValueError: Si les données sont invalides
        """
        try:
            return cls(
                id=str(row[0]) if row[0] is not None else "",
                code=str(row[1]) if row[1] is not None else "",
                username=str(row[2]) if row[2] is not None else "",
                email=str(row[3]) if row[3] is not None else None,
                entity=str(row[4]) if row[4] is not None else None,
                group=str(row[5]) if row[5] is not None else None,
                url_image=str(row[6]) if row[6] is not None else None,
                is_absent=bool(row[7]) if len(row) > 7 and row[7] is not None else True,
                password=str(row[8]) if len(row) > 8 and row[8] is not None else None
            )
        except IndexError as e:
            raise ValueError(f"Ligne de base de données incomplète: {e}")
        except Exception as e:
            raise ValueError(f"Erreur lors de la création du modèle: {e}")
        
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit le modèle en dictionnaire.
        
        Returns:
            Dictionnaire représentant l'utilisateur
        """
        return self.dict(exclude_none=False)
    
    def to_api_response(self) -> Dict[str, Any]:
        """
        Convertit le modèle en format de réponse API.
        
        Returns:
            Dictionnaire formaté pour l'API
        """
        return self.to_dict()
    
    def __str__(self) -> str:
        """Représentation string de l'utilisateur"""
        return f"User({self.username} - {self.email})"
    
    def __repr__(self) -> str:
        """Représentation détaillée de l'utilisateur"""
        return f"UserModel(id={self.id}, username={self.username}, entity={self.entity})"
    
    def to_mobile_dict(self) -> Dict[str, Any]:
        """Format optimisé pour liste mobile"""
        return {
            'id': self.id,
            'username': self.username,
            'code': self.code,
            'email': self.email,
            'entity': self.entity,
            'group': self.group,
            'url_image': self.url_image,
            'is_absent': self.is_absent
        }
    
    def to_mobile_detail(self) -> Dict[str, Any]:
        """Format détaillé pour mobile"""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'entity': self.entity,
            'group': self.group,
            'url_image': self.url_image,
            'is_absent': self.is_absent
        }


class ZoneModel(BaseModel):
    """
    Modèle pour les zones géographiques.
    """
    id: str = Field(..., description="Identifiant unique de la zone")
    code: str = Field(..., description="Code de la zone")
    description: str = Field(..., description="Description de la zone")
    entity: Optional[str] = Field(None, description="Entité associée à la zone")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'ZoneModel':
        """Crée une instance ZoneModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            entity=str(row[3]) if len(row) > 3 and row[3] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity': self.entity
        }
    
    def __str__(self) -> str:
        """Représentation string de la zone"""
        return f"Zone({self.code} - {self.description})"
    
    def __repr__(self) -> str:
        """Représentation détaillée de la zone"""
        return f"ZoneModel(id={self.id}, code={self.code}, entity={self.entity})"


class FamilleModel(BaseModel):
    """
    Modèle pour les familles d'équipements.
    """
    id: str = Field(..., description="Identifiant unique de la famille")
    code: str = Field(..., description="Code de la famille")
    description: str = Field(..., description="Description de la famille")
    parent_category: Optional[str] = Field(None, description="Catégorie parent de la famille")
    system_category: Optional[str] = Field(None, description="Catégorie système de la famille")
    level: Optional[int] = Field(None, description="Niveau de la famille dans la hiérarchie")
    entity: Optional[str] = Field(None, description="Entité associée à la famille")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'FamilleModel':
        """Crée une instance FamilleModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            parent_category=str(row[3]) if len(row) > 3 and row[3] is not None else None,
            system_category=str(row[4]) if len(row) > 4 and row[4] is not None else None,
            level=int(row[5]) if len(row) > 5 and row[5] is not None else None,
            entity=str(row[6]) if len(row) > 6 and row[6] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'code': self.code,
            'description': self.description,
            'parent_category': self.parent_category,
            'system_category': self.system_category,
            'level': self.level,
            'entity': self.entity
        }
    
    def __str__(self) -> str:
        """Représentation string de la famille"""
        return f"Famille({self.code} - {self.description})"
    
    def __repr__(self) -> str:
        """Représentation détaillée de la famille"""
        return f"FamilleModel(code={self.code}, description={self.description}, entity={self.entity})"
    
    def to_mobile_dict(self) -> Dict[str, Any]:
        """Format optimisé pour liste mobile"""
        return {
            'code': self.code,
            'description': self.description,
            'parent_category': self.parent_category,
            'system_category': self.system_category,
            'level': self.level,
            'entity': self.entity
        }


class EntityModel(BaseModel):
    """
    Modèle pour les entités.
    """
    id: str = Field(..., description="Identifiant unique de l'entité")
    code: str = Field(..., description="Code de l'entité")
    description: str = Field(..., description="Description de l'entité")
    entity_type: str = Field(..., description="Type d'entité")
    level: int = Field(..., description="Niveau de l'entité dans la hiérarchie")
    parent_entity: Optional[str] = Field(None, description="Entité parent")
    system_entity: Optional[str] = Field(None, description="Entité système")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'EntityModel':
        """Crée une instance EntityModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            entity_type=str(row[3]) if row[3] is not None else "",
            level=int(row[4]) if row[4] is not None else 0,
            parent_entity=str(row[5]) if len(row) > 5 and row[5] is not None else None,
            system_entity=str(row[6]) if len(row) > 6 and row[6] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity_type': self.entity_type,
            'level': self.level,
            'parent_entity': self.parent_entity,
            'system_entity': self.system_entity
        }
    
    def __str__(self) -> str:
        """Représentation string de l'entité"""
        return f"Entity({self.code} - {self.description})"
    
    def __repr__(self) -> str:
        """Représentation détaillée de l'entité"""
        return f"EntityModel(id={self.id}, code={self.code}, entity_type={self.entity_type})"
    
    def to_mobile_dict(self) -> Dict[str, Any]:
        """Format optimisé pour liste mobile"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity_type': self.entity_type,
            'level': self.level,
            'parent_entity': self.parent_entity,
            'system_entity': self.system_entity
        }


class CentreChargeModel(BaseModel):
    """
    Modèle pour les centres de charge.
    """
    id: str = Field(..., description="Identifiant unique du centre de charge")
    code: str = Field(..., description="Code du centre de charge")
    description: str = Field(..., description="Description du centre de charge")
    entity: Optional[str] = Field(None, description="Entité associée au centre de charge")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'CentreChargeModel':
        """Crée une instance CentreChargeModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            entity=str(row[3]) if len(row) > 3 and row[3] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity': self.entity
        }
    
    def __str__(self) -> str:
        """Représentation string du centre de charge"""
        return f"CentreCharge({self.code} - {self.description})"

    def __repr__(self) -> str:
        """Représentation détaillée du centre de charge"""
        return f"CentreChargeModel(id={self.id}, code={self.code}, entity={self.entity})"


class UniteModel(BaseModel):
    """Modèle pour les unités organisationnelles.
    """
    id: str = Field(..., description="Identifiant unique de l'unité")
    code: str = Field(..., description="Code de l'unité")
    description: str = Field(..., description="Description de l'unité")
    entity: Optional[str] = Field(None, description="Entité associée à l'unité")
    parent_entity: Optional[str] = Field(None, description="Entité parente de l'unité")
    system_entity: Optional[str] = Field(None, description="Entité système de l'unité")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'UniteModel':
        """Crée une instance UniteModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            entity=str(row[3]) if len(row) > 3 and row[3] is not None else None,
            parent_entity=str(row[4]) if len(row) > 4 and row[4] is not None else None,
            system_entity=str(row[5]) if len(row) > 5 and row[5] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity': self.entity,
            'parent_entity': self.parent_entity,
            'system_entity': self.system_entity
        }
    
    def __str__(self) -> str:
        """Représentation string de l'unité"""
        return f"Unite({self.code} - {self.description})"
    
    def __repr__(self) -> str:
        """Représentation détaillée de l'unité"""
        return f"UniteModel(id={self.id}, code={self.code}, entity={self.entity}, parent_entity={self.parent_entity}, system_entity={self.system_entity})"


class FeederModel(BaseModel):
    """
    Modèle pour les feeders.
    """
    id: str = Field(..., description="Identifiant unique du feeder")
    code: str = Field(..., description="Code du feeder")
    description: str = Field(..., description="Description du feeder")
    entity: Optional[str] = Field(None, description="Entité associée au feeder")
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'FeederModel':
        """Crée une instance FeederModel à partir d'une ligne de DB"""
        return cls(
            id=str(row[0]) if row[0] is not None else "",
            code=str(row[1]) if row[1] is not None else "",
            description=str(row[2]) if row[2] is not None else "",
            entity=str(row[3]) if len(row) > 3 and row[3] is not None else None
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict(exclude_none=True)
    
    def to_api_response(self) -> Dict[str, Any]:
        """Convertit en format de réponse API"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'entity': self.entity
        }
    
    def __str__(self) -> str:
        """Représentation string du feeder"""
        return f"Feeder({self.code} - {self.description})"
    
    def __repr__(self) -> str:
        """Représentation détaillée du feeder"""
        return f"FeederModel(id={self.id}, code={self.code}, entity={self.entity})"


class EquipmentFilterModel(BaseModel):
    """
    Modèle pour les filtres de recherche d'équipements.
    """
    zone: Optional[str] = None
    famille: Optional[str] = None
    entity: Optional[str] = None
    search_term: Optional[str] = None
    page: int = Field(1, ge=1, description="Numéro de page")
    page_size: int = Field(10, ge=1, le=100, description="Taille de page")

    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire pour la requête"""
        return {k: v for k, v in self.dict().items() if v is not None}

    def has_filters(self) -> bool:
        """Vérifie si des filtres sont appliqués"""
        return any([self.zone, self.famille, self.entity, self.search_term])


class EquipmentStatsModel(BaseModel):
    """
    Modèle pour les statistiques des équipements.
    """
    total_count: int = Field(..., description="Nombre total d'équipements")
    zones_count: int = Field(..., description="Nombre de zones")
    familles_count: int = Field(..., description="Nombre de familles")
    entities_count: int = Field(..., description="Nombre d'entités")
    equipment_with_coordinates: int = Field(0, description="Équipements avec coordonnées")
    equipment_with_feeder: int = Field(0, description="Équipements avec feeder")
    last_updated: Optional[datetime] = Field(None, description="Dernière mise à jour")

    def to_dict(self) -> Dict[str, Any]:
        """Convertit en dictionnaire"""
        return self.dict()


# Classes d'erreur personnalisées
class EquipmentNotFoundError(Exception):
    """Exception levée quand un équipement n'est pas trouvé"""
    pass


class InvalidEquipmentDataError(Exception):
    """Exception levée quand les données d'équipement sont invalides"""
    pass


# Fonctions utilitaires
def validate_equipment_data(data: Dict[str, Any]) -> bool:
    """
    Valide les données d'équipement.
    
    Args:
        data: Dictionnaire contenant les données à valider
        
    Returns:
        True si valide, False sinon
    """
    required_fields = ['id', 'code', 'famille', 'zone', 'entity', 'unite', 'centreCharge', 'description']
    
    for field in required_fields:
        if field not in data or not data[field]:
            return False
    
    return True


def create_equipment_from_dict(data: Dict[str, Any]) -> EquipmentModel:
    """
    Crée un EquipmentModel à partir d'un dictionnaire.
    
    Args:
        data: Dictionnaire contenant les données d'équipement
        
    Returns:
        Instance EquipmentModel
        
    Raises:
        InvalidEquipmentDataError: Si les données sont invalides
    """
    if not validate_equipment_data(data):
        raise InvalidEquipmentDataError("Données d'équipement invalides")
    
    try:
        return EquipmentModel(**data)
    except Exception as e:
        raise InvalidEquipmentDataError(f"Erreur lors de la création du modèle: {e}")


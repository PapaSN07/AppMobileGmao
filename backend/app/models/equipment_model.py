from sqlalchemy import Boolean, Integer, func

from typing import Any, Dict, List, Optional
from sqlalchemy import Column, String, Float, Text, Date

from app.models.attribute_model import AttributeClicClac


# Importer les deux bases depuis engine
from app.db.sqlalchemy.engine import Base, BaseClicClac

class EquipmentModel(Base):
    """Modèle SQLAlchemy pour les équipements Coswin."""
    __tablename__ = 'equipment'
    __table_args__ = {'schema': 'dbo'}
    
    # ✅ CORRECTION: Colonnes selon EQUIPMENT_INFINITE_QUERY
    id = Column('pk_equipment', Integer, primary_key=True, autoincrement=True)
    codeParent = Column('ereq_parent_equipment', String(50), nullable=True)
    code = Column('ereq_code', String(50), nullable=False, unique=True, index=True)
    famille = Column('ereq_category', String(50), nullable=False)
    zone = Column('ereq_zone', String(50), nullable=False)
    entity = Column('ereq_entity', String(50), nullable=False)
    unite = Column('ereq_function', String(50), nullable=False)
    centreCharge = Column('ereq_costcentre', String(50), nullable=False)
    description = Column('ereq_description', Text, nullable=False)
    longitude = Column('ereq_longitude', Float, nullable=True)
    latitude = Column('ereq_latitude', Float, nullable=True)
    feeder = Column('ereq_string2', String(255), nullable=True)
    barCode = Column('ereq_bar_code', String(50), nullable=True)  # ✅ AJOUTÉ
    creation_date = Column('ereq_creation_date', Date, default=func.now())

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Attributs Python pour données jointes (pas des colonnes DB)
        self.attributes: List[Dict[str, Any]] = []
        self.centreChargeDescription: Optional[str] = None
        self.feederDescription: Optional[str] = None

    @classmethod
    def from_db_row(cls, row: tuple) -> 'EquipmentModel':
        """
        Crée une instance depuis EQUIPMENT_INFINITE_QUERY ou EQUIPMENT_BY_ID_QUERY
        Structure attendue: pk_equipment, ereq_parent_equipment, ereq_code, ereq_category,
        ereq_zone, ereq_entity, ereq_function, ereq_costcentre, ereq_description,
        ereq_longitude, ereq_latitude, feeder, feeder_description, [attributs...]
        """
        try:
            equipment = cls()
            # ✅ CORRECTION: Garder ID comme Integer
            equipment.id = int(row[0]) if row[0] is not None else None
            equipment.codeParent = str(row[1]) if row[1] is not None else None
            equipment.code = str(row[2]) if row[2] is not None else ""
            equipment.famille = str(row[3]) if row[3] is not None else ""
            equipment.zone = str(row[4]) if row[4] is not None else ""
            equipment.entity = str(row[5]) if row[5] is not None else ""
            equipment.unite = str(row[6]) if row[6] is not None else ""
            # ✅ CORRECTION: ereq_costcentre est déjà la description via JOIN
            equipment.centreCharge = str(row[7]) if row[7] is not None else ""
            equipment.centreChargeDescription = str(row[7]) if row[7] is not None else ""
            equipment.description = str(row[8]) if row[8] is not None else ""
            equipment.longitude = float(row[9]) if row[9] is not None and str(row[9]).strip() else None
            equipment.latitude = float(row[10]) if row[10] is not None and str(row[10]).strip() else None
            equipment.feeder = str(row[11]) if len(row) > 11 and row[11] is not None else None
            equipment.feederDescription = str(row[12]) if len(row) > 12 and row[12] is not None else None
            return equipment
        except (IndexError, ValueError) as e:
            raise ValueError(f"Erreur lors de la création du modèle: {e}")

    def to_dict(self) -> Dict[str, Any]:
        """Convertit le modèle en dictionnaire."""
        return {
            'id': str(self.id) if self.id is not None else None,  # ✅ String pour API
            'codeParent': self.codeParent,
            'code': self.code,
            'famille': self.famille,
            'zone': self.zone,
            'entity': self.entity,
            'unite': self.unite,
            'centreCharge': self.centreChargeDescription or self.centreCharge,
            'description': self.description,
            'longitude': str(self.longitude) if self.longitude is not None else None,
            'latitude': str(self.latitude) if self.latitude is not None else None,
            'feeder': self.feeder,
            'feederDescription': self.feederDescription,
            'attributes': self.attributes
        }


# ✅ Builder pour construire les équipements avec attributs
class EquipmentWithAttributesBuilder:
    """
    Utilitaire pour construire des équipements avec attributs depuis EQUIPMENT_INFINITE_QUERY
    """
    
    @staticmethod
    def build_from_query_results(results: List[tuple]) -> List[EquipmentModel]:
        """
        Construit une liste d'équipements avec leurs attributs depuis votre requête complexe
        Structure: pk_equipment, ereq_parent_equipment, ereq_code, ereq_category, ereq_zone,
        ereq_entity, ereq_function, ereq_costcentre, ereq_description, ereq_longitude,
        ereq_latitude, feeder, feeder_description, attr_id, attr_specification, 
        attr_index, attr_name, attr_value
        """
        equipment_dict = {}
        
        for row in results:
            equipment_id = str(row[0])  # pk_equipment
            
            # Créer l'équipement s'il n'existe pas
            if equipment_id not in equipment_dict:
                equipment = EquipmentModel.from_db_row(row[:13])  # 13 premiers champs
                equipment_dict[equipment_id] = equipment
            else:
                equipment = equipment_dict[equipment_id]
            
            # Ajouter l'attribut s'il existe (colonnes 13-17)
            if len(row) > 13 and row[13] is not None:  # attr_id
                attr_data = {
                    'id': str(row[13]),        # attr_id
                    'specification': row[14],   # attr_specification
                    'index': row[15],          # attr_index
                    'name': row[16],           # attr_name
                    'value': row[17]           # attr_value
                }
                equipment.attributes.append(attr_data)
        
        return list(equipment_dict.values())

    @staticmethod
    def build_single_from_query_results(results: List[tuple]) -> Optional[EquipmentModel]:
        """Construit un seul équipement avec ses attributs"""
        if not results:
            return None
        
        equipments = EquipmentWithAttributesBuilder.build_from_query_results(results)
        return equipments[0] if equipments else None

class EquipmentClicClac(BaseClicClac):
    __tablename__ = "equipment"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    code_parent = Column(String(255), nullable=True)
    code = Column(String(255), nullable=True, index=True)
    famille = Column(String(255), nullable=True, index=True)
    zone = Column(String(255), nullable=True)
    entity = Column(String(255), nullable=True, index=True)
    unite = Column(String(255), nullable=True)
    centre_charge = Column(String(255), nullable=True, index=True)
    description = Column(String(255), nullable=True)
    longitude = Column(String(255), nullable=True)
    latitude = Column(String(255), nullable=True)
    feeder = Column(String(255), nullable=True, index=True)
    feeder_description = Column(String(255), nullable=True)
    info = Column(String(255), nullable=True)
    etat = Column(String(255), nullable=True, default='NORMAL')
    type = Column(String(255), nullable=True, default='0. Technique')
    localisation = Column(String(255), nullable=True)
    niveau = Column(Integer, nullable=True, default=1)
    n_serie = Column(String(255), nullable=True, index=True)
    created_at = Column(Date, default=func.now(), nullable=False)
    updated_at = Column(Date, default=func.now(), onupdate=func.now(), nullable=False)
    created_by = Column(String(255), nullable=True)
    judged_by = Column(String(255), nullable=True)
    is_update = Column(Boolean, default=False)
    is_new = Column(Boolean, default=False)
    is_approved = Column(Boolean, default=False)
    is_rejected = Column(Boolean, default=False)
    commentaire = Column(String(255), nullable=True)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Attributs Python pour données jointes (pas des colonnes DB)
        self.attributes: List[AttributeClicClac] = []

    def to_dict_SDDV(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'famille': self.famille,
            'unite': self.unite,
            'centre_charge': self.centre_charge,
            'zone': self.zone,
            'entity': self.entity,
            'feeder': self.feeder,
            'feeder_description': self.feeder_description,
            'localisation': self.localisation,
            'code_parent': self.code_parent,
            'code': self.code,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None,
            'created_by': self.created_by,
            'judged_by': self.judged_by,
            'is_update': self.is_update,
            'is_new': self.is_new,
            'is_approved': self.is_approved,
            'is_rejected': self.is_rejected,
            'attributes': [attr.to_dict() for attr in self.attributes],
            'commentaire': self.commentaire
        }

class HistoryEquipmentClicClac(BaseClicClac):
    __tablename__ = "history_equipment"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    commentaire = Column(String(255), nullable=True)
    date_history_created_at = Column(Date, default=func.now(), nullable=False)
    equipment_id = Column(Integer, nullable=True, index=True)
    code_parent = Column(String(255), nullable=True)
    code = Column(String(255), nullable=True)
    famille = Column(String(255), nullable=True)
    zone = Column(String(255), nullable=True)
    entity = Column(String(255), nullable=True)
    unite = Column(String(255), nullable=True)
    centre_charge = Column(String(255), nullable=True)
    description = Column(String(255), nullable=True)
    longitude = Column(String(255), nullable=True)
    latitude = Column(String(255), nullable=True)
    feeder = Column(String(255), nullable=True)
    feeder_description = Column(String(255), nullable=True)
    info = Column(String(255), nullable=True)
    etat = Column(String(255), nullable=True, default='NORMAL')
    type = Column(String(255), nullable=True, default='Technique')
    localisation = Column(String(255), nullable=True)
    niveau = Column(Integer, nullable=True, default=1)
    n_serie = Column(String(255), nullable=True)
    created_at = Column(Date, nullable=True)
    updated_at = Column(Date, nullable=True)
    created_by = Column(String(255), nullable=True)
    judged_by = Column(String(255), nullable=True)
    is_update = Column(Boolean, default=False)
    is_new = Column(Boolean, default=False)
    is_approved = Column(Boolean, default=False)
    is_rejected = Column(Boolean, default=False)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'commentaire': self.commentaire,
            'date_history_created_at': self.date_history_created_at.isoformat() if self.date_history_created_at is not None else None,
            'equipment_id': str(self.equipment_id) if self.equipment_id is not None else None,
            'code_parent': self.code_parent,
            'code': self.code,
            'famille': self.famille,
            'zone': self.zone,
            'entity': self.entity,
            'unite': self.unite,
            'centre_charge': self.centre_charge,
            'description': self.description,
            'longitude': self.longitude,
            'latitude': self.latitude,
            'feeder': self.feeder,
            'feeder_description': self.feeder_description,
            'info': self.info,
            'etat': self.etat,
            'type': self.type,
            'localisation': self.localisation,
            'niveau': self.niveau,
            'n_serie': self.n_serie,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None,
            'created_by': self.created_by,
            'judged_by': self.judged_by,
            'is_update': self.is_update,
            'is_new': self.is_new,
            'is_approved': self.is_approved,
            'is_rejected': self.is_rejected
        }
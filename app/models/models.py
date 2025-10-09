from sqlalchemy import Column, String, Integer, DateTime, Float, Text, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import declarative_base
from typing import Dict, Any, List, Optional

# Base SQLAlchemy
Base = declarative_base()

class EquipmentModel(Base):
    """Modèle SQLAlchemy pour les équipements Coswin."""
    __tablename__ = 't_equipment'
    __table_args__ = {'schema': 'coswin'}
    
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
    creation_date = Column('ereq_creation_date', DateTime, default=func.now())

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


class UserModel(Base):
    """Modèle SQLAlchemy pour les utilisateurs."""
    # ✅ CORRECTION: Table selon GET_USER_AUTHENTICATION_QUERY
    __tablename__ = 'coswin_user'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_coswin_user', Integer, primary_key=True, autoincrement=True)
    code = Column('cwcu_code', String(50), nullable=False)
    username = Column('cwcu_signature', String(100), nullable=False)
    password = Column('cwcu_password', String(255), nullable=True)
    email = Column('cwcu_email', String(255), nullable=True)
    entity = Column('cwcu_entity', String(50), nullable=True)
    group = Column('cwcu_preferred_group', String(50), nullable=True)
    url_image = Column('cwcu_url_image', String(500), nullable=True)
    is_absent = Column('cwcu_is_absent', Boolean, default=True)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.role = ''  # Rôle utilisateur (non stocké en DB)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'UserModel':
        """Crée depuis GET_USER_AUTHENTICATION_QUERY"""
        try:
            user = cls()
            user.id = int(row[0]) if row[0] is not None else None
            user.code = str(row[1]) if row[1] is not None else ""
            user.username = str(row[2]) if row[2] is not None else ""
            user.email = str(row[3]) if row[3] is not None else None
            user.entity = str(row[4]) if row[4] is not None else None
            user.group = str(row[5]) if row[5] is not None else None
            user.url_image = str(row[6]) if row[6] is not None else None
            user.is_absent = bool(row[7]) if len(row) > 7 and row[7] is not None else True
            user.password = str(row[8]) if len(row) > 8 and row[8] is not None else None
            return user
        except (IndexError, ValueError) as e:
            raise ValueError(f"Erreur lors de la création du modèle utilisateur: {e}")

    def to_dict(self) -> Dict[str, Any]:
        """Convertit le modèle en dictionnaire."""
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'username': self.username,
            'email': self.email,
            'entity': self.entity,
            'group': self.group,
            'url_image': self.url_image,
            'is_absent': self.is_absent,
            'role': self.role
        }


class ZoneModel(Base):
    """Modèle SQLAlchemy pour les zones géographiques."""
    # ✅ CORRECTION: Table selon ZONE_QUERY
    __tablename__ = 't_zone'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_zone', Integer, primary_key=True, autoincrement=True)
    code = Column('mdzo_code', String(50), nullable=False)
    description = Column('mdzo_description', Text, nullable=False)
    entity = Column('mdzo_entity', String(50), nullable=True)
    
    @classmethod
    def from_db_row(cls, row: tuple) -> 'ZoneModel':
        """Crée depuis ZONE_QUERY"""
        zone = cls()
        zone.id = int(row[0]) if row[0] is not None else None
        zone.code = str(row[1]) if row[1] is not None else ""
        zone.description = str(row[2]) if row[2] is not None else ""
        zone.entity = str(row[3]) if len(row) > 3 and row[3] is not None else None
        return zone

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'entity': self.entity
        }


class FamilleModel(Base):
    """Modèle SQLAlchemy pour les familles d'équipements."""
    # ✅ CORRECTION: Table selon CATEGORY_QUERY
    __tablename__ = 't_category'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_category', Integer, primary_key=True, autoincrement=True)
    code = Column('mdct_code', String(50), nullable=False)
    description = Column('mdct_description', Text, nullable=False)
    parent_category = Column('mdct_parent_category', String(50), nullable=True)
    system_category = Column('mdct_system_category', String(50), nullable=True)
    level = Column('mdct_level', String(10), nullable=True)
    entity = Column('mdct_entity', String(50), nullable=True)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'FamilleModel':
        """Crée depuis CATEGORY_QUERY ou GET_FAMILLES_QUERY"""
        famille = cls()
        famille.id = int(row[0]) if row[0] is not None else None
        famille.code = str(row[1]) if row[1] is not None else ""
        famille.description = str(row[2]) if row[2] is not None else ""
        famille.parent_category = str(row[3]) if len(row) > 3 and row[3] is not None else None
        famille.system_category = str(row[4]) if len(row) > 4 and row[4] is not None else None
        famille.level = str(row[5]) if len(row) > 5 and row[5] is not None else None
        famille.entity = str(row[6]) if len(row) > 6 and row[6] is not None else None
        return famille

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'parent_category': self.parent_category,
            'system_category': self.system_category,
            'level': self.level,
            'entity': self.entity
        }


class EntityModel(Base):
    """Modèle SQLAlchemy pour les entités."""
    # ✅ CORRECTION: Table selon ENTITY_QUERY
    __tablename__ = 't_entity'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_entity', Integer, primary_key=True, autoincrement=True)
    code = Column('chen_code', String(50), nullable=False)
    description = Column('chen_description', Text, nullable=False)
    entity_type = Column('chen_entity_type', String(50), nullable=False)
    level = Column('chen_level', String(10), nullable=False, default="0")
    parent_entity = Column('chen_parent_entity', String(50), nullable=True)
    system_entity = Column('chen_system_entity', String(50), nullable=True)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'EntityModel':
        """Crée depuis ENTITY_QUERY"""
        entity = cls()
        entity.id = int(row[0]) if row[0] is not None else None
        entity.code = str(row[1]) if row[1] is not None else ""
        entity.description = str(row[2]) if row[2] is not None else ""
        entity.entity_type = str(row[3]) if row[3] is not None else ""
        entity.level = str(row[4]) if row[4] is not None else "1"
        entity.parent_entity = str(row[5]) if len(row) > 5 and row[5] is not None else None
        entity.system_entity = str(row[6]) if len(row) > 6 and row[6] is not None else None
        return entity

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'entity_type': self.entity_type,
            'level': self.level,
            'parent_entity': self.parent_entity,
            'system_entity': self.system_entity
        }


class CentreChargeModel(Base):
    """Modèle SQLAlchemy pour les centres de charge."""
    # ✅ CORRECTION: Table selon COSTCENTRE_QUERY
    __tablename__ = 't_costcentre'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_costcentre', Integer, primary_key=True, autoincrement=True)
    code = Column('mdcc_code', String(50), nullable=False)
    description = Column('mdcc_description', Text, nullable=False)
    entity = Column('mdcc_entity', String(50), nullable=True)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'CentreChargeModel':
        """Crée depuis COSTCENTRE_QUERY"""
        centre = cls()
        centre.id = int(row[0]) if row[0] is not None else None
        centre.code = str(row[1]) if row[1] is not None else ""
        centre.description = str(row[2]) if row[2] is not None else ""
        centre.entity = str(row[3]) if len(row) > 3 and row[3] is not None else None
        return centre

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'entity': self.entity
        }


class UniteModel(Base):
    """Modèle SQLAlchemy pour les unités organisationnelles."""
    # ✅ CORRECTION: Table selon FUNCTION_QUERY
    __tablename__ = 't_function_'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_function_', Integer, primary_key=True, autoincrement=True)
    code = Column('mdfn_code', String(50), nullable=False)
    description = Column('mdfn_description', Text, nullable=False)
    entity = Column('mdfn_entity', String(50), nullable=True)
    parent_function = Column('mdfn_parent_function', String(50), nullable=True)  # ✅ CORRECTION
    system_function = Column('mdfn_system_function', String(50), nullable=True)  # ✅ CORRECTION

    @classmethod
    def from_db_row(cls, row: tuple) -> 'UniteModel':
        """Crée depuis FUNCTION_QUERY"""
        unite = cls()
        unite.id = int(row[0]) if row[0] is not None else None
        unite.code = str(row[1]) if row[1] is not None else ""
        unite.description = str(row[2]) if row[2] is not None else ""
        unite.entity = str(row[3]) if len(row) > 3 and row[3] is not None else None
        unite.parent_function = str(row[4]) if len(row) > 4 and row[4] is not None else None
        unite.system_function = str(row[5]) if len(row) > 5 and row[5] is not None else None
        return unite

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'code': self.code,
            'description': self.description,
            'entity': self.entity,
            'parent_function': self.parent_function,
            'system_function': self.system_function
        }


# ✅ SUPPRIMÉ: FeederModel (les feeders sont des équipements dans t_equipment)

class EquipmentSpecs(Base):
    """Modèle SQLAlchemy pour equipment_specs selon EQUIPMENT_SPEC_ADD_QUERY"""
    __tablename__ = 'equipment_specs'
    __table_args__ = {'schema': 'coswin'}
    
    id = Column('pk_equipment_specs', Integer, primary_key=True, autoincrement=True)
    etes_specification = Column(String(50), nullable=False)  # cwsp_code
    etes_equipment = Column(String(50), nullable=False)      # ereq_code
    etes_release_date = Column(DateTime, default=func.now())
    etes_release_number = Column(Integer, default=1)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'specification': self.etes_specification,
            'equipment': self.etes_equipment,
            'release_date': self.etes_release_date.isoformat() if self.etes_release_date is not None else None,
            'release_number': self.etes_release_number
        }


class EquipmentAttribute(Base):
    """Modèle SQLAlchemy pour equipment_attribute selon EQUIPMENT_ATTRIBUTE_ADD_QUERY"""
    __tablename__ = 'equipment_attribute'
    __table_args__ = {'schema': 'coswin'}
    
    # ✅ Clés primaires composites
    commonkey = Column(Integer, primary_key=True)  # pk_equipment_specs
    indx = Column(String(10), primary_key=True)    # cwat_index
    etat_value = Column(Text, nullable=True)       # Valeur de l'attribut

    def to_dict(self) -> Dict[str, Any]:
        return {
            'commonkey': self.commonkey,
            'index': self.indx,
            'value': self.etat_value
        }


class Specification(Base):
    """Modèle SQLAlchemy pour t_specification selon EQUIPMENT_T_SPECIFICATION_QUERY"""
    __tablename__ = 't_specification'
    __table_args__ = {'schema': 'coswin'}
    
    pk_specification = Column(Integer, primary_key=True, autoincrement=True)
    cwsp_code = Column(String(50), nullable=False, unique=True)
    cwsp_description = Column(Text, nullable=True)

    def to_dict(self) -> Dict[str, Any]:
        return {
            'pk_specification': self.pk_specification,
            'code': self.cwsp_code,
            'description': self.cwsp_description
        }


class Attribute(Base):
    """Modèle SQLAlchemy pour attribute selon EQUIPMENT_CLASSE_ATTRIBUTS_QUERY"""
    __tablename__ = 'attribute'
    __table_args__ = {'schema': 'coswin'}
    
    pk_attribute = Column(Integer, primary_key=True, autoincrement=True)
    cwat_index = Column(String(10), nullable=False)
    cwat_specification = Column(Integer, ForeignKey('coswin.t_specification.pk_specification'))
    cwat_name = Column(String(255), nullable=False)
    cwat_type = Column(String(50), default='string')

    def to_dict(self) -> Dict[str, Any]:
        return {
            'pk_attribute': self.pk_attribute,
            'index': self.cwat_index,
            'specification': self.cwat_specification,
            'name': self.cwat_name,
            'type': self.cwat_type
        }


class AttributeValues(Base):
    """Modèle SQLAlchemy pour attribute_values selon ATTRIBUTE_VALUES_QUERY"""
    __tablename__ = 'attribute_values'
    __table_args__ = {'schema': 'coswin'}
    
    pk_attribute_values = Column(Integer, primary_key=True, autoincrement=True)
    cwav_specification = Column(String(50), nullable=False)
    cwav_attribute_index = Column(String(10), nullable=False)
    cwav_value = Column(Text, nullable=False)

    @classmethod
    def from_db_row(cls, row: tuple) -> 'AttributeValues':
        """Crée depuis ATTRIBUTE_VALUES_QUERY"""
        attr_val = cls()
        attr_val.pk_attribute_values = int(row[0]) if row[0] is not None else None
        attr_val.cwav_value = str(row[1]) if row[1] is not None else ""
        return attr_val

    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.pk_attribute_values) if self.pk_attribute_values is not None else None,
            'specification': self.cwav_specification,
            'attribute_index': self.cwav_attribute_index,
            'value': self.cwav_value
        }


# ✅ NOUVEAU: Builder pour construire les équipements avec attributs
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

# ✅ NOUVEAU: Modèles pour l'historique des modifications pour Clic Clac

class AttributeClicClac(Base):
    __tablename__ = "attribute"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    specification = Column(String(255), nullable=False, index=True)
    famille = Column(String(255), nullable=False, index=True)
    indx = Column(Integer, nullable=False)
    attribute_name = Column(String(255), nullable=False)
    value = Column(String, nullable=True)
    code = Column(String(255), nullable=False, index=True)
    description = Column(String, nullable=True)
    is_copy_ot = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'specification': self.specification,
            'famille': self.famille,
            'indx': self.indx,
            'attribute_name': self.attribute_name,
            'value': self.value,
            'code': self.code,
            'description': self.description,
            'is_copy_ot': self.is_copy_ot,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None
        }

class EquipmentClicClac(Base):
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
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
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
    
class HistoryEquipmentClicClac(Base):
    __tablename__ = "history_equipment"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    commentaire = Column(String(255), nullable=True)
    date_history_created_at = Column(DateTime, default=func.now(), nullable=False)
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
    created_at = Column(DateTime, nullable=True)
    updated_at = Column(DateTime, nullable=True)
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

class HistoryAttributeClicClac(Base):
    __tablename__ = "history_attribute"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    history_id = Column(Integer, ForeignKey('dbo.history_equipment.id', ondelete='CASCADE'), nullable=False, index=True)
    attribute_id = Column(Integer, nullable=True, index=True)
    attribute_name = Column(String(255), nullable=True)
    value = Column(Text, nullable=True)
    code = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'history_id': str(self.history_id) if self.history_id is not None else None,
            'attribute_id': str(self.attribute_id) if self.attribute_id is not None else None,
            'attribute_name': self.attribute_name,
            'value': self.value,
            'code': self.code,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None
        }

class UserClicClac(Base):
    __tablename__ = "users"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(150), nullable=False, unique=True, index=True)
    password = Column(String(512), nullable=False)  # stocke le hash bcrypt / argon2
    email = Column(String(255), nullable=False, unique=True, index=True)
    supervisor = Column(Integer, ForeignKey('dbo.users.id', ondelete='SET NULL'), nullable=True, index=True)
    url_image = Column(String(512), nullable=True)
    address = Column(Text, nullable=True)
    company = Column(String(255), nullable=True)
    role = Column(String(100), nullable=False, default='user', index=True)
    is_connected = Column(Boolean, default=False, nullable=True, index=True)
    is_enabled = Column(Boolean, default=True, nullable=True, index=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
    
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'username': self.username,
            'email': self.email,
            'supervisor': str(self.supervisor) if self.supervisor is not None else None,
            'url_image': self.url_image,
            'role': self.role,
            'address': self.address,
            'company': self.company,
            'is_connected': self.is_connected,
            'is_enabled': self.is_enabled,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None
        }
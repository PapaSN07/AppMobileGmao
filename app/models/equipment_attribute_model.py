from sqlalchemy import Integer, Text
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String

Base = declarative_base()


class EquipmentAttribute(Base):
    """Modèle SQLAlchemy pour equipment_attribute selon EQUIPMENT_ATTRIBUTE_ADD_QUERY"""
    __tablename__ = 'equipment_attribute'
    __table_args__ = {'schema': 'dbo'}
    
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
from sqlalchemy import Boolean, Date, ForeignKey, Integer, Text, func

from typing import Any, Dict
from sqlalchemy import Column, String

# Importer les deux bases depuis engine
from app.db.sqlalchemy.engine import Base, BaseClicClac

class Attribute(Base):
    """Modèle SQLAlchemy pour attribute selon EQUIPMENT_CLASSE_ATTRIBUTS_QUERY"""
    __tablename__ = 'attribute'
    __table_args__ = {'schema': 'dbo'}
    
    pk_attribute = Column(Integer, primary_key=True, autoincrement=True)
    cwat_index = Column(String(10), nullable=False)
    cwat_specification = Column(Integer, ForeignKey('dbo.t_specification.pk_specification'))
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

class AttributeClicClac(BaseClicClac):
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
    created_at = Column(Date, default=func.now())
    updated_at = Column(Date, default=func.now(), onupdate=func.now())
    
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

class HistoryAttributeClicClac(BaseClicClac):
    __tablename__ = "history_attribute"
    __table_args__ = {'schema': 'dbo'}

    id = Column(Integer, primary_key=True, autoincrement=True)
    history_id = Column(Integer, ForeignKey('dbo.history_equipment.id', ondelete='CASCADE'), nullable=False, index=True)
    specification = Column(String(255), nullable=False, index=True)
    famille = Column(String(255), nullable=False, index=True)
    indx = Column(Integer, nullable=True, index=True)
    attribute_name = Column(String(255), nullable=True)
    value = Column(Text, nullable=True)
    code = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)
    is_copy_ot = Column(Boolean, default=False)
    created_at = Column(Date, nullable=False)
    updated_at = Column(Date, nullable=False)
    date_history_created_at = Column(Date, default=func.now(), onupdate=func.now(), nullable=False)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'id': str(self.id) if self.id is not None else None,
            'history_id': str(self.history_id) if self.history_id is not None else None,
            'specification': self.specification,
            'famille': self.famille,
            'indx': str(self.indx) if self.indx is not None else None,
            'attribute_name': self.attribute_name,
            'value': self.value,
            'code': self.code,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at is not None else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at is not None else None,
            'date_history_created_at': self.date_history_created_at.isoformat() if self.date_history_created_at is not None else None
        }
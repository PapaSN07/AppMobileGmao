from sqlalchemy import Integer
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String, Text


Base = declarative_base()

class EntityModel(Base):
    """Modèle SQLAlchemy pour les entités."""
    __tablename__ = 'entity'
    __table_args__ = {'schema': 'dbo'}
    
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
from sqlalchemy import Integer
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String, Text


Base = declarative_base()

class FamilleModel(Base):
    """Modèle SQLAlchemy pour les familles d'équipements."""
    # ✅ CORRECTION: Table selon CATEGORY_QUERY
    __tablename__ = 'category'
    __table_args__ = {'schema': 'dbo'}
    
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
from sqlalchemy import Integer
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String, Text

Base = declarative_base()

class CentreChargeModel(Base):
    """Modèle SQLAlchemy pour les centres de charge."""
    # ✅ CORRECTION: Table selon COSTCENTRE_QUERY
    __tablename__ = 'costcentre'
    __table_args__ = {'schema': 'dbo'}
    
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
from sqlalchemy import Integer
from sqlalchemy.orm import declarative_base

from typing import Any, Dict
from sqlalchemy import Column, String, Text


Base = declarative_base()

class ZoneModel(Base):
    """Modèle SQLAlchemy pour les zones géographiques."""
    __tablename__ = 'zone'
    __table_args__ = {'schema': 'dbo'}
    
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